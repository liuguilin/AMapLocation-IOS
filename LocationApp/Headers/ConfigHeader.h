//
//  ConfigHeader.h
//  LocationApp
//
//  Created by 大伊 on 2025/5/24.
//

#ifndef ConfigHeader_h
#define ConfigHeader_h
//网络错误error的判定常量，属于无网络/连接不到网络/连接不到服务器的那些错误
#define IS_NO_NETWORK_ERROR(ErrorCode) \
(ErrorCode == kCFHostErrorHostNotFound\
|| ErrorCode == kCFHostErrorUnknown\
|| ErrorCode == kCFHostErrorUnknown\
|| ErrorCode == kCFErrorHTTPConnectionLost\
|| ErrorCode == kCFErrorHTTPProxyConnectionFailure\
|| ErrorCode == kCFErrorHTTPSProxyConnectionFailure\
|| ErrorCode == kCFStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod\
|| ErrorCode == kCFURLErrorTimedOut\
|| ErrorCode == kCFURLErrorCannotFindHost\
|| ErrorCode == kCFURLErrorCannotConnectToHost\
|| ErrorCode == kCFURLErrorNetworkConnectionLost\
|| ErrorCode == kCFURLErrorDNSLookupFailed\
|| ErrorCode == kCFURLErrorNotConnectedToInternet\
|| ErrorCode == kCFURLErrorInternationalRoamingOff\
|| ErrorCode == kCFURLErrorSecureConnectionFailed\
|| ErrorCode == kCFURLErrorCannotLoadFromNetwork\
|| ErrorCode == kCFNetServiceErrorUnknown\
|| ErrorCode == kCFNetServiceErrorTimeout\
|| ErrorCode == kCFNetServiceErrorDNSServiceFailure)\

#define WEAK_SELF(weakSelf)  __weak __typeof(self)weakSelf = self;


#endif /* ConfigHeader_h */
