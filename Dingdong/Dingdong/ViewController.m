//
//  ViewController.m
//  Dingdong
//
//  Created by fan on 2018/6/21.
//  Copyright © 2018年 fan. All rights reserved.
//

#import "ViewController.h"
#import <HealthKit/HealthKit.h>
#import "PedometerManager.h"

// 屏幕宽高
#define kMainScreenWidth    [[UIScreen mainScreen] bounds].size.width
#define kMainScreenHeight   [[UIScreen mainScreen] bounds].size.height


@interface ViewController ()

@property (nonatomic, strong) HKHealthStore *healthStore;
@property (nonatomic, strong) UILabel *stepsLable;
@property (nonatomic, strong) UILabel *stepsLable2;

@property (nonatomic, strong) UILabel *tipLable;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = @"叮咚";
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSFontAttributeName:[UIFont systemFontOfSize:19],
                                                                      NSForegroundColorAttributeName:[UIColor blackColor]
                                                                      }];
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    // HealthKit步数
    self.stepsLable = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, kMainScreenWidth-20, 45)];
    [self.view addSubview:self.stepsLable];
    self.stepsLable.textColor = [UIColor blueColor];
    self.stepsLable.font = [UIFont systemFontOfSize:18];
    
    // CoreMotion步数
    self.stepsLable2 = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.stepsLable.frame)+30, kMainScreenWidth-20, 45)];
    self.stepsLable2.textColor = [UIColor blueColor];
    self.stepsLable2.font = [UIFont systemFontOfSize:18];
    [self.view addSubview:self.stepsLable2];
    
    // error提示语
    self.tipLable = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(self.stepsLable2.frame)+30, kMainScreenWidth-20, 45)];
    self.tipLable.textColor = [UIColor redColor];
    self.tipLable.font = [UIFont systemFontOfSize:18];
    [self.view addSubview:self.tipLable];
    
    
    // 通过<CoreMotion/CoreMotion.h>来获取步数
    [self fetchStepCountFromCoreMotion];
    
    // 通过<HealthKit/HealthKit.h>来获取步数
    [self fetchStepCountFromHealthKit];
}


- (void)fetchStepCountFromCoreMotion {
    __weak __typeof(self) wself = self;
    [[PedometerManager shareInstance] startPedometerUpdatesTodayWithHandler_simple:^(PedometerData *pedometerData, NSError *error) {
        __strong __typeof(wself) sself = wself;
        if (!error) {
            sself.stepsLable2.text = [NSString stringWithFormat:@"CoreMotion的计步数据：%@",pedometerData.numberOfSteps];
        }
    }];
}


- (void)fetchStepCountFromHealthKit {
    //查看healthKit在设备上是否可用，iPad上不支持HealthKit
    if (![HKHealthStore isHealthDataAvailable]) {
        self.tipLable.text = @"该设备不支持HealthKit";
    }else{
        //创建healthStore对象
        self.healthStore = [[HKHealthStore alloc]init];
        
        //设置需要获取的权限 这里仅设置了步数
        HKObjectType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        NSSet *healthSet = [NSSet setWithObjects:stepType, nil];
        
        __weak __typeof(self) wself = self;
        //从健康应用中获取权限
        [self.healthStore requestAuthorizationToShareTypes:nil readTypes:healthSet completion:^(BOOL success, NSError * _Nullable error) {
            __strong __typeof(wself) sself = wself;
            if (success) {
                //获取步数后我们调用获取步数的方法
                [sself readStepCount];
            } else {
                sself.tipLable.text = @"获取步数权限失败";
            }
        }];
    }
}

- (void)readStepCount {
    //查询采样信息
    HKSampleType *sampleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];

    //NSSortDescriptor来告诉healthStore怎么样将结果排序
    NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    //获取当前时间
    NSDate *now = [NSDate date];
    NSCalendar *calender = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *dateComponent = [calender components:unitFlags fromDate:now];
    int hour = (int)[dateComponent hour];
    int minute = (int)[dateComponent minute];
    int second = (int)[dateComponent second];
    NSDate *nowDay = [NSDate dateWithTimeIntervalSinceNow:  - (hour*3600 + minute * 60 + second) ];
    //时间结果与想象中不同是因为它显示的是0区
    NSLog(@"今天%@",nowDay);
    NSDate *nextDay = [NSDate dateWithTimeIntervalSinceNow:  - (hour*3600 + minute * 60 + second)  + 86400];
    NSLog(@"明天%@",nextDay);
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:nowDay endDate:nextDay options:(HKQueryOptionNone)];
    
    /*查询的基类是HKQuery，这是一个抽象类，能够实现每一种查询目标，这里我们需要查询的步数是一个HKSample类所以对应的查询类是HKSampleQuery。下面的limit参数传1表示查询最近一条数据，查询多条数据只要设置limit的参数值就可以了*/
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc]initWithSampleType:sampleType predicate:predicate limit:0 sortDescriptors:@[start,end] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        //设置一个int型变量来作为步数统计
        int allStepCount = 0;
        for (int i = 0; i < results.count; i ++) {
            //把结果转换为字符串类型
            HKQuantitySample *result = results[i];
            HKQuantity *quantity = result.quantity;
            NSMutableString *stepCount = (NSMutableString *)quantity;
            NSString *stepStr =[ NSString stringWithFormat:@"%@",stepCount];
            //获取51 count此类字符串前面的数字
            NSString *str = [stepStr componentsSeparatedByString:@" "][0];
            int stepNum = [str intValue];
            NSLog(@"%d",stepNum);
            //把一天中所有时间段中的步数加到一起
            allStepCount = allStepCount + stepNum;
        }
        
        //查询要放在多线程中进行，如果要对UI进行刷新，要回到主线程
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            self.stepsLable.text = [NSString stringWithFormat:@"HealthKit的计步数据：%d",allStepCount];
        }];
    }];
    //执行查询
    [self.healthStore executeQuery:sampleQuery];
}


@end
