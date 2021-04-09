//
//  RTCAppHealthKit+RTCAppHealthKit_Methods_ECG.m
//  RCTAppleHealthKit
//
//  Created by Igor Rudenko on 05.04.2021.
//  Copyright © 2021 Igor Rudenko. All rights reserved.
//

#import "RCTAppleHealthKit+Methods_ECG.h"
#import "RCTAppleHealthKit+Queries.h"
#import "RCTAppleHealthKit+Utils.h"

@implementation RCTAppleHealthKit (Methods_ECG)

- (void)fetchMostRecentECG:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback {
  NSMutableDictionary* params = [NSMutableDictionary dictionaryWithDictionary:input];
  [params setValue:@1 forKey:@"limit"];
  [params setValue:@NO forKey:@"ascending"];
  [self fetchECG:params callback:callback];
}

- (void)fetchECG:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback {
  HKElectrocardiogramType *ecgType = [HKObjectType electrocardiogramType];
  NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
  BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
  NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
  NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
  if(startDate == nil){
    callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
    return;
  }
  NSPredicate * predicate = [RCTAppleHealthKit predicateForSamplesBetweenDates:startDate endDate:endDate];
  
  NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:ascending];
  
  // declare the block
  void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);
  // create and assign the block
  handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
    if (!results) {
      if (callback) {
        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
      }
      return;
    }
    
    if (callback) {
      NSMutableArray *data = [NSMutableArray array];
      dispatch_group_t group = dispatch_group_create();
      for (HKElectrocardiogram *sample in results) {
        dispatch_group_enter(group);
        [self fetchECGValueOfSample:sample completion:^(NSArray * samples, NSError *error) {
          if (error == nil) {
            NSMutableDictionary* params = [NSMutableDictionary dictionary];
            params[@"ecg"] = samples;
            params[@"frequency"] = @([sample.samplingFrequency doubleValueForUnit:[HKUnit hertzUnit]]);
            params[@"date"] = @(sample.endDate.timeIntervalSince1970);
            double averageHeartRate = [sample.averageHeartRate doubleValueForUnit:[[HKUnit countUnit] unitDividedByUnit:[HKUnit minuteUnit]]];
            params[@"avgRate"] = @(averageHeartRate);
            params[@"classification"] = @(sample.classification);
            [data addObject:params];
          }
          dispatch_group_leave(group);
        }];
      }
      dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        callback(@[[NSNull null], data]);
      });
    }
  };
  
  HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:ecgType
                                                         predicate:predicate
                                                             limit:limit
                                                   sortDescriptors:@[timeSortDescriptor]
                                                    resultsHandler:handlerBlock];
  
  [self.healthStore executeQuery:query];
}

-(void)fetchECGValueOfSample:(HKElectrocardiogram*)sample
                  completion:(void (^)(NSArray *, NSError *))completion {
  NSMutableArray* voltages = [NSMutableArray array];
  HKElectrocardiogramQuery* query = [[HKElectrocardiogramQuery alloc] initWithElectrocardiogram:sample dataHandler:^(HKElectrocardiogramQuery * _Nonnull query, HKElectrocardiogramVoltageMeasurement * _Nullable voltageMeasurement, BOOL done, NSError * _Nullable error) {
    double voltage = [[voltageMeasurement quantityForLead:HKElectrocardiogramLeadAppleWatchSimilarToLeadI] doubleValueForUnit:[HKUnit voltUnitWithMetricPrefix:HKMetricPrefixMilli]];
    voltage = (round(voltage * 10000)) / 10000;
    [voltages addObject:[NSNumber numberWithDouble: voltage]];
    if (done == YES || error != nil) {
      completion(voltages, nil);
    }
  }];
  [self.healthStore executeQuery:query];
}

@end
