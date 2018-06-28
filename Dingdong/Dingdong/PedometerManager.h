//
//  PedometerManager.h
//  Dingdong
//
//  Created by fan on 2018/6/21.
//  Copyright © 2018年 fan. All rights reserved.
//

/*
 注意事项：

 1、CoreMotion和HealthKit需要配置plist文件，如下：
 
 <key>NSHealthShareUsageDescription</key>
 <string>App需要您的同意,才能访问运动与健身</string>
 <key>NSHealthUpdateUsageDescription</key>
 <string>App需要您的同意,才能访问运动与健身</string>
 <key>NSMotionUsageDescription</key>
 <string>App需要您的同意,才能访问运动与健身</string>

 2、仅支持iPhone5s及其以上设备
 
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PedometerData : NSObject

/** 步数 */
@property(nonatomic, strong, nullable) NSNumber *numberOfSteps;
/** 步行+跑步距离 */
@property(nonatomic, strong, nullable) NSNumber *distance;

@end


@class PedometerData;

typedef void (^PedometerHandler)(PedometerData * _Nullable pedometerData,NSError * _Nullable error);

@interface PedometerManager : NSObject

+ (instancetype _Nullable )shareInstance;


/** 今日已走步数 */
@property(nonatomic, strong, nullable) NSNumber *numberOfTodaySteps;


/**
 *  计步器是否可以使用
 *
 *  @return YES or NO
 */
+ (BOOL)isStepCountingAvailable;

/**
 *  查询某时间段的行走数据
 *
 *  @param start   开始时间
 *  @param end     结束时间
 *  @param handler 查询结果
 */
- (void)queryPedometerDataFromDate:(NSDate *_Nonnull)start
                            toDate:(NSDate *_Nonnull)end
                       withHandler:(PedometerHandler _Nullable )handler;

/**
 *  监听今天（从零点开始）的行走数据
 *
 *  @param handler 查询结果、变化就更新
 */
- (void)startPedometerUpdatesTodayWithHandler:(PedometerHandler _Nullable )handler;
- (void)startPedometerUpdatesTodayWithHandler_simple:(PedometerHandler _Nullable )handler;


/**
 *  停止监听运动数据
 */
- (void)stopPedometerUpdates;

@end
