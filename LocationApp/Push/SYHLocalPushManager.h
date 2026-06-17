//
//  SYHLocalPushManager.h
//  LocationApp
//
//  Created by 大伊 on 2025/5/31.
//

#import <Foundation/Foundation.h>

static NSString * _Nullable SYHUserDidReceiveNotificationResponse = @"SYHUserDidReceiveNotificationResponse";

NS_ASSUME_NONNULL_BEGIN

@interface SYHLocalPushManager : NSObject
+ (instancetype)shared;

- (void)requestAuthorization;
@end

NS_ASSUME_NONNULL_END
