//
//  SYHAnswerResult.h
//  LocationApp
//
//  Created by 大伊 on 2025/9/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SYHAnswerResult : NSObject

// @"day": "白天"，@"night":"夜间";
@property (nonatomic, copy) NSString *type;
// 时间
@property (nonatomic, assign) int year;
@property (nonatomic, assign) int month;
@property (nonatomic, assign) int day;

// 是否提交
@property (nonatomic, assign) BOOL isCommit;


- (BOOL)isToday;
@end

NS_ASSUME_NONNULL_END
