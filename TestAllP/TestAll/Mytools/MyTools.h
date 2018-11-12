//
//  MyTools.h
//  that is me1
//
//  Created by zhaoguoying on 16/6/24.
//  Copyright © 2016年 heike. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singleton.h"
#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <sys/sysctl.h>
#import <mach/mach.h>
typedef void(^blockAlert)();             // 系统弹窗 block 类型
typedef void(^bk_afn)(BOOL isSuccess); // 
typedef void(^bk_inside)(BOOL isSuccess,NSInteger maxCount); // 内层 block
typedef void(^bk_outside)(BOOL isSuccess,NSInteger maxCount,bk_inside bk_inside);  // 外层 block

@interface MyTools : NSObject

@property(nonatomic,strong) NSMutableArray *arrColor;
@property(nonatomic,copy)bk_inside bk_inside; // 重试机制 弱引用

singleton_interface(MyTools);

// 单例对象  💐 💤 ♻️ 🔌
//+(instancetype)sharedGetDataManager;




// 判断网络是否连接
+(BOOL)connectedToNetwork;

// MD5加密
+(NSString *)md5HexDigest:(NSString *)password;

// uuid
+(NSString *)uuid;

// 获取时间戳
+(NSString *)timeTampDigit:(int)digit;

// 获取时间戳 CPU时钟
+(NSString *)timeTampTicksDigit:(int)digit;

// date 转字符串 format可以传nil
+(NSString *)date2String:(NSDate *)date format:(NSString *)format;

// 字符串-->date  字符串和format格式必须对应
+(NSDate *)string2date:(NSString *)strTime format:(NSString *)format;

// 时间-->时间戳 (字符串或者 date类型) format可以传nil
+(NSString *)time2timeStamp:(id)timeStr format:(NSString *)format;

// 时间戳-->时间 yyyy-MM-dd HH:mm:ss.sss (format可以传nil)
+(NSString *)timeStamp2str:(NSInteger)timeStamp format:(NSString *)format;

//// 获取传入时间的字符串格式 yyyy-MM-dd HH:mm:ss
//+(NSString *)date2String:(NSDate *)date;
//
//// 获取当前时间的字符串格式 yyyy-MM-dd HH:mm:ss
//+(NSString *)getCurrentDate;
//
//// 时间戳转时间 yyyy-MM-dd HH:mm:ss.fff
//+(NSString *)timeStamp2timeStr:(NSString *)timeStamp;
//
//// 时间戳转时间 yyyy-MM-dd HH:mm:ss.fff
//+(NSString *)timeStamp2timeStrInt:(int)timeStamp;
//
//// 时间转时间戳
//+(NSString*)time2timeStamp:(NSString *)timeStr;
//
// 计算时间差 yyyy-MM-dd HH:mm:ss 返回多少 时分秒
+(NSString *)timeIntervalFistTime:(NSString *)fistTime secondTime:(NSString *)secondTime;

// 计算时间差 yyyy-MM-dd HH:mm:ss 返回 秒
+(NSString *)timeIntervalReturnSSFistTime:(NSString *)fistTime secondTime:(NSString *)secondTime;

// 10位时间戳转时间 上午 下午 昨天 星期一 年月日
+(NSString *)timeTamp2Time:(long long)timeStamp accurate:(BOOL)accurate;

// 获取所有国家 249个国家和地区
+(NSMutableArray *)getAllCuntry;

// 保留几位小数
+(NSString *)roundUp:(float)number afterPoint:(int)position;

// 只进不舍  求整数-----------------------------------------------
+(NSInteger)getIntegerNumberWithIntoOnly:(NSInteger)number;

// 获取当前window
+(UIWindow *)mainWindow;

/*
 时间戳的显示格式化问题，所有当天的作品，所有涂鸦作品展示时的时间戳只展示“HH：MM”，
 非跨年的时间展示“MM月DD日 HH：MM“，
 跨年后格式：“YYYY年MM月DD日 HH：MM“
 */
+(NSString *)customFormatDate:(NSString*)date_Str;

// 数组转 json 字符串
+(NSString *)array2Josn:(NSMutableArray*)array;

// 转图片 base64
+(NSString *)image2DataURL:(UIImage *)image;

// 压缩图片
+(UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size;

// 获取手机型号
+ (NSString*)deviceString;

// 计算文字高度方法(只有文字)
+(float)getHeightWithStr:(NSString*)str labelWidth:(float)width fontSize:(float)size;

// 设置行间距  一行时不设置行间距
+(NSAttributedString *)attrStr:(NSString *)str width:(float)width lineSpacing:(int)lineSpacing fontSize:(float)size;

// 获取label高度 一行时不计算行间距
+(float)getLabelHeightWithStr:(NSString *)str width:(float)width lineSpacing:(int)lineSpacing fontSize:(float)size;

// 判断传入对象是否为空 并替换
+(NSString *)isNullWith:(id)str return:(NSString *)strRetur;

// 返回 XML 格式的 view 的 frame
+(NSString *)digView:(UIView *)view;

// 获取手机 IP 地址
//+(NSArray *)getIpAddresses;

// 字典转 JSON
+(NSString *)dictionary2Json:(NSDictionary *)dic;

// JSON 转字典
+(NSDictionary *)json2dictionary:(NSString *)jsonString;

// 读取本地 json.txt 文件 转化为 JSON
+(NSMutableDictionary *)dicWithpathForResource:(NSString *)name ofType:(NSString *)type;

// 根据颜色创建图片
+(UIImage *)imageWithColor:(UIColor *)color andSize:(CGSize)size;

// 获取沙河路径
+(NSString *)getDocumentDir;

// 获取缓存路径
+(NSString *)getCacheDir;

// 获取临时目录
+(NSString *)getTempDir;

// 判断输入是否为全数字
+(BOOL)isPureInt:(NSString *)string;

// 判断字符串 是否为中文
+(BOOL) validateNickname:(NSString *)nickname;

// 汉字转拼音
+(NSString *)pinyinString:(NSString *)aString;

// 弹窗 消息
+(void)showMessage:(NSString *)string toView:(UIView *)view;

// 弹窗 消息
+ (void)showMessage:(NSString *)string toView:(UIView *)view offset:(CGPoint)offset;

// 颜色转换(16进制转 RRB)
+(UIColor *)color16toRGB:(NSString *)color alpha:(CGFloat)alpha;

//颜色转换(RGB转 16)
+(void)colorRGBto16r:(int)r g:(int)g b:(int)b;

// 创建横线
+(UIView *)viewFrame:(CGRect)frame color:(UIColor *)color;

// 创建 label
+(UILabel *)labelFrame:(CGRect)frame aligment:(int)aligment text:(NSString *)text;

// NSUserDefaults 存储
+(void)userDefWithObject:(id)object key:(NSString *)key;

// NSUserDefaults 读取
+(id)userDefWithKey:(NSString *)key;

// 设置颜色
+(NSAttributedString *)attrStr:(NSString *)str color:(UIColor *)color rang:(NSRange)rang;

// 设置行间距
+(void)attr:(NSMutableAttributedString **)attrS LineSpace:(float)lineSpacing;

// 设置字体
+(void)attr:(NSMutableAttributedString **)attrS fontSize:(float)fontSize rang:(NSRange)rang;

// 设置颜色
+(void)attr:(NSMutableAttributedString **)attrS color:(UIColor *)color rang:(NSRange)rang;

// 是否单行
+(BOOL)isSingleRow:(NSString *)str fontSize:(float)fontSize width:(float)width;

// 根据秒数和时间 获取时间
+(NSString *)dateWithSeconds:(NSInteger)seconds date:(NSDate *)date;

// 获取过去的 某月日期
+(NSString *)monthWithNumber:(NSInteger)monthNumber date:(NSDate *)date;

// alert 弹窗
+(void)alertTitle:(NSString *)title message:(NSString *)message okTitle:(NSString *)okTitle cancleTitle:(NSString *)cancleTitle self:(UIViewController *)selfS blockAlert:(blockAlert)blockAlert;

// 遍历父视图
+(UIView *)superViewWithView:(UIView *)view class:(Class)aClass;

// 归档
+(BOOL)archiveWithModel:(id)model key:(NSString *)key filePath:(NSString *)filePath;

// 反归档
+(id)unarchiverWithKey:(NSString *)key filePath:(NSString *)filePath;

// 当前网络连接
+(BOOL)network;

// 创建目录
+(BOOL)creatDirectory:(NSString *)Dir;

// 判断文件是否存在
+(BOOL)fileIsExist:(NSString *)filePath;

// 创建文件
+(BOOL)creatFile:(NSString *)filePath contenData:(NSData *)data;

// 复制文件
+(BOOL)copyFileFromFilePath:(NSString *)fromFilePath toFilePath:(NSString *)toFilePath;

// 移动文件
+(BOOL)moveFileFromFilePath:(NSString *)fromFilePath toFilePath:(NSString *)toFilePath;

// 删除文件
+(BOOL)deleteFileWithFilePath:(NSString *)filePath;

// 根据图片二进制流获取图片格式
+ (NSString *)imageTypeWithData:(NSData *)data;

// 图片压缩
+(UIImage *)image:(UIImage *)image toScale:(float)scaleSize;

// 视频压缩
+(void)videoCompressSource:(NSString *)sourceFilePath savePath:(NSString *)saveFilePath compressResult:(bk_afn)blockVideoC;

// 获取本地视频第一帧图片
+(UIImage *)imageFromLocalVideo:(NSString *)path atTime:(NSTimeInterval)aTime;

// 获取网络视频的第一帧图片
+(UIImage *)imageFromRemoteVideo:(NSString *)strUrl atTime:(NSTimeInterval)aTime;

// 获取音频或者视频时长
+(float)durationAudioOrVideo:(NSString *)filePath;

// 重试机制 因为本全局变量不会销毁 当在某个页面调用本方法时本方法不会销毁
-(void)retryMaxCount:(NSInteger)maxCount bk_Outside:(bk_outside)bk_outside;

// 删除指定类型的文件 传nil全部删除
+(void)removeContentsOfDirectory:(NSString*)dir extension:(NSString*)extension;

// 指定对象是否包含某个属性
+(BOOL)isContainProperties:(NSString *)pro obj:(id)obj;

//---------------------------------------------------------------------------------
/**
 *  驼峰转下划线（loveYou -> love_you）
 */
+(NSString *)mj_underlineFromCamel;
/**
 *  下划线转驼峰（love_you -> loveYou）
 */
+(NSString *)mj_camelFromUnderline;
/**
 * 首字母变大写
 */
+(NSString *)mj_firstCharUpper;
/**
 * 首字母变小写
 */
+(NSString *)mj_firstCharLower;

+(BOOL)mj_isPureInt;

//+(NSURL *)mj_url;




// 获取当前版本号
+(NSString *)getVersion;

// 遍历子视图
+(UIView *)subView:(UIView *)view clas:(Class)aClass;

// 通过路径获取文件大小
+(long long)fileSizeAtPath:(NSString *)mediaUrl;

// 获取可用内存大小(单位：字节）
+(double)getFreeMemory;

// 获取可用磁盘大小(单位：字节）
+(uint64_t)getFreeDiskspace;

// 计算图片的宽和高
+(CGSize)imageSize:(CGSize)imageSize maxSize:(CGSize)maxSize;

// 字节大小转换 K M G
+(NSString *)dataSizeFormant:(long long)length;

// 相对路径
+(NSString *)filePaht2HOME:(NSString *)filePaht;

// 绝对路径
+(NSString *)filePaht2home:(NSString *)filePaht;

// 打印测试
-(void)testAddtext:(NSString *)text;

// 根据图片url获取网络图片尺寸
+(CGSize)getImageSizeWithURL:(id)URL;

// 获取网络时间和本地时钟时间 **注意:1.获取网络时间可能会失败 2.手机重启本地时钟会重置**
// 传入的时间戳必须为13位 否则会请求网络时间戳
+(void)updataTimeStamp:(NSString *)timeStamp;

// 返回数组:1拼音首字母 2按拼音排序的一维数组 3按拼音排序的二维数组
+(NSMutableArray *)sortByArr:(NSArray *)arrTemp property:(NSString *)propertyName type:(int)type;

// 输入文本是否为数字
+(BOOL)isNumber:(NSString *)text;

@end







