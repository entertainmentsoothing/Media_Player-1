//
//  AppDefine.h
//  YoutubeSearch
//
//  Created by An Nguyen on 2/24/18.
//  Copyright © 2018 An Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability/Reachability.h"

#define ChangeDataNotification @"ChangeDataNotification"
#define PlayerAppearNotification @"PlayerAppearNotification"
#define ADMOB_APP_ID @"ca-app-pub-4842169906324435~7542120276"
#define ADMOB_BANNER_ID @"ca-app-pub-4842169906324435/6101702634"
#define ADMOB_INTERSTITIAL_ID @"ca-app-pub-4842169906324435/4201641060"
#define ADMOB_REWARDED_VIDEO_ID @"ca-app-pub-4842169906324435/6659395397"

@interface AppDefine : NSObject
+ (instancetype) sharedInstance;
@property (nonatomic) BOOL isInAD;
@property (nonatomic) Reachability *internetReachability;
@end
