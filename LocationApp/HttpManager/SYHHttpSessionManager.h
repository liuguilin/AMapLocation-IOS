//
//  SYHHttpSessionManager.h
//  BusinessExchange
//
//  Created by     生意汇 on 2017/5/3.
//  Copyright © 2017年     生意汇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonHeader.h"


typedef NS_ENUM(NSUInteger,RequestMethod){
    GET = 1,
    POST
};
@interface SYHHttpSessionManager : NSObject
+(void)requestDataWithUrl:(NSString *_Nullable)url dict:(NSDictionary *_Nullable)parameters method:(RequestMethod)method andSucc:(void (^_Nullable)(id _Nullable response))succBlock andFail:(void (^_Nullable)(NSError * _Nullable error))failBlock;

//上传头像
+(void)postImageWithUrl:(NSString *_Nullable)url params:(NSDictionary*_Nullable)parameters constructingBodyWithBlock:(void(^_Nonnull)(id<AFMultipartFormData>  _Nonnull formData))block progress:(void(^_Nonnull)(NSProgress * _Nonnull uploadProgress))progress success:(void(^_Nullable)(id  _Nullable responseObject))succBlock failure:(void(^_Nullable)(NSError * _Nullable theError))failureBlock;

+(id _Nullable )jsonFromText:(NSString *_Nullable)text andEncoding:(NSStringEncoding)encoding;

@end
