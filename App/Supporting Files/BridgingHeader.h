//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

@import NewTermCommon;

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST
@import IOKit;

extern CFTypeRef IOPSCopyPowerSourcesInfo(void);
extern CFArrayRef IOPSCopyPowerSourcesList(CFTypeRef blob);
extern CFDictionaryRef IOPSGetPowerSourceDescription(CFTypeRef blob, CFTypeRef ps);
#endif
