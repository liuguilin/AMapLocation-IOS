//
//  SYHLocationModel.m
//  LocationApp
//
//  Created by 大伊 on 2025/5/31.
//

#import "SYHLocationModel.h"

@interface SYHLocationModel () <NSSecureCoding>

@end


@implementation SYHLocationModel

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.address forKey:@"address"];
    [aCoder encodeObject:self.time forKey:@"time"];
    [aCoder encodeDouble:self.lat forKey:@"lat"];
    [aCoder encodeDouble:self.lng forKey:@"lng"];

}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.address = [aDecoder decodeObjectForKey:@"address"];
        self.time = [aDecoder decodeObjectForKey:@"time"];
        self.lat = [aDecoder decodeDoubleForKey:@"lat"];
        self.lng = [aDecoder decodeDoubleForKey:@"lng"];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end
