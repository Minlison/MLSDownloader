//
//  DownloadOperation.h
//  testFileDownloader
//
//  Created by MinLison on 16/1/13.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "curl.h"
#import "MLSDownloaderCommon.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

static inline size_t convenient_func(void* ptr, size_t size, size_t nmemb, void* data)
{
    return (size_t)(size * nmemb);
}

/**
 *   获取本地文件大小
 *
 *  @param fp 文件指针
 *
 *  @return 本地文件大小
 */
long GetLocalFileLenth(FILE *fp);
/**
 *  递归锁
 */
NSRecursiveLock *recursiveLock();

// 计算网速加权重
#define _NETWORK_SPPED_COUNT_ 1

typedef NS_ENUM(NSInteger, DownloadOperationErrorCode)
{
        // common
        DownloadOperationErrorCodeCancel = 1,       // 取消
        DownloadOperationErrorCodeCacheError,   // 空间不足
        DownloadOperationErrorCodeFileIsNotExit,   // 文件不存在
        // m3u8
        DownloadOperationErrorCodeNotM3U8Url,
        DownloadOperationErrorCodeNetworkUnConnection,
        DownloadOperationErrorCodeStartCountToLarge,
        DownloadOperationErrorCodeCreateM3U8FileError,
        DownloadOperationErrorCodeReusmeError,

};

typedef NS_OPTIONS(NSUInteger, MLSDownloadState)
{
        MLSDownloadStatePaused          = -1,
        MLSDownloadStateReady           = 1,
        MLSDownloadStateExecuting       = 2,
        MLSDownloadStateCompletion      = 3
};

@class MLSDownloadOperation;


@interface MLSDownloadOperation : NSOperation <NSCoding, NSCopying, NSMutableCopying>


#pragma - mark custom
/**
 *  自定义参数，会原封不动的传回
 */
@property (strong, nonatomic) id <NSCoding> customData;
/**
 *  是否允许网络良好的情况下，自动继续, 默认为NO
 */
@property (assign, nonatomic, getter=isCanAutoResume) BOOL canAutoResume;

#pragma mark - 文件信息
/**
 *  文件下载进度百分比
 */
@property (assign, nonatomic) CGFloat completionPercent;
/**
 *  文件原始大小
 */
@property (assign, nonatomic) CGFloat fileSize;
/**
 * 文件下载后保存路径
 */
@property (copy, nonatomic, readonly) NSString *localFullPath;

/**
 * 文件类型
 */
@property (copy, nonatomic, readonly) NSString *fileType;


/**
 *  文件下载地址
 */
@property (copy, nonatomic, readonly) NSString *urlStr;

/**
 *  文件名
 */
@property (copy, nonatomic, readonly) NSString *fileName;
/**
 *  临时文件名 xx.mp4.tmp
 */
@property (copy, nonatomic, readonly) NSString *tempFileName;
/**
 *   完成后文件名 xx.mp4
 */
@property (copy, nonatomic, readonly) NSString *saveFileName;
/**
 *  文件本地保存路径
 */
@property (copy, nonatomic, readonly) NSString *filePath;

/**
 *  占位图片路径
 */
@property (copy, nonatomic, readonly) NSString *placeHolderImageUrl;

/**
 *  本地播放地址
 */
@property (copy, nonatomic, readonly) NSString *locaPlayUrlStr;

#pragma mark - 下载状态
/**
 *  下载状态
 */
@property (assign, nonatomic) MLSDownloadState state;

/**
 *  操作文件的key
 */
@property (copy, nonatomic, readonly) NSString *key;


// 完成
@property (assign, nonatomic) BOOL completion NS_DEPRECATED_IOS(1_0,1_0,"请使用方法isCompletion");
// 暂停
@property (assign, nonatomic, getter=isSuspend) BOOL suspend NS_DEPRECATED_IOS(1_0,1_0,"请使用方法isPaused");
// 下载
@property (assign, nonatomic, getter=isDownloading) BOOL downloading NS_DEPRECATED_IOS(1_0,1_0,"请使用方法isExecuting");
// 等待中
@property ( assign, nonatomic, getter=isWaiting ) BOOL waiting NS_DEPRECATED_IOS(1_0,1_0,"请使用方法isReady");

@property ( assign, nonatomic, getter=isWritingFile ) BOOL writingFile NS_DEPRECATED_IOS(1_0,1_0,"unUsed");


/**
 *  初始化下载操作 --> 子类实现
 *
 *  @param urlStr        下载地址
 *  @param fileName      文件名
 *  @param fileSize      文件大小-> 如果不确定，传入0 会自动获取
 *  @param path          本地存储路径
 *  @param placeHolder   占位图url路径，没有就传入nil，会自动截取
 *  @param progressBlock 进度回调
 *  @param completion    完成回调
 *
 *  @return operation
 */
- (instancetype)initWithUrlStr:(nonnull NSString *)urlStr
                      fileName:(nonnull NSString *)fileName
                      fileSize:(CGFloat)fileSize
           fileDestinationPath:(nonnull NSString *)path
                   placeHolder:(nonnull NSString *)placeHolder
                      progress:(MLSDownloaderProgressCallBackBlock)progressBlock
                    completion:(MLSDownloaderCompletionCallBackBlock)completion;



// 恢复
- (instancetype)resume;

// 暂停
- (void)paused;
- (BOOL)isPaused;
/**
 *  是否已经完成  不要调用isFineshed
 */
- (BOOL)isCompletion;

// 删除本地文件
- (BOOL)deleteFile;

- (BOOL)changeUrlString:(NSString *)urlString;
// 计算网速 --> 子类实现
- (void)countNetworkSpeed;
// 完成回调
@property (copy, nonatomic, readonly) MLSDownloaderCompletionCallBackBlock completionCallBackBlock;

// 设置完成回调
- (void)setCompletionBlock:(MLSDownloaderCompletionCallBackBlock)completion;

// 下载进度回调
@property (copy, nonatomic, readonly) MLSDownloaderProgressCallBackBlock progressCallBackBlock;

// 设置下载进度回调
- (void)setProgressBlock:(MLSDownloaderProgressCallBackBlock)progress;

// 网速回调
@property (copy, nonatomic, readonly) DownloaderNetworkSpeedCompletionBlock networkSpeedCallBackBlock;

// 设置网速回调
- (void)setNetworkSpeedBlock:(DownloaderNetworkSpeedCompletionBlock)networkSpeedBlock;

/**
 *  更改跟目录
 *
 *  @param path 根目录
 */
- (void)changeFileRootPathWithPath:(NSString *)path;

@end

FOUNDATION_EXTERN NSString *resumeDataLocalStr;
FOUNDATION_EXTERN NSString *waitingArrayLocalStr;
FOUNDATION_EXTERN NSString *tmpM3u8TextLoacalStr;
FOUNDATION_EXTERN NSString *realM3u8TextLocalStr;

FOUNDATION_EXTERN NSString *errorDomain;


#pragma clang diagnostic pop
