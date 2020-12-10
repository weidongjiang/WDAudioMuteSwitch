# WDAudioMuteSwitch
iOS获取设备静音键的开关状态



#题记：检测苹果手机的物理静音按键的开关状态

最近业务上有个需求就是以静音键的状态来做一些逻辑显示，但是在iOS5以后，苹果就没有开放现成的api来获取静音键的状态。只要遇到这样的情况，基本都是“曲线救国”。

###目前网上基本获取静音键的状态大体有三种方式：
####第一种：使用对应的api获取

```
CFStringRef state = nil;
UInt32 propertySize = sizeof(CFStringRef);
AudioSessionInitialize(NULL, NULL, NULL, NULL);
OSStatus status = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &state);
    
if (status == kAudioSessionNoError){
     return (CFStringGetLength(state) == 0);   // YES = silent
}
    return NO;
```
试了试，但是获取状态不正确。

####第二种方式：
通过播放一段短的白噪音，根据回调时间差来计数，然后根据计数的大小来判断是否静音。[参考文献](https://github.com/Rich2k/RBDMuteSwitch).
但是这种方式的获取也存在一些误差，在某些情况下，由于runloop的时机，以及计数的误差，加上判断阀值的设定，总会有些误差导致有那么几次静音键的状态获取不对。


####第三种方式：
国外大佬的解决方案，[SoundSwitch.zip](http://sharkfood.com/content/Developers/content/Sound%20Switch/SoundSwitch.zip).但是此地址打开失败。


综合以上情况，最后选择了第二种方式来获取静音键的开关状态。所以一直在查找那些为什么状态获取失败的原因。

在我调试的时候，发现在静音键关闭的时候，获取状态为开的时候，获取音量的值始终为0.
```
[[AVAudioSession sharedInstance] outputVolume]
```

至此，可以知道有两个地方的影响，导致获取静音键按钮的开光状态的误差原因。
1、在某些情况下，由于runloop的时机，以及计数的误差，加上判断阀值的设定，导致判断出错。
2、当前获取音量的值为0影响了获取结果。


###优化方案：
1、摒弃runloop技术策略，改用播放时间戳的判断。因为上面demo的思想就是播放一个短音效。所以根据前后播放时间差的判断，规避由于计数器的判断误差。

2、针对获取音量的值为0情况，一般都是AVFoundation获取音量的时候，播放器没有激活。或者播放器声道资源被占用。所以在每一次播放白噪音时，提前设置AVAudioSession,并且播放一算音频，确保在获取前声道没有被第三方或者APP里面的其他播放业务打断。

```
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];//保证不会打断第三方app的音频播放 导致获取不准确
    NSString *itemVideoPath = [[NSBundle mainBundle] pathForResource:@"detection" ofType:@"aiff"];
    AVPlayer *player = [AVPlayer playerWithURL:[NSURL URLWithString:itemVideoPath]];
    [player play];
```


最终解决方案代码：核心代码

[demo地址]()

HTAudioMonitorManager.m
```


static void PlaySoundCompletionBlock(SystemSoundID SSID,void*clientData) {
    AudioServicesRemoveSystemSoundCompletion(SSID);
    [[HTAudioMonitorManager sharedInstance] updateAudioMonitor];
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


- (void)showAudioMonitorTips:(int)volume {
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];//保证不会打断第三方app的音频播放 导致获取不准确
    NSString *itemVideoPath = [[NSBundle mainBundle] pathForResource:@"detection" ofType:@"aiff"];
    AVPlayer *player = [AVPlayer playerWithURL:[NSURL URLWithString:itemVideoPath]];
    [player play];
    
    [self audioMonitorMuteCallBack:^(BOOL ismute) {
        CGFloat outputVolume = [[AVAudioSession sharedInstance] outputVolume]*100;
        NSLog(@"showAudioMonitorTips--ismute-%d---outputVolume-%f---volume%d---currentThread--%@",ismute?1:0,outputVolume,volume,[NSThread currentThread]);
        if (ismute || (outputVolume < volume && outputVolume >= 0)) {
            [HTProgressHUD showTips:@"设备音量太小或处于静音模式，请调大音量哦~" duration:3.5];
        }
    }];
}

+ (void)showAudioMuteTips:(int)volume {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[HTAudioMonitorManager sharedInstance] showAudioMonitorTips:volume];
    });
}

@end
```







