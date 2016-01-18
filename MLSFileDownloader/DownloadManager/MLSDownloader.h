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


#define MLSDownloaderSingleton [MLSDownloader shareDownloader]

@interface MLSDownloader : NSObject
@property (strong, nonatomic, readonly) NSMutableArray <MLSDownloadOperation *>*downloadingArray;
@property (strong, nonatomic, readonly) NSMutableDictionary <NSString *, MLSDownloadOperation *> *downloadingInfo;

// 下载队列
@property (strong, nonatomic, readonly) NSOperationQueue *downloadQueue;

// Kb/s
//MARK: 暂时未做
@property (assign, nonatomic, readonly) CGFloat networkSpeed;

// 单例
+ (instancetype)shareDownloader;

// 恢复上次下载的状态
- (void)recoverDownloadState;

// 保存下载状态
- (void)saveDownloadState;


/**
 *  添加下载操作
 *
 *  @param urlStr     文件url地址
 *  @param fileName   保存本地的文件名
 *  @param fileSize   文件大小（B）
 *  @param cateID   video_cate_id
 *  @param videoID   video_id
 *  @param image   占位图片
 *  @param path       本地文件路径
 *  @param progress   下载进度回调
 *  @param completion 下载完成、失败回调
 *
 *  @return key  根据key可以获取下载操作downloadTask
 */
- (MLSDownloadOperation *)startDownloadWithUrlStr:(NSString *)urlStr
                                         fileName:(NSString *)fileName
                                         fileSize:(CGFloat)fileSize
                                          cate_id:(NSString *)cateID
                                         video_id:(NSString *)videoID
                                       video_type:(NSString *)videoType
                              placeHolderImageUrl:(NSString *)imageUrl
                              fileDestinationPath:(NSString *)path
                                         progress:(MLSDownloaderProgressCallBackBlock)progressBlock
                                       completion:(MLSDownloaderCompletionCallBackBlock)completion;


/**
 *  添加下载操作
 *
 *  @param urlStr     文件url地址
 *  @param fileName   保存本地的文件名
 *  @param fileSize   文件大小（B）
 *  @param cateID   video_cate_id
 *  @param videoID   video_id
 *  @param image   占位图片
 *  @param path       本地文件路径
 *  @param progress   下载进度回调
 *  @param completion 下载完成、失败回调
 *
 *  @return key  根据key可以获取下载操作downloadTask
 */
- (MLSDownloadOperation *)startDownloadWithUrlStr:(NSString *)urlStr
                                         fileName:(NSString *)fileName
                                         fileSize:(CGFloat)fileSize
                                          cate_id:(NSString *)cateID
                                         video_id:(NSString *)videoID
                                 placeHolderImage:(UIImage *)image
                              fileDestinationPath:(NSString *)path
                                         progress:(MLSDownloaderProgressCallBackBlock)progressBlock
                                       completion:(MLSDownloaderCompletionCallBackBlock)completion;


/**
 *  添加下载操作
 *
 *  @param urlStr     文件url地址
 *  @param fileName   保存本地的文件名
 *  @param fileSize   文件大小（B）
 *  @param image   占位图片
 *  @param path       本地文件路径
 *  @param progress   下载进度回调
 *  @param completion 下载完成、失败回调
 *
 *  @return key  根据key可以获取下载操作downloadTask
 */
- (MLSDownloadOperation *)startDownloadWithUrlStr:(NSString *)urlStr
                                   fileName:(NSString *)fileName
                                   fileSize:(CGFloat)fileSize
                           placeHolderImage:(UIImage *)image
                        fileDestinationPath:(NSString *)path
                                   progress:(MLSDownloaderProgressCallBackBlock)progressBlock
                                 completion:(MLSDownloaderCompletionCallBackBlock)completion;
// 是否已经添加到下载
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

///  暂停下载操作
///
///  @param key 根据添加下载时获取得key，在每个downloadInfo中含有对应的key值
///
///  @return 是否成功
- (void)pauseDownloadWithKey:(NSString *)key completion:(MLSDownloaderOperationCallBackBlock)completion;

///  恢复下载操作
///
///  @param key 根据添加下载时获取得key，在每个downloadInfo中含有对应的key值
///
///  @return 是否成功
- (void)resumeDownloadWithKey:(NSString *)key completion:(MLSDownloaderOperationCallBackBlock)completion;

///  删除下载操作
///
///  @param key 根据添加下载时获取得key，在每个downloadInfo中含有对应的key值
///
///  @return 是否成功
- (void)deleteDownloadWithKey:(NSString *)key completion:(MLSDownloaderOperationCallBackBlock)completion;


@end
