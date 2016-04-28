//
//  DownloadNomarlOperation.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/13.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "MLSDownloadNomarlOperation.h"
#import "MLSDownloadFileTools.h"
#import "MLSDownloaderCommon.h"

/**
 *  下载回调函数
 *
 *  @param ptr             自定义参数
 *  @param totalToDownload 总共需要下载量
 *  @param nowDownloaded   已经下载量
 *  @param totalToUpLoad   总共需要上传量
 *  @param nowUpLoaded     已经上传量
 *
 *  @return 是否成功
 */
int normalDownloadProgressFunc(void *ptr, double totalToDownload, double nowDownloaded, double totalToUpLoad, double nowUpLoaded);
/**
 *  下载写入本地函数
 *
 *  @param downloadData 下载的数据
 *  @param size         大小
 *  @param count        个数
 *  @param userdata     自定义参数
 *
 *  @return 写入本地的数据量
 */
size_t normalDownLoadPackageFunc(char *downloadData, size_t size, size_t count, void* userdata);


@interface MLSDownloadNomarlOperation()
/**
 *  C文件指针
 */
@property ( assign, nonatomic ) FILE * fp;

/**
 *  本地文件大小
 */
@property ( assign, nonatomic ) long localLength;


/**
 *  已经下载的文件长度
 */
@property ( assign, nonatomic) int64_t downloadLength;


@property (assign, nonatomic) int tempCountNetworkSpeed;

// 判断是cancel还是libcurl错误
@property (assign, nonatomic,getter=isCurlError) BOOL curlError;
/**
 *  获取需要下载的文件大小
 */
- (double)getDownloadSize;
// 检查本地文件夹，找出已经下载过的文件
- (void)checkLocalDownloadState;
// 准备curl
- (BOOL)prepareForCurl;
// 使用curl下载
- (BOOL)downloadUseCurl;

@end

@implementation MLSDownloadNomarlOperation



- (void)main
{
        @autoreleasepool
        {
                self.curlError = NO;
                [self checkLocalDownloadState];

                if (!self.isCancelled && self.state != MLSDownloadStateCompletion)
                {
                        [recursiveLock() lock];
                        self.state = MLSDownloadStateExecuting;
                        [recursiveLock() unlock];


                        if (![self checkNetworkFileIsExit])
                        {
                                [recursiveLock() lock];
                                self.state = MLSDownloadStatePaused;
                                [self cancel];
                                [recursiveLock() unlock];
                        }
                        else if ( [self prepareForCurl] )
                        {
                                if (self.state == MLSDownloadStateExecuting)
                                {
                                        [self downloadUseCurl];
                                }
                        }


                }

        }
}


// 计算网速 --> 子类实现
- (void)countNetworkSpeed
{
        NSLog(@"%@计算网速",self.fileName);
        dispatch_async(dispatch_get_main_queue(), ^{

                if (self.networkSpeedCallBackBlock != nil)
                {

                        if (self.tempCountNetworkSpeed != 0 && self.networkSpeedCallBackBlock != nil)
                        {
                                self.networkSpeedCallBackBlock(self.downloadLength - self.tempCountNetworkSpeed);
                        }

                        // 临时计算属性清零
                        self.tempCountNetworkSpeed = (int)self.downloadLength;
                }
        });
}



- (NSString *)locaPlayUrlStr
{
        if (self.state == MLSDownloadStateCompletion )
        {
                NSString *url = nil;


                NSError *error = nil;

                NSArray <NSString *>*array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.localFullPath error:&error];

                if (error != nil || array == nil || array.count == 0 )
                {
                        return nil;
                }
                else
                {
                        url = [[NSString stringWithFormat:@"file://%@/%@",self.localFullPath,self.saveFileName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }
                return url;
        }
        return nil;
}

// 检查本地文件夹，找出已经下载过的文件
- (void)checkLocalDownloadState
{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *fileSavePath = [self.localFullPath stringByAppendingPathComponent:self.saveFileName];

        BOOL isDir = NO;
        if ([fileManager fileExistsAtPath:fileSavePath isDirectory:&isDir])
        {
                if (!isDir)
                {
                        [recursiveLock() lock];
                        [self cancel];
                        self.state = MLSDownloadStateCompletion;
                        self.completionPercent = 1.0;
                        [recursiveLock() unlock];

                        dispatch_async(dispatch_get_main_queue(), ^{

                                if (self.completionCallBackBlock != nil)
                                {
                                        self.completionCallBackBlock(self,[NSURL URLWithString:[fileSavePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] ,nil);
                                        return ;
                                }
                        });
                }
        }
        else
        {
                [fileManager removeItemAtPath:fileSavePath error:NULL];
        }

}
// 准备curl
- (BOOL)prepareForCurl
{
        // Create a file to save package.
        char tempPah[1024] = {0};

        const char *cSavePath = [self.localFullPath cStringUsingEncoding:NSUTF8StringEncoding];
        const char *tempFileName = [self.tempFileName cStringUsingEncoding:NSUTF8StringEncoding];

        sprintf(tempPah, "%s/%s",cSavePath,tempFileName);

        //================断点续载===================

        FILE *fp = NULL;
        fp = fopen(tempPah, "a+b");
        self.fp = fp;

        if (fp == NULL)
        {
                self.state = MLSDownloadStatePaused;
                return NO;
        }

        long localLen = GetLocalFileLenth(fp);
        self.localLength = localLen;

        [self getDownloadSize];

        if (localLen == self.fileSize)
        {
                char savePath[1024] = {0};

                sprintf(savePath, "%s/%s",cSavePath,[self.saveFileName cStringUsingEncoding:NSUTF8StringEncoding]);
                rename(tempPah, savePath);
                [recursiveLock() lock];
                [self cancel];
                self.state = MLSDownloadStateCompletion;
                [recursiveLock() unlock];

                dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.completionCallBackBlock != nil)
                        {
                                self.completionCallBackBlock(self,[NSURL URLWithString:self.filePath],nil);
                        }
                });
                return NO;
        }

        return YES;

}
// 使用curl下载
- (BOOL)downloadUseCurl
{
        const char *packageUrl = [self.urlStr cStringUsingEncoding:NSUTF8StringEncoding];

        // Create a file to save package.
        char tempPah[1024] = {0};

        const char *cSavePath = [self.localFullPath cStringUsingEncoding:NSUTF8StringEncoding];
        const char *tempFileName = [self.tempFileName cStringUsingEncoding:NSUTF8StringEncoding];
        sprintf(tempPah, "%s/%s",cSavePath,tempFileName);

        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        // Download pacakge
        CURLcode res;
        CURL *curl = curl_easy_init();

        curl_easy_setopt(curl, CURLOPT_URL, packageUrl);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, &normalDownLoadPackageFunc);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, self);

        curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);
        curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, &normalDownloadProgressFunc);
        curl_easy_setopt(curl, CURLOPT_PROGRESSDATA, self);

        curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
        curl_easy_setopt(curl, CURLOPT_LOW_SPEED_LIMIT, 1L);
        curl_easy_setopt(curl, CURLOPT_LOW_SPEED_TIME, 5L);

        curl_easy_setopt(curl, CURLOPT_HEADER, 0L);
        curl_easy_setopt(curl, CURLOPT_NOBODY, 0L);

        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
        curl_easy_setopt(curl, CURLOPT_RESUME_FROM, self.localLength);

        // 不打断线程等待
        curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);



        curl_easy_setopt(curl, CURLOPT_USERAGENT,"User-Agent:Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; en-us) AppleWebKit/534.50 (KHTML, like Gecko) Version/5.1 Safari/534.50");

        res = curl_easy_perform(curl);

        curl_easy_cleanup(curl);

        // CURLE_WRITE_ERROR  // 调用pause方法取消下载
        // CURLE_OK  正常下载完
        // CURLE_COULDNT_CONNECT  无网络连接
        // CURLE_OPERATION_TIMEDOUT  正在下载中，断掉网络
        // CURLE_RANGE_ERROR  传入的range不对

        if ( self.fp != NULL )
        {
                fclose(self.fp);
                self.fp = NULL;
        }

        curl = NULL;

        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

        if (res == CURLE_OK)
        {
                char savePath[1024] = {0};

                sprintf(savePath, "%s/%s",cSavePath,[self.saveFileName cStringUsingEncoding:NSUTF8StringEncoding]);

                [recursiveLock() lock];
                rename(tempPah, savePath);
                [self cancel];
                self.state = MLSDownloadStateCompletion;
                [recursiveLock() unlock];

                dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.completionCallBackBlock != nil)
                        {
                                self.completionCallBackBlock(self,[NSURL URLWithString:self.filePath],nil);
                        }
                });

                return YES;
        }
        else
        {
                [recursiveLock() lock];
                self.state = MLSDownloadStatePaused;
                [recursiveLock() unlock];

                NSString *errorReson = [NSString stringWithFormat:@"error Code CURLcode = %d",res];
                NSInteger errorCode = res;

                if (self.isCancelled || !self.isCurlError)
                {
                        errorReson = @"已取消";
                        errorCode = DownloadOperationErrorCodeCancel;
                }
                else if (res == CURLE_WRITE_ERROR)
                {
                        errorCode = DownloadOperationErrorCodeCacheError;
                        errorReson = @"空间不足";
                }

                NSError *error = [NSError errorWithDomain:errorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey : errorReson}];



                dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.completionCallBackBlock != nil)
                        {
                                self.completionCallBackBlock(self,nil,error);
                        }
                });
                return NO;
        }

}
- (double)getDownloadSize
{
        if (self.urlStr == nil)
        {
                return 0;
        }

        const char *url = [self.urlStr cStringUsingEncoding:NSUTF8StringEncoding];

        CURL* curl;
        CURLcode res;
        double size = 0.0;

        curl = curl_easy_init();
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_NOBODY, 1L);
        curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, convenient_func);
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
        // 不打断线程sleep
        curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
        curl_easy_setopt(curl, CURLOPT_USERAGENT,"User-Agent:Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; en-us) AppleWebKit/534.50 (KHTML, like Gecko) Version/5.1 Safari/534.50");

        res = curl_easy_perform(curl);

        [recursiveLock() lock];

        res = curl_easy_getinfo(curl, CURLINFO_CONTENT_LENGTH_DOWNLOAD, &size);

        [recursiveLock() unlock];

        curl_easy_cleanup(curl);

        if ( self.fileSize <= size && size > 0 )
        {
                self.fileSize = size;
        }

        if(res != CURLE_OK)
        {
                fprintf(stderr, "curl_easy_getinfo() failed: %s\n", curl_easy_strerror(res));
                NSLog(@"curl_easy_getinfo() error");
                return 0;
        }



        return size;
}
- (BOOL)checkNetworkFileIsExit
{
        if (self.urlStr == nil)
        {
                return NO;
        }

        const char *url = [self.urlStr cStringUsingEncoding:NSUTF8StringEncoding];

        CURL* curl;
        CURLcode res;
        int responseCode = 0;

        curl = curl_easy_init();
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_NOBODY, 1L);
        curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, convenient_func);
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
        // 不打断线程sleep
        curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
        curl_easy_setopt(curl, CURLOPT_USERAGENT,"User-Agent:Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; en-us) AppleWebKit/534.50 (KHTML, like Gecko) Version/5.1 Safari/534.50");

        res = curl_easy_perform(curl);

        [recursiveLock() lock];

        res = curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &responseCode);

        [recursiveLock() unlock];

        curl_easy_cleanup(curl);

        if( res != CURLE_OK )
        {
                fprintf(stderr, "checkNetworkFileIsExit failed: %s\n", curl_easy_strerror(res));
                NSLog(@"checkNetworkFileIsExit error");
        }

        // 说明文件不存在
        if ( responseCode >= 400 || res!= CURLE_OK )
        {


                [recursiveLock() lock];
                [self cancel];
                self.state = MLSDownloadStatePaused;
                [recursiveLock() unlock];

                NSString *errorReson = @"网络文件不存在";

                NSError *error = [NSError errorWithDomain:errorDomain code:DownloadOperationErrorCodeFileIsNotExit userInfo:@{NSLocalizedDescriptionKey : errorReson}];

                dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.completionCallBackBlock != nil)
                        {
                                self.completionCallBackBlock(self,nil,error);
                        }
                });

                return NO;
        }

        return YES;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
        if (self = [super initWithCoder:aDecoder])
        {
                self.downloadLength = [aDecoder decodeInt64ForKey:@"downloadLength"];
        }
        return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder
{
        [super encodeWithCoder:encoder];
        [encoder encodeInt64:self.downloadLength forKey:@"downloadLength"];
}
- (id)copyWithZone:(NSZone *)zone
{
        MLSDownloadNomarlOperation * theCopy = nil;

        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];

        if (data)
        {
                theCopy = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                theCopy.downloadLength = self.downloadLength;
        }

        return theCopy;
}
- (id)mutableCopyWithZone:(NSZone *)zone
{
        MLSDownloadNomarlOperation * theCopy = nil;

        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];

        if (data)
        {
                theCopy = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                theCopy.downloadLength = self.downloadLength;
        }

        return theCopy;
}
@end
// ===================C method =====================

int normalDownloadProgressFunc(void *ptr, double totalToDownload, double nowDownloaded, double totalToUpLoad, double nowUpLoaded)
{
        if ( ![[UIApplication sharedApplication] isNetworkActivityIndicatorVisible])
        {
                 [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        }
        if (totalToDownload == 0 || nowDownloaded == 0 || totalToDownload / nowDownloaded == 1)
        {
                return 0;
        }

        //    static int percent = 0;
        MLSDownloadNomarlOperation *operation = (__bridge MLSDownloadNomarlOperation *)ptr;

        float tmp = 0;
        long localLen = (long)operation.localLength;


        [recursiveLock() lock];
        operation.downloadLength = nowDownloaded + localLen;
        [recursiveLock() unlock];

        if ( totalToDownload > 0 )
        {
                tmp = (float)((nowDownloaded + (double)localLen) / (totalToDownload + (double)localLen));
                if (tmp == 0)
                {
                        tmp = operation.completionPercent;
                }
        }
        operation.completionPercent = tmp;

        dispatch_async(dispatch_get_main_queue(), ^{

                if ( operation.progressCallBackBlock != nil )
                {
                        operation.progressCallBackBlock(operation,tmp);
                }
        });
        
        return 0;
}

size_t normalDownLoadPackageFunc(char *downloadData, size_t size, size_t count, void* userdata)
{
        [recursiveLock() lock];
        
        MLSDownloadNomarlOperation *operation = (__bridge MLSDownloadNomarlOperation *)userdata;
        
        if (!operation.fp)
        {
                operation.state = MLSDownloadStatePaused;
                operation.curlError = NO;
                return 0;
        }

        size_t writeData = fwrite( downloadData, size , count, operation.fp );
        
        
        
        if (operation.isCancelled || operation.state != MLSDownloadStateExecuting)
        {
                [recursiveLock() unlock];
                operation.curlError = NO;
                return 0;
        }
        operation.curlError = (writeData != size * count);
        [recursiveLock() unlock];


        return writeData;
}

