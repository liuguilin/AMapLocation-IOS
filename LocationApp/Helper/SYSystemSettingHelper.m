//
//  SYSettingLanguageHelper.m
//  LocationApp
//
//  Created by 大伊 on 2025/9/21.
//

#import "SYSystemSettingHelper.h"

@implementation SYSystemSettingHelper

+ (NSString *)getSettingLanguage {
    NSString *languageCode = [self getSimplifiedLanguageCode];
    
    if ([languageCode isEqualToString:@"en"]) {
        return @"english"; // 简体中文
    } else if ([languageCode isEqualToString:@"zh"]) {
        return @"complicated"; // 繁体中文
    } else {
        return @"simple"; // 英语，兜底英语
    }
}



+ (NSString *)getPreferredLanguage {
    return [NSLocale preferredLanguages].firstObject;
}

+ (NSString *)getSimplifiedLanguageCode {
    return [[NSLocale currentLocale] languageCode];
}


+ (NSString *)generateUuidString {
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref = CFUUIDCreateString(NULL, uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString*)uuid_string_ref];
    CFRelease(uuid_ref);
    CFRelease(uuid_string_ref);
    return [uuid lowercaseString];
}

+ (NSString *)getUuidString {
    NSString *service = @"com.location.uuid";
    NSString *account = @"uuid";
    
    // 先从钥匙串读取
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:service forKey:(__bridge id)kSecAttrService];
    [query setObject:account forKey:(__bridge id)kSecAttrAccount];
    [query setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    if (status == errSecSuccess) {
        NSData *data = (__bridge_transfer NSData *)result;
        NSString *uuid = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (uuid && uuid.length > 0) {
            return uuid;
        }
    }
    
    // 钥匙串中没有，生成新的UUID
    NSString *uuid = [self generateUuidString];
    
    // 保存到钥匙串
    NSData *uuidData = [uuid dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *saveQuery = [NSMutableDictionary dictionary];
    [saveQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [saveQuery setObject:service forKey:(__bridge id)kSecAttrService];
    [saveQuery setObject:account forKey:(__bridge id)kSecAttrAccount];
    [saveQuery setObject:uuidData forKey:(__bridge id)kSecValueData];
    [saveQuery setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge id)kSecAttrAccessible];
    
    SecItemAdd((__bridge CFDictionaryRef)saveQuery, NULL);
    return uuid;
}


@end
