//
//  MLSDownloader.h
//  testFileDownloader
//
//  Created by MinLison on 16/1/14.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLSDownloaderCommon.h"
#import "MLSDownloaderM3u8Operation.h"
#import "MLSDownloadNomarlOperation.h"
#import "MLSDownloadFileTools.h"
#import "MLSDownloadAccount.h"


#define MLSDownloaderSingleton [MLSDownloader shareDownloader]

@interface MLSDownloader : NSObject <NSCoding>

@property (strong, nonatomic) NSMutableArray <MLSDownloadOperation *>*downloadingArray;
@property (strong, nonatomic) NSMutableDictionary <NSString *, MLSDownloadOperation *> *downloadingInfo;

/**
 *  是否仅在wifi下下载 ，默认是YES
 */
@property (assign, nonatomic, getter=isOnlyUseWifi) BOOL onlyUseWifi;

/**
 *  是否自动继续  默认为NO
 */
@property (assign, nonatomic, getter=isAutoResume) BOOL autoResume;

/**
 *  是否启用后台下载， 必须在plist文件中配置后台播放音乐， 默认为 NO
 */
@property (assign, nonatomic, getter=isAllowBackgroundDownload) BOOL allowBackgroundDownload;

/**
 *  允许的最大并发下载量
 */
@property (assign, nonatomic) NSInteger maxConcurrentCount;

/**
 *  下载队列
 */
@property (strong, nonatomic, readonly) NSOperationQueue *downloadQueue;

/**
 *  单例
 */
+ (instancetype)shareDownloader;


/**
 *  恢复上次下载的状态
 */
- (void)recoverDownloadState;

/**
 *  程序进入前台，恢复下载状态
 */
- (void)foregroundRecoverDownloadState;

/**
 *  保存下载状态, 是否取消下载
 */
- (void)saveDownloadStateWithCancelAllDownload:(BOOL)cancel;

/**
 *  取消所有下载操作
 */
- (void)cancelAllDownloadingOperation;

/**
 *  添加下载操作
 *
 *  @param urlStr       文件url地址
 *  @param fileName     保存本地的文件名
 *  @param fileSize     文件大小（B）
 *  @param customPara   自定义参数
 *  @param image        占位图片
 *  @param path         本地文件路径根目录（文件夹路径），如果为nil，则使用 [MLSDownloadFileTools saveFilePath]
 *  @param progress     下载进度回调
 *  @param completion   下载完成、失败回调
 *
 *  @return key  根据key可以获取下载操作downloadTask
 */
- (MLSDownloadOperation *)startDownloadWithUrlStr:(NSString *)urlStr
                                         fileName:(NSString *)fileName
                                         fileSize:(CGFloat)fileSize
                                       customPara:(id <NSCoding>)customPara
                              placeHolderImageUrl:(NSString *)imageUrl
                              fileDestinationPath:(NSString *)path
                                         progress:(MLSDownloaderProgressCallBackBlock)progressBlock
                                       completion:(MLSDownloaderCompletionCallBackBlock)completion;


/**
 *  是否已经添加到下载
 *
 *  @param fileName 文件名
 *
 *  @return true or false
 */
- (BOOL)haveAddToDownloadWithFileName:(NSString *)fileName;
/**
 *  根据文件名，返回操作
    如果操作没有完成，则返回nil
 *
 *  @param fileName 文件名
 *
 *  @return 操作
 */
- (MLSDownloadOperation *)operationWithName:(NSString *)fileName;

/**
 *  暂停下载操作
 *
 *  @param key        根据添加下载时获取得key，在每个operation中含有对应的key值
 *  @param completion 回调
 */
- (void)pauseDownloadWithKey:(NSString *)key completion:(MLSDownloaderOperationCallBackBlock)completion;

/**
 *  恢复下载操作
 *
 *  @param key        根据添加下载时获取得key，在每个operation中含有对应的key值
 *  @param completion 回调
 */
- (void)resumeDownloadWithKey:(NSString *)key completion:(MLSDownloaderOperationCallBackBlock)completion;

/**
 *  删除下载操作
 *
 *  @param key        根据添加下载时获取得key，在每个operation中含有对应的key值
 *  @param completion 回调
 */
- (void)deleteDownloadWithKey:(NSString *)key completion:(MLSDownloaderOperationCallBackBlock)completion;


@end

FOUNDATION_EXTERN NSString *MLSDownloadRefreshDataNotifaction;
