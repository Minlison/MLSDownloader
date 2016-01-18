//
//  DownloaderSessionManager.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/13.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "MLSDownloaderSessionManager.h"

@implementation MLSDownloaderSessionManager
+ (instancetype)shareDownloadManager {
    // 配置网络服务
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 60;
    sessionConfig.timeoutIntervalForResource = 60 * 30;
    sessionConfig.discretionary = YES;                  // 系统自动选择最佳网络下载
    sessionConfig.HTTPMaximumConnectionsPerHost = 3;    // 最多允许连接三台主机
    sessionConfig.allowsCellularAccess = NO;
    
    
    static MLSDownloaderSessionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] initWithSessionConfiguration:sessionConfig];
    });
    return manager;
}



// 添加下载任务
- (NSURLSessionDownloadTask *)addDownloadTaskWithResumeData:(NSData *)resumeData destination:(NSString *)destination downloadProgress:(DownloaderProgressBlock)downloadProgress completionHandler:(DownloaderCompletionBlock)completionHandler {
    if (destination == nil) {
        NSLog(@"downloadTask destination is nil");
        return nil;
    }
    if (resumeData == nil) {
        NSLog(@"downloadTask resumeData is nil");
        return nil;
    }
    
    
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    
    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithResumeData:resumeData progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSString *urlDestination = [NSString stringWithFormat:@"file://%@",destination];
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
            
            urlDestination = [urlDestination stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        }else {
            
            urlDestination = [urlDestination stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
            
        }
        
        return [NSURL URLWithString:urlDestination];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(response, filePath, error);
        }
    }];
    
    
    // 进度回调
    [self setDownloadTaskDidWriteDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        
        if (downloadProgress) {
            downloadProgress(session,downloadTask,bytesWritten,totalBytesWritten,totalBytesExpectedToWrite);
        }
        
    }];
    
    return downloadTask;
    
}

// 添加下载任务
- (NSURLSessionDownloadTask *)addDownloadTaskWithUrlString:(NSString *)urlString destination:(NSString *)destination downloadProgress:(DownloaderProgressBlock)downloadProgress completionHandler:(DownloaderCompletionBlock)completionHandler {
    NSAssert(urlString, @"urlString不能为空");
    NSAssert(destination, @"目标文件目录不能为空");
    if (destination == nil) {
        NSLog(@"downloadTask destination is nil");
        return nil;
    }
    if (urlString == nil) {
        NSLog(@"downloadTask urlString is nil");
        return nil;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    
    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithRequest:request progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSString *urlDestination = [NSString stringWithFormat:@"file://%@",destination];
        
        if ([UIDevice currentDevice].systemVersion.integerValue >= 8.0) {
            
            urlDestination = [urlDestination stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        }else {
            
            urlDestination = [urlDestination stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
        }
#pragma clang diagnostic pop
        
        return [NSURL URLWithString:urlDestination];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nonnull filePath, NSError * _Nonnull error) {
        if (completionHandler ) {
            completionHandler(response, filePath, error);
        }
    }];
    
    // 进度回调
    [self setDownloadTaskDidWriteDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        
        if (downloadProgress) {
            downloadProgress(session,downloadTask,bytesWritten,totalBytesWritten,totalBytesExpectedToWrite);
        }
        
    }];
    
    return downloadTask;
}

@end

