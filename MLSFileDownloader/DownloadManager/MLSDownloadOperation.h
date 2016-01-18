//
//  DownloadOperation.h
//  testFileDownloader
//
//  Created by MinLison on 16/1/13.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLSDownloaderCommon.h"
// 计算网速加权
#define _NETWORK_SPPED_COUNT_ 20
// 默认网速大小
#define _DEFAULT_NETWORK_SPEED 10
typedef NS_ENUM(NSInteger, DownloaderM3u8OperationError){
    DownloaderM3u8OperationErrorNotM3U8Url = 1,
    DownloaderM3u8OperationErrorNetworkUnConnection = 2,
    DownloaderM3u8OperationErrorStartCountToLarge = 3,
    DownloaderM3u8OperationErrorCreateM3U8FileError = 4,
    DownloaderOperationReusmeError = 5
};
@class MLSDownloadOperation;


dispatch_queue_t global_parser_queue(void);

@interface MLSDownloadOperation : NSOperation <NSCoding>

@property (copy, nonatomic) NSString *video_id;
@property (copy, nonatomic) NSString *cate_id;
@property (copy, nonatomic) NSString *video_type;

/*************/


// downloader操作key
@property (copy, nonatomic) NSString *key;

// 单位B
@property (assign, nonatomic) CGFloat fileSize;

// 下载地址
@property (copy, nonatomic) NSString *urlStr;

// 文件名称
@property (copy, nonatomic) NSString *fileName;

// 文件路径
@property (copy, nonatomic) NSString *filePath;

// 占位图片
@property (strong, nonatomic) UIImage *placeHolderImage;

// 占位图片urlStr
@property (copy, nonatomic) NSString *placeHolderImageUrl;

// 完成
@property (assign, nonatomic, getter=isCompletion) BOOL completion;
// 暂停
@property (assign, nonatomic, getter=isSuspend) BOOL suspend;
// 下载
@property (assign, nonatomic, getter=isDownloading) BOOL downloading;


// 完成进度
@property (assign, nonatomic) CGFloat completionPercent;

// 本地播放地址,如果下载没有完成，为nil
@property (copy, nonatomic) NSString *locaPlayUrlStr;
// 视频总时间
@property (assign, nonatomic) NSInteger totalSeconds;

// 计算网速的timer
@property (strong, nonatomic) NSTimer *timer;

// 计算网速的数组
@property (strong, nonatomic) NSMutableArray <NSNumber *>*countNetworkArr;



// 断点续传
@property (strong, nonatomic) NSData *resumeData;




// 初始化下载操作 --> 子类实现
- (instancetype)initWithUrlStr:(NSString *)urlStr
                      fileName:(NSString *)fileName
                      fileSize:(CGFloat)fileSize
           fileDestinationPath:(NSString *)path
                   placeHolder:(UIImage *)placeHolder
                      progress:(MLSDownloaderProgressCallBackBlock)progressBlock
                    completion:(MLSDownloaderCompletionCallBackBlock)completion;

// 地址失效时，更改地址 --> 子类实现
- (instancetype)changeDownloadUrlString:(NSString *)urlString;

// 恢复指定下载操作 --->子类实现
- (instancetype)resume;

// 计算网速 --> 子类实现
- (void)countNetworkSpeed;

// 取消当前下载
- (void)cancelCurrentDownload;
// 删除文件
- (BOOL)deleteFile;



// 完成回调
@property (copy, nonatomic) MLSDownloaderCompletionCallBackBlock completionCallBackBlock;

// 设置完成回调
- (void)setCompletionBlock:(MLSDownloaderCompletionCallBackBlock)completion;

// 下载进度回调
@property (copy, nonatomic) MLSDownloaderProgressCallBackBlock progressCallBackBlock;

// 设置下载进度回调
- (void)setProgressBlock:(MLSDownloaderProgressCallBackBlock)progress;

// 网速回调
@property (copy, nonatomic) DownloaderNetworkSpeedCompletionBlock networkSpeedCallBackBlock;

// 设置网速回调
- (void)setNetworkSpeedBlock:(DownloaderNetworkSpeedCompletionBlock)networkSpeedBlock;
@end

extern NSString *resumeDataLocalStr;
extern NSString *waitingArrayLocalStr;
extern NSString *tmpM3u8TextLoacalStr;
extern NSString *realM3u8TextLocalStr;

extern NSString *errorDomain;
