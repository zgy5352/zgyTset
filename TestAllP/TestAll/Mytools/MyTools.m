//
//  MyTools.m
//  that is me1
//
//  Created by zhaoguoying on 16/6/24.
//  Copyright © 2016年 heike. All rights reserved.
//

#import "MyTools.h"

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <netinet/in.h>//connectedToNetwork 方法
#import <QuartzCore/QuartzCore.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "sys/utsname.h"
#import "Reachability.h" // 网络判断
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetImageGenerator.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <ImageIO/ImageIO.h>


//static GetDataManager *manager = nil;
@interface MyTools ()

@property(nonatomic,strong) NSMutableDictionary *dicToken;
@property(nonatomic,strong)UITextView *textView;
@property(nonatomic,strong)NSMutableDictionary *ticks;
@end



@implementation MyTools
singleton_implementation(MyTools)

// 单例对象
/*
 +(instancetype)sharedGetDataManager{
 
 // block中的代码整个程序只会运行一次
 static dispatch_once_t onceToken;
 dispatch_once(&onceToken, ^{
 
 manager = [[GetDataManager alloc] init];
 });
 
 return manager;
 }
 */

-(NSMutableDictionary *)ticks{
    if (!_ticks) _ticks = [MyTools userDefWithKey:@"ticks"];
    return _ticks;
}

//判断网络是否连接
+(BOOL)connectedToNetwork{
    
    //创建零地址，0.0.0.0的地址表示查询本机的网络连接状态
    struct sockaddr_in zeroAddress;            //struct用来向方法中传递复杂的参数(把参数当作对象,这样便于扩展)
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    //获得连接的标志
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    //如果不能获取连接标志，则不能连接网络，直接返回
    if (!didRetrieveFlags)
    {
        return NO;
    }
    //根据获得的连接标志进行判断
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    BOOL isWWAN = flags & kSCNetworkReachabilityFlagsIsWWAN;
    return (isReachable && (!needsConnection || isWWAN)) ? YES : NO;
}

//MD5加密
+(NSString *)md5HexDigest:(NSString*)password{
    const char *original_str = [password UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++) {
        [hash appendFormat:@"%02X", result[i]];
    }
    NSString *mdfiveString = [hash lowercaseString];
    
    return mdfiveString;
}

// uuid
+(NSString *)uuid{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef strUuid = CFUUIDCreateString(kCFAllocatorDefault,uuid);
    NSString * str = [NSString stringWithString:(__bridge NSString *)strUuid];
    CFRelease(strUuid);
    CFRelease(uuid);
    return  str;
}

// 获取时间戳
+(NSString *)timeTampDigit:(int)digit{
    
    NSTimeInterval timeTamp = [[NSDate date] timeIntervalSince1970];
    NSInteger timeInt = timeTamp*1000000;
    NSString *time = [NSString stringWithFormat:@"%ld",timeInt];
    
    return [time substringToIndex:digit];
}

// 获取时间戳 CPU时钟 最多13位
+(NSString *)timeTampTicksDigit:(int)digit{  // ?*? 机制还有些问题
    
    NSDictionary *dic = [MyTools sharedMyTools].ticks;
    
    if (dic) {
        long ticksNow = [self ticksTime];
        long ticksOld = [dic[@"ticks"] integerValue];
        
        // 计算当前时间戳(手机重启并且获取服务器时间也未成功的情况下 计算时间会不准) 最怕手机重启
        NSInteger timeStampTicks = [dic[@"timeStamp"] integerValue] +(ticksNow>=ticksOld ? ticksNow-ticksOld:ticksNow)*1000;
        
        if (ABS(timeStampTicks-[self timeTampDigit:13].integerValue)>60000) { // 超过60秒认为手机系统时间不准
            
            return [NSString stringWithFormat:@"%.0f",timeStampTicks/pow(10, (13-digit))];
        }else{
            return [self timeTampDigit:digit];
        }
    } else {
        return [self timeTampDigit:digit];
    }
}

// date 转字符串 format可以传nil
+(NSString *)date2String:(NSDate *)date format:(NSString *)format{
    
    NSDateFormatter *formatter = [self dateFormatterWithformat:format];
    NSString *timeStr = [formatter stringFromDate:date];
    
    NSLog(@"date 转字符串:%@",timeStr);
    
    return timeStr;
}

// 字符串-->date  字符串和format格式必须对应
+(NSDate *)string2date:(NSString *)strTime format:(NSString *)format{
    
    NSDateFormatter *formatter = [self dateFormatterWithformat:format];
    NSDate *date = [formatter dateFromString:strTime];
    
    NSLog(@"字符串转date:%@",date);
    
    return date;
}

// 时间-->时间戳 (字符串或者 date类型) format可以传nil
+(NSString *)time2timeStamp:(id)timeStr format:(NSString *)format{
    
    NSDateFormatter *formatter = [self dateFormatterWithformat:format];
    // 如果是字符串就把字符串转成 date
    NSDate *date = [timeStr isKindOfClass:[NSString class]] ? [formatter dateFromString:timeStr]:timeStr;
    
    NSInteger timeStamp = [date timeIntervalSince1970];
    NSString *timeSp = [NSString stringWithFormat:@"%ld",timeStamp];
    
    NSLog(@"时间转时间戳:%@",timeSp);
    
    return timeSp;
}

// 时间戳-->时间 yyyy-MM-dd HH:mm:ss.sss (format可以传nil)
+(NSString *)timeStamp2str:(NSInteger)timeStamp format:(NSString *)format{
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    NSDateFormatter *formatter = [self dateFormatterWithformat:format];
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"Asia/Beijing"]; // 转化时区
    
    NSString *timeStr = [formatter stringFromDate:date];
    
    NSLog(@"时间戳转时间--int:%@",timeStr);
    
    return timeStr;
}

// 日期格式
+(NSDateFormatter *)dateFormatterWithformat:(NSString *)format{
    
    if(!format) format = @"yyyy-MM-dd HH:mm:ss";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    
    return formatter;
}

////获取传入时间的字符串格式 yyyy-MM-dd HH:mm:ss
//+(NSString *)date2String:(NSDate *)date{
//    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    
//    NSString *dateStr = [dateFormatter stringFromDate:date];
//    
//    return dateStr;
//}
//
//// 获取当前时间 yyyy-MM-dd HH:mm:ss
//+(NSString *)getCurrentDate {
//    
//    NSDate *date = [NSDate date];
//    NSTimeZone *zone = [NSTimeZone systemTimeZone];
//    NSInteger interval = [zone secondsFromGMTForDate: date];
//    
//    NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
//    NSString *strDate = [[NSString stringWithFormat:@"%@",localeDate] substringToIndex:19];
//    NSLog(@"当前时间:%@", strDate);
//    
//    return strDate;
//}
//
//// 时间戳转时间 yyyy-MM-dd HH:mm:ss.fff
//+(NSString *)timeStamp2timeStr:(NSString *)timeStamp{
//    
//    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:timeStamp.floatValue];
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    //转换成字符串
//    NSString *timeStr = [formatter stringFromDate:confromTimesp];
//    NSLog(@"时间戳转时间--字符串:%@",timeStr);
//    
//    return timeStr;
//}
//
//// 时间戳转时间 yyyy-MM-dd HH:mm:ss.fff
//+(NSString *)timeStamp2timeStrInt:(int)timeStamp{
//    
//    
//    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:timeStamp];
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    //转换成字符串
//    NSString *timeStr = [formatter stringFromDate:confromTimesp];
//    NSLog(@"时间戳转时间--int:%@",timeStr);
//    
//    return timeStr;
//}
//
//// 时间转时间戳 yyyy-MM-dd HH:mm:ss.fff
//+(NSString *)time2timeStamp:(NSString *)timeStr{
//    
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    
//    [formatter setDateStyle:NSDateFormatterMediumStyle];
//    [formatter setTimeStyle:NSDateFormatterShortStyle];
//    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    
//    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"Asia/Beijing"];
//    [formatter setTimeZone:timeZone];
//    
//    NSDate *date = [formatter dateFromString:timeStr]; // 将字符串按formatter转成nsdate
//    
//    //时间转时间戳的方法:
//    NSString *timeSp = [NSString stringWithFormat:@"%ld",(long)[date timeIntervalSince1970]];
//    
//    NSLog(@"时间转时间戳:%@",timeSp);
//    
//    return timeSp;
//}

// 计算时间差 yyyy-MM-dd HH:mm:ss
+(NSString *)timeIntervalFistTime:(NSString *)fistTime secondTime:(NSString *)secondTime{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *datefist = [dateFormatter dateFromString:fistTime];
    NSDate *datesecond = [dateFormatter dateFromString:secondTime];
    NSTimeInterval time = [datesecond timeIntervalSinceDate:datefist];
    
    int days=((int)time)/(3600*24);
    int hours=((int)time)%(3600*24)/3600;
    int minutes = ((int)time)%(3600*24)%3600/60;
    int seconds = ((int)time)%(3600*24)%3600%60;
    
    NSString *dateContent = [[NSString alloc] initWithFormat:@"时间差:%i天%i小时%i分%i秒",days,hours,minutes,seconds];
    NSLog(@"%@",dateContent);
    
    return dateContent;
}

// 计算时间差 yyyy-MM-dd HH:mm:ss
+(NSString *)timeIntervalReturnSSFistTime:(NSString *)fistTime secondTime:(NSString *)secondTime{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *datefist = [dateFormatter dateFromString:fistTime];
    NSDate *datesecond = [dateFormatter dateFromString:secondTime];
    NSTimeInterval time = [datesecond timeIntervalSinceDate:datefist];
    
    //    int days=((int)time)/(3600*24);
    //    int hours=((int)time)%(3600*24)/3600;
    //    int minutes = ((int)time)%(3600*24)%3600/60;
    //    int seconds = ((int)time)%(3600*24)%3600%60;
    
    //    NSString *dateContent = [[NSString alloc] initWithFormat:@"%i天%i小时%i分%i秒",days,hours,minutes,seconds];
    //    NSLog(@"%@",dateContent);
    
    return [NSString stringWithFormat:@"%lf",time];
}

// 10位时间戳转时间 上午 下午 昨天 星期一 年月日
+(NSString *)timeTamp2Time:(long long)timeStamp accurate:(BOOL)accurate{ // 大于一天是否精确到时钟
    
    NSTimeInterval seconds = timeStamp;
    NSDate *myDate = [NSDate dateWithTimeIntervalSince1970:seconds];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    int unit = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear ;
    NSDateComponents *nowCmps = [calendar components:unit fromDate:[ NSDate date]];
    NSDateComponents *myCmps = [calendar components:unit fromDate:myDate];
    
    NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
    dateFmt.AMSymbol = @"上午";
    dateFmt.PMSymbol = @"下午";
    
    //2. 指定日历对象,要去取日期对象的那些部分.
    NSDateComponents *comp =  [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday fromDate:myDate];
    
    if (nowCmps.year != myCmps.year) {
        dateFmt.dateFormat = [NSString stringWithFormat:@"yyyy-MM-dd%@",accurate ? @" aaa hh:mm":@""];
    } else {
        if (nowCmps.month==myCmps.month && nowCmps.day==myCmps.day) {
            dateFmt.dateFormat = @"aaa hh:mm";
        } else if (nowCmps.month==myCmps.month && (nowCmps.day-myCmps.day)==1){
            dateFmt.dateFormat = [NSString stringWithFormat:@"昨天%@",accurate ? @" aaa hh:mm":@""];
        } else if (nowCmps.month==myCmps.month && (nowCmps.day-myCmps.day)<7){
            switch (comp.weekday) {
                case 1:
                    dateFmt.dateFormat = [NSString stringWithFormat:@"星期日%@",accurate ? @" aaa hh:mm":@""];
                    break;
                case 2:
                    dateFmt.dateFormat = [NSString stringWithFormat:@"星期一%@",accurate ? @" aaa hh:mm":@""];
                    break;
                case 3:
                    dateFmt.dateFormat = [NSString stringWithFormat:@"星期二%@",accurate ? @" aaa hh:mm":@""];
                    break;
                case 4:
                    dateFmt.dateFormat = [NSString stringWithFormat:@"星期三%@",accurate ? @" aaa hh:mm":@""];
                    break;
                case 5:
                    dateFmt.dateFormat = [NSString stringWithFormat:@"星期四%@",accurate ? @" aaa hh:mm":@""];
                    break;
                case 6:
                    dateFmt.dateFormat = [NSString stringWithFormat:@"星期五%@",accurate ? @" aaa hh:mm":@""];
                    break;
                case 7:
                    dateFmt.dateFormat = [NSString stringWithFormat:@"星期六%@",accurate ? @" aaa hh:mm":@""];
                    break;
                default:
                    break;
            }
        }else{
            dateFmt.dateFormat = [NSString stringWithFormat:@"MM-dd%@",accurate ? @" aaa hh:mm":@""];
        }
    }
    return [dateFmt stringFromDate:myDate];
}

// 获取所有国家249个国家和地区
+(NSMutableArray *)getAllCuntry{
    
    NSMutableArray *countriesArray = [[NSMutableArray alloc] init];
    
    NSLocale *locale = [NSLocale currentLocale];
    
    NSArray *countryArray = [NSLocale ISOCountryCodes];
    
    for (NSString *countryCode in countryArray)
    {
        NSString *displayNameString = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
        [countriesArray addObject:displayNameString];
    }
    return countriesArray;
}

// 保留两位小数
+(NSString *)roundUp:(float)number afterPoint:(int)position{
    NSDecimalNumberHandler* roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundUp scale:position raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
    NSDecimalNumber *ouncesDecimal;
    NSDecimalNumber *roundedOunces;
    
    ouncesDecimal = [[NSDecimalNumber alloc] initWithFloat:number];
    roundedOunces = [ouncesDecimal decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
    return [NSString stringWithFormat:@"%@",roundedOunces];
}

// 只进不舍  求整数
+(NSInteger)getIntegerNumberWithIntoOnly:(NSInteger)number{
    int index = (int)number/10;
    
    float numberfloat = (float)number/10;
    
    if (numberfloat > index){
        
        return (index+1);
    }else{
        
        return index;
    }
}

// 获取当前window
+(UIWindow *)mainWindow{
    
    UIApplication *app = [UIApplication sharedApplication];
    if ([app.delegate respondsToSelector:@selector(window)])
    {
        return [app.delegate window];
    }
    else
    {
        return [app keyWindow];
    }
}

/*
 时间戳的显示格式化问题，所有当天的作品，所有涂鸦作品展示时的时间戳只展示“HH：MM”，
 非跨年的时间展示“MM月DD日 HH：MM“，
 跨年后格式：“YYYY年MM月DD日 HH：MM“
 */
+(NSString*)customFormatDate:(NSString*)date_Str
{
    NSString *newDateStr;
    if (date_Str!=nil && ![date_Str isEqual:[NSNull null]] && date_Str.length>0)
    {
        //获取当前系统时间
        NSDate *now = [NSDate date];
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
        NSDateComponents *dateComponent = [calendar components:unitFlags fromDate:now];
        
        int year = [dateComponent year];//系统当前年
        NSString *year_str = [NSString stringWithFormat:@"%i",year];
        int day = [dateComponent day];//系统当前日
        NSString *day_str = [NSString stringWithFormat:@"%i",day];
        
        NSDateFormatter *date_Formatter = [[NSDateFormatter alloc] init];
        [date_Formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSLocale *locale=[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [date_Formatter setLocale:locale];
        
        //将当前日期转换成date格式
        NSDate *date = [date_Formatter dateFromString:date_Str];
        //保证格式统一  先格式化一次
        NSString *dateStrFormat = [date_Formatter stringFromDate:date];
        NSArray *dateStrAry = [dateStrFormat componentsSeparatedByString:@"-"];
        NSString *date_year = [dateStrAry objectAtIndex:0];//获取传过来日期的年
        NSString *date_day = [dateStrAry objectAtIndex:2];//获取传过来日期的日
        if ([date_year isEqualToString:year_str]) //如果是当前年
        {
            
            if([date_day hasPrefix:day_str])//如果是当天
            {
                [date_Formatter setDateFormat:@"HH:mm"];
                newDateStr = [NSString stringWithFormat:@"今天 %@",[date_Formatter stringFromDate:date]];
            }
            else
            {
                [date_Formatter setDateFormat:@"MM月dd日 HH:mm"];
                newDateStr = [date_Formatter stringFromDate:date];
            }
            
        }
        else
        {
            [date_Formatter setDateFormat:@"yyyy年MM月dd日 HH:mm"];
            newDateStr = [date_Formatter stringFromDate:date];
        }
    }
    else
    {
        newDateStr = @"";
    }
    
    return newDateStr;
}

+(NSString*)array2Josn:(NSMutableArray*)array{
    
    //    NSData *theData = [NSKeyedArchiver archivedDataWithRootObject:array];
    
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if ([jsonData length] > 0 && error == nil)
    {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                     encoding:NSUTF8StringEncoding];
        return jsonString;
    }
    else
    {
        return nil;
    }
}

//转图片
+(BOOL)imageHasAlpha:(UIImage *)image{
    
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(image.CGImage);
    return (alpha == kCGImageAlphaFirst ||
            alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst ||
            alpha == kCGImageAlphaPremultipliedLast);
}

// 转图片 base64
+(NSString *)image2DataURL:(UIImage *)image{
    
    NSData *imageData = nil;
    NSString *mimeType = nil;
    
    if ([self imageHasAlpha:image]) {
        imageData = UIImagePNGRepresentation(image);
        mimeType = @"image/png";
    } else {
        imageData = UIImageJPEGRepresentation(image, 1.0f);
        mimeType = @"image/jpeg";
    }
    
    
    //   NSLog(@"%@",[imageData base64EncodedStringWithOptions: 0]);
    return [imageData base64EncodedStringWithOptions: 0];
    
}

// 压缩图片
+(UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size{
    
    UIGraphicsBeginImageContext(size);
    [img drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

// 获取手机型号
+(NSString *)deviceString{
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    if ([deviceString isEqualToString:@"iPhone1,1"])  return @"iPhone 1G";
    if ([deviceString isEqualToString:@"iPhone1,2"])  return @"iPhone 3G";
    if ([deviceString isEqualToString:@"iPhone2,1"])  return @"iPhone 3GS";
    if ([deviceString isEqualToString:@"iPhone3,1"])  return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone4,1"])  return @"iPhone 4S";
    if ([deviceString isEqualToString:@"iPhone5,2"])  return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone5,3"])  return @"iPhone 5c (A1456/A1532)";
    if ([deviceString isEqualToString:@"iPhone5,4"])  return @"iPhone 5c (A1507/A1516/A1526/A1529)";
    if ([deviceString isEqualToString:@"iPhone6,1"])  return @"iPhone 5s (A1453/A1533)";
    if ([deviceString isEqualToString:@"iPhone6,2"])  return @"iPhone 5s (A1457/A1518/A1528/A1530)";
    if ([deviceString isEqualToString:@"iPhone7,1"])  return @"iPhone 6 Plus (A1522/A1524)";
    if ([deviceString isEqualToString:@"iPhone7,2"])  return @"iPhone 6 (A1549/A1586)";
    if ([deviceString isEqualToString:@"iPhone8,1"])  return @"iPhone 6s";
    if ([deviceString isEqualToString:@"iPhone8,2"])  return @"iPhone 6s plus";
    
    
    if ([deviceString isEqualToString:@"iPhone3,2"])  return @"Verizon iPhone 4";
    if ([deviceString isEqualToString:@"iPod1,1"])    return @"iPod Touch 1G";
    if ([deviceString isEqualToString:@"iPod2,1"])    return @"iPod Touch 2G";
    if ([deviceString isEqualToString:@"iPod3,1"])    return @"iPod Touch 3G";
    if ([deviceString isEqualToString:@"iPod4,1"])    return @"iPod Touch 4G";
    if ([deviceString isEqualToString:@"iPad1,1"])    return @"iPad";
    if ([deviceString isEqualToString:@"iPad2,1"])    return @"iPad 2 (WiFi)";
    if ([deviceString isEqualToString:@"iPad2,2"])    return @"iPad 2 (GSM)";
    if ([deviceString isEqualToString:@"iPad2,3"])    return @"iPad 2 (CDMA)";
    if ([deviceString isEqualToString:@"i386"])       return @"Simulator";
    if ([deviceString isEqualToString:@"x86_64"])     return @"Simulator";
    //    NSLog(@"NOTE: Unknown device type: %@", deviceString);
    return deviceString;
}

// 计算文字高度方法(只有文字)
+(float)getHeightWithStr:(NSString*)str labelWidth:(float)width fontSize:(float)size{
    
    CGRect r = [str boundingRectWithSize:CGSizeMake(width, 2000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:size]} context:nil];
    
    return r.size.height;
}

// 设置行间距  一行时不设置行间距
+(NSAttributedString *)attrStr:(NSString *)str width:(float)width lineSpacing:(int)lineSpacing fontSize:(float)size{
    
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:str];
    [self attr:&attr fontSize:size rang:NSMakeRange(0, attr.length)];
    
    if (![self isSingleRow:str fontSize:size width:width]) {
        
        [self attr:&attr LineSpace:lineSpacing];
    }
    
    return attr;
}

// 获取label高度 一行时不计算行间距
+(float)getLabelHeightWithStr:(NSString *)str width:(float)width lineSpacing:(int)lineSpacing fontSize:(float)size{
    
    CGFloat heightSum = [self getHeightWithStr:str labelWidth:width fontSize:size];
    int row = heightSum/1.193359/size;
    
    return heightSum + lineSpacing*(row - 1);
}

// 判断传入对象是否为空 并替换
+(NSString *)isNullWith:(id)object return:(NSString *)strRetur{
    // http://blog.csdn.net/xdrt81y/article/details/8981133
    
    //    if (str==[NSNull null] ||[str isEqual:nil] || str==nil){
    //
    //        return strRetur;
    //    }else{
    //        return [NSString stringWithFormat:@"%@",str];
    //    }
    
    
    if (!object) return strRetur;
    
    if ([object isKindOfClass:[NSString class]]) {
        
        NSString *str = object;
        if (str.length==0) return strRetur;
    }
    
    if ([object isKindOfClass:[NSArray class]]) {
        
        NSArray *arr = object;
        if (arr.count==0) return strRetur;
    }
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        
        NSDictionary *dic = object;
        if (dic.count==0) return strRetur;
    }
    
    if ([object isKindOfClass:[NSNull class]]) {
        
        return strRetur;
    }
    
    //    if ([object isEqual:nil]) return strRetur;
    
    return object;
}


// 返回XML 格式的 所有view的frame
+(NSString *)digView:(UIView *)view{
    
    if ([view isKindOfClass:[UITableViewCell class]]) return @"";
    // 1.初始化
    NSMutableString *xml = [NSMutableString string];
    
    // 2.标签开头
    [xml appendFormat:@"<%@ frame=\"%@\"", view.class, NSStringFromCGRect(view.frame)];
    if (!CGPointEqualToPoint(view.bounds.origin, CGPointZero)) {
        [xml appendFormat:@" bounds=\"%@\"", NSStringFromCGRect(view.bounds)];
    }
    
    if ([view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scroll = (UIScrollView *)view;
        if (!UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, scroll.contentInset)) {
            [xml appendFormat:@" contentInset=\"%@\"", NSStringFromUIEdgeInsets(scroll.contentInset)];
        }
    }
    
    // 3.判断是否要结束
    if (view.subviews.count == 0) {
        [xml appendString:@" />"];
        return xml;
    } else {
        [xml appendString:@">"];
    }
    
    // 4.遍历所有的子控件
    for (UIView *child in view.subviews) {
        NSString *childXml = [self digView:child];
        [xml appendString:childXml];
    }
    
    // 5.标签结尾
    [xml appendFormat:@"</%@>", view.class];
    
    return xml;
}

// 获取手机 IP 地址
//+(NSArray *)getIpAddresses{
//    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
//    if (sockfd < 0) return nil;
//    NSMutableArray *ips = [NSMutableArray array];
//
//    int BUFFERSIZE = 4096;
//    struct ifconf ifc;
//    char buffer[BUFFERSIZE], *ptr, lastname[IFNAMSIZ], *cptr;
//    struct ifreq *ifr, ifrcopy;
//    ifc.ifc_len = BUFFERSIZE;
//    ifc.ifc_buf = buffer;
//    if (ioctl(sockfd, SIOCGIFCONF, &ifc) >= 0){
//        for (ptr = buffer; ptr < buffer + ifc.ifc_len; ){
//            ifr = (struct ifreq *)ptr;
//            int len = sizeof(struct sockaddr);
//            if (ifr->ifr_addr.sa_len > len) {
//                len = ifr->ifr_addr.sa_len;
//            }
//            ptr += sizeof(ifr->ifr_name) + len;
//            if (ifr->ifr_addr.sa_family != AF_INET) continue;
//            if ((cptr = (char *)strchr(ifr->ifr_name, ':')) != NULL) *cptr = 0;
//            if (strncmp(lastname, ifr->ifr_name, IFNAMSIZ) == 0) continue;
//            memcpy(lastname, ifr->ifr_name, IFNAMSIZ);
//            ifrcopy = *ifr;
//            ioctl(sockfd, SIOCGIFFLAGS, &ifrcopy);
//            if ((ifrcopy.ifr_flags & IFF_UP) == 0) continue;
//
//            NSString *ip = [NSString stringWithFormat:@"%s", inet_ntoa(((struct sockaddr_in *)&ifr->ifr_addr)->sin_addr)];
//            [ips addObject:ip];
//        }
//    }
//    close(sockfd);
//    return ips;
//}

// 字典转 JSON
+(NSString *)dictionary2Json:(NSDictionary *)dic{
    
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) {
        
        NSLog(@"字典转 JSON 失败💐💐💐:%@",error);
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
}

// JSON 转字典
+(NSDictionary *)json2dictionary:(NSString *)jsonString {
    
    if (jsonString == nil) return nil;
    
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    
    if(error) {
        
        NSLog(@"json解析失败💐💐💐：%@",error);
        
        return nil;
    }
    return dic;
}

// 读取本地 json.txt 文件 转化为 JSON
+(NSMutableDictionary *)dicWithpathForResource:(NSString *)name ofType:(NSString *)type{
    
    NSString*filePath = [[NSBundle mainBundle] pathForResource:name ofType:type];
    NSData*data = [NSData dataWithContentsOfFile:filePath];
    NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:nil];
    
    // 效果一样
    //    NSString*filePath=[[NSBundle mainBundle] pathForResource:name ofType:type];
    //    NSMutableDictionary *dicPlist = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    
    return dic;
}

// 根据颜色创建图片
+(UIImage *)imageWithColor:(UIColor *)color andSize:(CGSize)size{
    
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

// 获取沙河路径
+(NSString *)getDocumentDir{
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    return path;
}

// 获取缓存路径
+(NSString *)getCacheDir{
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject];
    return path;
}

// 获取临时目录
+(NSString *)getTempDir{
    
    return NSTemporaryDirectory();
}

// 判断输入是否为全数字
+(BOOL)isPureInt:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string]; //定义一个NSScanner，扫描string
    int val;
    return[scan scanInt:&val] && [scan isAtEnd];
}

// 判断字符串 是否为中文
+(BOOL) validateNickname:(NSString *)nickname{
    NSString *nicknameRegex = @"^[\u4e00-\u9fff]{2,8}$";
    NSPredicate *passWordPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",nicknameRegex];
    return [passWordPredicate evaluateWithObject:nickname];
}

// 汉字转拼音
+ (NSString *)pinyinString:(NSString *)aString {
    //转成了可变字符串
    NSMutableString *str = [NSMutableString stringWithString:aString];
    //先转换为带声调的拼音
    CFStringTransform((CFMutableStringRef)str, NULL, kCFStringTransformMandarinLatin, NO);
    //再转换为不带声调的拼音
    CFStringTransform((CFMutableStringRef)str,NULL, kCFStringTransformStripDiacritics, NO);
    //转化为大写拼音
    NSString *pinYin = [str capitalizedString];
    return pinYin;
}

// 弹窗 消息
+ (void)showMessage:(NSString *)string toView:(UIView *)view{
    
    if (view==nil) view = [self mainWindow];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(string, @"HUD message title");
    //    hud.offset = CGPointMake(0.f, 0);
    hud.userInteractionEnabled = !(view==[self mainWindow]);
    
    [hud hideAnimated:YES afterDelay:2.f];
}

// 弹窗 消息
+ (void)showMessage:(NSString *)string toView:(UIView *)view offset:(CGPoint)offset{
    
    if (view==nil) view = [self mainWindow];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.offset = offset;
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(string, @"HUD message title");
    //    hud.offset = CGPointMake(0.f, 0);
    hud.userInteractionEnabled = !(view==[self mainWindow]);
    
    [hud hideAnimated:YES afterDelay:2.f];
}

//颜色转换(16进制转 RGB)
+(UIColor *)color16toRGB:(NSString *)color alpha:(CGFloat)alpha{
    
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    if ([cString length] < 6) {
        return [UIColor clearColor];
    }
    
    if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6)
        return [UIColor clearColor];
    
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    //r
    NSString *rString = [cString substringWithRange:range];
    
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    NSLog(@"16ToRGB:r--%d g--%d b--%d",r,g,b);
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:alpha];
}

//颜色转换(RGB转 16)
+(void)colorRGBto16r:(int)r g:(int)g b:(int)b{
    
    int c = r << 16 | g << 8 | b;
    
    NSString *str = [NSString stringWithFormat:@"#%06x",c];
    
    NSLog(@"%@",str);
}

// 创建横线
+(UIView *)viewFrame:(CGRect)frame color:(UIColor *)color{
    
    UIView *viewLine = [[UIView alloc] initWithFrame:frame];
    viewLine.backgroundColor = color;
    
    return viewLine;
}

// 创建 label
+(UILabel *)labelFrame:(CGRect)frame aligment:(int)aligment text:(NSString *)text{
    
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    if(text) label.text = text;
    label.textAlignment = aligment;
    
    return label;
}

// NSUserDefaults 存储
+(void)userDefWithObject:(id)object key:(NSString *)key{
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:object forKey:key];
    [ud synchronize];
}

// NSUserDefaults 读取
+(id)userDefWithKey:(NSString *)key{
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    return [ud objectForKey:key];
}

// 设置颜色
+(NSAttributedString *)attrStr:(NSString *)str color:(UIColor *)color rang:(NSRange)rang{
    
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:str];
    
    [attr addAttribute:NSForegroundColorAttributeName value:color range:rang];
    
    return attr;
}

// 设置行间距
+(void)attr:(NSMutableAttributedString **)attrS LineSpace:(float)lineSpacing{
    
    NSMutableAttributedString *attr = *attrS;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = lineSpacing;
    [attr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attr.length)];
}

// 设置字体
+(void)attr:(NSMutableAttributedString **)attrS fontSize:(float)fontSize rang:(NSRange)rang{
    
    NSMutableAttributedString *attr = *attrS;
    
    [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:fontSize] range:rang];
}

// 设置颜色
+(void)attr:(NSMutableAttributedString **)attrS color:(UIColor *)color rang:(NSRange)rang{
    
    NSMutableAttributedString *attr = *attrS;
    
    [attr addAttribute:NSForegroundColorAttributeName value:color range:rang];
}

// 是否单行
+(BOOL)isSingleRow:(NSString *)str fontSize:(float)fontSize width:(float)width{
    
    CGFloat heightLine = 1.193359 * fontSize; // 一行的高度 1.193359
    CGFloat heightSum = [self getHeightWithStr:str labelWidth:width fontSize:fontSize];
    
    return heightSum < heightLine+1;
}

// 根据秒数和时间 获取时间
+(NSString *)dateWithSeconds:(NSInteger)seconds date:(NSDate *)date{
    
    if(date==nil) date = NSDate.new;
    
    NSDate *lastDay = [NSDate dateWithTimeInterval:seconds sinceDate:date];
    NSString *str = [MyTools date2String:lastDay format:@"yyyy-MM-dd HH:mm:ss"];
    
    return str;
}

// 获取过去的 某月日期
+(NSString *)monthWithNumber:(NSInteger)monthNumber date:(NSDate *)date{
    
    if(date==nil) date = NSDate.new;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setMonth:monthNumber];
    NSCalendar *calender = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *mDate = [calender dateByAddingComponents:comps toDate:date options:0];
    
    return [MyTools date2String:mDate format:@"yyyy-MM-dd HH:mm:ss"];
}

// alert 弹窗
+(void)alertTitle:(NSString *)title message:(NSString *)message okTitle:(NSString *)okTitle cancleTitle:(NSString *)cancleTitle self:(UIViewController *)selfS blockAlert:(blockAlert)blockAlert{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:okTitle style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        
        blockAlert();
        
    }];
    
    UIAlertAction *cancle = [UIAlertAction actionWithTitle:cancleTitle style:(UIAlertActionStyleCancel) handler:nil];
    [alert addAction:ok];
    [alert addAction:cancle];
    
    [selfS presentViewController:alert animated:YES completion:nil];
}

// 遍历父视图
+(UIView *)superViewWithView:(UIView *)view class:(Class)aClass{
    
    for (UIView *next = view.superview; next; next = next.superview) {
        if ([next isKindOfClass:aClass]) {
            
            return next;
        }
    }
    return nil;
}

// 归档
+(BOOL)archiveWithModel:(id)model key:(NSString *)key filePath:(NSString *)filePath{
    
    //存储归档后的数据
    NSMutableData *data = [NSMutableData data];
    // 创建归档工具
    NSKeyedArchiver *archiv = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    // 开始归档
    [archiv encodeObject:model forKey:key];
    // 归档结束
    [archiv finishEncoding];
    // 写入沙河
    BOOL isSuccess = [data writeToFile:filePath atomically:YES];
    
    return isSuccess;
}

// 反归档
+(id)unarchiverWithKey:(NSString *)key filePath:(NSString *)filePath{
    
    // 读取归档数据
    NSMutableData *data = [NSMutableData dataWithContentsOfFile:filePath];
    // 创建反归档工具
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    // 反归档
    return [unarchiver decodeObjectForKey:key];
}

// 当前网络连接
+(BOOL)network{
    
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reach currentReachabilityStatus];
    
    return status==ReachableViaWWAN||status==ReachableViaWWAN;
}

// 创建目录
+(BOOL)creatDirectory:(NSString *)Dir{
    
    NSFileManager *fm = [NSFileManager defaultManager];

    // 创建路径的时候,YES自动创建路径中缺少的目录,NO的不会创建缺少的目录
    BOOL isCreat = [fm createDirectoryAtPath:Dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    return isCreat;
}

// 判断文件是否存在
+(BOOL)fileIsExist:(NSString *)filePath{
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    return [fm fileExistsAtPath:filePath];
}

// 创建文件
+(BOOL)creatFile:(NSString *)filePath contenData:(NSData *)data{
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 判断文件是否存在
    BOOL isExist = [fm fileExistsAtPath:filePath];
    
    if (!isExist) {
        isExist = [fm createFileAtPath:filePath contents:data attributes:nil];
    }
    return isExist;
}

// 复制文件
+(BOOL)copyFileFromFilePath:(NSString *)fromFilePath toFilePath:(NSString *)toFilePath{
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isCopy = [fm copyItemAtPath:fromFilePath toPath:toFilePath error:nil];
    
    return isCopy;
}

// 移动文件
+(BOOL)moveFileFromFilePath:(NSString *)fromFilePath toFilePath:(NSString *)toFilePath{
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isMove = [fm moveItemAtPath:fromFilePath toPath:toFilePath error:nil];
    
    return isMove;
}

// 删除文件
+(BOOL)deleteFileWithFilePath:(NSString *)filePath{
    
    if (![self fileIsExist:filePath]) return YES;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    BOOL isRemove = [fm removeItemAtPath:filePath error:&error];
    NSLog(@"%@",error);
    
    return isRemove;
}

// 根据图片二进制流获取图片格式
+ (NSString *)imageTypeWithData:(NSData *)data {
    uint8_t type;
    [data getBytes:&type length:1];
    switch (type) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
        case 0x52:
            // R as RIFF for WEBP
            if ([data length] < 12) {
                return nil;
            }
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return @"image/webp";
            }
            return nil;
    }
    return nil;
}

// 图片压缩
+(UIImage *)image:(UIImage *)image toScale:(float)scaleSize{
    
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
    
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

// 视频压缩
+(void)videoCompressSource:(NSString *)sourceFilePath savePath:(NSString *)saveFilePath compressResult:(bk_afn)blockVideoC{
    
    NSURL *fileUrlSource = [NSURL fileURLWithPath:sourceFilePath];
    
    //转码配置
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:fileUrlSource options:nil];
    AVAssetExportSession *exportSession= [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputURL = [NSURL fileURLWithPath:saveFilePath];
    exportSession.outputFileType = AVFileTypeMPEG4;
    
    NSData *dataSource = [NSData dataWithContentsOfURL:fileUrlSource];
    float sizeSource = dataSource.length/1000.0/1000.0;
    NSLog(@"压缩前大小:%.2f",sizeSource);
    NSLog(@"正在压缩...");
    NSInteger time1 = [[MyTools timeTampDigit:13] integerValue];
    
    // 压缩完成回调
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        if(exportSession.status==AVAssetExportSessionStatusUnknown) {
            
            NSLog(@"AVAssetExportSessionStatusUnknown");
        }else if (exportSession.status==AVAssetExportSessionStatusWaiting){
            
            NSLog(@"AVAssetExportSessionStatusWaiting");
        }else if (exportSession.status==AVAssetExportSessionStatusExporting){
            
            NSLog(@"AVAssetExportSessionStatusExporting");
        }else if (exportSession.status==AVAssetExportSessionStatusCompleted){
            
            NSData *dataNew = [NSData dataWithContentsOfFile:saveFilePath];
            float sizeNew = dataNew.length/1000.0/1000.0;
            NSInteger time2 = [[MyTools timeTampDigit:13] integerValue];
            NSLog(@"压缩完成...大小为:%.2f  压缩百分比%.2f%%  压缩耗时%.3fs",sizeNew,sizeNew/sizeSource*100,(time2-time1)/1000.0);
        }else if (exportSession.status==AVAssetExportSessionStatusFailed){
            
            NSLog(@"压缩失败:%@",exportSession.error);
        }else if (exportSession.status==AVAssetExportSessionStatusCancelled){
            
            NSLog(@"压缩取消");
        }
        blockVideoC(exportSession.status==AVAssetExportSessionStatusCompleted); // block 回调
    }];
}

// 获取本地视频第一帧图片
+(UIImage *)imageFromLocalVideo:(NSString *)path atTime:(NSTimeInterval)aTime{
    
    if(!path) return nil;
    
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileUrl options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(aTime, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return videoImage;
}

// 获取网络视频的第一帧图片
+(UIImage *)imageFromRemoteVideo:(NSString *)strUrl atTime:(NSTimeInterval)aTime{
    
    if (![strUrl containsString:@"http"]) return nil;
    
    NSURL *url = [NSURL URLWithString:strUrl];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval time = aTime;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(time, 60)actualTime:NULL error:&thumbnailImageGenerationError];
    
    if(!thumbnailImageRef)
        NSLog(@"获取视频第一帧图片错误 %@",thumbnailImageGenerationError);
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc]initWithCGImage: thumbnailImageRef] : nil;
    
    return thumbnailImage;
}

// 获取音频或者视频时长
+(float)durationAudioOrVideo:(NSString *)filePath{
    
    NSURL *url = [NSURL fileURLWithPath:filePath];
    AVURLAsset* audioAsset =[AVURLAsset URLAssetWithURL:url options:nil];
    CMTime audioDuration = audioAsset.duration;
    
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    
    return audioDurationSeconds;
}

// 重试机制 因为本全局变量不会销毁 当在某个页面调用本方法时本方法不会销毁
-(void)retryMaxCount:(NSInteger)maxCount bk_Outside:(bk_outside)bk_outside{
    
    __weak typeof(self) selfWeak = self;
    self.bk_inside = ^(BOOL isSuccess, NSInteger maxCount) {
        
        if (isSuccess) {
            NSLog(@"成功");
        }else if(!isSuccess && maxCount==0){ // 超出重试次数
            NSLog(@"超出重试次数 停止");
        }else{ // 重试
//            NSLog(@":%@-***-%@",bk_outside,selfWeak.bk_inside);
            if (bk_outside && selfWeak.bk_inside) {
                NSLog(@"剩余%ld次",maxCount);
                bk_outside(isSuccess,maxCount,selfWeak.bk_inside);
            }else{
                NSLog(@"已销毁:%@-***-%@",bk_outside,selfWeak.bk_inside);
            }
        }
    };
    
    bk_outside(YES,maxCount,self.bk_inside);
}

// 删除指定类型的文件 传nil全部删除
+(void)removeContentsOfDirectory:(NSString*)dir extension:(NSString*)extension{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:dir error:NULL];
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [e nextObject])) {
        if (extension != nil) {
            if ([[filename pathExtension] hasPrefix:extension]) {
                
                [fileManager removeItemAtPath:[dir stringByAppendingPathComponent:filename] error:NULL];
            }
        } else{
            [fileManager removeItemAtPath:[dir stringByAppendingPathComponent:filename] error:NULL];
        }
    }
}

// 指定对象是否包含某个属性
+(BOOL)isContainProperties:(NSString *)pro obj:(id)obj{
    
    u_int count;
    objc_property_t *properties  =class_copyPropertyList([obj class], &count);
    
    for (int i = 0; i<count; i++){
        
        const char* propertyName =property_getName(properties[i]);
        NSString *property = [NSString stringWithUTF8String: propertyName];
        if ([pro isEqualToString:property]) return YES;
    }
    
    return NO;
}

// 获取当前版本号
+(NSString *)getVersion{
    
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

// 遍历子视图
+(UIView *)subView:(UIView *)view clas:(Class)class{
    
    return [self subView:view level:1 clas:class];
}

// 遍历子视图
+(UIView *)subView:(UIView *)view level:(int)level clas:(Class)class{
    
    for (UIView *subview in view.subviews) {
        // 根据层级决定前面空格个数，来缩进显示
        NSString *blank = @"";
        for (int i = 1; i < level; i++) blank = [NSString stringWithFormat:@"  %@", blank];
        // 打印子视图类名
        NSLog(@"%@%d: %@", blank, level, subview.class);
        // 找到指定类直接返回
        if ([subview isKindOfClass:class]) {
            return subview;
        }
        // 递归获取此视图的子视图
        UIView *aview = [self subView:subview level:(level+1)clas:class];
        if (aview) return aview;
    }
    return nil;
}

// 通过路径获取文件大小
+(long long)fileSizeAtPath:(NSString *)mediaUrl{
    
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:mediaUrl]){
        return [[manager attributesOfItemAtPath:mediaUrl error:nil] fileSize];
    }else {
        return 0;
    }
}

// 获取可用内存大小(单位：字节）
+(double)getFreeMemory{
    
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(),
                                               HOST_VM_INFO,
                                               (host_info_t)&vmStats,
                                               &infoCount);
    if (kernReturn != KERN_SUCCESS) {
        return NSNotFound;
    }
    
    return vm_page_size *vmStats.free_count;
}

// 获取可用磁盘大小(单位：字节）
+(uint64_t)getFreeDiskspace{
    
    uint64_t totalSpace = 0.0f;
    uint64_t totalFreeSpace = 0.0f;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes floatValue];
        totalFreeSpace = [freeFileSystemSizeInBytes floatValue];
//        NSLog(@"Memory Capacity of %llu GB with %llu GB Free memory available.", ((totalSpace/1024ll)/1024ll/1024ll), ((totalFreeSpace/1024ll)/1024ll/1024ll));
    } else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], [error code]);
    }
    
    return totalFreeSpace;
}

// 计算图片的宽和高
+(CGSize)imageSize:(CGSize)imageSize maxSize:(CGSize)maxSize{
    
    if (imageSize.width>maxSize.width || imageSize.height>maxSize.height) {
        
        if (imageSize.width/imageSize.height > maxSize.width/maxSize.height) {
            
            imageSize.height = imageSize.height/imageSize.width * maxSize.width;
            imageSize.width = maxSize.width;
        }else{
            imageSize.width = imageSize.width/imageSize.height * maxSize.height;
            imageSize.height = maxSize.height;
        }
    }
    return imageSize;
}

// 字节大小转换 K M G
+(NSString *)dataSizeFormant:(long long)length{
    
    if (length>=1024*1024*1024) {
        return [NSString stringWithFormat:@"%.2fG",length*1.0/1024/1024/1024];
    } else if(length>=1024*1024){
        return [NSString stringWithFormat:@"%.2fM",length*1.0/1024/1024];
    } else{
        return [NSString stringWithFormat:@"%.2fK",length*1.0/1024];
    }
}

// 相对路径
+(NSString *)filePaht2HOME:(NSString *)filePaht{
    if ([filePaht containsString:NSHomeDirectory()]) {
        return [@"$(HOME)" stringByAppendingString:[filePaht substringFromIndex:NSHomeDirectory().length]];
    }
    return filePaht;
}

// 绝对路径
+(NSString *)filePaht2home:(NSString *)filePaht{
    if ([filePaht containsString:@"$(HOME)"]) {
        return [NSHomeDirectory() stringByAppendingString:[filePaht substringFromIndex:7]];
    }
    return filePaht;
}

// 打印测试
-(void)testAddtext:(NSString *)text{
    
    if (!self.textView) {
        UIWindow *window = [UIWindow new];
        window.frame = CGRectMake(60, 64, [UIScreen mainScreen].bounds.size.width-60*2, 200);
        window.windowLevel = UIWindowLevelAlert;
        [[MyTools mainWindow] addSubview:window];
        [window makeKeyAndVisible];
        
        _textView = [[UITextView alloc] initWithFrame:window.bounds];
        [window addSubview:_textView];
        _textView.backgroundColor = window.backgroundColor = [UIColor clearColor];
    }
    
    if (self.textView.text.length) {
        self.textView.text = [NSString stringWithFormat:@"%@\n%@",self.textView.text,text];
    }else{
        self.textView.text = text;
    }
//    [[MyTools mainWindow] bringSubviewToFront:self.textView];
}

// 根据图片url获取网络图片尺寸
+(CGSize)getImageSizeWithURL:(id)URL{
    NSURL * url = nil;
    if ([URL isKindOfClass:[NSURL class]])    url = URL;
    if ([URL isKindOfClass:[NSString class]]) url = [NSURL URLWithString:URL];
    if (!URL) return CGSizeZero;
    
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    CGFloat width = 0, height = 0;
    
    if (imageSourceRef) {
        
        // 获取图像属性
        CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, NULL);
        
        //以下是对手机32位、64位的处理
        if (imageProperties != NULL) {
            
            CFNumberRef widthNumberRef = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
            
#if defined(__LP64__) && __LP64__
            if (widthNumberRef != NULL) CFNumberGetValue(widthNumberRef, kCFNumberFloat64Type, &width);
            
            CFNumberRef heightNumberRef = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
            
            if (heightNumberRef != NULL) CFNumberGetValue(heightNumberRef, kCFNumberFloat64Type, &height);
#else
            if (widthNumberRef != NULL) CFNumberGetValue(widthNumberRef, kCFNumberFloat32Type, &width);
            
            CFNumberRef heightNumberRef = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
            
            if (heightNumberRef != NULL) CFNumberGetValue(heightNumberRef, kCFNumberFloat32Type, &height);
#endif
            /********************** 此处解决返回图片宽高相反问题 **********************/
            // 图像旋转的方向属性
            NSInteger orientation = [(__bridge NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyOrientation) integerValue];
            CGFloat temp = 0;
            switch (orientation) {
                case UIImageOrientationLeft: // 向左逆时针旋转90度
                case UIImageOrientationRight: // 向右顺时针旋转90度
                case UIImageOrientationLeftMirrored: // 在水平翻转之后向左逆时针旋转90度
                case UIImageOrientationRightMirrored: { // 在水平翻转之后向右顺时针旋转90度
                    temp = width;
                    width = height;
                    height = temp;
                }
                    break;
                default:
                    break;
            }
            /********************** 此处解决返回图片宽高相反问题 **********************/
            
            CFRelease(imageProperties);
        }
        CFRelease(imageSourceRef);
    }
    return CGSizeMake(width, height);
}

// 获取网络时间和本地时钟时间 **注意:1.获取网络时间可能会失败 2.手机重启本地时钟会重置**
// 传入的时间戳必须为13位 否则会请求网络时间戳
+(void)updataTimeStamp:(NSString *)timeStamp{
    // 时间修改通知 NSSystemClockDidChangeNotification UIApplicationSignificantTimeChangeNotification
    
    if (timeStamp.length==13) {
        NSDictionary *dic = @{@"timeStamp":timeStamp,
                              @"ticks":[NSString stringWithFormat:@"%ld",[self ticksTime]],
                              };
        [MyTools userDefWithObject:dic key:@"ticks"];
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:[NSURL URLWithString: @"http://www.baidu.com"]];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval:15];
    [request setHTTPShouldHandleCookies:FALSE];
    [request setHTTPMethod:@"GET"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue new] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        // 要把网络数据强转 不然用不了下面那个方法获取不到内容（个人感觉，不知道对不）
        NSHTTPURLResponse *responsee = (NSHTTPURLResponse *)response;
        NSString *date = [[responsee allHeaderFields] objectForKey:@"Date"];
        
        date = [date substringFromIndex:5];
        date = [date substringToIndex:date.length-4];
        NSDateFormatter *dMatter = [NSDateFormatter new];
        dMatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_us"];
        [dMatter setDateFormat:@"dd MMM yyyy HH:mm:ss"];
        //         NSDate *netDate = [[dMatter dateFromString:date] dateByAddingTimeInterval:60*60*8]; //这个获取时间是正常时间，但是转化后会快8个小时，所以取的没有处理8小时的时间
        NSDate *netDate = [dMatter dateFromString:date];
        NSTimeZone *zone = [NSTimeZone systemTimeZone];
        NSInteger interval = [zone secondsFromGMTForDate: netDate];
        NSDate *localeDate = [netDate dateByAddingTimeInterval: interval];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
        NSString *nowtimeStr = [NSString string];
        nowtimeStr = [formatter stringFromDate:localeDate];
        NSString *timeStamp = [MyTools time2timeStamp:nowtimeStr format:@"YYYY-MM-dd HH:mm:ss"];
        NSLog(@"请求到时间");
        if (timeStamp.integerValue>1500000000) { // 无网络会返回0
            NSDictionary *dic = @{@"timeStamp":[NSString stringWithFormat:@"%@000",timeStamp],
                                  @"ticks":[NSString stringWithFormat:@"%ld",[self ticksTime]],
                                  };
            [MyTools userDefWithObject:dic key:@"ticks"];
            NSLog(@"🌺userdef时间:%@",[MyTools userDefWithKey:@"ticks"]);
        }
    }];
}

// CUP时钟
+(time_t)ticksTime{
    
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    time_t now;
    time_t uptime = -1;
    
    (void)time(&now);
    
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0){
        uptime = now - boottime.tv_sec;
    }
    return uptime;
}

// 返回数组:1拼音首字母 2按拼音排序的一维数组 3按拼音排序的二维数组
+(NSMutableArray *)sortByArr:(NSArray *)arrTemp property:(NSString *)propertyName type:(int)type{
    
    UILocalizedIndexedCollation *sortManager = [UILocalizedIndexedCollation currentCollation];
    NSInteger sectionCount = [sortManager sectionTitles].count; // 26+1
    NSMutableArray *arrOutside = [NSMutableArray array]; // 外层数组
    
    // 变成二维数组
    for (int i=0; i<sectionCount; i++) {
        NSMutableArray *arrInside = [NSMutableArray array];
        [arrOutside addObject:arrInside];
    }
    
    // 1.先分类 把model放入对应 section
    for (id model in arrTemp) {
        NSInteger index = [sortManager sectionForObject:model collationStringSelector:NSSelectorFromString(propertyName)];
        [arrOutside[index] addObject:model];
    }
    // 2.对分类排序 对每个section中的model按照指定属性排序
    for (int i=0; i<sectionCount; i++) {
        NSArray *newArrSection = [sortManager sortedArrayFromArray:arrOutside[i] collationStringSelector:NSSelectorFromString(propertyName)];
        arrOutside[i] = newArrSection.mutableCopy;
    }
    
    // 存放 数组和key
    NSMutableArray *arr1 = [NSMutableArray arrayWithCapacity:27]; // A B Z
    NSMutableArray *arr2 = [NSMutableArray array];                // 一维数组排序
    NSMutableArray *arr3 = [NSMutableArray arrayWithCapacity:27]; // 二维数组排序
    
    for (int i=0; i<arrOutside.count; i++) {
        if ([arrOutside[i] count]!=0) {
            
            [arr1 addObject:sortManager.sectionIndexTitles[i]];
            [arr3 addObject:arrOutside[i]];
            for (id model in arrOutside[i]) { [arr2 addObject:model]; }
        }
    }
    
    if(type==1){ return arr1;
    }else if (type==2){ return arr2;
    }else if (type==3){ return arr3;
    }else{ return nil;
    }
}

// 输入文本是否为数字
+(BOOL)isNumber:(NSString *)text{
    if (text.length == 0) return NO;
    
    NSString *regex = @"[0-9]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    
    return [pred evaluateWithObject:text];
}





@end
