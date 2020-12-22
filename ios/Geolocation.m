#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(Geolocation, RCTEventEmitter)

RCT_EXTERN_METHOD(configure: (NSString)url withOffline:(BOOL)offline withTimeInterval: (Double)timeInterval withToken:(NSString)token)
RCT_EXTERN_METHOD(start: (RCTPromiseResolveBlock)resolver withRejecter: (RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(stop: (RCTPromiseResolveBlock)resolver withRejecter: (RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(getExplicitLocation: (RCTPromiseResolveBlock)resolver withRejecter: (RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(setConfig: (Double)timeInterval)
RCT_EXTERN_METHOD(locationChangeListener: (RCTEventEmitter)emitter)
@end
