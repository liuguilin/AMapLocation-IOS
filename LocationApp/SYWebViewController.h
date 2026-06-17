//
//  SYWebViewController.h
//  LocationApp
//
//  Created by 大伊 on 2025/5/31.
//

#import <UIKit/UIKit.h>

@class SYHAnswerResult;

NS_ASSUME_NONNULL_BEGIN

@interface SYWebViewController : UIViewController
@property (nonatomic, assign) BOOL isNight;
/** 补填历史问卷时传入；nil 表示提交当天问卷 */
@property (nonatomic, strong, nullable) SYHAnswerResult *answerResult;
@end

NS_ASSUME_NONNULL_END
