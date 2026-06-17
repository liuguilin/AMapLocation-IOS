//
//  ViewController.m
//  LocationApp
//
//  Created by 大伊 on 2025/5/24.
//

#import "ViewController.h"
#import "SYHLocationManager.h"
#import "SYHLocalPushManager.h"
#import "SYWebViewController.h"
#import "SYHSubmitDataService.h"
#import "SYSystemSettingHelper.h"
@import GoogleMaps;

@interface ViewController ()<GMSMapViewDelegate>

@property (nonatomic, strong) GMSMapView *mapView;


@property (nonatomic, strong) UIView *todayQuestionView;
@property (nonatomic, strong) UIView *sevenDayQuestionView;
@property (nonatomic, strong) UIView *promptView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addListener];
    
    SYHLocationManager.shared.viewController = self;
    __weak ViewController *weakSelf = self;
    SYHLocationManager.shared.locationUpdateBlock = ^(CLLocationCoordinate2D coordinate) {
        weakSelf.mapView.camera = [GMSCameraPosition cameraWithLatitude:coordinate.latitude
                                                               longitude:coordinate.longitude
                                                                    zoom:12];
        
        
    };
        
    GMSMapViewOptions *options = [[GMSMapViewOptions alloc] init];
    options.camera = [GMSCameraPosition cameraWithLatitude:1.285
                                                          longitude:103.848
                                                               zoom:12];
    options.frame = self.view.bounds;

    GMSMapView *mapView = [[GMSMapView alloc] initWithOptions:options];
    mapView.delegate = self;
    mapView.myLocationEnabled = YES;
    mapView.settings.myLocationButton = YES;
    self.mapView = mapView;
//    [self.view addSubview:self.mapView];
    
    // 保证单例先创建一下
    [SYHSubmitDataService shared];
    
    [self setupUI];
    
}


- (void)setupUI {
    [self.todayQuestionView removeFromSuperview];
    [self.sevenDayQuestionView removeFromSuperview];
    [self.promptView removeFromSuperview];

    self.todayQuestionView = [self generateTodayQuestionView];
    self.sevenDayQuestionView = [self generateSevenDayQuestionView];
    self.promptView = [self generatePromptView];

    CGRect frame = self.sevenDayQuestionView.frame;
    frame.origin.y = CGRectGetMaxY(self.todayQuestionView.frame) + 40;
    frame.size.height = self.promptView.frame.origin.y - frame.origin.y - 40;
    self.sevenDayQuestionView.frame = frame;

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.mapView.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

#pragma mark - UI （今日问卷）

- (UIView *)generateTodayQuestionView {
    CGFloat containerWidth = self.view.frame.size.width - 20 * 2;
    UIView *todayQuestionView = [[UIView alloc] initWithFrame:CGRectMake(20, 120, self.view.frame.size.width - 40, 100)];
    todayQuestionView.backgroundColor = [UIColor whiteColor];
    todayQuestionView.layer.cornerRadius = 10;
    todayQuestionView.layer.masksToBounds = YES;
    [self.view addSubview:todayQuestionView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, containerWidth - 20, 50)];
    titleLabel.text = NSLocalizedString(@"今日问卷（点击可填写）", nil);
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [todayQuestionView addSubview:titleLabel];
    
    NSDate *date = [NSDate now];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    
    SYHAnswerResult *amResult = [self getAnswerResultWithYear:components.year month:components.month day:components.day type:@"day"];
    SYHAnswerResult *pmResult = [self getAnswerResultWithYear:components.year month:components.month day:components.day type:@"night"];
    
    
    UIView *amView = [self generateTodayQuestinSubViewWithWidth:containerWidth title:NSLocalizedString(@"早问卷（8:00起填写）", nil) isInputh:YES isSelected:amResult.isCommit action:@selector(clickTodayAm:)];
    CGRect frame = amView.frame;
    frame.origin.y = CGRectGetMaxY(titleLabel.frame) + 20;
    amView.frame = frame;
    [todayQuestionView addSubview:amView];

    
    UIView *pmView = [self generateTodayQuestinSubViewWithWidth:containerWidth title:NSLocalizedString(@"晚问卷（20:00起填写）", nil) isInputh:YES isSelected:pmResult.isCommit action:@selector(clickTodayPm:)];
    frame = pmView.frame;
    frame.origin.y = CGRectGetMaxY(amView.frame) + 20;
    pmView.frame = frame;
    [todayQuestionView addSubview:pmView];
    
    frame = todayQuestionView.frame;
    frame.size.height = CGRectGetMaxY(pmView.frame) + 20;
    todayQuestionView.frame = frame;
    
    return todayQuestionView;
}

- (nullable SYHAnswerResult *)getAnswerResultWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day type:(NSString *)type {
    for (SYHAnswerResult *result in [SYHLocationManager shared].answerArray) {
        if (result.year == year && result.month == month && result.day == day) {
            if ([result.type isEqualToString:type ]) {
                return result;
            }
        }
    }
    return nil;
}

- (void)clickTodayAm:(UIButton *)sender {
    
    NSLog(@"clickTodayAm");
    
    NSDate *now = [NSDate now];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:now];
    NSInteger currentHour = components.hour;
    NSInteger currentMinute = components.minute;
    BOOL isAmTime = (currentHour == 8 && currentMinute > 30) || (currentHour >= 9);
    if (!isAmTime) { // 不是早上问卷提交时间不能点击
        return;
    }
    
    for (SYHAnswerResult *result in [SYHLocationManager shared].answerArray) {
        if (result.isToday && [result.type isEqualToString:@"day"] && result.isCommit) {
            return;
        }
    }
    
    [self openWebView: NO answerResult:nil];
}

- (void)clickTodayPm:(UIButton *)sender {
    NSLog(@"clickTodayPm");
    
    NSDate *now = [NSDate now];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:now];
    NSInteger currentHour = components.hour;
    // 8:30以后，20点之前上报day的数据
    BOOL isPmTime = currentHour >= 21;
    if (!isPmTime) { // 不是晚上提交的时间不允许点击
        return;
    }
    
    for (SYHAnswerResult *result in [SYHLocationManager shared].answerArray) {
        if (result.isToday && [result.type isEqualToString:@"night"] && result.isCommit) {
            return;
        }
    }
    
    [self openWebView: YES answerResult:nil];
}


- (UIView *)generateTodayQuestinSubViewWithWidth:(CGFloat)width title:(NSString *)title isInputh:(BOOL)isInput isSelected:(BOOL)isSelected action:(SEL)action {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(20, 0, width - 40, 50)];
    
    CGFloat containerWidth = view.frame.size.width;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, containerWidth - 50, 50)];
    label.font = [UIFont systemFontOfSize:17];
    label.text = title;
    [view addSubview:label];
    
    CGFloat iconWidth = 26;
    UIImageView *iconImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:isSelected ? @"icon_selected" : @"icon_unselected"]];
    iconImage.frame = CGRectMake(containerWidth - iconWidth, (50 - iconWidth) / 2, iconWidth, iconWidth);
    [view addSubview:iconImage];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, containerWidth, 50)];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:btn];
    
    return view;
    
}

#pragma mark - UI （7天内未填写问卷）
- (UIView *)generateSevenDayQuestionView {
    
    CGFloat containerWidth = self.view.frame.size.width - 20 * 2;
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20, 120, containerWidth, 100)];
    scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.layer.cornerRadius = 10;
    scrollView.layer.masksToBounds = YES;
    [self.view addSubview:scrollView];
    
    UIView *sevenDayQuestionView = [[UIView alloc] initWithFrame:CGRectMake(20, 0, self.view.frame.size.width - 40, 100)];
    sevenDayQuestionView.userInteractionEnabled = YES;
//    sevenDayQuestionView.backgroundColor = [UIColor whiteColor];

    [scrollView addSubview:sevenDayQuestionView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, containerWidth - 20, 50)];
    titleLabel.text = NSLocalizedString(@"7天内未填写问卷（点击可填写）", nil);
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [sevenDayQuestionView addSubview:titleLabel];
    
    UIView *lastView = titleLabel;
    NSArray *answerArray = [SYHLocationManager shared].answerArray;
    for (int i = 0; i < answerArray.count; i++) {
        SYHAnswerResult *answerResult = answerArray[i];
        if (answerResult.isCommit || answerResult.isToday) {
            continue;
        }
        NSString *answerType = [answerResult.type isEqualToString:@"day"] ? NSLocalizedString(@"早问卷", nil) : NSLocalizedString(@"晚问卷", nil);
        NSString *title = [self getTimeStrWithYear:answerResult.year month:answerResult.month day:answerResult.day answerType:answerType];
        UIView *view = [self generateSevenDayQuestinSubViewWithWidth:containerWidth title:title action:@selector(clickSevenDayQuestion:) tag:i];
        CGRect frame = view.frame;
        frame.origin.y = CGRectGetMaxY(lastView.frame) + 20;
        view.frame = frame;
        [sevenDayQuestionView addSubview:view];
        lastView = view;
    }
 

    CGRect frame = sevenDayQuestionView.frame;
    frame.size.height = CGRectGetMaxY(lastView.frame) + 20;
    sevenDayQuestionView.frame = frame;
    
    scrollView.contentSize = CGSizeMake(containerWidth, sevenDayQuestionView.frame.size.height);
    
    return scrollView;
}

- (NSString *)getTimeStrWithYear:(int)year month:(int)month day:(int)day answerType:(NSString *)answerType {
    if ([[SYSystemSettingHelper getSettingLanguage] isEqualToString:@"english"]) {
        NSDictionary *monthDict = @{
            @(1): @"Jan.",
            @(2): @"Feb.",
            @(3): @"Mar.",
            @(4): @"Apr.",
            @(5): @"May",
            @(6): @"Jun.",
            @(7): @"Jul.",
            @(8): @"Aug.",
            @(9): @"Sep.",
            @(10): @"Oct.",
            @(11): @"Nov.",
            @(12): @"Dec."
        };
        return [NSString stringWithFormat:@"%@-%@%d %d", answerType, monthDict[@(month)], day, year];

        
    } else {
        return [NSString stringWithFormat:@"%d年%d月%d日%@", year, month, day, answerType];
    }
}

- (UIView *)generateSevenDayQuestinSubViewWithWidth:(CGFloat)width title:(NSString *)title action:(SEL)action tag:(NSUInteger)tag {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(20, 0, width - 40, 50)];
    
    CGFloat containerWidth = view.frame.size.width;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, containerWidth, 50)];
    label.font = [UIFont systemFontOfSize:17];
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:title];
    [text addAttribute:NSUnderlineStyleAttributeName
                 value:@(NSUnderlineStyleSingle)
                 range:NSMakeRange(0, text.length)];
    [text addAttribute:NSUnderlineColorAttributeName
                 value:[UIColor blueColor]
                 range:NSMakeRange(0, text.length)];
    label.attributedText = text;

    
    label.text = title;
    [view addSubview:label];

    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, containerWidth, 50)];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    btn.tag = tag;
    [view addSubview:btn];
    
    return view;
    
}

- (void)clickSevenDayQuestion:(UIButton *)button {
    NSLog(@"clickSevenDayQuestion");
    SYHAnswerResult *result = [SYHLocationManager shared].answerArray[button.tag];
    BOOL isNight = [result.type isEqualToString:@"night"];
    [self openWebView:isNight answerResult:result];
}

#pragma mark - UI （提示信息）

- (UIView *)generatePromptView {
    UILabel *promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, self.view.frame.size.height - 100, self.view.frame.size.width - 60, 40)];
    promptLabel.font = [UIFont systemFontOfSize:17];
    promptLabel.text = NSLocalizedString(@"⚠️ 请勿关闭，避免数据丢失", nil);
    [self.view addSubview:promptLabel];
    
    return promptLabel;
}


#pragma mark - private method


- (void)addListener {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveNotificationResponse) name:SYHUserDidReceiveNotificationResponse object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAnswerDataUpdateNotification) name:SYHAnswerDataUpdateNotificationResponse object:nil];
}

- (void)onAnswerDataUpdateNotification {
    [self setupUI];
}

- (void)onReceiveNotificationResponse {
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour fromDate:now];
    NSInteger currentHour = components.hour;
    BOOL isNight = currentHour > 20;
    
    [self openWebView:isNight answerResult:nil];
    
}

- (void)openWebView:(BOOL)isNight answerResult:(nullable SYHAnswerResult *)result {
    SYWebViewController *webViewController = [[SYWebViewController alloc] init];
    webViewController.isNight = isNight;
    webViewController.answerResult = result;
    webViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:webViewController animated:YES completion:nil];
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView
    didTapPOIWithPlaceID:(NSString *)placeID
                    name:(NSString *)name
       location:(CLLocationCoordinate2D)location {
    NSLog(@"You tapped %@: %@, %f/%f", name, placeID, location.latitude, location.longitude);
    
//    infoMarker = [GMSMarker markerWithPosition:location];
//    infoMarker.snippet = placeID;
//    infoMarker.title = name;
//    infoMarker.opacity = 0;
//    CGPoint pos = infoMarker.infoWindowAnchor;
//    pos.y = 1;
//    infoMarker.infoWindowAnchor = pos;
//    infoMarker.map = mapView;
//    mapView.selectedMarker = infoMarker;
    
}


@end
