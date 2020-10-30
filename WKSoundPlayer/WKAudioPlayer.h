//
//  WKAudioPlayer.h
//  WorkSDK
//
//  Created by xiaofeng on 2020/4/28.
//  Copyright © 2020 xiaofeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, WKAudioPlayerState){
    WKAudioPlayerStateNormal = 0,/**< 未播放状态 */
    WKAudioPlayerStatePlaying = 2,/**< 正在播放 */
    WKAudioPlayerStateCancel = 3,/**< 播放被取消 */
};

@protocol WKAudioPlayerDelegate <NSObject>

- (void)audioPlayerStateDidChanged:(WKAudioPlayerState)audioPlayerState forIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_BEGIN

@interface WKAudioPlayer : NSObject

@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, weak) id<WKAudioPlayerDelegate>delegate;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) UIButton* playerButton;

+ (instancetype)sharePlayer;

- (void)playAudioWithURLString:(NSString *)URLString atIndex:(NSUInteger)index withParentButton:(UIButton*)playerButton;

- (void)stopAudioPlayer;

@end

NS_ASSUME_NONNULL_END
