//
//  UrlHeader.h
//  BusinessExchange
//
//  Created by     生意汇 on 2017/5/2.
//  Copyright © 2017年     生意汇. All rights reserved.
//

#ifndef UrlHeader_h
#define UrlHeader_h

#define IS_DEBUG



#define google_appkey @"AIzaSyDqWX4RDS30z1VqhiMOCeomM9BGsm0ZnVg"
//测试环境
#ifdef IS_DEBUG

//预上线
#define SYH_PATH @"http://8.210.252.35:3000"

//#define SYH_PATH @"http://8.210.252.35:3000"

#else
//正式环境
#define SYH_PATH @"https://8.210.252.35:3000"

  



#endif



#define STRING_WITH_FORMAT(absolute) [NSString stringWithFormat:@"%@/%@",SYH_PATH,absolute]


#define SUBMIT_LOCATION_DATA_URL STRING_WITH_FORMAT(@"api/submit")//提交定位数据

#endif /* UrlHeader_h */
