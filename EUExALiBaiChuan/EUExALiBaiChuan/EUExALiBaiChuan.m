//
//  EUExALiBaiChuan.m
//  EUExALiBaiChuan
//
//  Created by 杨广 on 16/5/12.
//  Copyright © 2016年 杨广. All rights reserved.
//

#import "EUExALiBaiChuan.h"
#import <ALBBSDK/ALBBWebViewService.h>
#import <ALBBTradeSDK/ALBBCartService.h>
#import <ALBBTradeSDK/ALBBItemService.h>
#import <ALBBTradeSDK/ALBBOrderService.h>
#import <ALBBTradeSDK/ALBBPromotionService.h>
#import <ALBBTradeSDK/ALBBTradeService.h>
#import <ALBBSDK/ALBBSDK.h>
#import "EUtility.h"

@interface EUExALiBaiChuan()
@property (nonatomic, strong) id<ALBBTradeService> tradeService;
@property (nonatomic, strong) tradeProcessFailedCallback onTradeFailure;
@property (nonatomic, strong) tradeProcessSuccessCallback onTradeSuccess;
//@property (nonatomic, strong) ACJSFunctionRef *funcLogin;
//@property (nonatomic, strong) ACJSFunctionRef *funcLogout;
//@property (nonatomic, strong) addCartCacelledCallback onCartCancel;
//@property (nonatomic, strong) addCartSuccessCallback onCartSuccess;

@end
NSMutableDictionary  *taoKeParams;
@implementation EUExALiBaiChuan
+(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    // 如果百川处理过会返回YES
    if (![[ALBBSDK sharedInstance] handleOpenURL:url]) {
        // 处理其他app跳转到自己的app
    }
    return YES;
}

-(void)init:(NSMutableArray*)inArguments{
    ACArgsUnpack(ACJSFunctionRef*func) = inArguments;
    [[ALBBSDK sharedInstance] setDebugLogOpen:NO];//开发阶段打开日志开关，方便排查错误信息
    [[ALBBSDK sharedInstance] setUseTaobaoNativeDetail:YES];//优先使用手淘APP打开商品详情页面，如果没有安装手机淘宝，SDK会使用H5打开
    [[ALBBSDK sharedInstance] setViewType:ALBB_ITEM_VIEWTYPE_TAOBAO];//使用淘宝H5页面打开商品详情
    [[ALBBSDK sharedInstance] asyncInit:^{
        NSLog(@"init success");
        NSDictionary *dic = @{@"status":@0};
         [self callBackJsonWithFunction:@"cbInit" parameter:dic];
        [func executeWithArguments:ACArgsPack(@(0))];
        
    } failure:^(NSError *error) {
        NSDictionary *dic = @{@"status":@1,@"errorCode":@(error.code)};
        [self callBackJsonWithFunction:@"cbInit" parameter:dic];
        [func executeWithArguments:ACArgsPack(@(1),@(error.code))];
        NSLog(@"init failure, %@", error);
    }];
    
    
    _tradeService=ALBBService(ALBBTradeService);
     //__weak typeof(self) Myself = self;
    _onTradeSuccess=^(ALBBTradeResult *tradeProcessResult){
        NSString *tip=[NSString stringWithFormat:@"交易成功:成功的订单%@\n，失败的订单%@\n",tradeProcessResult.paySuccessOrders,tradeProcessResult.payFailedOrders];
//        NSDictionary *dic = @{@"status":@0,@"paySuccessOrders":tradeProcessResult.paySuccessOrders,@"payFailedOrders":tradeProcessResult.payFailedOrders};
//        [Myself callBackJsonWithFunction:@"onTrade" parameter:dic];
        NSLog(@"%@", tip);
    };
    _onTradeFailure=^(NSError *error){
//        NSDictionary *dic = @{@"status":@1,@"errorCode":@(error.code),@"msg":error.localizedDescription};
//        [Myself callBackJsonWithFunction:@"onTrade" parameter:dic];
        NSLog(@"error:%@",error);
    };
}
-(void)login:(NSMutableArray*)inArguments{
    ACArgsUnpack(ACJSFunctionRef*func) = inArguments;
    if(![[TaeSession sharedInstance] isLogin]){
        id <ALBBLoginService> loginService = [[ALBBSDK sharedInstance] getService:@protocol(ALBBLoginService)];
        [loginService showLogin:[self.webViewEngine viewController] successCallback:^(TaeSession *session) {
            NSDictionary *dic = @{@"isLogin":@0};
            [self callBackJsonWithFunction:@"cbLogin" parameter:dic];
            [func executeWithArguments:ACArgsPack(@(0))];
        } failedCallback:^(NSError *error){
            NSDictionary *dic = @{@"isLogin":@1};
            [self callBackJsonWithFunction:@"cbLogin" parameter:dic];
            [func executeWithArguments:ACArgsPack(@(1))];
        }];
    }else{
        NSDictionary *dic = @{@"isLogin":@0};
        [self callBackJsonWithFunction:@"cbLogin" parameter:dic];
        [func executeWithArguments:ACArgsPack(@(0))];
    }

}
-(NSDictionary*)getUserInfo:(NSMutableArray*)inArguments{
    if ([[TaeSession sharedInstance] isLogin]) {
        TaeSession *session=[TaeSession sharedInstance];
        NSDictionary *tip = @{@"userId":[session getUser].userId,@"nick":[session getUser].nick,@"iconUrl":[session getUser].iconUrl,@"loginTime":[session getLoginTime],@"authorizationCode":[session getAuthorizationCode],@"isLogin":[session isLogin]?@0:@1};
        
        NSLog(@"UserInfo:%@",tip);
        
        return tip;
    }else{
        NSDictionary *dic = @{@"isLogin":@1};
        return dic;
    }
    
}
-(void)logout:(NSMutableArray*)inArguments{
    ACArgsUnpack(ACJSFunctionRef*func) = inArguments;
    if([[TaeSession sharedInstance] isLogin]){
        [ALBBService(ALBBLoginService) logout];
    }else{
        NSDictionary *dic = @{@"isLogin":@1};
        [self callBackJsonWithFunction:@"cbLogout" parameter:dic];
        [func executeWithArguments:ACArgsPack(@(0))];
 
    }
    
    [ALBBService(ALBBLoginService) setSessionStateChangedHandler:^(TaeSession *session) {
        if([session isLogin]){//未登录变为已登录
            NSDictionary *dic = @{@"isLogin":@0};
            [self callBackJsonWithFunction:@"cbLogout" parameter:dic];
            [func executeWithArguments:ACArgsPack(@(1))];
            
        }else{//已登录变为未登录
            NSDictionary *dic = @{@"isLogin":@1};
            [self callBackJsonWithFunction:@"cbLogout" parameter:dic];
            [func executeWithArguments:ACArgsPack(@(0))];
            
        }
    }];
}
//打开购物车页面
-(void)openMyCart:(NSMutableArray*)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    if(info && [info objectForKey:@"isvcode"]){
        NSString *isv_code = [info objectForKey:@"isvcode"];
        [[ALBBSDK sharedInstance] setISVCode:isv_code]; //设置全局的app标识，在电商模块里等同于isv_code
    }
    TaeWebViewUISettings *viewSettings =[self getWebViewSetting];
    ALBBTradePage *page=[ALBBTradePage myCartsPage];
    ALBBTradeTaokeParams *taoKeParams = nil;
     [_tradeService  show:[self.webViewEngine viewController] isNeedPush:NO webViewUISettings:viewSettings page:page taoKeParams:taoKeParams tradeProcessSuccessCallback:_onTradeSuccess tradeProcessFailedCallback:_onTradeFailure];
}
//打开订单列表页面
-(void)openMyOrdersPage:(NSMutableArray*)inArguments{
    TaeWebViewUISettings *viewSettings =[self getWebViewSetting];
    //@param status      订单状态. 0为全部订单; 1为待付款订单; 2为待发货订单; 3为待收货订单; 4为待评价订单.
    //@param isAllOrder  是否显示全部订单. 传YES时, 显示全部订单; 传NO时, 显示ISV的订单.
    ALBBTradePage *page=[ALBBTradePage  myOrdersPage:0 isAllOrder:YES];
    ALBBTradeTaokeParams *taoKeParams = nil;//[self getTaoKeParams];
    [_tradeService  show:[self.webViewEngine viewController] isNeedPush:NO webViewUISettings:viewSettings page:page taoKeParams:taoKeParams tradeProcessSuccessCallback:_onTradeSuccess tradeProcessFailedCallback:_onTradeFailure];
}
//打开商品真实ID对应的详情页面
-(void)openItemDetailPageById:(NSMutableArray*)inArguments{
        if(inArguments.count<1){
            return;
        }
    //id info=[inArguments[0] JSONValue];
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *itemid = [info objectForKey:@"itemid"];
    NSString *mmpid = [info objectForKey:@"mmpid"];
    NSString *isv_code = [info objectForKey:@"isvcode"];
    NSDictionary *params;
    if (isv_code != nil) {
        params = @{ @"isv_code" : isv_code};
    }else{
        params = nil;
    }
     ALBBTradeTaokeParams *taoKeParamsDataTmp=[[ALBBTradeTaokeParams alloc] init];
    taoKeParamsDataTmp.pid = mmpid;
    NSNumber *realitemId= [[[NSNumberFormatter alloc]init] numberFromString:itemid];//@"45535180986",@"AAHd5d-HAAeGwJedwSnHktBI"
    ALBBTradeTaokeParams *taoKeParams = taoKeParamsDataTmp;
    
    ALBBTradePage *page=[ALBBTradePage itemDetailPage:[NSString stringWithFormat:@"%@",realitemId] params:params];
    [_tradeService  show:[self.webViewEngine viewController] isNeedPush:NO webViewUISettings:nil page:page taoKeParams:taoKeParams tradeProcessSuccessCallback:_onTradeSuccess tradeProcessFailedCallback:_onTradeFailure];
}
//通过URL打开指定商品页面
-(void)openItemDetailPageByURL:(NSMutableArray*)inArguments{
    if(inArguments.count<1){
        return;
    }
    //id info=[inArguments[0] JSONValue];
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *url = [info objectForKey:@"url"];
    NSString *mmpid = [info objectForKey:@"mmpid"];
    ALBBTradeTaokeParams *taoKeParamsDataTmp=[[ALBBTradeTaokeParams alloc] init];
    taoKeParamsDataTmp.pid = mmpid;
    TaeWebViewUISettings *viewSettings =[self getWebViewSetting];
    ALBBTradePage *page=[ALBBTradePage page:url];
    ALBBTradeTaokeParams *taoKeParams = taoKeParamsDataTmp;
    [_tradeService  show:[self.webViewEngine viewController] isNeedPush:NO webViewUISettings:viewSettings page:page taoKeParams:taoKeParams tradeProcessSuccessCallback:_onTradeSuccess tradeProcessFailedCallback:_onTradeFailure];
}

-( TaeWebViewUISettings *)getWebViewSetting{
    TaeWebViewUISettings *settings = [[TaeWebViewUISettings alloc] init];
    settings.titleColor = [UIColor blueColor];
    settings.tintColor = [UIColor redColor];
    settings.barTintColor = [UIColor grayColor];
    return settings;
}
#pragma mark - CallBack Method

-(void)callBackJsonWithFunction:(NSString *)functionName parameter:(id)obj{
    [self.webViewEngine callbackWithFunctionKeyPath:[NSString stringWithFormat:@"uexALiBaiChuan.%@",functionName] arguments:ACArgsPack([obj ac_JSONFragment])];
    
}
@end
