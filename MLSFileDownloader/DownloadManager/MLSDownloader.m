//
//  MLSDownloader.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/14.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "MLSDownloader.h"
#import "NSString+MLSEncrypt.h"

@interface MLSDownloader ()
@property (strong, nonatomic, readwrite) NSMutableArray <MLSDownloadOperation *>*downloadingArray;
@property (strong, nonatomic, readwrite) NSMutableDictionary <NSString *, MLSDownloadOperation *> *downloadingInfo;

// 下载队列
@property (strong, nonatomic, readwrite) NSOperationQueue *downloadQueue;

// Kb/s  小b
@property (assign, nonatomic, readwrite) CGFloat networkSpeed;

@end

#define LVRDefaultMaxDownloadCount 1
#define DownloadQueueName  @"com.mlsdownload.queue";
#define DirectoryPathString @"com.downloader.downloadState"
#define ArchiverFileNameString @"archiver.downloadeAccount.downloader"
#define ArchiverErrorFileNameString @"archiver.error"

@implementation MLSDownloader
// 单例
+ (instancetype)shareDownloader {
    
    static dispatch_once_t onceToken;
    static MLSDownloader *downloader = nil;
    
    dispatch_once(&onceToken, ^{
        downloader = [[self alloc] init];
        
        NSOperationQueue *downloadQueue = [[NSOperationQueue alloc] init];
        downloadQueue.maxConcurrentOperationCount = LVRDefaultMaxDownloadCount;
        downloadQueue.name = DownloadQueueName;
        
        downloader.downloadQueue = downloadQueue;
        
        [[NSNotificationCenter defaultCenter] addObserver:downloader selector:@selector(saveDownloadState) name:UIApplicationWillTerminateNotification object:nil];
        
        downloader.downloadingArray = [NSMutableArray array];
        downloader.downloadingInfo = [NSMutableDictionary dictionary];
        
        [downloader recoverDownloadState];
    });
    return downloader;
}
- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}
- (void)dealloc {
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.downloadQueue cancelAllOperations];
}

// 恢复上次下载的状态
- (void)recoverDownloadState {
    
    NSString *fileDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:DirectoryPathString];
    
    NSString *saveFilePath = [fileDirectoryPath stringByAppendingPathComponent:ArchiverFileNameString];
    
    MLSDownloader *downloader = [NSKeyedUnarchiver unarchiveObjectWithFile:saveFilePath];
    
    if (downloader.downloadingInfo != nil) {
        self.downloadingInfo = [NSMutableDictionary dictionaryWithDictionary:downloader.downloadingInfo];
        
    }
    
    if (downloader.downloadingArray != nil) {
        self.downloadingArray = [NSMutableArray arrayWithArray:downloader.downloadingArray];
    }
    
    NSLog(@"%@---\n%@",self.downloadingInfo,self.downloadingArray);
}

// 保存下载状态
- (void)saveDownloadState {
    
    NSString *fileDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:DirectoryPathString];
    
    NSString *saveFilePath = [fileDirectoryPath stringByAppendingPathComponent:ArchiverFileNameString];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 取消当前所有下载操作
    [self.downloadingInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, MLSDownloadOperation * _Nonnull obj, BOOL * _Nonnull stop) {
        
        if (obj.isDownloading) {
            [self pauseDownloadWithKey:key completion:nil];
            
        }
    }];
    
    if (![fileManager fileExistsAtPath:fileDirectoryPath]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:fileDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error != nil) {
            
            [NSKeyedArchiver archiveRootObject:error toFile:[fileDirectoryPath stringByAppendingPathComponent:ArchiverErrorFileNameString]];
            NSLog(@"%@",error);
        }else {
            
            [NSKeyedArchiver archiveRootObject:self toFile:saveFilePath];
        }
    }
}

- (BOOL)haveAddToDownloadWithFileName:(NSString *)fileName {
    __block BOOL isAddDownload = NO;
    
    [self.downloadingArray enumerateObjectsUsingBlock:^(MLSDownloadOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.fileName isEqualToString:fileName]) {
            isAddDownload = YES;
            *stop = YES;
        }
        
    }];
    
    return isAddDownload;
}
- (MLSDownloadOperation *)operationWithName:(NSString *)fileName {
    
    __block MLSDownloadOperation *operation = nil;
    
    [self.downloadingArray enumerateObjectsUsingBlock:^(MLSDownloadOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( [obj.fileName isEqualToString:fileName] ) {
            
            if ([obj isCompletion]) {
                
                operation = obj;
            }
            *stop = YES;
        }
    }];
    return operation;
}
- (MLSDownloadOperation *)startDownloadWithUrlStr:(NSString *)urlStr
                                         fileName:(NSString *)fileName
                                         fileSize:(CGFloat)fileSize
                                          cate_id:(NSString *)cateID
                                         video_id:(NSString *)videoID
                                       video_type:(NSString *)videoType
                              placeHolderImageUrl:(NSString *)imageUrl
                              fileDestinationPath:(NSString *)path
                                         progress:(MLSDownloaderProgressCallBackBlock)progressBlock
                                       completion:(MLSDownloaderCompletionCallBackBlock)completion {
    MLSDownloadOperation *operation = [self startDownloadWithUrlStr:urlStr fileName:fileName fileSize:fileSize placeHolderImage:nil fileDestinationPath:path progress:progressBlock completion:completion];
    operation.video_id = videoID;
    operation.cate_id  = cateID;
    operation.video_type = videoType;
    operation.placeHolderImageUrl = imageUrl;
    return operation;
    
}

- (MLSDownloadOperation *)startDownloadWithUrlStr:(NSString *)urlStr
                                         fileName:(NSString *)fileName
                                         fileSize:(CGFloat)fileSize
                                          cate_id:(NSString *)cateID
                                         video_id:(NSString *)videoID
                                 placeHolderImage:(UIImage *)image
                              fileDestinationPath:(NSString *)path
                                         progress:(MLSDownloaderProgressCallBackBlock)progressBlock
                                       completion:(MLSDownloaderCompletionCallBackBlock)completion {
    MLSDownloadOperation *operation = [self startDownloadWithUrlStr:urlStr fileName:fileName fileSize:fileSize placeHolderImage:image fileDestinationPath:path progress:progressBlock completion:completion];
    operation.video_id = videoID;
    operation.cate_id  = cateID;
    return operation;
}

- (MLSDownloadOperation *)startDownloadWithUrlStr:(NSString *)urlStr
                                         fileName:(NSString *)fileName
                                         fileSize:(CGFloat)fileSize
                                 placeHolderImage:(UIImage *)image
                              fileDestinationPath:(NSString *)path
                                         progress:(MLSDownloaderProgressCallBackBlock)progressBlock
                                       completion:(MLSDownloaderCompletionCallBackBlock)completion {
    MLSDownloadOperation *operation = nil;
    
    if (urlStr == nil) {
        return nil;
    }
    NSLog(@"文件存放目录 ====  %@",path);
    
    // 取值key (应使用url)
    NSString *key = [urlStr md5String];
    operation = [self.downloadingInfo valueForKey:key];
    
    if ( operation != nil && [self.downloadQueue.operations containsObject:operation] ) {
        
        return [self.downloadingInfo valueForKey:key];
    }else {
        
        operation = nil;
        [self.downloadingInfo removeObjectForKey:key];
        [self.downloadingArray removeObject:operation];
    }
    
    // 检查是否是m3u8文件
    NSRange range = [urlStr rangeOfString:@"m3u8" options:NSCaseInsensitiveSearch];
    
    if (range.location != NSNotFound) {
        // 是m3u8文件,提供m3u8下载
        operation = [[MLSDownloaderM3u8Operation alloc] initWithUrlStr:urlStr fileName:fileName fileSize:fileSize fileDestinationPath:path placeHolder:image progress:progressBlock completion:completion];
    }else {
        // 不是m3u8文件，提供普通文件下载
        operation = [[MLSDownloadNomarlOperation alloc] initWithUrlStr:urlStr fileName:fileName fileSize:fileSize fileDestinationPath:path placeHolder:image progress:progressBlock completion:completion];
    }
    
    [self.downloadQueue addOperation:operation];
    [self.downloadingArray addObject:operation];
    [self.downloadingInfo setObject:operation forKey:key];
    return operation;
}

- (void)pauseDownloadWithKey:(NSString *)key completion:(MLSDownloaderOperationCallBackBlock)completion {
    MLSDownloadOperation *operation = [self.downloadingInfo valueForKey:key];
    [operation cancelCurrentDownload];
    if (completion != nil) {
        completion(operation,nil);
    }
}


- (void)resumeDownloadWithKey:(NSString *)key completion:(MLSDownloaderOperationCallBackBlock)completion {
    
    MLSDownloadOperation *operation = [self.downloadingInfo valueForKey:key];
    MLSDownloadOperation *newOperation = [operation resume];
    
    NSUInteger index = [self.downloadingArray indexOfObject:operation];
    [self.downloadingInfo setObject:newOperation forKey:key];
    [self.downloadingArray replaceObjectAtIndex:index withObject:newOperation];
    
    if (completion != nil) {
        
        if (newOperation != nil) {
            
            completion(newOperation, nil);
            
            
        }else {
            
            NSError *error = [NSError errorWithDomain:errorDomain code:DownloaderOperationReusmeError userInfo:nil];
            completion(nil, error);
        }
    }
    
    if (newOperation != nil) {
        [self.downloadQueue addOperation:newOperation];
    }
    
}


- (void)deleteDownloadWithKey:(NSString *)key completion:(MLSDownloaderOperationCallBackBlock)completion {
    
    MLSDownloadOperation *operation = [self.downloadingInfo valueForKey:key];
    [operation cancelCurrentDownload];
    [operation deleteFile];
    [self.downloadingArray removeObject:operation];
    [self.downloadingInfo removeObjectForKey:key];
    
}

- (NSMutableDictionary<NSString *,MLSDownloadOperation *> *)downloadingInfo {
    if (_downloadingInfo == nil) {
        _downloadingInfo = [[NSMutableDictionary alloc] init];
    }
    return _downloadingInfo;
}
- (NSMutableArray<MLSDownloadOperation *> *)downloadingArray {
    if (_downloadingArray == nil) {
        _downloadingArray = [[NSMutableArray alloc] init];
    }
    return _downloadingArray;
}

//===========================================================
//  Keyed Archiving
//
//===========================================================
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.downloadingArray forKey:@"downloadingArray"];
    [encoder encodeObject:self.downloadingInfo forKey:@"downloadingInfo"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.downloadingArray = [decoder decodeObjectForKey:@"downloadingArray"];
        self.downloadingInfo = [decoder decodeObjectForKey:@"downloadingInfo"];
    }
    return self;
}

@end
