//
//  SYWebViewController.m
//  LocationApp

#import "SYWebViewController.h"
#import <WebKit/WebKit.h>
#import "SYHHttpSessionManager.h"
#import "SYSystemSettingHelper.h"
#import "SYHAudioRecorderManager.h"
#import "SYHSubmitDataService.h"
#import "SYHAnswerResult.h"

@interface SYWebViewController () <WKNavigationDelegate, WKScriptMessageHandler, SYHAudioRecorderManagerDelegate>

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation SYWebViewController

#pragma mark - SWBridge 注入脚本

- (NSString *)swBridgeInjectionScript {
    return
    @"window.SWBridge = {"
    @"  startVoiceRecording: function() {"
    @"    window.webkit.messageHandlers.SWBridge.postMessage({method:'startVoiceRecording'});"
    @"  },"
    @"  stopVoiceRecording: function() {"
    @"    window.webkit.messageHandlers.SWBridge.postMessage({method:'stopVoiceRecording'});"
    @"  },"
    @"  playVoiceRecording: function() {"
    @"    window.webkit.messageHandlers.SWBridge.postMessage({method:'playVoiceRecording'});"
    @"  },"
    @"  clearVoiceRecording: function() {"
    @"    window.webkit.messageHandlers.SWBridge.postMessage({method:'clearVoiceRecording'});"
    @"  },"
    @"  submitAnswers: function(answersJson) {"
    @"    window.webkit.messageHandlers.SWBridge.postMessage({method:'submitAnswers', data: answersJson});"
    @"  },"
    @"  goBack: function() {"
    @"    window.webkit.messageHandlers.SWBridge.postMessage({method:'goBack'});"
    @"  }"
    @"};";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = YES;

    WKUserContentController *userController = [[WKUserContentController alloc] init];

    WKUserScript *bridgeScript = [[WKUserScript alloc] initWithSource:[self swBridgeInjectionScript]
                                                        injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                     forMainFrameOnly:YES];
    [userController addUserScript:bridgeScript];
    [userController addScriptMessageHandler:self name:@"SWBridge"];
    config.userContentController = userController;

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    self.webView.navigationDelegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.allowsBackForwardNavigationGestures = YES;
    [self.view addSubview:self.webView];

    SYHAudioRecorderManager.shared.delegate = self;

    if (self.isNight) {
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *today = [cal components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                         fromDate:[NSDate date]];
        int year  = self.answerResult ? self.answerResult.year  : (int)today.year;
        int month = self.answerResult ? self.answerResult.month : (int)today.month;
        int day   = self.answerResult ? self.answerResult.day   : (int)today.day;
        SYHAudioRecorderManager.shared.recordingYear  = year;
        SYHAudioRecorderManager.shared.recordingMonth = month;
        SYHAudioRecorderManager.shared.recordingDay   = day;
        [SYHAudioRecorderManager.shared loadExistingRecordingForYear:year month:month day:day];
    }

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSString *urlString = [NSString stringWithFormat:@"file://%@", filePath];
    urlString = [NSString stringWithFormat:@"%@?language=%@", urlString, [SYSystemSettingHelper getSettingLanguage]];
    if (self.isNight) {
        urlString = [NSString stringWithFormat:@"%@&type=night", urlString];
    }
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
}

#pragma mark - SWBridge 消息处理

- (void)handleSWBridgeMessage:(NSDictionary *)body {
    NSString *method = body[@"method"];
    if (![method isKindOfClass:[NSString class]]) return;

    if ([method isEqualToString:@"startVoiceRecording"]) {
        [SYHAudioRecorderManager.shared startRecording];
    } else if ([method isEqualToString:@"stopVoiceRecording"]) {
        [SYHAudioRecorderManager.shared stopRecording];
    } else if ([method isEqualToString:@"playVoiceRecording"]) {
        [SYHAudioRecorderManager.shared startPlayback];
    } else if ([method isEqualToString:@"clearVoiceRecording"]) {
        [SYHAudioRecorderManager.shared reset];
    } else if ([method isEqualToString:@"submitAnswers"]) {
        [self handleSubmitAnswers:body[@"data"]];
    } else if ([method isEqualToString:@"goBack"]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)handleSubmitAnswers:(id)data {
    if (self.isNight && SYHAudioRecorderManager.shared.recordingState != SYHRecordingStateFinished) {
        NSString *js = @"alert('请完成语音日记后再提交 / 請完成語音日記後再提交 / Please complete the voice diary before submitting.');";
        [self.webView evaluateJavaScript:js completionHandler:nil];
        return;
    }

    NSString *parameterStr = nil;
    if ([data isKindOfClass:[NSString class]]) {
        parameterStr = (NSString *)data;
    } else if ([data isKindOfClass:[NSArray class]]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
        parameterStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }

    NSArray *answers = [SYHHttpSessionManager jsonFromText:parameterStr andEncoding:NSUTF8StringEncoding];
    NSString *type = self.isNight ? @"night" : @"day";

    if (self.answerResult) {
        [[SYHSubmitDataService shared] submitLocationMsgWithAnswers:answers
                                                            isToday:[self.answerResult isToday]
                                                               year:self.answerResult.year
                                                              month:self.answerResult.month
                                                                day:self.answerResult.day
                                                               type:type];
    } else {
        [[SYHSubmitDataService shared] submitLocationMsgWithAnswers:answers type:type];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SYHAudioRecorderManagerDelegate

- (void)audioRecorderDidStartRecording {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyVoiceDiaryProgress:0];
    });
}

- (void)audioRecorderDidStopRecording:(NSTimeInterval)duration {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyVoiceDiaryComplete:duration];
    });
}

- (void)audioRecorderDidUpdateDuration:(NSTimeInterval)duration {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyVoiceDiaryProgress:duration];
    });
}

- (void)audioRecorderDidFinishPlayback {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyVoiceDiaryPlayEnded];
    });
}

- (void)audioRecorderDidFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyVoiceDiaryError:error.localizedDescription ?: @"录音失败"];
    });
}

#pragma mark - VoiceDiaryBridge 通知 H5

- (void)notifyVoiceDiaryProgress:(NSTimeInterval)duration {
    NSInteger secs = (NSInteger)lround(duration);
    NSString *js = [NSString stringWithFormat:
                    @"window.VoiceDiaryBridge&&window.VoiceDiaryBridge.onRecordProgress&&"
                    @"window.VoiceDiaryBridge.onRecordProgress({elapsedSeconds:%ld});",
                    (long)secs];
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

- (void)notifyVoiceDiaryComplete:(NSTimeInterval)duration {
    NSInteger secs = (NSInteger)lround(duration);
    NSString *js = [NSString stringWithFormat:
                    @"window.VoiceDiaryBridge&&window.VoiceDiaryBridge.onRecordComplete&&"
                    @"window.VoiceDiaryBridge.onRecordComplete({duration:%ld});",
                    (long)secs];
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

- (void)notifyVoiceDiaryError:(NSString *)message {
    NSString *escaped = [message stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    NSString *js = [NSString stringWithFormat:
                      @"window.VoiceDiaryBridge&&window.VoiceDiaryBridge.onRecordError&&"
                      @"window.VoiceDiaryBridge.onRecordError('%@');",
                      escaped];
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

- (void)notifyVoiceDiaryPlayEnded {
    NSString *js = @"window.VoiceDiaryBridge&&window.VoiceDiaryBridge.onPlayEnded&&window.VoiceDiaryBridge.onPlayEnded();";
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

#pragma mark - WKNavigationDelegate / WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"SWBridge"] && [message.body isKindOfClass:[NSDictionary class]]) {
        [self handleSWBridgeMessage:(NSDictionary *)message.body];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"页面加载完成");
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"加载失败: %@", error.localizedDescription);
}

@end
