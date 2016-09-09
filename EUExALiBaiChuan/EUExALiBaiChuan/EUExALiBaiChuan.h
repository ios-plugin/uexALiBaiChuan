//
//  EUExALiBaiChuan.h
//  EUExALiBaiChuan
//
//  Created by 杨广 on 16/5/12.
//  Copyright © 2016年 杨广. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppCanKit/AppCanKit.h>
#import <ALBBLoginSDK/ALBBLoginService.h>
@interface EUExALiBaiChuan : EUExBase
@property(nonatomic, strong) loginSuccessCallback loginSuccessCallback;
@property(nonatomic, strong) loginFailedCallback loginFailedCallback;
@end
