//
//  WKAudioPlayer.m
//  WorkSDK
//
//  Created by xiaofeng on 2020/4/28.
//  Copyright © 2020 xiaofeng. All rights reserved.
//

#import "WKAudioPlayer.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#include "amrFileCodec.h"

NSString *const kXMNAudioDataKey;

@interface WKAudioPlayer()<AVAudioPlayerDelegate>

@property (nonatomic, strong) NSOperationQueue *audioDataOperationQueue;
@property (nonatomic, assign) WKAudioPlayerState audioPlayerState;
@property (nonatomic, strong) NSTimer* soundTimer;

@end

@implementation WKAudioPlayer{
    int showTag;
}

+ (void)initialize {
    //配置播放器配置
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error: nil];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _audioDataOperationQueue = [[NSOperationQueue alloc] init];
        _index = NSUIntegerMax;
        showTag = 1;

    }
    return self;
}

+ (instancetype)sharePlayer{
    static dispatch_once_t onceToken;
    static id shareInstance;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    return shareInstance;
}

#pragma mark - Public Methods

- (void)playAudioWithURLString:(NSString *)URLString atIndex:(NSUInteger)index withParentButton:(UIButton*)playerButton{
    if (!URLString) {
        return;
    }
    //如果来自同一个URLString并且index相同,则直接取消
    if ([self.URLString isEqualToString:URLString] && self.index == index) {
        [self stopAudioPlayer];
        [self setAudioPlayerState:WKAudioPlayerStateCancel];
        return;
    }
    
    _playerButton = playerButton;
    if (_soundTimer == nil) {
        
        _soundTimer =  [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    }

    
    self.URLString = URLString;
    self.index = index;
    
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSData *audioData = [self audioDataFromURLString:URLString atIndex:index];
        if (!audioData) {
            [self setAudioPlayerState:WKAudioPlayerStateCancel];
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self playAudioWithData:audioData];
        });
    }];
    [_audioDataOperationQueue addOperation:blockOperation];
    
}

- (void)stopAudioPlayer {
    if (_audioPlayer) {
        _audioPlayer.playing ? [_audioPlayer stop] : nil;
        _audioPlayer.delegate = nil;
        _audioPlayer = nil;
        [[WKAudioPlayer sharePlayer] setAudioPlayerState:WKAudioPlayerStateCancel];
        
        [_soundTimer invalidate];
        _soundTimer = nil;
        [_playerButton setImage:NSBundleImage(wk_icon_play) forState:UIControlStateNormal];
    }
}

//动画播放时计时器控制动画
- (void)timerAction{
    
    if (showTag==4) {
        showTag = 1;
    }
    
    [_playerButton setImage:NSBundleImage(wk_icon_playNum(showTag)) forState:UIControlStateNormal];
    
    showTag++;
}

#pragma mark - Private Methods

- (NSData *)audioDataFromURLString:(NSString *)URLString atIndex:(NSUInteger)index{
    NSData *audioData;

    if ([URLString hasSuffix:@".caf"]) {//播放本机录制的文件
        audioData = [NSData dataWithContentsOfFile:URLString];
    } else if ([URLString hasSuffix:@".amr"]) {//播放安卓发来的AMR文件
        audioData = DecodeAMRToWAVE([NSData dataWithContentsOfFile:URLString]);
    } else {
        NSLog(@"soundFile not support!");
    }

    if (audioData) {
        objc_setAssociatedObject(audioData, &kXMNAudioDataKey, [NSString stringWithFormat:@"%@_%ld",URLString,index], OBJC_ASSOCIATION_COPY);
    }
    
    return audioData;
}
- (void)playAudioWithData:(NSData *)audioData {
    NSString *audioURLString = objc_getAssociatedObject(audioData, &kXMNAudioDataKey);
    
    if (![[NSString stringWithFormat:@"%@_%ld",self.URLString,self.index] isEqualToString:audioURLString]) {
        return;
    }
    
    NSError *audioPlayerError;
    _audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:&audioPlayerError];
    if (!_audioPlayer || !audioData) {
        [self setAudioPlayerState:WKAudioPlayerStateCancel];
        return;
    }
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityStateChanged:) name:UIDeviceProximityStateDidChangeNotification object:nil];
    
    _audioPlayer.volume = 1.0f;
    _audioPlayer.delegate = self;
    [_audioPlayer prepareToPlay];
    [self setAudioPlayerState:WKAudioPlayerStatePlaying];
    [_audioPlayer play];
}

- (void)cancelOperation {
    for (NSOperation *operation in _audioDataOperationQueue.operations) {
        [operation cancel];
        break;
    }
}

- (void)proximityStateChanged:(NSNotification *)notification {
    if ([[UIDevice currentDevice] proximityState] == YES) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }else {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}

#pragma mark - Setters

- (void)setURLString:(NSString *)URLString {
    if (_URLString) {
        //说明当前有正在播放,或者正在加载的视频,取消operation(如果没有在执行任务),停止播放
        [self cancelOperation];
        [self stopAudioPlayer];
        [self setAudioPlayerState:WKAudioPlayerStateCancel];
    }
    _URLString = [URLString copy];
}

- (void)setAudioPlayerState:(WKAudioPlayerState)audioPlayerState{
    _audioPlayerState = audioPlayerState;
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayerStateDidChanged:forIndex:)]) {
        [self.delegate audioPlayerStateDidChanged:_audioPlayerState forIndex:self.index];
    }
    if (_audioPlayerState == WKAudioPlayerStateCancel || _audioPlayerState == WKAudioPlayerStateNormal) {
        _URLString = nil;
        _index = NSUIntegerMax;
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self setAudioPlayerState:WKAudioPlayerStateNormal];
    
    //删除近距离事件监听
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
    
    //延迟一秒将audioPlayer 释放
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .2f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self stopAudioPlayer];
    });
}

@end
