//
//  AppDefine.m
//  YoutubeSearch
//
//  Created by An Nguyen on 2/24/18.
//  Copyright © 2018 An Nguyen. All rights reserved.
//

#import "AppDefine.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface AppDefine ()<GADRewardBasedVideoAdDelegate>

@end

@implementation AppDefine

+ (instancetype) sharedInstance {
    static AppDefine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AppDefine alloc]init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.internetReachability = [Reachability reachabilityForInternetConnection];
        [self.internetReachability startNotifier];
        
        [GADRewardBasedVideoAd sharedInstance].delegate = self;
        [self requestRewardedVideo];
    }
    return self;
}

- (void) requestRewardedVideo {
    GADRequest *request = [GADRequest request];
    [[GADRewardBasedVideoAd sharedInstance] loadRequest:request withAdUnitID:ADMOB_REWARDED_VIDEO_ID];
}

- (void)rewardBasedVideoAd:(nonnull GADRewardBasedVideoAd *)rewardBasedVideoAd didRewardUserWithReward:(nonnull GADAdReward *)reward {
    
}
- (void)rewardBasedVideoAdWillLeaveApplication:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    NSLog(@">>> Leave");
}
- (void)rewardBasedVideoAdDidOpen:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    NSLog(@">>> Open");
}

-(void)rewardBasedVideoAdDidClose:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    NSLog(@">>> Closed");
    [self requestRewardedVideo];
}
@end
