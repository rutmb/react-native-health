//
//  RTCAppHealthKit+RTCAppHealthKit_Methods_ECG.h
//  RCTAppleHealthKit
//
//  Created by Igor Rudenko on 05.04.2021.
//  Copyright © 2021 Igor Rudenko. All rights reserved.
//

#import "RCTAppleHealthKit.h"

@interface RCTAppleHealthKit (Methods_ECG)

- (void)fetchMostRecentECG:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fetchECG:(NSDictionary *)input
        callback:(RCTResponseSenderBlock)callback;

@end
