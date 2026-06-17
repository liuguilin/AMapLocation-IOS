//
//  NSString+Envon.h
//  BusinessExchange
//
//  Created by     生意汇 on 2017/5/3.
//  Copyright © 2017年     生意汇. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Addition)

+(BOOL)isNullOrEmpty:(NSString *)str;
+(BOOL)IsNullOrWhiteSpace:(NSString *)str;

/**
 截取前后空格

 @param str 目标字符串
 @return 相关操作的字符串
 */
+(NSString *)trim:(NSString *)str;


/**
 md5加密

 @param input 需要加密的字符串
 @return 加密后的字符串
 */
+ (NSString *) md5:(NSString *) input;

#pragma mark - 沙盒路径
+(NSString *)pathGetHomePath;
+(NSString *)pathGetTmpPath;
+(NSString *)pathGetDocumentsPath;
+(NSString *)pathGetCachesPath;
+(NSString *)pathGetLibraryPath;
+(NSString *)pathForResource:(NSString *)fileName;
@end
