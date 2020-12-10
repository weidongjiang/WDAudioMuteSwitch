//
//  ViewController.m
//  WDAudioMuteSwitch
//
//  Created by 伟东 on 2020/12/10.
//

#import "ViewController.h"
#import "WDAudioMuteSwitchManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[WDAudioMuteSwitchManager sharedInstance] getAudioMuteSwitch:^(BOOL ismute) {
        NSLog(@"getAudioMuteSwitch--%d",ismute?1:0);
    }];
}


@end
