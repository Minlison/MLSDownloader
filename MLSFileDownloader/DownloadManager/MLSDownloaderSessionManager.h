//
//  DownloaderSessionManager.h
//  testFileDownloader
//
//  Created by MinLison on 16/1/13.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "AFURLSessionManager.h"

// 进度回调
typedef void (^DownloaderProgressBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);

// 完成回调block
typedef void (^DownloaderCompletionBlock)(NSURLResponse *response, NSURL *filePath, NSError *error);

@interface MLSDownloaderSessionManager : AFURLSessionManager

+ (instancetype)shareDownloadManager;

// 添加断点续传操作
- (NSURLSessionDownloadTask *)addDownloadTaskWithResumeData:(NSData *)resumeData destination:(NSString *)destination downloadProgress:(DownloaderProgressBlock)downloadProgress completionHandler:(DownloaderCompletionBlock)completionHandler;

// 添加新的下载操作
- (NSURLSessionDownloadTask *)addDownloadTaskWithUrlString:(NSString *)urlString destination:(NSString *)destination downloadProgress:(DownloaderProgressBlock)downloadProgress completionHandler:(DownloaderCompletionBlock)completionHandler;
@end
