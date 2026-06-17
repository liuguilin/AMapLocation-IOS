//
//  SYHAnswerResult.m
//  LocationApp
//
//  Created by 大伊 on 2025/9/21.
//

#import "SYHAnswerResult.h"

@interface SYHAnswerResult () <NSSecureCoding>

@end

@implementation SYHAnswerResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.type forKey:@"type"];
    [aCoder encodeInt:self.year forKey:@"year"];
    [aCoder encodeInt:self.month forKey:@"month"];
    [aCoder encodeInt:self.day forKey:@"day"];

    [aCoder encodeBool:self.isCommit forKey:@"isCommit"];

}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.type = [aDecoder decodeObjectForKey:@"type"];
        self.isCommit = [aDecoder decodeBoolForKey:@"isCommit"];
        self.year = [aDecoder decodeIntForKey:@"year"];
        self.month = [aDecoder decodeIntForKey:@"month"];
        self.day = [aDecoder decodeIntForKey:@"day"];

    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}


- (BOOL)isToday {
    NSDate *date = [NSDate now];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    return self.year == components.year && self.month == components.month && self.day == components.day;
}


- (BOOL)isEqual:(id)other {
    if([other isKindOfClass:[SYHAnswerResult class]]) {
        SYHAnswerResult *otherResult = (SYHAnswerResult *)other;
        return [self.type isEqualToString:otherResult.type] && self.year == otherResult.self.year && self.month == otherResult.self.month && self.day == otherResult.self.day;
    } else {
        return false;
    }
}

@end
