//
//  MLSDownloader.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/14.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "MLSDownloader.h"

#import <AVFoundation/AVFoundation.h>
#import "MLSNetworkReachability.h"

@interface MLSDownloader ()
//@property (strong, nonatomic, readwrite) NSArray <MLSDownloadOperation *>*downloadingArray;
//@property (strong, nonatomic, readwrite) NSMutableDictionary <NSString *, MLSDownloadOperation *> *downloadingInfo;

// 下载队列
@property (strong, nonatomic, readwrite) NSOperationQueue *downloadQueue;

// 企业版使用
@property ( strong, nonatomic ) AVAudioPlayer *audioPlayer;

@property (strong, nonatomic)  MLSNetworkReachability *networkReach;

@end

#define MLSDefaultMaxDownloadCount 2
#define DownloadQueueName  @".com.mlsdownload.queue";

static MLSDownloader *downloader = nil;

@implementation MLSDownloader
// 单例
+ (instancetype)shareDownloader
{

    static dispatch_once_t downloaderOnceToken;

    if (downloader != nil)
    {
        return downloader;
    }
    dispatch_once(&downloaderOnceToken, ^{

        downloader = [[self alloc] init];

        NSOperationQueue *downloadQueue = [[NSOperationQueue alloc] init];
        downloadQueue.maxConcurrentOperationCount = MLSDefaultMaxDownloadCount;
        downloadQueue.name = DownloadQueueName;


        // 本项目使用
        downloadQueue.qualityOfService = NSQualityOfServiceBackground;

        downloader.downloadQueue = downloadQueue;
        downloader.onlyUseWifi = YES;
        downloader.autoResume = NO;
        downloader.allowBackgroundDownload = NO;

        [[NSNotificationCenter defaultCenter] addObserver:downloader selector:@selector(backgroundSaveDownloadState) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:downloader selector:@selector(foregroundRecoverDownloadState) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:downloader selector:@selector(terminateSaveDownloadState) name:UIApplicationWillTerminateNotification object:nil];

        downloader.downloadingInfo = [NSMutableDictionary dictionary];

        [downloader recoverDownloadState];
        [downloader createNetworkReachablity];

    });
    NSLog(@"downloader");
    return downloader;
}
- (void)setValue:(id)value forKey:(NSString *)key
{
    if ([key isEqualToString:@"downloadingInfo"])
    {
        self.downloadingInfo = value;
    }
}

- (void)setMaxConcurrentCount:(NSInteger)maxConcurrentCount
{
    _maxConcurrentCount = maxConcurrentCount;

    if (self.downloadQueue != nil)
    {
        [self.downloadQueue setMaxConcurrentOperationCount:maxConcurrentCount];
    }
}
- (void)createNetworkReachablity
{

    if ([self.networkReach isReachable])
    {
        return;
    }
    self.networkReach = [MLSNetworkReachability reachabilityForInternetConnection];

    __weak typeof (self) weakSelf = self;

    self.networkReach.reachableBlock = ^(MLSNetworkReachability * reachability)
    {

        dispatch_async(dispatch_get_main_queue(), ^{

            switch ([reachability currentReachabilityStatus])
            {
                case NotReachable:
                {
                    [weakSelf cancelAllDownloadingOperation];
                }
                    break;
                case ReachableViaWWAN:
                {
                    if ( !self.isOnlyUseWifi && self.isAutoResume )
                    {
                        // 恢复下载

                        [weakSelf.downloadingInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, MLSDownloadOperation * _Nonnull obj, BOOL * _Nonnull stop) {

                            if ( obj.isCanAutoResume && obj.state == MLSDownloadStatePaused )
                            {
                                [weakSelf resumeDownloadWithKey:key completion:nil];
                            }
                        }];
                    }
                    else
                    {
                        // 仅在wifi下下载
                        [weakSelf cancelAllDownloadingOperation];
                    }
                }
                    break;
                case ReachableViaWiFi:
                {
                    // wifi下恢复下载

                    [weakSelf.downloadingInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, MLSDownloadOperation * _Nonnull obj, BOOL * _Nonnull stop) {

                        if ( obj.isCanAutoResume && obj.state == MLSDownloadStatePaused )
                        {
                            [weakSelf resumeDownloadWithKey:key completion:nil];
                        }
                    }];
                }
                    break;
                default:
                {
                    [weakSelf cancelAllDownloadingOperation];
                }
                    break;
            }
        });
    };

    self.networkReach.unreachableBlock = ^(MLSNetworkReachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf cancelAllDownloadingOperation];
        });
    };

    [self.networkReach startNotifier];
}
/**
 *  添加下载操作
 *
 *  @param urlStr       文件url地址
 *  @param fileName     保存本地的文件名
 *  @param fileSize     文件大小（B）
 *  @param customPara   自定义参数
 *  @param image        占位图片
 *  @param path         本地文件路径
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
                                       completion:(MLSDownloaderCompletionCallBackBlock)completion
{
    NSAssert((urlStr != nil && fileName != nil && path != nil), @"url  filename  path 不能为空");

    MLSDownloadOperation *operation = nil;

    // 检查是否是m3u8文件
    NSRange range = [urlStr rangeOfString:@"m3u8" options:NSCaseInsensitiveSearch];

    if (range.location != NSNotFound)
    {
        // 是m3u8文件,提供m3u8下载
        operation = [[MLSDownloaderM3u8Operation alloc] initWithUrlStr:urlStr fileName:fileName fileSize:fileSize fileDestinationPath:path placeHolder:imageUrl progress:progressBlock completion:completion];
        operation.customData = customPara;
    }
    else
    {
        // 不是m3u8文件，提供普通文件下载
        // 是m3u8文件,提供m3u8下载
        operation = [[MLSDownloadNomarlOperation alloc] initWithUrlStr:urlStr fileName:fileName fileSize:fileSize fileDestinationPath:path placeHolder:imageUrl progress:progressBlock completion:completion];
        operation.customData = customPara;
    }

    NSLog(@"文件存放目录 ====  %@",path);

    // 取值key (应使用url)

    if ([self.downloadingInfo valueForKey:operation.key] != nil)
    {
        operation = [self.downloadingInfo valueForKey:operation.key];

        if ( [self.downloadQueue.operations containsObject:operation] )
        {
            [operation cancel];
        }
        [self.downloadingInfo removeObjectForKey:operation.key];
        return operation;
    }

    [self.downloadQueue addOperation:operation];
    [self.downloadingInfo setObject:operation forKey:operation.key];


    [self saveDownloadStateWithCancelAllDownload:NO];

    NSLog(@"self.downloadQueue.operations   ==  \n%@",self.downloadQueue.operations);

    return operation;
}

- (void)supportBackgroundDownload
{
    if (self.downloadQueue.operations.count > 0)
    {
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:NULL];
        [session setActive:YES error:NULL];

        NSBundle *voiceBundle = [[NSBundle alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"mlsvoice" ofType:@"bundle"]];

        NSString *silenceUrlStr = [voiceBundle pathForResource:@"silence" ofType:@"mp3"];

        NSURL *silenceUrl = [[NSURL alloc] initFileURLWithPath:silenceUrlStr];
        NSError *error = nil;
        AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:silenceUrl error:&error];

        if (error != nil)
        {
            NSLog(@"%@",error);
        }

        self.audioPlayer = audioPlayer;
        [audioPlayer prepareToPlay];
        [audioPlayer setNumberOfLoops:-1];
        [audioPlayer setVolume:1];
        [audioPlayer setCurrentTime:0];
        [audioPlayer play];
    }
}
- (void)stopBackgroundDownload
{
    if (self.audioPlayer == nil)
    {
        return;
    }
    if ([self.audioPlayer isPlaying])
    {
        [self.audioPlayer stop];
    }
    self.audioPlayer = nil;
}

- (void)dealloc
{
    [self saveDownloadStateWithCancelAllDownload:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)foregroundRecoverDownloadState
{
    if (self.allowBackgroundDownload)
    {
        [self stopBackgroundDownload];
    }
    [self recoverDownloadState];
}
// 恢复上次下载的状态
- (void)recoverDownloadState
{
    [MLSDownloadAccount recoverDownloadState];

}
// 保存下载状态
- (void)saveDownloadStateWithCancelAllDownload:(BOOL)cancel
{
    if (cancel)
    {
        [self cancelAllDownloadingOperation];
    }
    [MLSDownloadAccount saveDownloadState];
}

- (void)backgroundSaveDownloadState
{
    if (self.allowBackgroundDownload)
    {
        [self supportBackgroundDownload];
        [self saveDownloadStateWithCancelAllDownload:NO];
    }
    else
    {
        [self saveDownloadStateWithCancelAllDownload:YES];
    }
}
- (void)terminateSaveDownloadState
{
    [self saveDownloadStateWithCancelAllDownload:YES];
}

// 取消当前所有下载操作
- (void)cancelAllDownloadingOperation
{

    [self.downloadingInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, MLSDownloadOperation * _Nonnull obj, BOOL * _Nonnull stop) {

        if (obj.state == MLSDownloadStateExecuting)
        {
            [obj paused];
        }
    }];
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

            if ([obj isFinished])
            {
                operation = obj;
            }
            *stop = YES;
        }
    }];
    return operation;
}


- (void)pauseDownloadWithKey:(NSString *)key completion:(MLSDownloaderOperationCallBackBlock)completion
{
    if (key == nil)
    {
        return;
    }
    MLSDownloadOperation *operation = [self.downloadingInfo valueForKey:key];

    if (operation.isReady || operation.isExecuting)
    {
        [operation paused];
    }
    if (completion != nil)
    {
        completion(operation,nil);
    }

    [self saveDownloadStateWithCancelAllDownload:NO];
    NSLog(@"self.downloadQueue.operations   ==  \n%@",self.downloadQueue.operations);
}


- (void)resumeDownloadWithKey:(NSString *)key completion:(MLSDownloaderOperationCallBackBlock)completion
{
    if (key == nil)
    {
        return;
    }

    MLSDownloadOperation *operation = [self.downloadingInfo valueForKey:key];



    MLSDownloadOperation *newOperation = [operation resume];

    // 由于重装软件之后，文件路径改变，所有需要更新文件目录
    [newOperation changeFileRootPathWithPath:[MLSDownloadFileTools saveFilePath]];

    if (newOperation == nil)
    {
        return;
    }

    [self.downloadingInfo setObject:newOperation forKey:key];


    if (completion != nil)
    {
        if (newOperation != nil && ![self.downloadQueue.operations containsObject:newOperation])
        {
            completion(newOperation, nil);
            [self.downloadQueue addOperation:newOperation];
        }
        else
        {
            NSError *error = [NSError errorWithDomain:errorDomain code:DownloadOperationErrorCodeReusmeError userInfo:nil];
            completion(nil, error);
        }
    }

    [self saveDownloadStateWithCancelAllDownload:NO];

    NSLog(@"self.downloadQueue.operations   ==  \n%@",self.downloadQueue.operations);
}


- (void)deleteDownloadWithKey:(NSString *)key completion:(MLSDownloaderOperationCallBackBlock)completion {

    if (key == nil)
    {
        return;
    }

    MLSDownloadOperation *operation = [self.downloadingInfo valueForKey:key];
    [operation cancel];
    [operation deleteFile];

    [self.downloadingInfo removeObjectForKey:key];

    if (completion != nil)
    {
        completion(operation, nil);
    }

    NSLog(@"%@",self.downloadQueue.operations);

    [self saveDownloadStateWithCancelAllDownload:NO];

    NSLog(@"self.downloadQueue.operations   ==  \n%@",self.downloadQueue.operations);
}

- (NSMutableDictionary<NSString *,MLSDownloadOperation *> *)downloadingInfo
{
    if (_downloadingInfo == nil)
    {
        _downloadingInfo = [[NSMutableDictionary alloc] init];
    }
    return _downloadingInfo;
}

- (NSArray<MLSDownloadOperation *> *)downloadingArray
{
    if (self.downloadingInfo == nil)
    {
        return nil;
    }
    return self.downloadingInfo.allValues;
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
