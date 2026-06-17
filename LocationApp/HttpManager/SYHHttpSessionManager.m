//
//  SYHHttpSessionManager.m
//  BusinessExchange
//
//  Created by     生意汇 on 2017/5/3.
//  Copyright © 2017年     生意汇. All rights reserved.
//

#import "SYHHttpSessionManager.h"
#import "SYHGlobalService.h"
//#import "AppDelegate.h"
//#import "SYHModelName.h"
//#import "SYHRequestCacheService.h"

@interface SYHHttpSessionManager ()

@property (nonatomic, strong) AFHTTPSessionManager *manager;

@end

@implementation SYHHttpSessionManager

///单例
+(instancetype)sharedManage
{
    static SYHHttpSessionManager *global = nil;
    static dispatch_once_t kadOnce;
    dispatch_once(&kadOnce, ^{
        global = [[self alloc] init];
    });
    return global;
}

-(void)requestDataWithUrl:(NSString *)url dict:(NSDictionary *)parameters method:(RequestMethod)method andSucc:(void (^)(id response))succBlock andFail:(void (^)(NSError *error))failBlock{
    AFHTTPSessionManager * manager = [self getManagerUserAgent];
    [manager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    manager.requestSerializer.timeoutInterval = 15;
    WEAK_SELF(me)
    switch (method) {
        case GET:{
            [manager GET:url parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSString *retString = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
                [me requestSuccessWithResponseObject:retString url:url dict:parameters andSucc:succBlock failure:failBlock];
//                [SYHRequestCacheService saveDataToLocalWithUrl:url params:parameters json:retString];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"error");
                if (IS_NO_NETWORK_ERROR(error.code)) {
                    if (failBlock) {
                        failBlock(error);
                    }
                    
                }else{
                    if (failBlock) {
                        failBlock(error);
                    }
                }
            }];
        }
            break;
            
        default:{
            [manager POST:url parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSString *retString = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
                [me requestSuccessWithResponseObject:retString url:url dict:parameters andSucc:succBlock failure:failBlock];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"%@",error);
                if (IS_NO_NETWORK_ERROR(error.code)) {
                        if (failBlock) {
                            failBlock(error);
                        }

                } else {
                    if (failBlock) {
                        failBlock(error);
                    }
                }
            }];
        }
            break;
    }
}

+(void)requestDataWithUrl:(NSString *)url dict:(NSDictionary *)parameters method:(RequestMethod)method andSucc:(void (^)(id response))succBlock andFail:(void (^)(NSError *error))failBlock{
    [[SYHHttpSessionManager sharedManage] requestDataWithUrl:url dict:parameters method:method andSucc:succBlock andFail:failBlock];
}

-(void)requestSuccessWithResponseObject:(NSString *)retString url:(NSString *)url dict:(NSDictionary *)parameters andSucc:(void (^)(id response))succBlock failure:(void(^)(NSError * theError))failureBlock{
    id resultData = [SYHHttpSessionManager jsonFromText:retString andEncoding:NSUTF8StringEncoding];
    if (succBlock) {
        succBlock(resultData);
    }
}

+(void)postImageWithUrl:(NSString *)url params:(NSDictionary*)parameters constructingBodyWithBlock:(void(^)(id<AFMultipartFormData>  _Nonnull formData))block progress:(void(^)(NSProgress * _Nonnull uploadProgress))progress success:(void(^)(id  _Nullable responseObject))succBlock failure:(void(^)(NSError * theError))failureBlock{
    [[SYHHttpSessionManager sharedManage] postImageWithUrl:url params:parameters constructingBodyWithBlock:block progress:progress success:succBlock failure:failureBlock];
}

-(AFHTTPSessionManager *)getManagerUserAgent{
//    NSString * userAgent = [SYHGlobalService getUserAgent];
//    if (userAgent) {
//        if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
//            NSMutableString *mutableUserAgent = [userAgent mutableCopy];
//            if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false)) {
//                userAgent = mutableUserAgent;
//            }
//        }
//        [self.manager.requestSerializer setValue:userAgent forHTTPHeaderField:@"User-Agent"];
//    return self.manager;
//    }
    
    
    //测试cookie
//    NSDictionary *properties = [[NSMutableDictionary alloc] init];
//    [properties setValue:@"AppUserInfo" forKey:NSHTTPCookieName];
//    [properties setValue:@"AppUserInfo" forKey:NSHTTPCookieValue];
//    [properties setValue:@"192.168.1.128" forKey:NSHTTPCookieDomain];
//    [properties setValue:@"192.168.1.128" forKey:NSHTTPCookieOriginURL];
//    [properties setValue:@"/" forKey:NSHTTPCookiePath];
//    [properties setValue:@"0" forKey:NSHTTPCookieVersion];
////    [properties setValue:@{@"uid":uid,@"token":token} forKey:@"userInfo"];
//    NSHTTPCookie * cookie = [NSHTTPCookie cookieWithProperties:properties];
    
//    [manager.requestSerializer setValue:@"这是cookie?????? fuck you" forHTTPHeaderField:@"cookies"];
    
    
    return self.manager;
}

///text转为json
+(id)jsonFromText:(NSString *)text andEncoding:(NSStringEncoding)encoding
{
    //增加容错处理，否则会闪退
    if ([NSString isNullOrEmpty:text]) {
        text = @"";
    }
    NSString *responseString = [NSString stringWithString:text];
    responseString = [responseString stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    responseString = [responseString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    responseString = [responseString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    NSData *resData = [[NSData alloc] initWithData:[responseString dataUsingEncoding:encoding]];
    id resultData =[NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableLeaves error:nil];
    return resultData;
}

#pragma mark - 实例方法
-(void)postImageWithUrl:(NSString *)url params:(NSDictionary*)parameters constructingBodyWithBlock:(void(^)(id<AFMultipartFormData>  _Nonnull formData))block progress:(void(^)(NSProgress * _Nonnull uploadProgress))progress success:(void(^)(id  _Nullable responseObject))succBlock failure:(void(^)(NSError * theError))failureBlock{
    // multipart 上传须用 AFHTTPRequestSerializer；JSON serializer 会设置 HTTPBody，导致 upload task 报错
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 60;
    WEAK_SELF(me)
    [manager POST:url parameters:parameters headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        if (block) {
            block(formData);
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString *retString = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
        id resultData = [SYHHttpSessionManager jsonFromText:retString andEncoding:NSUTF8StringEncoding];
        NSLog(@"%@",resultData[@"msg"]);
        if (succBlock) {
            succBlock(resultData);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
        if (failureBlock) {
            failureBlock(error);
        }
    }];
}

-(AFHTTPSessionManager *)manager{
    if (!_manager) {
        _manager = [AFHTTPSessionManager manager];
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
        [_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    return _manager;
}

@end
