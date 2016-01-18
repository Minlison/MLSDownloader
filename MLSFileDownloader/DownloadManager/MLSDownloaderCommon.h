//
//  MLSDownloaderCommon.h
//  testFileDownloader
//
//  Created by MinLison on 16/1/14.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MLSDownloadOperation;
typedef void(^MLSDownloaderOperationCallBackBlock)(MLSDownloadOperation *operation, NSError *error);
typedef void(^MLSDownloaderProgressCallBackBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, CGFloat progress, MLSDownloadOperation *operation);
typedef void(^MLSDownloaderCompletionCallBackBlock)(NSURLResponse *response, NSURL *filePath, NSError *error, MLSDownloadOperation *operation);
typedef void(^DownloaderNetworkSpeedCompletionBlock) (CGFloat networkSpeed);