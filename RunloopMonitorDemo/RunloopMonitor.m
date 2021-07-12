//
//  RunloopMonitor.m
//  RunloopMonitorDemo
//
//  Created by Marshal on 2021/7/12.
//

/* Run Loop Observer Activities */
//typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
//    kCFRunLoopEntry = (1UL << 0),           // 即将进入Loop
//    kCFRunLoopBeforeTimers = (1UL << 1),    //即将处理Timer
//    kCFRunLoopBeforeSources = (1UL << 2),   //即将处理Source
//    kCFRunLoopBeforeWaiting = (1UL << 5),   //即将进入休眠
//    kCFRunLoopAfterWaiting = (1UL << 6),    //刚从休眠中唤醒
//    kCFRunLoopExit = (1UL << 7),            //即将退出Loop
//    kCFRunLoopAllActivities = 0x0FFFFFFFU   //所有状态改变
//};

#import "RunloopMonitor.h"
#import <QuartzCore/QuartzCore.h>
#import "LSCallStack.h"

@interface RunloopMonitor ()
{
@package
    dispatch_semaphore_t _semaphore;
    NSInteger _semaphoreCount; //用于保存信号量次数，避免繁忙时signal多次
    BOOL _isMonitor; //是否需要监测
    
    CFRunLoopObserverRef _observer; //runloop观察者
    CFRunLoopActivity _activity; //runloop的活动状态
    
    NSInteger _cardCount; //卡的次数
    
    NSString *_lastCallStackSymbols; //保存用于处理连续重复的卡顿信息
    NSTimeInterval _lastInterval; //上次时间，一定时间后会显示重复卡顿信息，有利于调试
}

@end

@implementation RunloopMonitor

+ (instancetype)sharedInstance {
    static RunloopMonitor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.minInterval = 400;
        instance.maxCount = 5;
        instance.isPrintStackSymbols = YES;
    });
    return instance;
}

void runloopCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    RunloopMonitor *monitor = [RunloopMonitor sharedInstance];
    monitor->_activity = activity;
    //释放信号量（信号值+1，如果信号量值低于0则阻塞）
    dispatch_semaphore_signal(monitor->_semaphore);
}

- (void)startMonitor {
    _isMonitor = true;
    
    //注册observer监听runloop
    CFRunLoopObserverContext context = {0, (__bridge void*)self, NULL, NULL};
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runloopCallback, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    //初始化信号量等相关参数
    _semaphore = dispatch_semaphore_create(0);
    _semaphoreCount = 0;
    _cardCount = 0;
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(self) sself = wself;
        if (!sself) return;
        
        while (sself->_isMonitor) {
            //使用信号量阻塞当前线程(信号量值-1，如果信号量值低于0则阻塞)，设置一个超时时间400ms
            //如果超时时间到了，则会停止阻塞，信号量恢复，并返回一个非零的resut，如果是正常signal唤醒，则result返回0
            intptr_t result = dispatch_semaphore_wait(sself->_semaphore, dispatch_time(DISPATCH_TIME_NOW, sself->_minInterval * NSEC_PER_MSEC));
            //如果等待超时，runloop仍然在等到sources处理或者刚刚唤醒状态，被认为一次卡顿
            if (result != 0 && (sself->_activity == kCFRunLoopBeforeSources || sself->_activity == kCFRunLoopAfterWaiting)) {
                if (++sself->_cardCount >= sself->_maxCount) {
                    //大于或者等于为一次有效卡顿，回调卡顿提示block
                    if (sself.runloopMonitorCardCallback) sself.runloopMonitorCardCallback(sself);
                    if (sself.isPrintStackSymbols) __printStackSymbols(sself);
                    sself->_cardCount = 0;
                }
            }else {
                //没有超时，则重置卡顿此时
                sself->_cardCount = 0;
            }
        };
    });
}

- (void)endMonitor {
    _isMonitor = false;
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = NULL;
}

//打印堆栈信息
void __printStackSymbols(RunloopMonitor *self) {
    NSString *callStackSymbols =  [LSCallStack ls_backtraceOfMainThread];
    //仅仅显示2s之外的重复卡顿信息，为了方便调试
    if (!self->_lastCallStackSymbols || ![self->_lastCallStackSymbols isEqualToString:callStackSymbols] || (self->_lastInterval && CACurrentMediaTime() - self->_lastInterval > 2) ) {
        NSLog(@"检测到了卡顿\n 堆栈信息---callStackSymbols:\n%@\n", callStackSymbols);
    }
    self->_lastCallStackSymbols = callStackSymbols;
    self->_lastInterval = CACurrentMediaTime();
}

@end
