//
//  SYHSubmitDataService.m
//  LocationApp

#import "SYHSubmitDataService.h"
#import "SYHHttpSessionManager.h"
#import "UrlHeader.h"
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>
#import "SYHLocationManager.h"
#import "SYSystemSettingHelper.h"
#import "SYHAudioRecorderManager.h"

@interface SYHSubmitDataService ()
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableSet<NSString *> *submittingKeys;
@end

@implementation SYHSubmitDataService

+ (instancetype)shared {
    static SYHSubmitDataService *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _submittingKeys = [NSMutableSet set];
        [self startTimer];
    }
    return self;
}

- (void)startTimer {
    __weak typeof(self) weakSelf = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:90 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [weakSelf submitDataIfNeeded];
    }];
}

- (void)submitDataIfNeeded {
    NSDate *now = [NSDate now];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:now];
    NSInteger currentHour = components.hour;
    NSInteger currentMinute = components.minute;
    NSString *type = @"";
    if ((currentHour == 8 && currentMinute > 30) || (currentHour >= 9 && currentHour < 20)) {
        type = @"day";
    } else if (currentHour >= 21) {
        type = @"night";
    } else {
        return;
    }
    NSString *localKey = [self localKeyWithYear:components.year month:components.month day:components.day type:type];
    BOOL isSubmit = [[NSUserDefaults standardUserDefaults] boolForKey:localKey];
    if (!isSubmit) {
        [self submitLocationMsgWithAnswers:nil type:type];
    }
}

- (NSString *)localKeyWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day type:(NSString *)type {
    return [NSString stringWithFormat:@"%ld.%ld.%ld_%@_key", year, month, day, type];
}

- (void)submitLocationMsgWithAnswers:(nullable NSArray *)answers isToday:(BOOL)isToday year:(int)year month:(int)month day:(int)day type:(NSString *)type {
    if (isToday) {
        [self submitLocationMsgWithAnswers:answers type:type];
    } else {
        NSString *localKey = [self localKeyWithYear:year month:month day:day type:type];
        NSString *audioPath = nil;
        if ([type isEqualToString:@"night"]) {
            audioPath = [SYHAudioRecorderManager audioFilePathForYear:year month:month day:day];
        }
        [self submitLocationMsgWithAnswers:answers type:type year:year month:month day:day locations:@[] localKey:localKey audioPath:audioPath retryCount:5];
    }
}

- (void)submitLocationMsgWithAnswers:(nullable NSArray *)answers type:(nullable NSString *)type {
    NSArray *locations = [SYHLocationManager shared].locationArray;

    NSDate *now = [NSDate now];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour fromDate:now];

    if (type == nil || [type isEqualToString:@""]) {
        if (components.hour >= 8 && components.hour < 20) {
            type = @"day";
        } else {
            type = @"night";
        }
    }

    [[SYHLocationManager shared] updateAnswerDataWithType:type year:(int)components.year month:(int)components.month day:(int)components.day isCommit:NO];

    NSString *localKey = [self localKeyWithYear:components.year month:components.month day:components.day type:type];

    // 仅 night 类型附带录音文件，按当日日期查找
    NSString *audioPath = nil;
    if ([type isEqualToString:@"night"]) {
        audioPath = [SYHAudioRecorderManager audioFilePathForYear:(int)components.year
                                                            month:(int)components.month
                                                              day:(int)components.day];
    }

    [self submitLocationMsgWithAnswers:answers type:type year:(int)components.year month:(int)components.month day:(int)components.day locations:locations localKey:localKey audioPath:audioPath retryCount:5];
}

- (void)submitLocationMsgWithAnswers:(nullable NSArray *)answers
                                type:(NSString *)type
                                year:(int)year
                               month:(int)month
                                 day:(int)day
                           locations:(NSArray<SYHLocationModel *> *)locations
                            localKey:(NSString *)localKey
                           audioPath:(nullable NSString *)audioPath
                          retryCount:(int)retryCount {
    // 防止同一 localKey 并发重复提交；重试时 retryCount < 5 跳过此检查
    if (retryCount == 5) {
        if ([self.submittingKeys containsObject:localKey]) return;
        [self.submittingKeys addObject:localKey];
    }

    NSMutableDictionary *requestDict = [NSMutableDictionary dictionary];
    requestDict[@"answers"] = answers ?: @[@{@"answer": @[@"1"], @"qid": @1}];
    requestDict[@"type"] = type;
    NSTimeInterval nowTimestamp = [[NSDate now] timeIntervalSince1970];
    NSInteger timestampInt = (NSInteger)nowTimestamp;
    requestDict[@"timestamp"] = @(timestampInt);
    requestDict[@"enc"] = [SYHSubmitDataService generateEncryptedTimestamp:timestampInt];
    requestDict[@"locations"] = [SYHSubmitDataService convertModelsToDictionaries:locations];
    requestDict[@"platform"] = @"iOS";
    requestDict[@"uid"] = [SYSystemSettingHelper getUuidString];
    requestDict[@"date"] = [NSString stringWithFormat:@"%04d-%02d-%02d", year, month, day];

    NSLog(@"🍺：开始上传数据...");
    NSLog(@"%@\n%@", SUBMIT_LOCATION_DATA_URL, requestDict);

    void (^successHandler)(id) = ^(id response) {
        NSLog(@"🍺：上传成功success");
        if ([response[@"success"] intValue] == 1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.submittingKeys removeObject:localKey];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:localKey];
                [[SYHLocationManager shared] deleteLocations:locations];
                if (answers) {
                    [[SYHLocationManager shared] updateAnswerDataWithType:type year:year month:month day:day isCommit:YES];
                }
                // 删除该问卷日期对应的录音文件
                [SYHAudioRecorderManager deleteAudioFileForYear:year month:month day:day];
            });
        } else {
            if (retryCount <= 0) {
                NSLog(@"🍺：上传失败 不再重试：response-- %@", response);
                [self.submittingKeys removeObject:localKey];
                return;
            } else {
                NSLog(@"🍺：上传失败：重试第%d次，response-- %@", retryCount, response);
            }
            if (![[NSUserDefaults standardUserDefaults] boolForKey:localKey]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self submitLocationMsgWithAnswers:answers type:type year:year month:month day:day locations:locations localKey:localKey audioPath:audioPath retryCount:retryCount - 1];
                });
            }
            [[SYHLocationManager shared] updateAnswerDataWithType:type year:year month:month day:day isCommit:NO];
        }
    };

    void (^failHandler)(NSError *) = ^(NSError *error) {
        if (retryCount <= 0) {
            NSLog(@"🍺：上传失败 不再重试：error-- %@", error);
            [self.submittingKeys removeObject:localKey];
            return;
        } else {
            NSLog(@"🍺：上传失败：重试第%d次，error-- %@", retryCount, error);
        }
        if (![[NSUserDefaults standardUserDefaults] boolForKey:localKey]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self submitLocationMsgWithAnswers:answers type:type year:year month:month day:day locations:locations localKey:localKey audioPath:audioPath retryCount:retryCount - 1];
            });
        }
        [[SYHLocationManager shared] updateAnswerDataWithType:type year:year month:month day:day isCommit:NO];
    };

    if (audioPath) {
        NSInteger duration = (NSInteger)lround(SYHAudioRecorderManager.shared.currentDuration);
        NSData *payloadData = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:nil];
        NSString *payloadJson = payloadData
            ? [[NSString alloc] initWithData:payloadData encoding:NSUTF8StringEncoding]
            : @"{}";
        NSDictionary *formParams = @{
            @"data": payloadJson,
            @"voiceDiaryDuration": @(duration),
        };

        [SYHHttpSessionManager postImageWithUrl:SUBMIT_LOCATION_DATA_URL
                                         params:formParams
                      constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            NSError *appendError;
            [formData appendPartWithFileURL:[NSURL fileURLWithPath:audioPath]
                                       name:@"voiceDiary"
                                   fileName:@"voice_diary.mp4"
                                   mimeType:@"audio/mp4"
                                      error:&appendError];
            if (appendError) NSLog(@"🍺：附加音频失败: %@", appendError);
        }
                                       progress:nil
                                        success:successHandler
                                        failure:failHandler];
    } else {
        // 无录音：原有 JSON POST
        [SYHHttpSessionManager requestDataWithUrl:SUBMIT_LOCATION_DATA_URL
                                             dict:requestDict
                                           method:POST
                                          andSucc:successHandler
                                          andFail:failHandler];
    }
}

#pragma mark - model => Dictionary

+ (NSArray<NSDictionary *> *)convertModelsToDictionaries:(NSArray<SYHLocationModel *> *)models {
    NSMutableArray *result = [NSMutableArray array];
    for (id model in models) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        unsigned int count;
        objc_property_t *properties = class_copyPropertyList([model class], &count);
        for (int i = 0; i < count; i++) {
            NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
            id value = [model valueForKey:key];
            if (value) [dict setObject:value forKey:key];
        }
        free(properties);
        [result addObject:dict];
    }
    return result.copy;
}

#pragma mark - 加密

+ (NSString *)generateEncryptedTimestamp:(NSInteger)timestamp {
    // CLIENT_API.md §4: SHA256("{timestamp}SW_Tracking_2024240327") → 去非数字 → 前 10 位
    NSString *combined = [NSString stringWithFormat:@"%ldSW_Tracking_2024240327", (long)timestamp];
    const char *cStr = [combined UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(cStr, (CC_LONG)strlen(cStr), result);
    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", result[i]];
    }
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSString *digitsOnly = [[hash componentsSeparatedByCharactersInSet:nonDigits] componentsJoinedByString:@""];
    return [digitsOnly substringToIndex:MIN(10, digitsOnly.length)];
}

+ (NSInteger)encryptionKey { return 240327; }
+ (NSString *)salt { return @"SW_Tracking_2024"; }
+ (NSTimeInterval)timestampExpiry { return 3 * 60 * 1000; }

+ (NSString *)generateEncryptedWithTimeStamp:(NSInteger)timeStamp {
    NSString *combined = [NSString stringWithFormat:@"%ld%@%ld",
                         (long)timeStamp, [self salt], (long)[self encryptionKey]];
    const char *str = [combined UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, (CC_LONG)strlen(str), result);
    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", result[i]];
    }
    NSCharacterSet *nonDigitChars = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSString *digitsOnly = [[hash componentsSeparatedByCharactersInSet:nonDigitChars] componentsJoinedByString:@""];
    return [digitsOnly substringToIndex:MIN(10, digitsOnly.length)];
}

@end
