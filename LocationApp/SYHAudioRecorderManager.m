//
//  SYHAudioRecorderManager.m
//  LocationApp

#import "SYHAudioRecorderManager.h"

static const NSTimeInterval kMaxRecordingDuration = 120.0;
static const NSTimeInterval kMinRecordingDuration = 3.0;

@interface SYHAudioRecorderManager () <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong, nullable) AVAudioRecorder *recorder;
@property (nonatomic, strong, nullable) AVAudioPlayer *player;
@property (nonatomic, strong, nullable) NSTimer *durationTimer;
@property (nonatomic, strong, nullable) NSTimer *maxDurationTimer;

@property (nonatomic, assign, readwrite) SYHRecordingState recordingState;
@property (nonatomic, assign, readwrite) NSTimeInterval currentDuration;
@property (nonatomic, copy, readwrite, nullable) NSString *audioFilePath;

@end

@implementation SYHAudioRecorderManager

+ (instancetype)shared {
    static SYHAudioRecorderManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _recordingState = SYHRecordingStateIdle;
        _currentDuration = 0;
        [self configureAudioSession];
    }
    return self;
}

- (void)configureAudioSession {
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                           error:&error];
    if (error) {
        NSLog(@"AudioSession 设置失败: %@", error);
    }
}

#pragma mark - Public

- (void)startRecording {
    if (self.recordingState == SYHRecordingStateRecording) return;

    [self reset];

    NSError *sessionError;
    [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];
    if (sessionError) {
        [self.delegate audioRecorderDidFailWithError:sessionError];
        return;
    }

    int year = self.recordingYear, month = self.recordingMonth, day = self.recordingDay;
    if (year == 0) {
        NSDateComponents *c = [[NSCalendar currentCalendar]
            components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:[NSDate date]];
        year = (int)c.year; month = (int)c.month; day = (int)c.day;
    }
    NSString *fileName = [NSString stringWithFormat:@"voice_diary_%04d_%02d_%02d.mp4", year, month, day];
    self.audioFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];

    NSDictionary *settings = @{
        AVFormatIDKey:            @(kAudioFormatMPEG4AAC),
        AVSampleRateKey:          @44100,
        AVNumberOfChannelsKey:    @1,
        AVEncoderAudioQualityKey: @(AVAudioQualityMedium)
    };

    NSError *recorderError;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:self.audioFilePath]
                                                settings:settings
                                                   error:&recorderError];
    if (recorderError) {
        [self.delegate audioRecorderDidFailWithError:recorderError];
        return;
    }

    self.recorder.delegate = self;
    [self.recorder record];
    self.recordingState = SYHRecordingStateRecording;
    self.currentDuration = 0;

    __weak typeof(self) weakSelf = self;
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) {
        weakSelf.currentDuration += 1.0;
        [weakSelf.delegate audioRecorderDidUpdateDuration:weakSelf.currentDuration];
    }];
    self.maxDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMaxRecordingDuration
                                                            repeats:NO
                                                              block:^(NSTimer *timer) {
        [weakSelf stopRecording];
    }];

    [self.delegate audioRecorderDidStartRecording];
}

- (void)stopRecording {
    if (self.recordingState != SYHRecordingStateRecording) return;

    [self.durationTimer invalidate];
    self.durationTimer = nil;
    [self.maxDurationTimer invalidate];
    self.maxDurationTimer = nil;

    NSTimeInterval duration = self.recorder.currentTime;
    [self.recorder stop];
    self.recordingState = SYHRecordingStateFinished;

    if (duration < kMinRecordingDuration) {
        [self deleteAudioFile];
        self.recordingState = SYHRecordingStateIdle;
        NSError *error = [NSError errorWithDomain:@"SYHAudioRecorder"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"录音时间过短，请重新录制"}];
        [self.delegate audioRecorderDidFailWithError:error];
        return;
    }

    self.currentDuration = duration;
    [self.delegate audioRecorderDidStopRecording:duration];
}

- (void)startPlayback {
    if (!self.audioFilePath) return;

    NSError *error;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.audioFilePath]
                                                         error:&error];
    if (error) {
        [self.delegate audioRecorderDidFailWithError:error];
        return;
    }
    self.player.delegate = self;
    [self.player play];
}

- (void)stopPlayback {
    [self.player stop];
    self.player = nil;
}

- (void)reset {
    [self.durationTimer invalidate];
    self.durationTimer = nil;
    [self.maxDurationTimer invalidate];
    self.maxDurationTimer = nil;
    [self.recorder stop];
    self.recorder = nil;
    [self.player stop];
    self.player = nil;
    [self deleteAudioFile];
    self.recordingState = SYHRecordingStateIdle;
    self.currentDuration = 0;
}

- (void)deleteAudioFile {
    if (self.audioFilePath &&
        [[NSFileManager defaultManager] fileExistsAtPath:self.audioFilePath]) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:self.audioFilePath error:&error];
        if (error) NSLog(@"删除音频文件失败: %@", error);
    }
    self.audioFilePath = nil;
}

+ (nullable NSString *)audioFilePathForYear:(int)year month:(int)month day:(int)day {
    NSString *fileName = [NSString stringWithFormat:@"voice_diary_%04d_%02d_%02d.mp4", year, month, day];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    return [[NSFileManager defaultManager] fileExistsAtPath:path] ? path : nil;
}

+ (void)deleteAudioFileForYear:(int)year month:(int)month day:(int)day {
    NSString *fileName = [NSString stringWithFormat:@"voice_diary_%04d_%02d_%02d.mp4", year, month, day];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error) NSLog(@"删除音频文件失败: %@", error);
    }
}

- (void)loadExistingRecordingForYear:(int)year month:(int)month day:(int)day {
    NSString *path = [SYHAudioRecorderManager audioFilePathForYear:year month:month day:day];
    if (!path) return;
    NSError *error;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
    if (error) return;
    self.audioFilePath = path;
    self.currentDuration = player.duration;
    self.recordingState = SYHRecordingStateFinished;
    [self.delegate audioRecorderDidStopRecording:self.currentDuration];
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    [self reset];
    [self.delegate audioRecorderDidFailWithError:error];
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    self.player = nil;
    [self.delegate audioRecorderDidFinishPlayback];
}

@end
