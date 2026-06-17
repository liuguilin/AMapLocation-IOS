//
//  SYHSubmitDataService.h
//  LocationApp
//
//  Created by 大伊 on 2025/5/31.
//

#import <Foundation/Foundation.h>
#import "SYHLocationModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface SYHSubmitDataService : NSObject
+ (instancetype)shared;
//- (void)submitLocationMsgWithAnswers:(nullable NSArray *)answers;
- (void)submitLocationMsgWithAnswers:(nullable NSArray *)answers type:(nullable NSString *)type;
- (void)submitLocationMsgWithAnswers:(nullable NSArray *)answers isToday:(BOOL)isToday year:(int)year month:(int)month day:(int)day type:(NSString *)type;
- (NSString *)localKeyWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day type:(NSString *)type;

@end

NS_ASSUME_NONNULL_END
