//
//  DownloadNomarlOperation.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/13.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "MLSDownloadNomarlOperation.h"
#import "MLSDownloaderSessionManager.h"
@interface MLSDownloadNomarlOperation() <NSXMLParserDelegate> {
    BOOL barraryLock;
    NSInteger tempCountNetworkSpeed;
    BOOL fileInfoDataReady;
}
@property (copy, nonatomic, readwrite) NSString *fullPath;
@property (strong, nonatomic, readwrite) NSURLSessionDownloadTask *currentDownloadTask;
@property (copy, nonatomic, readwrite) NSString *fileType;
@property (copy, nonatomic, readwrite) NSString *suggestedFilename;
@property (copy, nonatomic, readwrite) NSString *tempFileName;
@property (strong, nonatomic) NSXMLParser *xmlParser;
@end

@implementation MLSDownloadNomarlOperation
- (instancetype)initWithUrlStr:(NSString *)urlStr
                      fileName:(NSString *)fileName
                      fileSize:(CGFloat)fileSize
           fileDestinationPath:(NSString *)path
                   placeHolder:(UIImage *)placeHolder
                      progress:(MLSDownloaderProgressCallBackBlock)progressBlock
                    completion:(MLSDownloaderCompletionCallBackBlock)completion {
    
    if (self = [super initWithUrlStr:urlStr fileName:fileName fileSize:fileSize fileDestinationPath:path placeHolder:placeHolder progress:progressBlock completion:completion]) {
        
        self.locaPlayUrlStr = nil;
        fileInfoDataReady = NO;
        self.downloading = YES;
        barraryLock = NO;
        tempCountNetworkSpeed = _DEFAULT_NETWORK_SPEED;
        
        self.fullPath = [path stringByAppendingPathComponent:fileName];
        
        NSError *error = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL dir = NO;
        
        if (![fileManager fileExistsAtPath:path isDirectory:&dir]) {
            
            if (dir == NO) {
                
                [[NSFileManager defaultManager] createDirectoryAtPath:self.fullPath withIntermediateDirectories:YES attributes:nil error:&error];
                
                if (error != nil) {
                    
                    [self cancel];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.completionCallBackBlock != nil) {
                            self.completionCallBackBlock(nil,[NSURL URLWithString:path],error,nil);
                        }
                    });
                    NSLog(@"create directory error %@",error);
                    
                }
            }
        }
    }
    
    return self;
}

- (instancetype)changeDownloadUrlString:(NSString *)urlString {
    
    MLSDownloadNomarlOperation *newOperation = [[MLSDownloadNomarlOperation alloc] initWithUrlStr:urlString fileName:self.fileName fileSize:self.fileSize fileDestinationPath:self.filePath placeHolder:self.placeHolderImage progress:self.progressCallBackBlock completion:self.completionCallBackBlock];
    
    newOperation.completionPercent = self.completionPercent;
    newOperation.tempFileName = self.tempFileName;
    newOperation.countNetworkArr = self.countNetworkArr;
    newOperation.placeHolderImageUrl = self.placeHolderImageUrl;
    newOperation.placeHolderImage = self.placeHolderImage;
    return newOperation;
}

- (instancetype)resume {
    
    return [self changeDownloadUrlString:self.urlStr];
}



- (void)main {
    @autoreleasepool {
        
        // 获取文件信息
        [self getFileInfoWithUrl:self.urlStr];
        
        while (!fileInfoDataReady) {
            
            if (self.isCancelled) {
                return;
            }else {
                continue;
            }
        }
        
       
        if (self.isCancelled) {
            return;
        }
        
        // 检查本地文件
        [self checkLocalDownloadState];
        
        if (self.isCancelled) {
            return;
        }
        
        // 开始下载
        [self startDownload];
    }
}
- (void)cancelCurrentDownload {
    
    if (self.currentDownloadTask != nil) {
        
        [self.currentDownloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            // 保存恢复数据
            [resumeData writeToFile:[self.fullPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@",self.fileName,resumeDataLocalStr]] atomically:YES];
            
            dispatch_async(global_parser_queue(), ^{
                
                self.xmlParser = [[NSXMLParser alloc] initWithData:resumeData];
                self.xmlParser.delegate = self;
                [self.xmlParser parse];
                
            });
            
        }];
    }
    [super cancelCurrentDownload];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    //记录所取得的文字列
    if ([string rangeOfString:@".tmp"].location != NSNotFound) {
        
        NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:string];
        NSError *error = nil;
        
        self.tempFileName = string;
        
        [[NSFileManager defaultManager] moveItemAtPath:tempFilePath toPath:[self.fullPath stringByAppendingPathComponent:string] error:&error];
        [parser abortParsing];
    }
}

// 根据url获取文件信息
- (void)getFileInfoWithUrl:(NSString *)urlString {
    
    if (urlString == nil) {
        
        [self cancelCurrentDownload];
        
        fileInfoDataReady = NO;
    }else {
        
        NSMutableURLRequest *requestM = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
        requestM.HTTPMethod = @"HEAD";
        
        [[[MLSDownloaderSessionManager shareDownloadManager] dataTaskWithRequest:requestM completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            
            if (error == nil) {
                
                fileInfoDataReady = YES;
                
                self.suggestedFilename = response.suggestedFilename;
                
                self.fullPath = [self.filePath stringByAppendingPathComponent:self.suggestedFilename];
                
                NSString *fileFullName = response.suggestedFilename;
                NSRange typeRange = [fileFullName rangeOfString:@"." options:NSBackwardsSearch];
                
                self.fileType = [fileFullName substringFromIndex:typeRange.location + typeRange.length];
                
                if (self.fileName == nil) {
                    
                    if (typeRange.location != NSNotFound) {
                        self.fileName = [fileFullName substringToIndex:typeRange.location];
                    }
                }
                if (self.fileSize == 0) {
                    self.fileSize = response.expectedContentLength <= 0 ? 0 : response.expectedContentLength;
                }
                
            }else {
                
                fileInfoDataReady = NO;
                [self cancelCurrentDownload];
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (self.completionCallBackBlock != nil) {
                        if (self.filePath) {
                            
                            self.completionCallBackBlock(response,[NSURL URLWithString:self.filePath],error,self);
                        }else {
                            self.completionCallBackBlock(response,nil,error,self);
                        }
                    }
                });
                
            }
        }] resume];
    }
}

// 检查本地文件夹，找出已经下载过的文件
- (void)checkLocalDownloadState {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL dir = NO;
    if ([fileManager fileExistsAtPath:[self.fullPath stringByAppendingPathComponent:self.tempFileName] isDirectory:&dir]) {
        
        if (dir == NO) {
            
            [fileManager moveItemAtPath:[self.fullPath stringByAppendingPathComponent:self.tempFileName] toPath:[NSTemporaryDirectory() stringByAppendingPathComponent:self.tempFileName] error:NULL];

            
            if ([fileManager fileExistsAtPath:[self.fullPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@",self.fileName,resumeDataLocalStr]]] ) {
                
                NSString *filePath = [self.fullPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@",self.fileName,resumeDataLocalStr]];
//                NSLog(@"%@",filePath);
                self.resumeData = [NSData dataWithContentsOfFile:filePath];
                
                [fileManager removeItemAtPath:[self.fullPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@",self.fileName,resumeDataLocalStr]] error:NULL];
            }
        }
    }
}
- (void)startDownload {
    
    __weak typeof (self) weakSelf = self;
    
    barraryLock = YES;
    
    void (^progressBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite)  = ^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite)  {
        
        __strong typeof (weakSelf) strongSelf = weakSelf;
        
        [self.countNetworkArr addObject:@(bytesWritten * 8)];
        
        CGFloat percent = totalBytesWritten * 1.0 / totalBytesExpectedToWrite;
        
        self.completionPercent = percent;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (strongSelf.progressCallBackBlock != nil) {
                strongSelf.progressCallBackBlock(session,downloadTask,percent,self);
            }
            
        });
        
        // 如果在下载过程中取消操作，就取消操作
        if (strongSelf.isCancelled) {
            // 取消循环等待锁
            barraryLock = NO;
        }
    };
    
    void (^completionBlock)(NSURLResponse *response, NSURL *filePath, NSError *error)  = ^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        __strong typeof (weakSelf) strongSelf = weakSelf;
        
        barraryLock = NO;
        
        if (error != nil ) {
            
            self.suspend = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (strongSelf.completionCallBackBlock != nil && ![error.localizedDescription isEqualToString:@"canceled"]) {
                    
                    strongSelf.completionCallBackBlock(response,filePath,nil,self);
                    
                }else if (strongSelf.completionCallBackBlock != nil) {
                    
                    strongSelf.completionCallBackBlock(response,filePath,error,self);
                }
            });
            
            
            NSLog(@"%@---download error %@",strongSelf.fileName, error);
        }else {
            self.completion = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (self.completionCallBackBlock != nil) {
                    
                    self.completionCallBackBlock(response,filePath,nil,self);
                }
            });
            NSLog(@"%@---download success",strongSelf.fileName);
        }
    };

    
    
    NSURLSessionDownloadTask *downloadTask = nil;
    
    if (self.resumeData != nil) {
        
         downloadTask = [[MLSDownloaderSessionManager shareDownloadManager] addDownloadTaskWithResumeData:self.resumeData destination:[self.fullPath stringByAppendingPathComponent:self.suggestedFilename] downloadProgress:progressBlock completionHandler:completionBlock];
        [downloadTask resume];
        self.currentDownloadTask = downloadTask;
        
    }else {
        
        downloadTask = [[MLSDownloaderSessionManager shareDownloadManager] addDownloadTaskWithUrlString:self.urlStr destination:[self.fullPath stringByAppendingPathComponent:self.suggestedFilename] downloadProgress:progressBlock completionHandler:completionBlock];
        [downloadTask resume];
    }
    
    self.currentDownloadTask = downloadTask;
    
    while (barraryLock == YES) {
        continue;
    }
}

- (NSString *)locaPlayUrlStr {
    
    if (self.isCompletion) {

        NSError *error = nil;
        
        
        NSArray <NSString *>*array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.fullPath error:&error];
        
        if (error != nil || array == nil || array.count == 0 ) {
            
            return nil;
            
        }else {
            
            return [NSString stringWithFormat:@"file://%@/%@",self.fullPath,array.lastObject];
        }
    }
    return nil;
}



//===========================================================
//  Keyed Archiving
//
//===========================================================
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.fullPath forKey:@"fullPath"];
    [encoder encodeObject:self.fileType forKey:@"fileType"];
    [encoder encodeObject:self.suggestedFilename forKey:@"suggestedFilename"];
    [encoder encodeObject:self.tempFileName forKey:@"tempFileName"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        self.fullPath = [decoder decodeObjectForKey:@"fullPath"];
        self.fileType = [decoder decodeObjectForKey:@"fileType"];
        self.suggestedFilename = [decoder decodeObjectForKey:@"suggestedFilename"];
        self.tempFileName = [decoder decodeObjectForKey:@"tempFileName"];
    }
    return self;
}

@end
