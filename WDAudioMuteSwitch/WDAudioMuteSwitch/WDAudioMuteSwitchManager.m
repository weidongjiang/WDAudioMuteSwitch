//
//  WDAudioMuteSwitchManager.m
//  WDAudioMuteSwitch
//
//  Created by 伟东 on 2020/12/10.
//

#import "WDAudioMuteSwitchManager.h"
#import <AVFoundation/AVFoundation.h>

#define HTAudioMonitorManager_monitorMute_key @"HTAudioMonitorManager_monitorMute_key"

@interface WDAudioMuteSwitchManager ()

@property (nonatomic, strong) NSDate *beginPlayDate;
- (void)updateAudioMonitor;

@end

static void PlaySoundCompletionBlock(SystemSoundID SSID,void*clientData) {
    AudioServicesRemoveSystemSoundCompletion(SSID);
    [[WDAudioMuteSwitchManager sharedInstance] updateAudioMonitor];
}


@implementation WDAudioMuteSwitchManager
static WDAudioMuteSwitchManager *sharedInstance = nil;
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WDAudioMuteSwitchManager alloc] init];
    });
    return sharedInstance;
}

- (void)updateAudioMonitor {

    NSTimeInterval playDuring = [[NSDate date] timeIntervalSinceDate:self.beginPlayDate];
    BOOL ismute;
    if (playDuring >= 0.1) {
        ismute = NO;
    }else{
        ismute = YES;
    }
    [[NSUserDefaults standardUserDefaults] setBool:ismute forKey:HTAudioMonitorManager_monitorMute_key];
}

- (void)audioMonitorMuteCallBack:(void(^)(BOOL ismute))callback {
    
    self.beginPlayDate = [NSDate date];
    
    CFURLRef soundFileURLRef = CFBundleCopyResourceURL(CFBundleGetMainBundle(),CFSTR("detection"),CFSTR("aiff"),NULL);
    SystemSoundID soundFileID;
    AudioServicesCreateSystemSoundID(soundFileURLRef, &soundFileID);
    AudioServicesAddSystemSoundCompletion(soundFileID,NULL,NULL, PlaySoundCompletionBlock, (__bridge void*)self);
    AudioServicesPlaySystemSound(soundFileID);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL _ismute = [[NSUserDefaults standardUserDefaults] boolForKey:HTAudioMonitorManager_monitorMute_key];
        if (callback) {
            callback(_ismute);
        }
    });
}


- (void)getAudioMuteSwitch:(WDAudioMuteSwitchManagerCallBack)callback {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _getAudioMuteSwitch:callback];
    });
}

- (void)_getAudioMuteSwitch:(WDAudioMuteSwitchManagerCallBack)callback {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];//保证不会打断第三方app的音频播放 导致获取不准确
    NSString *itemVideoPath = [[NSBundle mainBundle] pathForResource:@"detection" ofType:@"aiff"];
    AVPlayer *player = [AVPlayer playerWithURL:[NSURL URLWithString:itemVideoPath]];
    [player play];
    
    [self audioMonitorMuteCallBack:^(BOOL ismute) {
        if (callback) {
            callback(ismute);
        }
    }];
}

@end






