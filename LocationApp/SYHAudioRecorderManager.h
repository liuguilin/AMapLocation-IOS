//
//  SYHAudioRecorderManager.h
//  LocationApp

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, SYHRecordingState) {
    SYHRecordingStateIdle,
    SYHRecordingStateRecording,
    SYHRecordingStateFinished
};

@protocol SYHAudioRecorderManagerDelegate <NSObject>
- (void)audioRecorderDidStartRecording;
- (void)audioRecorderDidStopRecording:(NSTimeInterval)duration;
- (void)audioRecorderDidUpdateDuration:(NSTimeInterval)duration;
- (void)audioRecorderDidFinishPlayback;
- (void)audioRecorderDidFailWithError:(NSError *)error;
@end

@interface SYHAudioRecorderManager : NSObject

@property (nonatomic, assign, readonly) SYHRecordingState recordingState;
@property (nonatomic, assign, readonly) NSTimeInterval currentDuration;
@property (nonatomic, copy, readonly, nullable) NSString *audioFilePath;
@property (nonatomic, weak, nullable) id<SYHAudioRecorderManagerDelegate> delegate;

@property (nonatomic, assign) int recordingYear;
@property (nonatomic, assign) int recordingMonth;
@property (nonatomic, assign) int recordingDay;

+ (instancetype)shared;
+ (nullable NSString *)audioFilePathForYear:(int)year month:(int)month day:(int)day;
+ (void)deleteAudioFileForYear:(int)year month:(int)month day:(int)day;

- (void)loadExistingRecordingForYear:(int)year month:(int)month day:(int)day;
- (void)startRecording;
- (void)stopRecording;
- (void)startPlayback;
- (void)stopPlayback;
- (void)reset;
- (void)deleteAudioFile;

@end
