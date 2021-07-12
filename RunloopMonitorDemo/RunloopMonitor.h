//
//  RunloopMonitor.h
//  RunloopMonitorDemo
//
//  Created by Marshal on 2021/7/12.
//  runloop卡顿监测工具(主要检测卡主线程的卡顿)

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RunloopMonitor : NSObject

//多少次卡顿为一次有效卡顿，默认5次(减少错误监测几率)
@property (nonatomic, assign) NSInteger maxCount;
//一次卡顿的最小时间，单位毫秒ms，默认400ms
@property (nonatomic, assign) NSInteger minInterval;
//检测到卡顿后的回调
@property (nonatomic, copy) void (^runloopMonitorCardCallback)(RunloopMonitor *monitor);

//是否打印主队列堆栈信息，默认打印
@property (nonatomic, assign) BOOL isPrintStackSymbols;

+ (instancetype)sharedInstance;

- (void)startMonitor;//开始检测
- (void)endMonitor;//结束检测

@end

NS_ASSUME_NONNULL_END
