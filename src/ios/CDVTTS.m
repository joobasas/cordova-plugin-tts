/*
    Cordova Text-to-Speech Plugin
    https://github.com/vilic/cordova-plugin-tts

    by VILIC VANE
    https://github.com/vilic

    MIT License
*/

#import <Cordova/CDV.h>
#import <Cordova/CDVAvailability.h>
#import "CDVTTS.h"

@implementation CDVTTS

- (void) pluginInitialize {
    audioReleased = YES;
    synthesizer = [AVSpeechSynthesizer new];
    synthesizer.delegate = self;
    speaking = NO;

    audioSession = AVAudioSession.sharedInstance;
    audioSessionCategory = audioSession.category;
    audioSessionCategoryOptions = audioSession.categoryOptions;
    NSLog(@"currentAudioCategory %@", audioSessionCategory);

    [self observeLifeCycle];
    [self configureAudioPlayer];

    /*
        @Todo : Send js events to the webview for refresh
    */
    // [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(tick) userInfo:nil repeats:YES];
}

- (void) tick {
    /*
        @Todo : Send js events to the webview for refresh
    */
    return;

    switch (UIApplication.sharedApplication.applicationState) {
        case UIApplicationStateActive:
            NSLog(@"beep:app in foreground");
            break;
        case UIApplicationStateBackground:
            NSLog(@"beep:app in background");
            break;
        default:
            NSLog(@"beep:app inactive");
            break;
    }
    NSLog(@"beep:is playing %d",audioPlayer.isPlaying);
    NSLog(@"beep:background time remaining: %f",UIApplication.sharedApplication.backgroundTimeRemaining);
}

/**
 * Register the listener for pause and resume events.
 */
- (void) observeLifeCycle
{
    NSNotificationCenter* listener = [NSNotificationCenter
                                      defaultCenter];

        [listener addObserver:self
                     selector:@selector(keepAwake)
                         name:UIApplicationDidEnterBackgroundNotification
                       object:nil];

        [listener addObserver:self
                     selector:@selector(stopKeepingAwake)
                         name:UIApplicationWillEnterForegroundNotification
                       object:nil];

        [listener addObserver:self
                     selector:@selector(handleAudioSessionInterruption:)
                         name:AVAudioSessionInterruptionNotification
                       object:nil];
}

/**
 * Keep the app awake.
 */
- (void) keepAwake
{
    /*
    if (!enabled) {
        return;
    }
    */

    if(speaking) {
        return;
    }

    [audioPlayer play];
}

/**
 * Let the app going to sleep.
 */
- (void) stopKeepingAwake
{
    [audioPlayer pause];
}

/**
 * Configure the audio player.
 */
- (void) configureAudioPlayer
{
    NSString* path = [[NSBundle mainBundle]
                      pathForResource:@"jooba-beep" ofType:@"wav"];

    NSURL* url = [NSURL fileURLWithPath:path];


    audioPlayer = [[AVAudioPlayer alloc]
                   initWithContentsOfURL:url error:NULL];

    audioPlayer.volume        = 0.0;
    audioPlayer.numberOfLoops = -1;
};

/**
 * Restart playing sound when interrupted by phone calls.
 */
- (void) handleAudioSessionInterruption:(NSNotification*)notification
{
    // NSLog(@"beep handle audio interruption");
    [self keepAwake];
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];


    if (lastCallbackId) {
        //NSLog(@"jooba:finished speak lcid %@ -- %@",lastCallbackId,callbackId);
        [self.commandDelegate sendPluginResult:result callbackId:lastCallbackId];
        lastCallbackId = nil;
    } else {
        //NSLog(@"jooba:finished speak %@",callbackId);
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        callbackId = nil;
    }

    speaking = NO;
    [self releaseAudioSession];
}

/**
 * Request the audio session
 */
- (void) requestAudioSession {

    /*
    if(!audioReleased) {
        NSLog(@"jooba:audio not released yet!");
        //return;
    }
    */
    // NSLog(@"jooba:requested audio session");

    if(audioPlayer.isPlaying) {
        [audioPlayer pause];
    }

    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions: AVAudioSessionCategoryOptionDuckOthers error: nil];
    [[AVAudioSession sharedInstance] setActive:YES withOptions: AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];

    audioReleased = NO;
}

- (void) releaseAudioSession {
    /*
    if(audioReleased) {
        NSLog(@"jooba:audio already released");
    }
    */

    //NSLog(@"jooba:released audio session");

    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions: AVAudioSessionCategoryOptionMixWithOthers error: nil];
    [[AVAudioSession sharedInstance] setActive:YES withOptions: AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];

    audioReleased = YES;
    [audioPlayer play];
}

- (void) stopSpeak {
    //NSLog(@"jooba:Stop tts speak");
     if(synthesizer.isSpeaking) {
        [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }

    [self releaseAudioSession];

    if(stopCallbackId){
        //NSLog(@"jooba:Stop speak sc %@ -- %@",stopCallbackId, lastCallbackId);
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:stopCallbackId];
        stopCallbackId = nil;
    }

    if(lastCallbackId){
        //NSLog(@"jooba:Stop speak %@ -- %@",stopCallbackId, lastCallbackId);
        CDVPluginResult* reject = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:reject callbackId:lastCallbackId];
        lastCallbackId = nil;
    }

    speaking = NO;
}


- (void)speak:(CDVInvokedUrlCommand*)command {
    //NSLog(@"jooba:Speak command %@",command.callbackId);
    speaking = YES;
    speakCallbackId = command.callbackId;
    NSDictionary* options = [command.arguments objectAtIndex:0];
    NSString* text = [options objectForKey:@"text"];
    NSString* locale = [options objectForKey:@"locale"];
    double rate = [[options objectForKey:@"rate"] doubleValue];
    NSString* category = [options objectForKey:@"category"];

    /* Removed
    if ([category isEqualToString:@"ambient"]) {
    } else {
    }
    */

    if (callbackId) {
        lastCallbackId = callbackId;
    }

    if(synthesizer.isSpeaking){
        [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        [self stopSpeak];
    }

    callbackId = command.callbackId;

    double pitch = [[options objectForKey:@"pitch"] doubleValue];

    if (!locale || (id)locale == [NSNull null]) {
        locale = @"en-US";
    }

    if (!rate) {
        rate = 1.0;
    }

    if (!pitch) {
        pitch = 1.2;
    }

    AVSpeechUtterance* utterance = [[AVSpeechUtterance new] initWithString:text];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:locale];
    // Rate expression adjusted manually for a closer match to other platform.
    utterance.rate = (AVSpeechUtteranceMinimumSpeechRate * 1.5 + AVSpeechUtteranceDefaultSpeechRate) / 2.25 * rate * rate;
    // workaround for https://github.com/vilic/cordova-plugin-tts/issues/21
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
       utterance.rate = utterance.rate * 2;
       // see http://stackoverflow.com/questions/26097725/avspeechuterrance-speed-in-ios-8
    }

    utterance.pitchMultiplier = pitch;
    utterance.volume = 1.0;
    [self requestAudioSession];

    [synthesizer speakUtterance:utterance];
}

- (void)stop:(CDVInvokedUrlCommand*)command {
    // NSLog(@"jooba:Stop command %@", command.callbackId);
    stopCallbackId = command.callbackId;

    if(synthesizer.isSpeaking) {
        [synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }

    [self stopSpeak];
    [self releaseAudioSession];
}

- (void)checkLanguage:(CDVInvokedUrlCommand *)command {
    NSArray *voices = [AVSpeechSynthesisVoice speechVoices];
    NSString *languages = @"";
    for (id voiceName in voices) {
        languages = [languages stringByAppendingString:@","];
        languages = [languages stringByAppendingString:[voiceName valueForKey:@"language"]];
    }
    if ([languages hasPrefix:@","] && [languages length] > 1) {
        languages = [languages substringFromIndex:1];
    }

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:languages];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}
@end
