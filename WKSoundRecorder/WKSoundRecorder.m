//
//  WKSoundRecorder.m
//  WorkSDK
//
//  Created by xiaofeng on 2020/4/28.
//  Copyright © 2020 xiaofeng. All rights reserved.
//

#import "WKSoundRecorder.h"
#import "WorkVoiceView.h"

#pragma clang diagnostic ignored "-Wdeprecated"
#define GetImage(imageName)  [UIImage imageNamed:imageName]

@interface WKSoundRecorder()

@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) NSString *recordPath;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSTimer *levelTimer;

@property (nonatomic, strong) UIImageView *imageViewAnimation;
@property (nonatomic, strong) UIImageView *talkPhone, *image0;
@property (nonatomic, strong) UIImageView *shotTime;
@property (nonatomic, strong) UILabel *textLable;

@end

@implementation WKSoundRecorder

+ (WKSoundRecorder *)shareInstance {
    static WKSoundRecorder *sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        if (sharedInstance == nil) {
            sharedInstance = [[WKSoundRecorder alloc] init];
        }
    });
    return sharedInstance;
}

#pragma mark - Public Methods

- (void)startSoundRecord:(UIView *)view recordPath:(NSString *)path {
    self.recordPath = path;
    [self initHUBViewWithView:view];
    [self startRecord];
}

- (void)stopSoundRecord:(UIView *)view {
    if (self.levelTimer) {
        [self.levelTimer invalidate];
        self.levelTimer = nil;
    }
    
    NSString *str = [NSString stringWithFormat:@"%f",_recorder.currentTime];
    
    int times = [str intValue];
    if (times >= 1) {
        if (view == nil) {
            view = [[[UIApplication sharedApplication] windows] lastObject];
        }
        
        if ([view isKindOfClass:[UIWindow class]]) {
            [view addSubview:_HUD];
        } else {
            [view.window addSubview:_HUD];
        }
        if (_delegate&&[_delegate respondsToSelector:@selector(didStopSoundRecord)]) {
            [_delegate didStopSoundRecord];
        }
        if (self.recorder) {
            [self.recorder stop];
        }
    } else {
        [self deleteRecord];
        [self.recorder stop];
        if ([_delegate respondsToSelector:@selector(showSoundRecordFailed)]) {
            [_delegate showSoundRecordFailed];
        }
    }
    [self removeHUD];
}

- (void)soundRecordFailed:(UIView *)view {
    [self deleteRecord];
    [self.recorder stop];
    [self removeHUD];
}

- (void)readyCancelSound {

}

- (void)resetNormalRecord {
    _imageViewAnimation.hidden = NO;
    _talkPhone.hidden = NO;
    _shotTime.hidden = YES;
    _image0.hidden = NO;
    _textLable.hidden = YES;

}

- (void)showShotTimeSign:(UIView *)view {
    _imageViewAnimation.hidden = YES;
    _talkPhone.hidden = YES;
    _image0.hidden = YES;
    _shotTime.hidden = NO;
    _textLable.hidden = NO;
    _textLable.text = @"说话时间太短";
    
    [self performSelector:@selector(soundRecordFailed:) withObject:view afterDelay:1.5f];
}

- (void)showCountdown:(int)countDown{
    _imageViewAnimation.hidden = NO;
    _talkPhone.hidden = NO;
    _image0.hidden = NO;
    _shotTime.hidden = YES;
    _textLable.hidden = NO;
    _textLable.text = [NSString stringWithFormat:@"还可以说%d秒",countDown];
}

- (NSTimeInterval)soundRecordTime {
    return _recorder.currentTime;
}

#pragma mark - Private Methods

- (void)initHUBViewWithView:(UIView *)view {
    if (_HUD) {
        [_HUD removeFromSuperview];
        _HUD = nil;
    }
    if (view == nil) {
        view = [[[UIApplication sharedApplication] windows] firstObject];
    }
    if (_HUD == nil) {
        _HUD = [[MBProgressHUD alloc] initWithView:view];
        _HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        _HUD.margin = 0;
        
        WorkVoiceView *voiceView = [[WorkVoiceView alloc] initWithFrame:CGRectMake(0, 0, 222, 222)];
        voiceView.backgroundColor = WK_ColorFromHex(0x000000);
        
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        [voiceView addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@(127));
            make.height.equalTo(@(87));
            make.centerX.equalTo(voiceView.mas_centerX);
            make.centerY.equalTo(voiceView.mas_centerY);
        }];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        _talkPhone = imageView;
        _talkPhone.image = NSBundleImage(wk_icon_record_voice);
        [view addSubview:_talkPhone];
        [_talkPhone mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(view.mas_left);
            make.height.equalTo(@(87));
            make.centerY.equalTo(view.mas_centerY);
            make.width.equalTo(@(59));
        }];
        
        UIImageView *image0 = [[UIImageView alloc] initWithImage:NSBundleImage(wk_icon_record_v0)];
        self.image0 = image0;
        [view addSubview:image0];
        [image0 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(view);
            make.top.equalTo(view.mas_top);
            make.width.equalTo(@(56));
            make.height.equalTo(@(87));
        }];
        
        imageView = [[UIImageView alloc] init];
        _imageViewAnimation = imageView;
        [view addSubview:_imageViewAnimation];
        [_imageViewAnimation mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(image0);
        }];
        
        imageView = [[UIImageView alloc] init];
        self.shotTime = imageView;
        _shotTime.image = NSBundleImage(wk_icon_timeshort);
        _shotTime.hidden = YES;
        [view addSubview:_shotTime];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(view.mas_centerX);
            make.centerY.equalTo(view.mas_centerY);
            make.width.equalTo(@23);
            make.height.equalTo(@80);
        }];
        
        UILabel *label = [[UILabel alloc] init];
        _textLable = label;
        _textLable.backgroundColor = [UIColor clearColor];
        _textLable.textColor = [UIColor whiteColor];
        _textLable.textAlignment = NSTextAlignmentCenter;
        _textLable.font = WK_RegularSysFont(14);
        _textLable.text = @"说话时间太短";
        _textLable.hidden = YES;
        [view addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_talkPhone.mas_bottom).offset(10);
            make.centerX.equalTo(imageView.mas_centerX);
        }];

        _HUD.customView = voiceView;

        _HUD.mode = MBProgressHUDModeCustomView;
    }
    if ([view isKindOfClass:[UIWindow class]]) {
        [view addSubview:_HUD];
    } else {
        [view.window addSubview:_HUD];
    }
    [_HUD show:YES];
}

- (void)removeHUD {
    if (_HUD) {
        [_HUD removeFromSuperview];
        _HUD = nil;
    }
}

- (void)startRecord {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    //设置AVAudioSession
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err) {
        return;
    }
    
    //设置录音输入源
    UInt32 doChangeDefaultRoute = 1;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof (doChangeDefaultRoute), &doChangeDefaultRoute);
    err = nil;
    [audioSession setActive:YES error:&err];
    if(err) {
        return;
    }
    //设置文件保存路径和名称
    NSString *fileName = [NSString stringWithFormat:@"/voice-%5.2f.caf", [[NSDate date] timeIntervalSince1970]];
    self.recordPath = [self.recordPath stringByAppendingPathComponent:fileName];
    NSURL *recordedFile = [NSURL fileURLWithPath:self.recordPath];
    NSDictionary *dic = [self recordingSettings];
    //初始化AVAudioRecorder
    err = nil;
    _recorder = [[AVAudioRecorder alloc] initWithURL:recordedFile settings:dic error:&err];
    if(_recorder == nil) {
        return;
    }
    //准备和开始录音
    [_recorder prepareToRecord];
    self.recorder.meteringEnabled = YES;
    [self.recorder record];
    [_recorder recordForDuration:0];
    if (self.levelTimer) {
        [self.levelTimer invalidate];
        self.levelTimer = nil;
    }
    self.levelTimer = [NSTimer scheduledTimerWithTimeInterval: 0.0001 target: self selector: @selector(levelTimerCallback:) userInfo: nil repeats: YES];
}

- (void)deleteRecord {
    if (self.recorder) {
        [self.recorder stop];
        [self.recorder deleteRecording];
    }
    
    if (self.HUD) {
        [self.HUD hide:NO];
    }
}

- (void)levelTimerCallback:(NSTimer *)timer {
    if (_recorder&&_imageViewAnimation) {
        [_recorder updateMeters];
        double ff = [_recorder averagePowerForChannel:0];
        ff = ff + 60;
        if (ff > 0 && ff <= 10) {
            [_imageViewAnimation setImage:NSBundleImage(wk_icon_record_v0)];
        } else if (ff > 10 && ff < 20) {
            [_imageViewAnimation setImage:NSBundleImage(wk_icon_record_v1)];
        } else if (ff >= 20 && ff < 30) {
            [_imageViewAnimation setImage:NSBundleImage(wk_icon_record_v2)];
        } else if (ff >= 30 && ff < 40) {
            [_imageViewAnimation setImage:NSBundleImage(wk_icon_record_v3)];
        } else if (ff >= 40 && ff < 50) {
            [_imageViewAnimation setImage:NSBundleImage(wk_icon_record_v4)];
        } else if (ff >= 50 && ff < 60) {
            [_imageViewAnimation setImage:NSBundleImage(wk_icon_record_v5)];
        } else if (ff >= 60 && ff < 70) {
            [_imageViewAnimation setImage:NSBundleImage(wk_icon_record_v6)];
        } else if (ff >= 70 && ff < 80) {
            [_imageViewAnimation setImage:NSBundleImage(wk_icon_record_v7)];
        } else {
            [_imageViewAnimation setImage:NSBundleImage(wk_icon_record_v8)];
        }
    }
}

#pragma mark - Getters

- (NSDictionary *)recordingSettings
{
    NSMutableDictionary *recordSetting =[NSMutableDictionary dictionaryWithCapacity:10];
    [recordSetting setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    //2 采样率
    [recordSetting setObject:[NSNumber numberWithFloat:8000.0] forKey: AVSampleRateKey];
    //3 通道的数目
    [recordSetting setObject:[NSNumber numberWithInt:2]forKey:AVNumberOfChannelsKey];
    //4 采样位数  默认 16
    [recordSetting setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityMedium] forKey:AVEncoderAudioQualityKey];//音频质量

    return recordSetting;
}

- (NSString *)soundFilePath {
    return self.recordPath;
}

@end
