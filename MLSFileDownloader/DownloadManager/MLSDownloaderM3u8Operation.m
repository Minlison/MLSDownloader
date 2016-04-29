//
//  DownloaderM3u8Operation.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/8.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "MLSDownloaderM3u8Operation.h"
#import "NSFileManager+MLSFileManager.h"
#import "MLSDownloaderCommon.h"
int m3u8ProgressFunc(void *ptr, double totalToDownload, double nowDownloaded, double totalToUpLoad, double nowUpLoaded);
size_t m3u8downLoadPackage(char *downloadData, size_t size, size_t count, void* userdata);

@interface MLSDownloaderM3u8SegmentInfo : NSObject <NSCoding, NSCopying, NSMutableCopying>

@property (assign, nonatomic) NSInteger index;
@property (assign, nonatomic) CGFloat duration;
@property (copy, nonatomic) NSString *url;

@end


@implementation MLSDownloaderM3u8SegmentInfo

- (void)dealloc
{
        NSLog(@"DownloaderM3u8SegmentInfo dealloc");
}
//===========================================================
//  Keyed Archiving
//
//===========================================================
- (void)encodeWithCoder:(NSCoder *)encoder
{
        [encoder encodeInteger:self.index forKey:@"index"];
        [encoder encodeFloat:self.duration forKey:@"duration"];
        [encoder encodeObject:self.url forKey:@"url"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
        self = [super init];
        if (self)
        {
                self.index = [decoder decodeIntegerForKey:@"index"];
                self.duration = [decoder decodeFloatForKey:@"duration"];
                self.url = [decoder decodeObjectForKey:@"url"];
        }
        return self;
}
- (id)copyWithZone:(NSZone *)zone
{
        MLSDownloaderM3u8SegmentInfo * theCopy = [[[self class] allocWithZone:zone] init];

        if (theCopy)
        {
                theCopy.index = self.index;
                theCopy.duration = self.duration;
                theCopy.url = self.url.copy;
        }

        return theCopy;
}
- (id)mutableCopyWithZone:(NSZone *)zone
{
        MLSDownloaderM3u8Operation * theCopy = nil;

        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];

        if (data)
        {
                theCopy = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        return theCopy;
}
@end



#define _M3U8_SEGMENT_NAME_  @"id"

#define _TS_Downloading_    0x01



@interface MLSDownloaderM3u8Operation()
{
        char ts_downlad_flag;
}
/**
 *  记录当前正在使用的curl
 */
@property (assign, nonatomic) CURL *curl;
/**
 *  ts文件信息
 */
@property (assign, nonatomic) NSInteger totalTsCount;
@property (assign, nonatomic) NSInteger currentDownloadTsIndex;

@property (assign, nonatomic) FILE *fp;

/**
 *  m3u8文件信息记录
 */
@property (copy, nonatomic) NSString *header;
@property (copy, nonatomic) NSString *footer;

// 保存m3u8的列表信息
@property (strong, nonatomic, readwrite) NSArray <MLSDownloaderM3u8SegmentInfo *>*segmentInfoList;

// 等待下载的数组
@property (strong, nonatomic, readwrite) NSMutableArray <MLSDownloaderM3u8SegmentInfo *>*waitingDownloadArray;

// 计算网速时 下载长度
@property ( assign, nonatomic) int64_t downloadLength;

// 判断是cancel还是libcurl错误
@property (assign, nonatomic,getter=isCurlError) BOOL curlError;

@end
@implementation MLSDownloaderM3u8Operation



- (NSString *)locaPlayUrlStr {

        if (self.state == MLSDownloadStateCompletion)
        {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                NSString *url = nil;

                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)
                {
                        url = [[NSString stringWithFormat:@"http://127.0.0.1:%d/%@/%@",portNum,self.fileName,realM3u8TextLocalStr] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
                }
                else
                {
                        url = [[NSString stringWithFormat:@"http://127.0.0.1:%d/%@/%@",portNum,self.fileName,realM3u8TextLocalStr] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }
#pragma clang diagnostic pop
                return url;
        }
        return nil;
}



- (void)main
{
        @autoreleasepool
        {
                ts_downlad_flag = 0;

                if ( [self analyseVideoUrl:self.urlStr] )
                {
                        self.curlError = NO;

                        if (self.isCancelled)
                        {
                                return;
                        }
                        // 检查本地文件
                        if ( [self checkLocalDownloadState] )
                        {

                                // flag 开始下载
                                ts_downlad_flag |= _TS_Downloading_;

                                [recursiveLock() lock];
                                self.state = MLSDownloadStateExecuting;
                                [recursiveLock() unlock];

                                [self startDownloadM3u8Video];

                                if (self.isCancelled)
                                {
                                        ts_downlad_flag = 0;
                                        return;
                                }
                                [recursiveLock() lock];
                                [self createLocalM3U8File];
                                [recursiveLock() unlock];
                                
                                while ( self.state == MLSDownloadStateExecuting )
                                {
                                        continue;
                                }
                        }
                        else
                        {
                                [recursiveLock() lock];

                                [self cancel];
                                self.state = MLSDownloadStateCompletion;
                                [self createLocalM3U8File];

                                [recursiveLock() unlock];

                                dispatch_sync(dispatch_get_main_queue(), ^{

                                        if (self.completionCallBackBlock != nil)
                                        {
                                                self.completionCallBackBlock(self,[NSURL URLWithString:[self.localFullPath stringByAppendingPathComponent:realM3u8TextLocalStr]],nil);
                                        }
                                });
                        }


                }
                else
                {
                        [recursiveLock() lock];
                        self.state = MLSDownloadStatePaused;
                        [recursiveLock() unlock];
                }

                ts_downlad_flag = 0;

        }
}


// 解析url地址，找出ts片段的url地址
- (BOOL)analyseVideoUrl:(NSString *)videoUrl
{

        if ([videoUrl rangeOfString:@"%"].location == NSNotFound)
        {
                videoUrl = [videoUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }

        NSRange rangeOfM3U8 = [videoUrl rangeOfString:@"m3u8"];

        if(rangeOfM3U8.location == NSNotFound)
        {

                NSError *err = [NSError errorWithDomain:errorDomain code:DownloadOperationErrorCodeNotM3U8Url userInfo:nil];

                dispatch_async(dispatch_get_main_queue(), ^{

                        if (self.completionCallBackBlock && err != nil)
                        {
                                __weak typeof (self) weakSelf = self;
                                self.completionCallBackBlock(self, [NSURL URLWithString:weakSelf.filePath], err);
                        }
                });

                return NO;
        }

        NSURL *url = [NSURL URLWithString:videoUrl];
        NSError *error = nil;
        NSStringEncoding encoding;
        NSString *data = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:&error];

        if(!data || error != nil){

                dispatch_async(dispatch_get_main_queue(), ^{

                        if (self.completionCallBackBlock) {
                                __weak typeof (self) weakSelf = self;
                                self.completionCallBackBlock(self, [NSURL URLWithString:weakSelf.filePath], error);
                        }
                });

                return NO;
        }

        NSString *remainData = data;

        //    NSLog(@"original m3u8 list data is %@",data);

        //    NSRange httpRange = [remainData rangeOfString:@"http"];
        //    if(httpRange.location == NSNotFound){
        //        //暂时只针对腾讯视频
        //        NSString *newString = @"av";
        //        NSRange range = [videoUrl rangeOfString:@"playlist.av.m3u8"];
        //
        //        if(range.location != NSNotFound){
        //            newString = [NSString stringWithFormat:@"%@%@",[videoUrl substringToIndex:range.location],@"av"];
        //        }
        //        remainData = [remainData stringByReplacingOccurrencesOfString:@"av" withString:newString];
        //    }
        // 提取url地址,header 和footer
        NSMutableArray *segments = [NSMutableArray array];
        NSRange segmentRange = [remainData rangeOfString:@"#EXTINF:"];

        // 提取header
        if (segmentRange.location != NSNotFound)
        {

                self.header = [remainData substringToIndex:segmentRange.location];
        }

        NSInteger segmentIndex = 0;
        NSInteger totalSeconds = 0;
        NSRange linkRangeBegin = NSMakeRange(0, 0);
        NSRange linkRangeEnd = NSMakeRange(0, 0);

        while (segmentRange.location != NSNotFound) {

                MLSDownloaderM3u8SegmentInfo *segment = [[MLSDownloaderM3u8SegmentInfo alloc] init];
                //读取片段时长
                NSRange commaRange = [remainData rangeOfString:@","];
                NSString *value = [remainData substringWithRange:NSMakeRange(segmentRange.location + [@"#EXTINF:" length], commaRange.location -(segmentRange.location + [@"#EXTINF:" length]))];
                segment.duration = [value floatValue];
                totalSeconds += segment.duration;
                remainData = [remainData substringFromIndex:commaRange.location];
                //读取片段url
                linkRangeBegin = [remainData rangeOfString:@"http"];
                linkRangeEnd = [remainData rangeOfString:@"#"];
                NSString *linkurl = [remainData substringWithRange:NSMakeRange(linkRangeBegin.location, linkRangeEnd.location - linkRangeBegin.location)];

                linkurl = [linkurl stringByReplacingOccurrencesOfString:@"\n" withString:@""];


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                if ([UIDevice currentDevice].systemVersion.integerValue > 8.0) {

                        segment.url = [linkurl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
                }else {

                        segment.url = [linkurl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

                }
#pragma clang diagnostic pop
                segment.index = segmentIndex;

                segmentIndex++;
                [segments addObject:segment];
                remainData = [remainData substringFromIndex:linkRangeEnd.location];
                segmentRange = [remainData rangeOfString:@"#EXTINF:"];
        }

        self.footer = remainData;

        self.segmentInfoList = segments.copy;
        self.waitingDownloadArray = [[NSMutableArray alloc] initWithArray:segments];
        self.totalTsCount = segments.count;

        [self createLocalM3U8File];

        return YES;
}

- (void)createLocalM3U8File
{

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSLog(@"%@",self.locaPlayUrlStr);
        BOOL dir = NO;

        NSString *tempFilePath = [self.localFullPath stringByAppendingPathComponent:tmpM3u8TextLoacalStr];
        NSString *realFilePath = [self.localFullPath stringByAppendingPathComponent:realM3u8TextLocalStr];

        if ([fileManager fileExistsAtPath:tempFilePath isDirectory:&dir] && self.state == MLSDownloadStateCompletion )
        {
                if (dir == NO)
                {
                        NSError *error = nil;
                        [fileManager moveItemAtPath:tempFilePath toPath:realFilePath error:&error];

                        error = nil;
                        NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.localFullPath error:&error];
                        for (NSString *tempFilePath in contents)
                        {
                                // 如果下载完成后，存在临时文件，就全部删除
                                if ([tempFilePath hasSuffix:@".tmp"])
                                {
                                        [fileManager removeItemAtPath:tempFilePath error:NULL];
                                }
                        }


                        if (error == nil)
                        {
                                return;
                        }
                }
        }
        else if( self.segmentInfoList && self.segmentInfoList.count == self.totalTsCount )
        {
                NSString *fullPath = nil;
                if ( self.state == MLSDownloadStateCompletion )
                {
                        fullPath = tempFilePath;
                }
                else
                {
                        fullPath = realFilePath;
                }

                // 创建文件头部
                NSString* head = self.header;
                NSString* segmentPrefix = [NSString stringWithFormat:@"http://127.0.0.1:54321/%@/",self.fileName];

                NSInteger count = [self.segmentInfoList count];

                // 填充片段数据
                for(int i = 0;i<count;i++)
                {
                        // _M3U8_SEGMENT_NAME_
                        NSString *filename = [NSString stringWithFormat:@"%@%d.ts",_M3U8_SEGMENT_NAME_,i];

                        MLSDownloaderM3u8SegmentInfo *segInfo = [self.segmentInfoList objectAtIndex:i];

                        if (segInfo == nil)
                        {

                                NSError *error = [NSError errorWithDomain:errorDomain code:DownloadOperationErrorCodeCreateM3U8FileError userInfo:nil];

                                dispatch_async(dispatch_get_main_queue(), ^{

                                        if (self.completionCallBackBlock != nil)
                                        {
                                                self.completionCallBackBlock(self,[NSURL URLWithString:self.filePath],error);
                                        }
                                });

                                return;
                        }
                        NSString *length = [NSString stringWithFormat:@"#EXTINF:%f,\n",segInfo.duration];
                        NSString *url = [segmentPrefix stringByAppendingString:filename];
                        head = [NSString stringWithFormat:@"%@%@%@\n",head,length,url];
                }

                // 创建尾部
                NSString* end = self.footer;
                head = [head stringByAppendingString:end];
                NSMutableData *writer = [[NSMutableData alloc] init];
                [writer appendData:[head dataUsingEncoding:NSUTF8StringEncoding]];
                [writer writeToFile:fullPath atomically:YES];
        }
}


// 检查本地文件夹，找出已经下载过的文件
- (BOOL)checkLocalDownloadState {

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSMutableArray *downloadedArray = [NSMutableArray array];
        self.currentDownloadTsIndex = 0;
        // 遍历已经下载过的ts视频,并查找是否有临时文件
        [fileManager enumratePath:self.localFullPath options:NSDirectoryEnumerationSkipsSubdirectoryDescendants attributes:@{MLSFileManagerEnumrateTypeKey : @"ts"} completionBlock:^(NSString *fileUrl, NSString *fileName, NSError *error) {

                if (error != nil)
                {

                        NSLog(@"fileManager enumration error == %@",error);

                }
                else
                {
                        NSRange range = [fileName rangeOfString:@"."];
                        NSRange idRange = [fileName rangeOfString:_M3U8_SEGMENT_NAME_];

                        if ( idRange.location != NSNotFound && range.location != NSNotFound )
                        {

                                NSString *num = [fileName substringWithRange:NSMakeRange((idRange.location + idRange.length), (range.location - idRange.length))];

                                NSLog(@"%@",num);
                                NSInteger index = [num integerValue];

                                // 判断是否是临时文件，如果是临时文件，不记录
                                NSRange tmpRange = [fileName rangeOfString:@"tmp"];

                                if (tmpRange.location == NSNotFound )
                                {
                                        [downloadedArray addObjectsFromArray:[self.waitingDownloadArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.index = %d",index]]];
                                }
                        }

                        NSLog(@"检查本地文件%ld",self.currentDownloadTsIndex);

                        self.currentDownloadTsIndex++;
                }
        }];

        [self.waitingDownloadArray removeObjectsInArray:downloadedArray];

        return self.waitingDownloadArray.count != 0;
}
// 检查网络上是否有资源
- (BOOL)checkNetworkFileIsExit:(NSString *)urlString
{
        if (urlString == nil)
        {
                return NO;
        }

        const char *url = [urlString cStringUsingEncoding:NSUTF8StringEncoding];



        CURL* curl;
        CURLcode res = CURL_LAST;
        int responseCode = 0;



        curl = curl_easy_init();
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_NOBODY, 1L);
        curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, convenient_func);
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
        // 不打断线程sleep
        curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
        curl_easy_setopt(curl, CURLOPT_USERAGENT,"User-Agent:Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; en-us) AppleWebKit/534.50 (KHTML, like Gecko) Version/5.1 Safari/534.50");

        if (self.isCancelled)
        {
                [recursiveLock() lock];
                curl_easy_cleanup(curl);
                [recursiveLock() unlock];

                return NO;
        }

        [recursiveLock() lock];
        self.curl = curl;
        [recursiveLock() unlock];

        if (self.curl && !self.isCancelled && !self.isPaused)
        {
                res = curl_easy_perform(curl);
        }



        [recursiveLock() lock];
        if (self.curl)
        {
                res = curl_easy_getinfo(self.curl, CURLINFO_RESPONSE_CODE, &responseCode);
        }
        [recursiveLock() unlock];

        
        [recursiveLock() lock];
        if (self.curl)
        {
                curl_easy_cleanup(self.curl);
                self.curl = NULL;
        }
        [recursiveLock() unlock];

        if (self.isCancelled)
        {
                return NO;
        }

        // 说明文件不存在
        if ( responseCode >= 400 || res!= CURLE_OK )
        {
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
// 开始下载
- (void)startDownloadM3u8Video
{

        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

        // 等待上一个ts下载完成
        while ( (ts_downlad_flag & _TS_Downloading_ ) && self.state == MLSDownloadStateExecuting )
        {

                MLSDownloaderM3u8SegmentInfo *segment = self.waitingDownloadArray.firstObject;

                if (segment == nil)
                {
                        ts_downlad_flag &= (~_TS_Downloading_);

                        [recursiveLock() lock];

                        [self cancel];
                        self.state = MLSDownloadStateCompletion;
                        [self createLocalM3U8File];

                        [recursiveLock() unlock];

                        dispatch_async(dispatch_get_main_queue(), ^{
                                if (self.completionCallBackBlock != nil)
                                {
                                        self.completionCallBackBlock(self,[NSURL URLWithString:[self.localFullPath stringByAppendingPathComponent:realM3u8TextLocalStr]],nil);
                                }
                        });

                        break;
                }

                // Create a file to save package.
                char tempPath[1024] = {0};
                char realPath[1024] = {0};
                const char *cSavePath = [self.localFullPath cStringUsingEncoding:NSUTF8StringEncoding];

                sprintf(tempPath, "%s/%s%ld.ts.tmp",cSavePath,[_M3U8_SEGMENT_NAME_ cStringUsingEncoding:NSUTF8StringEncoding],segment.index);
                sprintf(realPath, "%s/%s%ld.ts",cSavePath,[_M3U8_SEGMENT_NAME_ cStringUsingEncoding:NSUTF8StringEncoding],segment.index);
                //================断点续载===================

                [recursiveLock() lock];
                FILE *fp = NULL;
                fp = fopen(tempPath, "a+b");
                self.fp = fp;

                if (fp == NULL)
                {
                        ts_downlad_flag &= (~_TS_Downloading_);
                        NSString *errorReson = [NSString stringWithFormat:@"文件路径不可访问"];
                        NSError *error = [NSError errorWithDomain:errorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : errorReson}];

                        dispatch_async(dispatch_get_main_queue(), ^{
                                if (self.completionCallBackBlock != nil)
                                {
                                        self.completionCallBackBlock(self,nil,error);
                                }
                        });
                        break;
                }

                long localLen = GetLocalFileLenth(fp);
                [recursiveLock() unlock];

                if (![self checkNetworkFileIsExit:segment.url] )
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
                        ts_downlad_flag &= (~_TS_Downloading_);
                        break;
                }
                else if ( self.currentDownloadTsIndex <= self.totalTsCount )
                {

                        NSLog(@"self.currentDownloadTsIndex == %ld",(long)segment.index);
                        NSLog(@"current download url %@",segment.url);

                        if (self.waitingDownloadArray.count > 0)
                        {
                                const char *packageUrl = [segment.url cStringUsingEncoding:NSUTF8StringEncoding];

                                // Download pacakge
                                CURLcode res = CURL_LAST;
                                CURL *curl = curl_easy_init();

                                curl_easy_setopt(curl, CURLOPT_URL, packageUrl);
                                curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, &m3u8downLoadPackage);
                                curl_easy_setopt(curl, CURLOPT_WRITEDATA, self);

                                curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);
                                curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, &m3u8ProgressFunc);
                                curl_easy_setopt(curl, CURLOPT_PROGRESSDATA, self);

                                curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
                                curl_easy_setopt(curl, CURLOPT_LOW_SPEED_LIMIT, 1L);
                                curl_easy_setopt(curl, CURLOPT_LOW_SPEED_TIME, 5L);

                                curl_easy_setopt(curl, CURLOPT_HEADER, 0L);
                                curl_easy_setopt(curl, CURLOPT_NOBODY, 0L);

                                curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
                                curl_easy_setopt(curl, CURLOPT_RESUME_FROM, localLen);

                                // 不打断线程等待
                                curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);



                                curl_easy_setopt(curl, CURLOPT_USERAGENT,"User-Agent:Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; en-us) AppleWebKit/534.50 (KHTML, like Gecko) Version/5.1 Safari/534.50");

                                [recursiveLock() lock];
                                self.curl = curl;
                                [recursiveLock() unlock];

                                if (self.isCancelled)
                                {
                                        [recursiveLock() lock];
                                        if (self.curl)
                                        {
                                                curl_easy_cleanup(self.curl);
                                                self.curl = NULL;
                                                curl = NULL;
                                        }
                                        [recursiveLock() unlock];
                                        return;
                                }

                                if (self.curl && !self.isCancelled && !self.isPaused)
                                {
                                        res = curl_easy_perform(curl);
                                }

                                
                                [recursiveLock() lock];

                                if (self.curl)
                                {
                                        curl_easy_cleanup(self.curl);
                                        self.curl = NULL;
                                        curl = NULL;
                                }
                                
                                [recursiveLock() unlock];

                                // CURLE_WRITE_ERROR  // 调用pause方法取消下载
                                // CURLE_OK  正常下载完
                                // CURLE_COULDNT_CONNECT  无网络连接
                                // CURLE_OPERATION_TIMEDOUT  正在下载中，断掉网络
                                // CURLE_RANGE_ERROR  传入的range不对
                                [recursiveLock() lock];
                                if ( self.fp != NULL )
                                {
                                        fclose(self.fp);
                                        self.fp = NULL;
                                }
                                [recursiveLock() unlock];

                                curl = NULL;

                                if (res == CURLE_OK)
                                {
                                        [recursiveLock() lock];
                                        rename(tempPath, realPath);
                                        self.currentDownloadTsIndex++;
                                        if (self.waitingDownloadArray.count > 0)
                                        {
                                                [self.waitingDownloadArray removeObjectAtIndex:0];
                                        }
                                        [recursiveLock() unlock];
                                        continue;
                                }
                                else
                                {
                                        [self cancel];

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
                                                errorReson = @"空间不足";
                                                errorCode = DownloadOperationErrorCodeCacheError;
                                        }

                                        NSError *error = [NSError errorWithDomain:errorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey : errorReson}];



                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                if (self.completionCallBackBlock != nil)
                                                {
                                                        self.completionCallBackBlock(self,nil,error);
                                                }
                                        });
                                        ts_downlad_flag &= (~_TS_Downloading_);
                                        break;
                                }
                        }
                        else
                        {
                                [recursiveLock() lock];

                                [self cancel];
                                self.state = MLSDownloadStateCompletion;
                                [self createLocalM3U8File];

                                [recursiveLock() unlock];

                                dispatch_async(dispatch_get_main_queue(), ^{
                                        if (self.completionCallBackBlock != nil)
                                        {
                                                self.completionCallBackBlock(self,[NSURL URLWithString:[self.localFullPath stringByAppendingPathComponent:realM3u8TextLocalStr]],nil);
                                        }
                                });
                        }


                }
                else
                {
                        [recursiveLock() lock];

                        [self cancel];
                        self.state = MLSDownloadStateCompletion;
                        [self createLocalM3U8File];

                        [recursiveLock() unlock];

                        dispatch_async(dispatch_get_main_queue(), ^{
                                if (self.completionCallBackBlock != nil)
                                {
                                        self.completionCallBackBlock(self,[NSURL URLWithString:[self.localFullPath stringByAppendingPathComponent:realM3u8TextLocalStr]],nil);
                                }
                        });
                }
        }
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

}

//===========================================================
//  Keyed Archiving
//
//===========================================================

- (id)copyWithZone:(NSZone *)zone
{
        MLSDownloaderM3u8Operation * theCopy = [[[self class] allocWithZone:zone] init];

        if (theCopy)
        {
                theCopy.totalTsCount = self.totalTsCount;
                theCopy.currentDownloadTsIndex = self.currentDownloadTsIndex;
                theCopy.segmentInfoList = self.segmentInfoList.copy;
                theCopy.waitingDownloadArray = self.waitingDownloadArray.copy;
                theCopy.header = self.header.copy;
                theCopy.footer = self.footer.copy;
        }

        return theCopy;
}
- (id)mutableCopyWithZone:(NSZone *)zone
{
        MLSDownloaderM3u8Operation * theCopy = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
        if (data)
        {
                theCopy = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                theCopy.totalTsCount = self.totalTsCount;
                theCopy.currentDownloadTsIndex = self.currentDownloadTsIndex;
                theCopy.segmentInfoList = self.segmentInfoList.mutableCopy;
                theCopy.waitingDownloadArray = self.waitingDownloadArray.mutableCopy;
                theCopy.header = self.header.mutableCopy;
                theCopy.footer = self.footer.mutableCopy;
        }
        return theCopy;
}
@end



// ===================C method =====================


int m3u8ProgressFunc(void *ptr, double totalToDownload, double nowDownloaded, double totalToUpLoad, double nowUpLoaded)
{
        if ( ![[UIApplication sharedApplication] isNetworkActivityIndicatorVisible])
        {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        }

        if (totalToDownload == 0 || nowDownloaded == 0 || totalToDownload / nowDownloaded == 1)
        {
                return 0;
        }
        // static int percent = 0;
        MLSDownloaderM3u8Operation *operation = (__bridge MLSDownloaderM3u8Operation *)ptr;

        
        CGFloat onePercent = 1.0 / operation.totalTsCount;
        
        if (operation.currentDownloadTsIndex >= operation.totalTsCount)
        {
                operation.currentDownloadTsIndex = operation.totalTsCount;
        }

        double speed = 0;
        if (curl_easy_getinfo(operation.curl, CURLINFO_SPEED_DOWNLOAD,&speed) == CURLE_OK)
        {
                if ( operation.networkSpeedCallBackBlock != nil )
                {
                        operation.networkSpeedCallBackBlock(speed);
                }
        }
        
        CGFloat percent = operation.currentDownloadTsIndex * onePercent + ( nowDownloaded * 1.0 / totalToDownload ) * onePercent;
        
        operation.completionPercent = percent;

        dispatch_async(dispatch_get_main_queue(), ^{
                
                if (operation.progressCallBackBlock != nil  )
                {
                        operation.progressCallBackBlock(operation,percent);
                }
        });
        
        return 0;
}
size_t m3u8downLoadPackage(char *downloadData, size_t size, size_t count, void* userdata)
{
        [recursiveLock() lock];
        
        MLSDownloaderM3u8Operation *operation = (__bridge MLSDownloaderM3u8Operation *)userdata;
        
        if (!operation.fp)
        {
                operation.state = MLSDownloadStatePaused;
                operation.curlError = NO;
                [recursiveLock() unlock];
                return 0;
        }
        
        size_t writeData = fwrite(downloadData, size , count, operation.fp);

        operation.downloadLength += writeData;

        if (operation.isCancelled || operation.state != MLSDownloadStateExecuting )
        {
                [recursiveLock() unlock];
                operation.curlError = NO;
                return 0;
        }
        operation.curlError = (writeData != size * count);
        [recursiveLock() unlock];
        
        return writeData;
}

// ===================C method =====================

