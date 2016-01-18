//
//  DownloadNomarlOperation.h
//  testFileDownloader
//
//  Created by MinLison on 16/1/13.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "MLSDownloadOperation.h"

@interface MLSDownloadNomarlOperation : MLSDownloadOperation
@property (copy, nonatomic, readonly) NSString *fullPath;
@property (strong, nonatomic, readonly) NSURLSessionDownloadTask *currentDownloadTask;
@property (copy, nonatomic, readonly) NSString *fileType;
@property (copy, nonatomic, readonly) NSString *suggestedFilename;
@property (copy, nonatomic, readonly) NSString *tempFileName;
@end
