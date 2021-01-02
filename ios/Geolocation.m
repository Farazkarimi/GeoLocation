#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(Geolocation, RCTEventEmitter)

RCT_EXTERN_METHOD(configure: (NSDictionary *)object)
RCT_EXTERN_METHOD(start: (RCTPromiseResolveBlock)resolver withRejecter: (RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(stop: (RCTPromiseResolveBlock)resolver withRejecter: (RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(getExplicitLocation: (RCTPromiseResolveBlock)resolver withRejecter: (RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(setConfig: (NSString *)timeInterval)
@end
