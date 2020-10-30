//
//  WKSoundRecorder.h
//  WorkSDK
//
//  Created by xiaofeng on 2020/4/28.
//  Copyright © 2020 xiaofeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WKSoundRecorderDelegate <NSObject>

@optional
- (void)showSoundRecordFailed;
- (void)didStopSoundRecord;

@end

@interface WKSoundRecorder : NSObject

@property (nonatomic, copy) NSString *soundFilePath;
@property (nonatomic, weak) id<WKSoundRecorderDelegate>delegate;

+ (WKSoundRecorder *)shareInstance;
/**
 *  开始录音
 *
 *  @param view 展现录音指示框的父视图
 *  @param path 音频文件保存路径
 */
- (void)startSoundRecord:(UIView * _Nullable)view recordPath:(NSString *)path;
/**
 *  录音结束
 */
- (void)stopSoundRecord:(UIView * _Nullable)view;
/**
 *  更新录音显示状态,手指向上滑动后 提示松开取消录音
 */
- (void)soundRecordFailed:(UIView * _Nullable)view;
/**
 *  更新录音状态,手指重新滑动到范围内,提示向上取消录音
 */
- (void)readyCancelSound;
/**
 *  更新录音状态,手指重新滑动到范围内,提示向上取消录音
 */
- (void)resetNormalRecord;
/**
 *  录音时间过短
 */
- (void)showShotTimeSign:(UIView * _Nullable)view ;
/**
 *  最后10秒，显示你还可以说X秒
 *
 *  @param countDown X秒
 */
- (void)showCountdown:(int)countDown;


- (NSTimeInterval)soundRecordTime;

@end

NS_ASSUME_NONNULL_END
