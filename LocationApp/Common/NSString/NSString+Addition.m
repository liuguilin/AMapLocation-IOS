//
//  NSString+Envon.m
//  BusinessExchange
//
//  Created by     生意汇 on 2017/5/3.
//  Copyright © 2017年     生意汇. All rights reserved.
//

#import "NSString+Addition.h"
#import<CommonCrypto/CommonDigest.h>
@implementation NSString (Addition)

+(BOOL)isNullOrEmpty:(NSString *)str
{
    str = [NSString toString:str];
    if ([str isEqual:[NSNull null]] || str==nil) {
        return YES;
    }
    else if(str.length==0)
    {
        return YES;
    }
    return NO;
}

+(BOOL)IsNullOrWhiteSpace:(NSString *)str
{
    str = [NSString toString:str];
    if ([str isEqual:[NSNull null]] || str==nil) {
        return YES;
    }
    else if(str.length==0)
    {
        return YES;
    }
    NSString *s = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(s.length==0)
    {
        return YES;
    }
    return NO;
}

+(NSString*)toString:(id)object
{
    if (object && ![object isEqual:[NSNull null]] ) {
        NSString *str = [NSString stringWithFormat:@"%@", object];
        return str;
    }else{ return @""; }
}

//截取字符串前后空格
+(NSString *)trim:(NSString *)str
{
    if([str isKindOfClass:[NSString class]]){
        if ([NSString IsNullOrWhiteSpace:str]) {
            return @"";
        }
        return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return str;
}

+ (NSString *) md5:(NSString *) input {
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    [output appendFormat:@"%02x", digest[i]];
    return  output;
}

#pragma mark - 文件路径处理 -

+(NSString *)pathGetHomePath
{
    return  NSHomeDirectory();
}

+(NSString *)pathGetTmpPath
{
    return NSTemporaryDirectory();
}

+(NSString *)pathGetDocumentsPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    return  docDir;
}

+(NSString *)pathGetLibraryPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    return  docDir;
}


+(NSString *)pathGetCachesPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDir = [paths objectAtIndex:0];
    return  cachesDir;
}

+(NSString *)pathForResource:(NSString *)fileName
{
    NSString *ext = [fileName pathExtension];
    NSString *name = [fileName stringByDeletingPathExtension];
    return [[NSBundle mainBundle] pathForResource:name ofType:ext];
}


@end
