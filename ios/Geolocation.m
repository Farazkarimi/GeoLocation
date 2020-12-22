#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(Geolocation, NSObject)

RCT_EXTERN_METHOD(getLocation:(RCTEventEmitter)emitter)

RCT_EXTERN_METHOD(getServerResponse:(NSString)url withToken:(NSString)token withOffline:(BOOL)offline withTimeInterval: (Double)timeInterval withEmitter:(RCTEventEmitter)emitter)
@end
