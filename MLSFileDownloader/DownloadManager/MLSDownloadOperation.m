//
//  DownloadOperation.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/13.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "MLSDownloadOperation.h"
#import "MLSDownloadFileTools.h"
#import "MLSDownloaderCommon.h"
#include <CommonCrypto/CommonCrypto.h>
#include <zlib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static inline NSString * MLSKeyPathFromOperationState(MLSDownloadState state)
{
        switch (state)
        {
                case MLSDownloadStateReady:
                        return @"isReady";
                case MLSDownloadStateExecuting:
                        return @"isExecuting";
                case MLSDownloadStateCompletion:
                        return @"isFinished";
                case MLSDownloadStatePaused:
                        return @"isPaused";
                default:
                {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
                        return @"state";
#pragma clang diagnostic pop
                }
        }
}

static inline BOOL MLSStateTransitionIsValid(MLSDownloadState fromState, MLSDownloadState toState, BOOL isCancelled)
{
        switch (fromState)
        {
                case MLSDownloadStateReady:
                        switch (toState)
                {
                        case MLSDownloadStatePaused:
                        case MLSDownloadStateExecuting:
                                return YES;
                        case MLSDownloadStateCompletion:
                                return isCancelled;
                        default:
                                return NO;
                }
                case MLSDownloadStateExecuting:
                        switch (toState)
                {
                        case MLSDownloadStatePaused:
                        case MLSDownloadStateCompletion:
                                return YES;
                        default:
                                return NO;
                }
                case MLSDownloadStateCompletion:
                        return NO;
                case MLSDownloadStatePaused:
                        return toState == MLSDownloadStateReady;
                default:
                {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
                        switch (toState)
                        {
                                case MLSDownloadStatePaused:
                                case MLSDownloadStateReady:
                                case MLSDownloadStateExecuting:
                                case MLSDownloadStateCompletion:
                                        return YES;
                                default:
                                        return NO;
                        }
                }
#pragma clang diagnostic pop
        }
}

static NSString *md5String(const void *data, CC_LONG len)
{
        unsigned char result[CC_MD5_DIGEST_LENGTH];
        CC_MD5(data, len, result);
        NSMutableString *resString = [NSMutableString string];
        for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        {
                [resString appendFormat:@"%02x",result[i]];
        }
        return resString;
}

NSRecursiveLock *recursiveLock()
{
        static NSRecursiveLock *lock;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
                lock = [[NSRecursiveLock alloc] init];
                lock.name = @"mls.donwload.lock";
        });
        return lock;
}

@interface MLSDownloadOperation()

// 完成回调
@property (copy, nonatomic, readwrite) MLSDownloaderCompletionCallBackBlock completionCallBackBlock;

// 下载进度回调
@property (copy, nonatomic, readwrite) MLSDownloaderProgressCallBackBlock progressCallBackBlock;

// 网速回调
@property (copy, nonatomic, readwrite) DownloaderNetworkSpeedCompletionBlock networkSpeedCallBackBlock;



@property (copy, nonatomic, readwrite) NSString *localFullPath;

@property (copy, nonatomic, readwrite) NSString *fileType;

@property (copy, nonatomic, readwrite) NSString *tempFileName;

@property (copy, nonatomic, readwrite) NSString *saveFileName;

@property (copy, nonatomic, readwrite) NSString *urlStr;

@property (copy, nonatomic, readwrite) NSString *fileName;

@property (copy, nonatomic, readwrite) NSString *filePath;

@property (copy, nonatomic, readwrite) NSString *placeHolderImageUrl;

@property (copy, nonatomic, readwrite) NSString *key;

@end

@implementation MLSDownloadOperation


// 下载进度回调
- (void)setProgressBlock:(MLSDownloaderProgressCallBackBlock)progress
{
        self.progressCallBackBlock = progress;
}
// 完成回调
- (void)setCompletionBlock:(MLSDownloaderCompletionCallBackBlock)completion
{
        self.completionCallBackBlock = completion;
}
- (void)setNetworkSpeedBlock:(DownloaderNetworkSpeedCompletionBlock)networkSpeedBlock {
        self.networkSpeedCallBackBlock = networkSpeedBlock;
}

- (void)setState:(MLSDownloadState)state
{
        if (!MLSStateTransitionIsValid(self.state, state, [self isCancelled]))
        {
                return;
        }
        [recursiveLock() lock];
        NSString *oldStateKey = MLSKeyPathFromOperationState(self.state);
        NSString *newStateKey = MLSKeyPathFromOperationState(state);

        [self willChangeValueForKey:newStateKey];
        [self willChangeValueForKey:oldStateKey];
        _state = state;
        [self didChangeValueForKey:oldStateKey];
        [self didChangeValueForKey:newStateKey];
        [recursiveLock() unlock];
}

- (BOOL)changeUrlString:(NSString *)urlString
{
    if ([self isExecuting])
    {
        return NO;
    }
    self.urlStr = urlString;
    return YES;
}

// 初始化下载操作
- (instancetype)initWithUrlStr:(NSString *)urlStr
                      fileName:(NSString *)fileName
                      fileSize:(CGFloat)fileSize
           fileDestinationPath:(NSString *)path
                   placeHolder:(NSString *)placeHolder
                      progress:(MLSDownloaderProgressCallBackBlock)progressBlock
                    completion:(MLSDownloaderCompletionCallBackBlock)completion
{

        if (self = [super init])
        {
                NSAssert((urlStr != nil && fileName != nil && path != nil), @"url  filename  path 不能为空");
                
                self.canAutoResume = NO;
                self.state = MLSDownloadStateReady;
                self.urlStr = urlStr;
                self.fileName = fileName;
                self.filePath = path;
                self.fileSize = fileSize;

                self.placeHolderImageUrl = placeHolder;


                self.fileType = [MLSDownloadFileTools fileFormatForUrlString:urlStr];
                self.fileType == nil ? self.fileType = @"mp4" : self.fileType;
                self.tempFileName = [NSString stringWithFormat:@"%@%@.tmp",self.fileName,self.fileType];
                self.localFullPath = [path stringByAppendingPathComponent:fileName];
                self.saveFileName = [NSString stringWithFormat:@"%@%@",self.fileName,self.fileType];


                NSString *key = [NSString stringWithFormat:@"%@",fileName];
                NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
                self.key = md5String(keyData.bytes, (CC_LONG)keyData.length);

                self.progressCallBackBlock = progressBlock;
                self.completionCallBackBlock = completion;

                NSError *error = nil;
                NSFileManager *fileManager = [NSFileManager defaultManager];
                BOOL dir = NO;

                if (![fileManager fileExistsAtPath:self.localFullPath isDirectory:&dir])
                {

                        if (dir == NO)
                        {

                                [[NSFileManager defaultManager] createDirectoryAtPath:self.localFullPath withIntermediateDirectories:YES attributes:nil error:&error];

                                if (error != nil)
                                {
                                        self.state = MLSDownloadStatePaused;
                                        [self cancel];

                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                if (self.completionCallBackBlock != nil)
                                                {
                                                        self.completionCallBackBlock(self,nil,error);
                                                }
                                        });
                                        NSLog(@"create directory error %@",error);

                                }
                        }
                }


        }
        return self;
}



- (NSString *)filePath
{
        if (_filePath == nil)
        {
                return [MLSDownloadFileTools saveFilePath];
        }
        return _filePath;
}

- (BOOL)isReady
{
        return self.state == MLSDownloadStateReady && [super isReady];
}

- (BOOL)isExecuting
{
        return self.state == MLSDownloadStateExecuting;
}

- (BOOL)isFinished
{
        return self.state == MLSDownloadStateCompletion || self.state == MLSDownloadStatePaused;
}
- (BOOL)isCompletion
{
    return self.state == MLSDownloadStateCompletion;
}

- (BOOL)isConcurrent
{
        return YES;
}

- (BOOL)isPaused
{
        return self.state == MLSDownloadStatePaused;
}
// 恢复指定下载操作
- (instancetype)resume
{
        [recursiveLock() lock];

        if (self.state == MLSDownloadStateExecuting)
        {
                [self cancel];
        }



        MLSDownloadOperation *operation = self.copy;
        operation.state = MLSDownloadStateReady;

        [recursiveLock() unlock];

        return operation;
}
// 暂停
- (void)paused
{
        if (self.isPaused)
        {
                return;
        }

        [recursiveLock() lock];

        self.state = MLSDownloadStatePaused;

        [self cancel];

        [recursiveLock() unlock];
}



// 删除本地文件
- (BOOL)deleteFile
{

        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL result = NO;

        NSError *error = nil;
        [fileManager removeItemAtPath:self.localFullPath error:&error];

        if (error == nil)
        {
                result = YES;
        }
        else
        {
                result = NO;
        }

        NSLog(@"%@---error%@",self.filePath,error);

        return result;
}

- (void)changeFileRootPathWithPath:(NSString *)path
{
        self.filePath = path;
        self.localFullPath = [path stringByAppendingPathComponent:self.fileName];
}


//===========================================================
//  Keyed Archiving
//
//===========================================================
- (void)encodeWithCoder:(NSCoder *)encoder
{

        @synchronized (self)
        {

                [encoder encodeObject:[self customParaData] forKey:@"customParaData"];
                [encoder encodeObject:[self localFullPath] forKey:@"localFullPath"];
                [encoder encodeObject:[self fileType] forKey:@"fileType"];

                [encoder encodeObject:[self urlStr] forKey:@"urlStr"];
                [encoder encodeObject:[self fileName] forKey:@"fileName"];
                [encoder encodeObject:[self filePath] forKey:@"filePath"];
                [encoder encodeObject:[self placeHolderImageUrl] forKey:@"placeHolderImageUrl"];

                if (self.state != MLSDownloadStateCompletion)
                {
                        [encoder encodeObject:[NSNumber numberWithUnsignedInteger:MLSDownloadStatePaused] forKey:@"state"];
                }
                else
                {
                        [encoder encodeObject:[NSNumber numberWithUnsignedInteger:MLSDownloadStateCompletion] forKey:@"state"];
                }

                [encoder encodeDouble:self.fileSize forKey:@"fileSize"];
                [encoder encodeObject:[self key] forKey:@"key"];
                [encoder encodeFloat:[self completionPercent] forKey:@"completionPercent"];
                [encoder encodeObject:[self tempFileName] forKey:@"tempFileName"];
                [encoder encodeObject:[self saveFileName] forKey:@"saveFileName"];
                [encoder encodeBool:self.isCanAutoResume forKey:@"canAutoResume"];

        }
}

- (id)initWithCoder:(NSCoder *)decoder
{
        self = [super init];
        if (self) {

                @synchronized (self)
                {
                        [self setCustomParaData:[decoder decodeObjectForKey:@"customParaData"]];
                        [self setLocalFullPath:[decoder decodeObjectForKey:@"localFullPath"]];
                        [self setFileType:[decoder decodeObjectForKey:@"fileType"]];

                        [self setUrlStr:[decoder decodeObjectForKey:@"urlStr"]];
                        [self setFileName:[decoder decodeObjectForKey:@"fileName"]];
                        [self setFilePath:[decoder decodeObjectForKey:@"filePath"]];
                        [self setPlaceHolderImageUrl:[decoder decodeObjectForKey:@"placeHolderImageUrl"]];
                        [self setState:(MLSDownloadState)[[decoder decodeObjectForKey:@"state"] unsignedIntegerValue]];

                        self.fileSize = [decoder decodeDoubleForKey:@"fileSize"];
                        [self setKey:[decoder decodeObjectForKey:@"key"]];
                        self.completionPercent = [decoder decodeFloatForKey:@"completionPercent"];
                        [self setTempFileName:[decoder decodeObjectForKey:@"tempFileName"]];
                        [self setSaveFileName:[decoder decodeObjectForKey:@"saveFileName"]];

                        self.canAutoResume = [decoder decodeBoolForKey:@"canAutoResume"];
                }

        }
        return self;
}
- (id)copy
{
        MLSDownloadOperation * theCopy = [[[self class] alloc] initWithUrlStr:self.urlStr fileName:self.fileName fileSize:self.fileSize fileDestinationPath:self.filePath placeHolder:self.placeHolderImageUrl progress:self.progressCallBackBlock completion:self.completionCallBackBlock];
        theCopy.completionPercent = self.completionPercent;
        theCopy.canAutoResume = self.isCanAutoResume;
        theCopy.key = self.key;

        NSData *customData = [NSKeyedArchiver archivedDataWithRootObject:self.customParaData];

        if (customData)
        {
                theCopy.customParaData = [NSKeyedUnarchiver unarchiveObjectWithData:customData];
        }

        return theCopy;

}
- (id)copyWithZone:(NSZone *)zone
{
        MLSDownloadOperation * theCopy = [[[self class] allocWithZone:zone] initWithUrlStr:self.urlStr fileName:self.fileName fileSize:self.fileSize fileDestinationPath:self.filePath placeHolder:self.placeHolderImageUrl progress:self.progressCallBackBlock completion:self.completionCallBackBlock];
        theCopy.completionPercent = self.completionPercent;
        theCopy.canAutoResume = self.isCanAutoResume;
        theCopy.key = self.key;

        NSData *customData = [NSKeyedArchiver archivedDataWithRootObject:self.customParaData];

        if (customData)
        {
                theCopy.customParaData = [NSKeyedUnarchiver unarchiveObjectWithData:customData];
        }
        
        return theCopy;
}
- (id)mutableCopyWithZone:(NSZone *)zone
{
        MLSDownloadOperation * theCopy = nil;

        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];

        if (data)
        {
                theCopy = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                theCopy.progressCallBackBlock = self.progressCallBackBlock;
                theCopy.completionCallBackBlock = self.completionCallBackBlock;
                theCopy.networkSpeedCallBackBlock = self.networkSpeedCallBackBlock;
        }

        return theCopy;
}
@end

NSString *resumeDataLocalStr = @"resume.data";
NSString *waitingArrayLocalStr = @"waiting.data";
NSString *tmpM3u8TextLoacalStr = @"movie.m3u8.tmp";
NSString *realM3u8TextLocalStr = @"movie.m3u8";
NSString *errorDomain = @"com.mlsdownloader.errordomain";

long GetLocalFileLenth(FILE *fp)
{

        if(fp != NULL)
        {
                fseek(fp, 0, SEEK_END);
                return ftell(fp);
        }
        return 0;
}
