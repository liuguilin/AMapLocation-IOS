//
//  LocationManager.m
//  LocationApp
//
//  Created by 大伊 on 2025/5/24.
//

#import "SYHLocationManager.h"
#import "SYHLocationModel.h"
#import "SYHSubmitDataService.h"
@import GoogleMaps;

@interface SYHLocationManager ()
@property (nonatomic, strong, nullable) NSTimer *timer;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic) CLLocationCoordinate2D currentCoordinate;

@property (nonatomic, strong) NSMutableArray *testLocationArray;
@property (nonatomic, strong) NSMutableArray <SYHAnswerResult *>*answerArray;


@end

NSString *SYHFirstDayKey = @"SYHFirstDayKey";

@implementation SYHLocationManager
+ (instancetype)shared {
    static SYHLocationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _manager = [[CLLocationManager alloc] init];
        _manager.delegate = self;
        _manager.desiredAccuracy = kCLLocationAccuracyBest;
        _manager.distanceFilter = 3.0; // 移动10米才更新
        _manager.allowsBackgroundLocationUpdates = YES;
        _manager.pausesLocationUpdatesAutomatically = NO;
        if (![[NSUserDefaults standardUserDefaults] objectForKey:SYHFirstDayKey]) { // 存取第一天，未后面数据做准备
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate now] forKey:SYHFirstDayKey];
            
            // 测试代码过去两天
//            NSCalendar *calendar = [NSCalendar currentCalendar];
//               NSDateComponents *components = [[NSDateComponents alloc] init];
//               [components setDay:-3];
//               NSDate *limitDate = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];
//            [[NSUserDefaults standardUserDefaults] setObject:limitDate forKey:SYHFirstDayKey];

        }
       
        [self startTracking];
        [self heartbeatRequestLocation];
        [self readLocalData];
        [self readTestLocalData];
        [self readAnswerData];
//        [self updateUploadSuccessLocalData:@[]];
        // 监听应用状态变化
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(restartLocationService)
            name:UIApplicationDidBecomeActiveNotification
            object:nil];
        
    }
    return self;
}

#pragma mark - 后台保活

// 启动后台任务
- (void)startBackgroundLocation {
    // 申请后台任务时间（iOS默认给3分钟）
    self.bgTask = [[UIApplication sharedApplication]
        beginBackgroundTaskWithExpirationHandler:^{
            // 超时回调（3分钟到仍无法完成时触发）
            [self.manager stopUpdatingLocation];
            [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
            self.bgTask = UIBackgroundTaskInvalid;
        }];
    
    // 启动定位
    [self.manager startUpdatingLocation];
}

// 重启服务
- (void)restartLocationService {
    // 1. 检查定位权限状态
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status != kCLAuthorizationStatusAuthorizedAlways) {
        [self.manager requestAlwaysAuthorization]; // 重新请求"始终"权限
        return;
    }
        
    // 2. 重启定位服务
    [self.manager stopUpdatingLocation]; // 先停止服务
    
    // 3. 重新配置关键参数（防止被系统重置）
    self.manager.allowsBackgroundLocationUpdates = YES;
    self.manager.pausesLocationUpdatesAutomatically = NO;
    
    // 4. 启动定位并申请后台任务保活
    [self.manager startUpdatingLocation];
    
    __weak typeof(self) weakSelf = self;

    // 5. 持有新的后台任务标识符
    self.bgTask = [[UIApplication sharedApplication]
        beginBackgroundTaskWithExpirationHandler:^{
            [weakSelf.manager stopUpdatingLocation];
            [[UIApplication sharedApplication] endBackgroundTask:weakSelf.bgTask];
        weakSelf.bgTask = UIBackgroundTaskInvalid;
        }
    ];
}

#pragma mark - 心跳定时获取定位

- (void)heartbeatRequestLocation {
    __weak typeof(self) weakSelf = self;
    // 3分钟获取一次定位
    // TODO: kevin 记得删除
//        self.timer = [NSTimer scheduledTimerWithTimeInterval:3 repeats:YES block:^(NSTimer * _Nonnull timer) {

    self.timer = [NSTimer scheduledTimerWithTimeInterval:180 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSDate *now = [NSDate now];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:NSCalendarUnitHour fromDate:now];

//        // 测试数据
//        NSDate *date = [NSDate now];
//        NSString *dateString = [weakSelf.dateFormatter stringFromDate:date];
//        [weakSelf updateTestLocationData: dateString];
        
        if (components.hour >= 8 && components.hour < 21) { // 只记录8点~20点之间的定位数据
            NSDate *date = [NSDate now];
            NSString *dateString = [weakSelf.dateFormatter stringFromDate:date];
            [weakSelf dealAddress:weakSelf.currentCoordinate time:dateString];
        }
    }];
}

- (void)startTracking {
    //    if (![CLLocationManager locationServicesEnabled]) {
    //        NSLog(@"定位服务未开启");
    //        return;
    //    }
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        if ([_manager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [_manager requestAlwaysAuthorization];
        }
    } else if (status == kCLAuthorizationStatusDenied) {
        NSLog(@"用户拒绝定位权限");
    } else {
        [_manager startUpdatingLocation];
    }
}

- (void)stopTracking {
    [_manager stopUpdatingLocation];
}

- (void)dealAddress:(CLLocationCoordinate2D)coordinate time:(NSString *)time {
    __weak typeof(self) weakSelf = self;
    GMSGeocoder *geocoder = [[GMSGeocoder alloc] init];
    [geocoder reverseGeocodeCoordinate:coordinate
                     completionHandler:^(GMSReverseGeocodeResponse *response, NSError *error) {
        SYHLocationModel *locationModel = [[SYHLocationModel  alloc] init];
        
        //        locationModel.lat = [NSString stringWithFormat:@"%f", coordinate.latitude];
        //        locationModel.lng = [NSString stringWithFormat:@"%f", coordinate.longitude];
        
        locationModel.lat = coordinate.latitude;
        locationModel.lng = coordinate.longitude;
        locationModel.time = time;
        
        if (error) { // 逆编码错误，也要将经纬度保存
            NSLog(@"逆地理编码失败: %@", error.localizedDescription);
            // 失败就重试
//            [weakSelf dealAddress:coordinate time:time];
        } else {
            
            GMSAddress *address = response.firstResult;
            NSLog(@"完整地址: %@", address.lines); // 街道地址数组
            NSLog(@"城市: %@", address.locality);  // 城市名
            NSLog(@"国家: %@", address.country);   // 国家名
            
            
            NSString *detailAddress = [NSString stringWithFormat:@"%@ %@ %@ %@", address.country, address.locality, address.subLocality, address.thoroughfare];
            locationModel.address = detailAddress;
            //        locationModel.address = [detailAddress stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            /// 在主线程操作数据，防止多线程操作数据
            [weakSelf.locationArray addObject:locationModel];
            [weakSelf saveLocalData];
        });
    }];
}



#pragma mark - public
// 已经上传成功过的内容直接删除
- (void)deleteLocations:(NSArray<SYHLocationModel *> *)locations {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", locations];
    NSArray *resultArray = [self.locationArray filteredArrayUsingPredicate:predicate];
    
    self.locationArray = [resultArray mutableCopy];
    [self saveLocalData];
    
    // 将上传成功的数据缓存
    [self updateUploadSuccessLocalData:locations];
}


#pragma mark - answer

- (void)updateAnswerDataWithType:(NSString *)type year:(int)year month:(int)month day:(int)day isCommit:(BOOL)isCommit {
    SYHAnswerResult *result = [self generateAnswerWithType:type year:year month:month day:day isCommit:isCommit];

    [self updateAnswerDataWithAnswerResult:result];
}

- (SYHAnswerResult *)generateAnswerWithType:(NSString *)type year:(int)year month:(int)month day:(int)day isCommit:(BOOL)isCommit {
    SYHAnswerResult *result = [[SYHAnswerResult alloc] init];
    result.type = type;
    result.isCommit = isCommit;
    result.year = year;
    result.month = month;
    result.day = day;
    return result;
}

- (void)updateAnswerDataWithAnswerResult:(SYHAnswerResult *)result {
    // 每次插入到第一个位置
    int index = -1;
    for (int i = 0; i < self.answerArray.count; i++) {
        if ([self.answerArray[i] isEqual:result]) {
            index = i;
            break;
        }
    }
    
    if (index != -1) { // 更新原有的数据，无需做插入和删除操作
        SYHAnswerResult *oldResult = self.answerArray[index];
        if (!oldResult.isCommit) { // 如果没有上报，就更新
            [self.answerArray replaceObjectAtIndex:index withObject:result];
        }
    } else {
        [self.answerArray insertObject:result atIndex:0];
        
        if ([result.type isEqualToString:@"day"] && self.answerArray.count > 16) {
            [self.answerArray removeLastObject];
        }
        
        if ([result.type isEqualToString:@"night"] && self.answerArray.count > 16) {
            [self.answerArray removeLastObject];
        }
    }
    
    [self saveAnswerLocalData:self.answerArray];
    [[NSNotificationCenter defaultCenter] postNotificationName:SYHAnswerDataUpdateNotificationResponse object:nil];
}

- (void)saveAnswerLocalData:(NSArray *)updateSuccessLocations {
    // 使用NSMutableData存储多个对象
    NSError *error;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:updateSuccessLocations requiringSecureCoding:YES error:&error];
    [data writeToFile:[self localAnswerPath] atomically:YES];
    
    if (error) {
        NSLog(@"%@", error);
    } else {
        NSLog(@"保存成功：%@", updateSuccessLocations);
    }
}

- (void)readAnswerData {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 使用NSMutableData存储多个对象
        NSData *data = [NSData dataWithContentsOfFile:[self localAnswerPath]];
        NSError *error;
        
        NSArray<SYHAnswerResult *> *decodedArray = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:[NSArray class], [SYHAnswerResult class], [NSString class], nil] fromData:data error:&error];
        if (error) {
            NSLog(@"🍺：读取本地错误：%@", error);
        } else {
            NSLog(@"🍺：读取本地成功，结果为：%@", decodedArray);
        }
        dispatch_async(dispatch_get_main_queue(), ^{ // 回到主线程更新数组
            if (decodedArray) {
                NSArray *arr = self.answerArray.copy;
                self.answerArray = [NSMutableArray arrayWithArray:decodedArray];
                for (SYHAnswerResult *result in arr) {
                    if (![self.answerArray containsObject:result]) {
                        [self.answerArray addObject:result];
                    }
                }
                
            }
            [self completeAnswerDataIfNeeded];
            [[NSNotificationCenter defaultCenter] postNotificationName:SYHAnswerDataUpdateNotificationResponse object:nil];
        });
        
    });
}

- (void)completeAnswerDataIfNeeded {
    NSMutableArray *answerResultArray = [NSMutableArray array];
    NSArray <NSDateComponents *> *pastSevenDaysComponents = [self getPastSevenDaysComponents];
    
    for (int i = 0; i < pastSevenDaysComponents.count; i++) {
        NSDateComponents *components = pastSevenDaysComponents[i];
        SYHAnswerResult *dayResult = [self getAnswerResultWithComponents:components type:@"day"];
        [answerResultArray addObject:dayResult];
        SYHAnswerResult *nightResult = [self getAnswerResultWithComponents:components type:@"night"];
        [answerResultArray addObject:nightResult];
    }
    self.answerArray = [answerResultArray mutableCopy];
}

- (SYHAnswerResult *)getAnswerResultWithComponents:(NSDateComponents *)components type:(NSString *)type {
    for (SYHAnswerResult *result in self.answerArray) {
        if ([result.type isEqualToString:type] && components.year == result.year && components.month == result.month && components.day == result.day) {
            return result;
        }
    }
    return [self generateAnswerWithType:type year:(int)components.year month:(int)components.month day:(int)components.day isCommit:NO];
}

// 过去7天包括今天是8天
- (NSArray <NSDateComponents *> *)getPastSevenDaysComponents {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    NSMutableArray *result = [NSMutableArray array];
    NSDate *limitDate = [[NSUserDefaults standardUserDefaults] objectForKey:SYHFirstDayKey];

    for (int i = 0; i <= 7; i++) {
        [offsetComponents setDay:-i];
        NSDate *pastDate = [calendar dateByAddingComponents:offsetComponents
                                                   toDate:now
                                                  options:0];
        
        // 如果设置了限制日期且当前日期早于限制日期，则跳过
        if (limitDate && [pastDate compare:limitDate] == NSOrderedAscending) {
            continue;
        }
        
        NSDateComponents *components = [calendar components:
            NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|
            NSCalendarUnitWeekday|NSCalendarUnitHour|NSCalendarUnitMinute
                                                  fromDate:pastDate];
        [result addObject:components];
    }
    
    return [result copy];
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *newLocation = locations.lastObject;
    NSLog(@"didUpdateLocations 经度: %f, 纬度: %f",
          newLocation.coordinate.longitude,
          newLocation.coordinate.latitude);
    self.currentCoordinate = newLocation.coordinate;
    
    // 任务完成后释放
    [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
    self.bgTask = UIBackgroundTaskInvalid;
    if (self.locationUpdateBlock) {
        self.locationUpdateBlock(newLocation.coordinate);
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"位置获取错误：%@", error);
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    if (manager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways) {
        [manager startUpdatingLocation];
    } else {
        NSLog(@"定位服务未开启");
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"请打开定位，并且设置为：始终，不然无法正常使用app" preferredStyle:(UIAlertControllerStyleAlert)];
        __weak typeof(self) weakSelf = self;
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"去开启" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf openLocationSettings];
        }];
        [alertController addAction:action];
        [self.viewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)openLocationSettings {
    NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:settingsURL]) {
        [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
    }
    
}

#pragma mark - local data

- (void)saveLocalData {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 使用NSMutableData存储多个对象
        NSError *error;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.locationArray requiringSecureCoding:YES error:&error];
        [data writeToFile:[self localPath] atomically:YES];
        
        if (error) {
            NSLog(@"保存本地错误：%@", error);
        } else {
            NSLog(@"保存本地成功");
        }
    });
}

- (void)readLocalData {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        
        // 使用NSMutableData存储多个对象
        NSData *data = [NSData dataWithContentsOfFile:[self localPath]];
        NSError *error;
        
        NSArray<SYHLocationModel *> *decodedArray = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:[NSArray class], [SYHLocationModel class], [NSString class], nil] fromData:data error:&error];
        if (error) {
            NSLog(@"读取本地错误：%@", error);
        } else {
            NSLog(@"读取本地成功，结果为：%@", decodedArray);
        }
        dispatch_async(dispatch_get_main_queue(), ^{ // 回到主线程更新数组
            if (decodedArray) {
                NSArray *arr = self.locationArray.copy;
                self.locationArray = [NSMutableArray arrayWithArray:decodedArray];
                [self.locationArray addObjectsFromArray:arr];
                
                // 测试代码
//                [self deleteLocations:self.locationArray];
//                [SYHSubmitDataService.shared submitLocationMsgWithAnswers:nil];
            }
        });
        
    });
}

- (NSString *)localPath {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
                     stringByAppendingPathComponent:@"user.archiver"];
    return path;

}

- (NSString *)localAnswerPath {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
                     stringByAppendingPathComponent:@"answer.archiver"];
    return path;

}

#pragma mark - 测试数据缓存

- (NSString *)uploadSuccessLocalPath {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
                     stringByAppendingPathComponent:@"uploadSuccess.archiver"];
    return path;
}

- (void)updateUploadSuccessLocalData:(NSArray<SYHLocationModel *> *)locations {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 使用NSMutableData存储多个对象
        NSData *data = [NSData dataWithContentsOfFile:[self uploadSuccessLocalPath]];
        NSError *error;
        
        NSArray<SYHLocationModel *> *decodedArray = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:[NSArray class], [SYHLocationModel class], [NSString class], nil] fromData:data error:&error];
        if (error) {
            NSLog(@"%@", error);
        }
        
        NSMutableArray<SYHLocationModel *> *finalArray = decodedArray.mutableCopy;
        if (!finalArray) {
            finalArray = [NSMutableArray array];
        }
        [finalArray addObjectsFromArray:locations];
        [self saveUploadSuccessLocalData:finalArray];
        
    });
}

- (void)saveUploadSuccessLocalData:(NSArray *)updateSuccessLocations {
    // 使用NSMutableData存储多个对象
    NSError *error;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:updateSuccessLocations requiringSecureCoding:YES error:&error];
    [data writeToFile:[self uploadSuccessLocalPath] atomically:YES];
    
    if (error) {
        NSLog(@"%@", error);
    } else {
        NSLog(@"保存成功：%@", updateSuccessLocations);
    }
}

#pragma mark - test local data

- (void)updateTestLocationData:(NSString *)time {
    SYHLocationModel *locationModel = [[SYHLocationModel alloc] init];
    NSDate *date = [NSDate now];
    NSString *dateString = [self.dateFormatter stringFromDate:date];
    locationModel.lat = self.currentCoordinate.latitude;
    locationModel.lng = self.currentCoordinate.longitude;
    locationModel.time = dateString;
    [self.testLocationArray addObject:locationModel];
    
    [self saveTestLocalData];
}


- (void)saveTestLocalData {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 使用NSMutableData存储多个对象
        NSError *error;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.testLocationArray requiringSecureCoding:YES error:&error];
        [data writeToFile:[self testLocalPath] atomically:YES];
        
        if (error) {
            NSLog(@"保存本地错误：%@", error);
        } else {
            NSLog(@"保存本地成功");
        }
    });
}

- (void)readTestLocalData {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 使用NSMutableData存储多个对象
        NSData *data = [NSData dataWithContentsOfFile:[self testLocalPath]];
        NSError *error;
        
        NSArray<SYHLocationModel *> *decodedArray = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:[NSArray class], [SYHLocationModel class], [NSString class], nil] fromData:data error:&error];
        if (error) {
            NSLog(@"🍺：读取本地错误：%@", error);
        } else {
            NSLog(@"🍺：读取本地成功，结果为：%@", decodedArray);
        }
        dispatch_async(dispatch_get_main_queue(), ^{ // 回到主线程更新数组
            if (decodedArray) {
                NSArray *arr = self.testLocationArray.copy;
                self.testLocationArray = [NSMutableArray arrayWithArray:decodedArray];
                [self.testLocationArray addObjectsFromArray:arr];
            }
        });
        
    });
}

- (NSString *)testLocalPath {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
                     stringByAppendingPathComponent:@"testLocationData.archiver"];
    return path;

}


#pragma mark - getter setter

- (NSMutableArray *)locationArray {
    if (!_locationArray) {
        _locationArray = [[NSMutableArray alloc] init];
    }
    return _locationArray;
}

- (NSMutableArray *)testLocationArray {
    if (!_testLocationArray) {
        _testLocationArray = [NSMutableArray array];
    }
    return _testLocationArray;
}

- (NSMutableArray<SYHAnswerResult *> *)answerArray {
    if (!_answerArray) {
        _answerArray = [NSMutableArray array];
    }
    return _answerArray;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"]; // 指定格式
    }
    return _dateFormatter;
}

@end
