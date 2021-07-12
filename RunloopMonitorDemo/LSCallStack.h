
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/**
 获取函数调用栈 ，忘了哪里搬来的了😂
 Xcode 的调试输出不稳定，有时候存在调用 NSLog() 但没有输出结果的情况，建议前往 控制台 中根据设备的 UUID 查看完整输出。
 真机调试和使用 Release 模式时，为了优化，某些符号表并不在内存中，而是存储在磁盘上的 dSYM 文件中，无法在运行时解析，因此符号名称显示为 <redacted>。
 关于dSYM可以参考 https://github.com/answer-huang/dSYMTools
 @see https://github.com/bestswifter/BSBacktraceLogger
 */

@interface LSCallStack : NSObject

+ (NSString *)ls_backtraceOfAllThread;
+ (NSString *)ls_backtraceOfCurrentThread;
+ (NSString *)ls_backtraceOfMainThread;
+ (NSString *)ls_backtraceOfNSThread:(NSThread *)thread;

@end

NS_ASSUME_NONNULL_END
