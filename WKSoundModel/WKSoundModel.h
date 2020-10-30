//
//  WKSoundModel.h
//  WorkSDK
//
//  Created by xiaofeng on 2020/4/28.
//  Copyright © 2020 xiaofeng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKSoundModel : NSObject

@property (nonatomic, copy) NSString *soundFilePath;
@property (nonatomic, assign) NSTimeInterval seconds;

- (NSString *)getMp3FilePath;

@end

NS_ASSUME_NONNULL_END
