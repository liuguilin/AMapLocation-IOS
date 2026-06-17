//
//  SYHLocationModel.h
//  LocationApp
//
//  Created by 大伊 on 2025/5/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SYHLocationModel : NSObject

@property (nonatomic, assign) double lat;
@property (nonatomic, assign) double lng;
//@property (nonatomic, copy) NSString *lat;
//@property (nonatomic, copy) NSString *lng;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *time;

@end

NS_ASSUME_NONNULL_END
