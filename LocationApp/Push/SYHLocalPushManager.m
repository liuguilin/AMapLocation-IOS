//
//  SYHLocalPushManager.m
//  LocationApp
//
//  Created by 大伊 on 2025/5/31.
//

#import "SYHLocalPushManager.h"
#import <UserNotifications/UserNotifications.h>
#import "SYHSubmitDataService.h"


@interface SYHLocalPushManager()<UNUserNotificationCenterDelegate>
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSMutableDictionary *LocalNotificaiton;


@end

@implementation SYHLocalPushManager

+ (instancetype)shared {
    static SYHLocalPushManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)requestAuthorization {
    // 请求通知权限
      UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
      center.delegate = self;
      [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound)
                           completionHandler:^(BOOL granted, NSError * _Nullable error) {
          if (!granted) {
              NSLog(@"用户拒绝了通知权限");
          }
      }];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self startTimer];
        /// 测试代码
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self scheduleLocalNotificationWithTitle:@"温馨提示" body:@"请打开app并且，填写问卷" after:1];
//        });
    }
    return self;
}


- (void)startTimer {
    __weak typeof(self) weakSelf = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:120 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [weakSelf pushNotificaitionIfNeeded];
    }];
}


- (void)pushNotificaitionIfNeeded {
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:now];
    NSInteger currentHour = components.hour;
    NSString *yearMonthDay = [NSString stringWithFormat:@"%ld.%ld.%ld", components.year, components.month, components.day];
    
    NSString *type;
    if (currentHour >= 8 && currentHour < 20) {
        type = @"day";
    } else {
        type = @"night";
    }
    
    if (currentHour == 8 || currentHour == 20) { // 第一次推送
//    if ((currentHour == 21 && components.minute > 50) || currentHour == 20) {
        NSLog(@"当前时间为：%ld点", currentHour);
        
        NSString *localKey = [self localNotificationKeyWithYearMonthDay:yearMonthDay type:type];

        BOOL isPush = [[NSUserDefaults standardUserDefaults] boolForKey:localKey];
        if (!isPush) {
            [self scheduleLocalNotificationWithTitle:NSLocalizedString(@"温馨提示", nil) body:NSLocalizedString(@"请打开app并且，填写问卷", nil) after:1];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:localKey];
        }
    } else if (currentHour == 9 || currentHour == 21) { // 第二次推送
        NSString *secondPushLocalKey = [self secondLocalNotificationKeyWithYearMonthDay:yearMonthDay type:type];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:secondPushLocalKey]) { // 如果已经二次推送了，直接返回
            return;
        }
        
        NSString *updateSuccessStatusKey = [SYHSubmitDataService.shared localKeyWithYear:components.year month:components.month day:components.day type:type];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:updateSuccessStatusKey]) { // 如果没有二次推送，但是已经提交过数据了，也不再进行二次推送
            return;
        }
        
        [self scheduleLocalNotificationWithTitle:NSLocalizedString(@"温馨提示", nil) body:NSLocalizedString(@"请打开app并且，填写问卷", nil) after:1];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:secondPushLocalKey];
        
    }
}


// 创建并发送本地通知
- (void)scheduleLocalNotificationWithTitle:(NSString *)title body:(NSString *)body after:(NSTimeInterval)seconds {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = title;
    content.body = body;
    content.sound = [UNNotificationSound defaultSound];
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger
                                                triggerWithTimeInterval:seconds
                                                repeats:NO];
    
    NSString *identifier = [NSString stringWithFormat:@"localNotification-%@", [[NSUUID UUID] UUIDString]];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                        content:content
                                                                        trigger:trigger];
    
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request
                                                         withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"添加通知失败: %@", error);
        }
    }];
}

#pragma mark - UserDefault

- (NSString *)secondLocalNotificationKeyWithYearMonthDay:(NSString *)YearMonthDayString type:(NSString *)type {
    return [NSString stringWithFormat:@"second_locationNotificationPush_%@_%@", YearMonthDayString, type];
}

- (NSString *)localNotificationKeyWithYearMonthDay:(NSString *)YearMonthDayString type:(NSString *)type {
    return [NSString stringWithFormat:@"locationNotificationPush_%@_%@", YearMonthDayString, type];
}


#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    NSLog(@"willPresentNotification");
    completionHandler(UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound);

}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    NSLog(@"用户点击了通知: %@", response.notification.request.content.userInfo);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SYHUserDidReceiveNotificationResponse object:nil];
    
    completionHandler();
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(nullable UNNotification *)notification {
    NSLog(@"openSettingsForNotification");

}

@end
