/*
	Cordova Text-to-Speech Plugin
	https://github.com/vilic/cordova-plugin-tts

	by VILIC VANE
	https://github.com/vilic

	MIT License
 */

#import <Cordova/CDV.h>
#import <AVFoundation/AVFoundation.h>

@interface CDVTTS : CDVPlugin <AVSpeechSynthesizerDelegate> {
    AVSpeechSynthesizer* synthesizer;
    NSString* lastCallbackId;
    NSString* callbackId;
    NSString* stopCallbackId;
    NSString* speakCallbackId;
    AVAudioSession* audioSession;
    AVAudioSessionCategory audioSessionCategory;
    AVAudioSessionCategoryOptions audioSessionCategoryOptions;
    AVAudioPlayer* audioPlayer;
    NSTimer *timer;
    BOOL enabled;
    BOOL speaking;
    BOOL audioReleased;
}

- (void)speak:(CDVInvokedUrlCommand*)command;
- (void)stopSpeak;
- (void)stop:(CDVInvokedUrlCommand*)command;
- (void)checkLanguage:(CDVInvokedUrlCommand*)command;
@end
