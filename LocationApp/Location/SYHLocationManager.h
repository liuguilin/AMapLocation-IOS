//
//  LocationManager.h
//  LocationApp
//
//  Created by 大伊 on 2025/5/24.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import "SYHLocationModel.h"
#import "SYHAnswerResult.h"
static NSString * _Nullable SYHAnswerDataUpdateNotificationResponse = @"SYHAnswerDataUpdateNotificationResponse";

@interface SYHLocationManager : NSObject <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *manager;
@property (weak, nonatomic) UIViewController *viewController;
@property (nonatomic, copy) void(^locationUpdateBlock)(CLLocationCoordinate2D);
@property (nonatomic, strong) NSMutableArray *locationArray;
@property (nonatomic, strong, readonly) NSMutableArray <SYHAnswerResult *>*answerArray;

+ (instancetype)shared;
- (void)startTracking;
- (void)stopTracking;

- (void)saveLocalData;
- (void)deleteLocations:(NSArray<SYHLocationModel *> *)locations;
- (void)updateAnswerDataWithType:(NSString *)type year:(int)year month:(int)month day:(int)day isCommit:(BOOL)isCommit;

@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTask;
// 启动后台任务（.m文件）
- (void)startBackgroundLocation;

@end

