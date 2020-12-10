//
//  WDAudioMuteSwitchManager.h
//  WDAudioMuteSwitch
//
//  Created by 伟东 on 2020/12/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^WDAudioMuteSwitchManagerCallBack)(BOOL ismute);

@interface WDAudioMuteSwitchManager : NSObject

+ (instancetype)sharedInstance;

- (void)getAudioMuteSwitch:(WDAudioMuteSwitchManagerCallBack)callback;

@end

NS_ASSUME_NONNULL_END
