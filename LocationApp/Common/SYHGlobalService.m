//
//  SYHGlobalService.m
//  LocationApp
//
//  Created by 大伊 on 2025/5/24.
//

#import <UIKit/UIKit.h>
#import "SYHGlobalService.h"
#import "SYHModelName.h"
#import "JSONModel/JSONModel.h"
@implementation SYHGlobalService

+(NSString *)getUserAgent{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    //本地 版本
    NSString *CurrentVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    
    NSDictionary * dict = @{@"appversioncode":CurrentVersion,@"brand":@"apple",@"model":[SYHModelName iphoneType],@"osversion":[[UIDevice currentDevice] systemVersion],@"platform":@"2",@"netmode":[SYHModelName networkingStatesFromStatebar]};
    
    NSString * userAgent = [self jsonStringEncoded: dict];
    return userAgent;
}

+ (NSString *)jsonStringEncoded:(NSDictionary *)dict {
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:&error];
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (!error) return json;
    }
    return nil;
}
@end
