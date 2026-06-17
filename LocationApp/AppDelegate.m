//
//  AppDelegate.m
//  LocationApp
//
//  Created by 大伊 on 2025/5/24.
//

#import "AppDelegate.h"
#import "UrlHeader.h"
#import "SYHLocalPushManager.h"
#import "SYHLocationManager.h"
#import "SYSystemSettingHelper.h"
@import GoogleMaps;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
//    [GMSServices provideAPIKey:@"ddd"];
    // 注册地图
    [GMSServices provideAPIKey:google_appkey];
//    [GMSPlacesClient provideAPIKey:@"YOUR_API_KEY"];


    // 注册本地推送
    [SYHLocalPushManager.shared requestAuthorization];
    
    NSString *uuid = [SYSystemSettingHelper getUuidString];
    
    NSLog(@"%@", uuid);
    
    
    return YES;
}



#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}



@end
