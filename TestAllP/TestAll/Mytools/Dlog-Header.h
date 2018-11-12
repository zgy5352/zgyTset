//
//  Dlog-Header.h
//  TestAll
//
//  Created by zhaoguoying on 2017/9/27.
//  Copyright © 2017年 ZDHS. All rights reserved.
//

#ifndef Dlog_Header_h
#define Dlog_Header_h
#import <Foundation/Foundation.h>

#pragma mark ---------------------------------------------  网址  ---------------------------------------------
//#define HTTP www.baidu.com
#define HTTP @"http://124.205.145.238:9001"

#pragma mark ---------------------------------------------  字符串  ---------------------------------------------
static NSString * const zgyStrNotiPinglun = @"notiPinglun"; // 点击评论通知
//const static NSString *APIKey = @"4b7aafb296107596059df00b3b97ae06";


#pragma mark ---------------------------------------------  第三方  ---------------------------------------------
//#import "UIImageView+WebCache.h"
//#import "MJRefresh.h"
//#import "SDCycleScrollView.h"
//#import "RequestTool.h"
//#import "DataHandle.h"

//#importRongCallLib.framewrok
//RongCallKit.framewrok、AgoraRtcEngineKit.framework
//CoreMotion.framework、VideoToolbox.framework、libresolv.tbd

#pragma mark ---------------------------------------------  自定义  ---------------------------------------------
#import "MyTools.h"
//#import "MNUserInfo.h"


#pragma mark ---------------------------------------------  工具  ---------------------------------------------
#import "Foundation+Log.h"
#import "UIView+Extension.h"
//#import "NSObject+MJKeyValue.h"
//#import "UIImage+Tool.h"

#pragma mark ---------------------------------------------  数字  ---------------------------------------------
#define SCREEN [[UIScreen mainScreen] bounds]
//#define kMin 0.5
//#define kMax 1

#pragma mark ---------------------------------------------  打印  ---------------------------------------------
#ifdef DEBUG

#define Dlog1(...) NSLog(__VA_ARGS__)
#define Dlog2(...) NSLog(@"💐 💤 ♻️%@",__VA_ARGS__)
#define Dlog3(...) NSLog(@"💐 💤 ♻️%s %d\n %@",__func__,__LINE__,[NSString stringWithFormat:__VA_ARGS__])

#else

#define Dlog1(...)
#define Dlog2(...)
#define Dlog3(...)
#define NSLog(...)

#endif

#pragma mark ---------------------------------------------  颜色  ---------------------------------------------
#define RGBCOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]
#define RGBRandomColor [UIColor colorWithRed:(arc4random()%256)/255.0 green:(arc4random()%256)/255.0 blue:(arc4random()%256)/255.0 alpha:(1)]

#define kcolourTableview RGBCOLOR(242,243,244,1) // tabelView 颜色
#define kcolourScroview RGBCOLOR(239,239,244,1)  // scroview 颜色

#define kcolourLine RGBCOLOR(237,238,239,1) // 浅色横线
#define kcolourGray1 RGBCOLOR(211,211,211,1) // 浅灰  重色横线
#define kcolourGray2 RGBCOLOR(169,169,169,1) // 深灰  浅色小字体
#define kcolourGray3 RGBCOLOR(112,128,144,1) // 石板灰
#define kcolourGray4 RGBCOLOR(47,79,79,1) // 深石板灰

#define kcolourBlue1 RGBCOLOR(0,191,255,1) // 深天蓝
#define kcolourBlue2 RGBCOLOR(30,144,255,1) // 道奇蓝
#define kcolourRed RGBCOLOR(227,69,69,1) // 红色


// 字体大小
//#define kLabelBoldFontSize20 [UIFont boldSystemFontOfSize:20]

#pragma mark ---------------------------------------------  其他  ---------------------------------------------
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
//#define IS_PAD (UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPad)
#define IS_IPHONE_X ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define Height_StatusBar ((IS_IPHONE_X==YES)?44.0f: 20.0f)
#define Height_NavBar    ((IS_IPHONE_X==YES)?88.0f: 64.0f)
#define Height_TabBar    ((IS_IPHONE_X==YES)?83.0f: 49.0f)
#define kTabbarSafeBottomMargin (IS_IPHONE_X ? 34.f : 0.f)




#endif /* Dlog_Header_h */
