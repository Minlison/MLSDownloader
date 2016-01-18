//
//  DownloaderM3u8Operation.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/8.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "MLSDownloaderM3u8Operation.h"
#import "NSMutableArray+MLSSafeAccess.h"
#import "NSFileManager+MLSFileManager.h"
#import "MLSDownloaderSessionManager.h"



@interface MLSDownloaderM3u8SegmentInfo : NSObject <NSCoding>

@property (assign, nonatomic) NSInteger index;
@property (assign, nonatomic) CGFloat duration;
@property (copy, nonatomic) NSString *url;

@end


@implementation MLSDownloaderM3u8SegmentInfo

- (void)dealloc {
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
    if (self) {
        self.index = [decoder decodeIntegerForKey:@"index"];
        self.duration = [decoder decodeFloatForKey:@"duration"];
        self.url = [decoder decodeObjectForKey:@"url"];
    }
    return self;
}
@end



#define _M3U8_SEGMENT_NAME_  @"id"
#define _M3U8_LOCAL_PLAY_NAME @"movie"

@interface MLSDownloaderM3u8Operation() <NSXMLParserDelegate> {
    BOOL barraryLock;
    NSInteger tempCountNetworkSpeed;
    // 标记每个ts是否下载完成
    BOOL tsDownloadError;
    BOOL finishedInfo;
}
// 下载信息
@property (copy, nonatomic, readwrite) NSString *fileTsPath;

// 保存m3u8的列表信息
@property (strong, nonatomic, readwrite) NSArray <MLSDownloaderM3u8SegmentInfo *>*segmentInfoList;

// 等待下载的数组
@property (strong, nonatomic, readwrite) NSMutableArray <MLSDownloaderM3u8SegmentInfo *>*waitingDownloadArray;

// 当前正在下载的task
@property (strong, nonatomic, readwrite) NSURLSessionDownloadTask *currentDownloadTask;

// ts文件信息
@property (assign, nonatomic, readwrite) NSInteger totalTsCount;
@property (assign, nonatomic, readwrite) NSInteger currentDownloadTsIndex;


// m3u8文件记录
@property (copy, nonatomic, readwrite) NSString *header;
@property (copy, nonatomic, readwrite) NSString *footer;

@property (copy, nonatomic, readwrite) NSString *tempFileName;
@property (strong, nonatomic) NSXMLParser *xmlParser;

@end
@implementation MLSDownloaderM3u8Operation

- (instancetype)initWithUrlStr:(NSString *)urlStr
                      fileName:(NSString *)fileName
                      fileSize:(CGFloat)fileSize
           fileDestinationPath:(NSString *)path
                   placeHolder:(UIImage *)placeHolder
                      progress:(MLSDownloaderProgressCallBackBlock)progressBlock
                    completion:(MLSDownloaderCompletionCallBackBlock)completion {
    
    if (self = [super initWithUrlStr:urlStr fileName:fileName fileSize:fileSize fileDestinationPath:path placeHolder:placeHolder progress:progressBlock completion:completion]) {
        
        self.fileTsPath = [path stringByAppendingPathComponent:fileName];
        self.locaPlayUrlStr = nil;
        
        self.totalTsCount = 0;
        self.totalSeconds = 0;
        
        self.downloading = YES;
        barraryLock = NO;
        finishedInfo = NO;
        
        tsDownloadError = NO;

        
        NSError *error = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL dir;
        if (![fileManager fileExistsAtPath:self.fileTsPath isDirectory:&dir]) {
            
            
            if (dir == NO) {
                
                [[NSFileManager defaultManager] createDirectoryAtPath:self.fileTsPath withIntermediateDirectories:YES attributes:nil error:&error];
                
                if (error != nil) {
                    
                    [self cancelCurrentDownload];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.completionCallBackBlock != nil) {
                            self.completionCallBackBlock(nil,[NSURL URLWithString:path],error,nil);
                        }
                    });
                    NSLog(@"create m3u8 directory error %@", error);
                }
            }
        }
    }
    return self;
}


- (instancetype)changeDownloadUrlString:(NSString *)urlString {
    
    MLSDownloaderM3u8Operation *newOperation = [[MLSDownloaderM3u8Operation alloc] initWithUrlStr:urlString fileName:self.fileName fileSize:self.fileSize fileDestinationPath:self.filePath placeHolder:self.placeHolderImage progress:self.progressCallBackBlock completion:self.completionCallBackBlock];
    
    newOperation.completionPercent = self.completionPercent;
    newOperation.tempFileName = self.tempFileName;
    newOperation.video_id = self.video_id;
    newOperation.video_type = self.video_type;
    newOperation.cate_id = self.cate_id;
    newOperation.placeHolderImageUrl = self.placeHolderImageUrl;
    
    return newOperation;
}

- (NSString *)locaPlayUrlStr {
    
    if (self.isCompletion) {
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSString *localPlayUrl = nil;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
            localPlayUrl = [[NSString stringWithFormat:@"http://127.0.0.1:%d/%@/%@.m3u8",portNum,self.fileName,_M3U8_LOCAL_PLAY_NAME] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        }else {
            localPlayUrl = [[NSString stringWithFormat:@"http://127.0.0.1:%d/%@/%@.m3u8",portNum,self.fileName,_M3U8_LOCAL_PLAY_NAME] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
#pragma clang diagnostic pop
        return localPlayUrl;
    }
    return nil;
}


- (instancetype)resume {
    
    return [self changeDownloadUrlString:self.urlStr];
}


- (void)main {
    @autoreleasepool {
        
        if (self.isCancelled) {
            return;
        }
        
        if ( [self analyseVideoUrl:self.urlStr] ){
        
            if (self.isCancelled) {
                return;
            }
            // 检查本地文件
            [self checkLocalDownloadState];
            
            // 开始下载
            [self startDownloadM3u8Video];
            
            while (self.isDownloading) {
                continue;
            }
            
        }else {
            self.suspend = YES;
        }
        
    }
}

- (void)cancelCurrentDownload {
    if (self.currentDownloadTask != nil) {
        
        [self.currentDownloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            // 保存恢复数据
            [resumeData writeToFile:[self.fileTsPath stringByAppendingPathComponent:resumeDataLocalStr] atomically:YES];
            
            
            dispatch_async(global_parser_queue(), ^{
                
                self.xmlParser = [[NSXMLParser alloc] initWithData:resumeData];
                self.xmlParser.delegate = self;
                [self.xmlParser parse];
                
            });
            
        }];
    }
    
    [super cancelCurrentDownload];
}
// XML 解析
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    // 记录所取得的文字列
    if ([string rangeOfString:@".tmp"].location != NSNotFound) {
        
        NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:string];
        NSError *error = nil;
        
        self.tempFileName = string;
        
        [[NSFileManager defaultManager] moveItemAtPath:tempFilePath toPath:[self.fileTsPath stringByAppendingPathComponent:string] error:&error];
        [parser abortParsing];
    }
}

// 解析url地址，找出ts片段的url地址
- (BOOL)analyseVideoUrl:(NSString *)videoUrl
{
    NSRange rangeOfM3U8 = [videoUrl rangeOfString:@"m3u8"];
    
    if(rangeOfM3U8.location == NSNotFound){
        
        NSError *err = [NSError errorWithDomain:errorDomain code:DownloaderM3u8OperationErrorNotM3U8Url userInfo:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.completionCallBackBlock && err != nil) {
                __weak typeof (self) weakSelf = self;
                self.completionCallBackBlock(nil, [NSURL URLWithString:weakSelf.filePath], err, self);
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
                self.completionCallBackBlock(nil, [NSURL URLWithString:weakSelf.filePath], error,self);
            }
        });
        
        return NO;
    }
    
    NSString *remainData = data;
    
//    NSLog(@"original m3u8 list data is %@",data);
    
    NSRange httpRange = [remainData rangeOfString:@"http"];
    if(httpRange.location == NSNotFound){
        //暂时只针对腾讯视频
        NSString *newString = @"av";
        NSRange range = [videoUrl rangeOfString:@"playlist.av.m3u8"];
        if(range.location != NSNotFound){
            newString = [NSString stringWithFormat:@"%@%@",[videoUrl substringToIndex:range.location],@"av"];
        }
        remainData = [remainData stringByReplacingOccurrencesOfString:@"av" withString:newString];
    }
    // 提取url地址,header 和footer
    NSMutableArray *segments = [NSMutableArray array];
    NSRange segmentRange = [remainData rangeOfString:@"#EXTINF:"];
    
    // 提取header
    self.header = [remainData substringToIndex:segmentRange.location];
    
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
        //
        segmentIndex++;
        [segments addObject:segment];
        remainData = [remainData substringFromIndex:linkRangeEnd.location];
        segmentRange = [remainData rangeOfString:@"#EXTINF:"];
    }
    
    self.footer = remainData;
    
    self.segmentInfoList = segments.copy;
    self.waitingDownloadArray = [[NSMutableArray alloc] initWithArray:segments];
    self.totalSeconds = totalSeconds;
    self.totalTsCount = segments.count;
    
    [self createLocalM3U8File];
    return YES;
}

// 检查本地文件夹，找出已经下载过的文件
- (void)checkLocalDownloadState {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    
    // 遍历已经下载过的ts视频
    [fileManager enumratePath:self.fileTsPath options:NSDirectoryEnumerationSkipsSubdirectoryDescendants attributes:@{FileManagerEnumrateTypeKey : @"ts"} completionBlock:^(NSString *fileUrl, NSString *fileName, NSError *error) {
        
        if (error != nil) {
            
            NSLog(@"fileManager enumration error == %@",error);
            
        }else {
            NSRange range = [fileName rangeOfString:@"."];
            NSRange idRange = [fileName rangeOfString:_M3U8_SEGMENT_NAME_];
            
            if (idRange.location != NSNotFound && range.location != NSNotFound) {
                
                NSString *num = [fileName substringWithRange:NSMakeRange((idRange.location + idRange.length), (range.location - idRange.length))];
                
                NSLog(@"%@",num);
                NSInteger index = [num integerValue];
                
                [indexSet addIndex:index];
            }
            
            NSLog(@"检查本地文件%ld",self.currentDownloadTsIndex);
            self.currentDownloadTsIndex++;
        }
    }];
    
    
    // 找是否有ts断点续传文件
    BOOL dir = NO;
    if ([fileManager fileExistsAtPath:[self.fileTsPath stringByAppendingPathComponent:self.tempFileName] isDirectory:&dir]) {
        
        if (dir == NO) {
            
            NSError *error = nil;
            
            [fileManager moveItemAtPath:[self.fileTsPath stringByAppendingPathComponent:self.tempFileName] toPath:[NSTemporaryDirectory() stringByAppendingPathComponent:self.tempFileName] error:&error];
            NSLog(@"%@",error);
            
            if ([fileManager fileExistsAtPath:[self.fileTsPath stringByAppendingPathComponent:resumeDataLocalStr]] ) {
                self.resumeData = [NSData dataWithContentsOfFile:[self.fileTsPath stringByAppendingPathComponent:resumeDataLocalStr]];
                [fileManager removeItemAtPath:[self.fileTsPath stringByAppendingPathComponent:resumeDataLocalStr] error:NULL];
            }
        }
    }
    
    if (indexSet.count > 0 && self.waitingDownloadArray.count > indexSet.count) {
        [self.waitingDownloadArray removeObjectsAtIndexes:indexSet];
    }
    
}

// 开始下载
- (void)startDownloadM3u8Video
{
    
    // 等待上一个ts下载完成
    while (barraryLock) {
        continue;
    }
    
    barraryLock = YES;
    
    if ( tsDownloadError == NO && !self.isSuspend && self.currentDownloadTsIndex <= self.totalTsCount) {
        
        NSLog(@"self.currentDownloadTsIndex == %ld",self.currentDownloadTsIndex);
        NSLog(@"current download url %@",self.waitingDownloadArray.firstObject.url);
    
        if (self.waitingDownloadArray.count > 0) {
            
            
            MLSDownloaderM3u8SegmentInfo *downInfo = (MLSDownloaderM3u8SegmentInfo *) self.waitingDownloadArray.firstObject;
            
            __weak typeof (self) weakSelf = self;
            
            void (^progressBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite)  = ^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite)  {
                
                __strong typeof (weakSelf) strongSelf = weakSelf;
                
                [self.countNetworkArr addObject:@(bytesWritten * 8)];
                
                CGFloat onePercent = 1.0 / self.totalTsCount;
                
                if (self.currentDownloadTsIndex >= self.totalTsCount) {
                    self.currentDownloadTsIndex = self.totalTsCount;
                }
                CGFloat percent = self.currentDownloadTsIndex * onePercent + ( totalBytesWritten * 1.0 / totalBytesExpectedToWrite ) * onePercent;
                
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
                    tsDownloadError = YES;
                }
            };
            
            void (^completionBlock)(NSURLResponse *response, NSURL *filePath, NSError *error)  = ^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                
                __strong typeof (weakSelf) strongSelf = weakSelf;
                
                barraryLock = NO;
                
                if (error != nil) {
                    
                    self.suspend = YES;
                    tsDownloadError = YES;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (strongSelf.completionCallBackBlock != nil && ![error.localizedDescription isEqualToString:@"canceled"]) {
                            
                            strongSelf.completionCallBackBlock(response,filePath,error,self);
                            
                        }else if (strongSelf.completionCallBackBlock != nil) {
                            
                            strongSelf.completionCallBackBlock(response,filePath,nil,self);
                        }
                        
                    });
                    
                    NSLog(@"%@---%ld download error %@",strongSelf.fileName,strongSelf.currentDownloadTsIndex, error);
                    
                    
                }else {
                    
                    tsDownloadError = NO;
                    
                    self.currentDownloadTsIndex++;
                    
                    // 移除下载完的操作
                    if ([strongSelf.waitingDownloadArray containsObject:downInfo]) {
                        
                        [strongSelf.waitingDownloadArray removeObject:downInfo];
                    }
                    // 开始新的下载
                    [strongSelf startDownloadM3u8Video];
                    NSLog(@"%@---%ld download success",strongSelf.fileName,strongSelf.currentDownloadTsIndex);
                }
            };
            
            // 如果在下载过程中取消操作，就取消操作
            if (self.isCancelled) {
                // 取消循环等待锁
                barraryLock = NO;
                tsDownloadError = YES;
                return;
            }
            // 每个ts文件的存放目录
            NSString * destination = [self.fileTsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%ld.ts",_M3U8_SEGMENT_NAME_,(long)self.currentDownloadTsIndex]];
            
            if (self.resumeData != nil) {
                
                NSURLSessionDownloadTask *downloadTask = [[MLSDownloaderSessionManager shareDownloadManager] addDownloadTaskWithResumeData:self.resumeData destination:destination downloadProgress:progressBlock completionHandler:completionBlock];
                [downloadTask resume];

                self.currentDownloadTask = downloadTask;
                
            }else {
                
                NSURLSessionDownloadTask *downloadTask = [[MLSDownloaderSessionManager shareDownloadManager] addDownloadTaskWithUrlString:downInfo.url destination:destination downloadProgress:progressBlock completionHandler:completionBlock];
                [downloadTask resume];
                self.currentDownloadTask = downloadTask;
            }
            
            
        }else {
            __weak typeof (self) weakSelf = self;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.completionCallBackBlock(nil,[NSURL URLWithString:weakSelf.filePath],nil,self);
                [self createLocalM3U8File];
            });
            self.completion = YES;
            NSLog(@"%@----------- download success",self.fileName);
        }
    }else if (self.currentDownloadTsIndex == self.totalTsCount + 1 ){
        
        self.completion = YES;
        
        [self createLocalM3U8File];
        
        if (self.progressCallBackBlock != nil) {
            self.progressCallBackBlock(nil,nil,1.0,self);
        }
        if (self.completionCallBackBlock != nil) {
            self.completionCallBackBlock(nil,[NSURL URLWithString:self.fileTsPath],nil,self);
        }
        return;
    }
}


- (void)createLocalM3U8File
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSLog(@"%@",self.locaPlayUrlStr);
    BOOL dir = NO;
    
    NSString *tempFilePath = [self.fileTsPath stringByAppendingPathComponent:tmpM3u8TextLoacalStr];
    NSString *realFilePath = [self.fileTsPath stringByAppendingPathComponent:realM3u8TextLocalStr];
    
    if ([fileManager fileExistsAtPath:tempFilePath isDirectory:&dir] ) {
        if (dir == NO) {
            NSError *error = nil;
            [fileManager moveItemAtPath:tempFilePath toPath:realFilePath error:&error];
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
                self.locaPlayUrlStr = [[NSString stringWithFormat:@"http://127.0.0.1:%d/%@/%@.m3u8",portNum,self.fileName,_M3U8_LOCAL_PLAY_NAME] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
            }else {
                self.locaPlayUrlStr = [[NSString stringWithFormat:@"http://127.0.0.1:%d/%@/%@.m3u8",portNum,self.fileName,_M3U8_LOCAL_PLAY_NAME] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            }
#pragma clang diagnostic pop
            
            
            error = nil;
            NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.fileTsPath error:&error];
            for (NSString *tempFilePath in contents) {
                // 如果下载完成后，存在临时文件，就全部删除
                if ([tempFilePath hasSuffix:@".tmp"]) {
                    [fileManager removeItemAtPath:tempFilePath error:NULL];
                }
            }
            
            
            if (error == nil) {
                return;
            }
        }
    }
    
    if( self.segmentInfoList && self.segmentInfoList.count == self.totalTsCount ){
        
        NSString *fullPath = [self.fileTsPath stringByAppendingPathComponent:tmpM3u8TextLoacalStr];
        // 创建文件头部
        NSString* head = self.header;
        NSString* segmentPrefix = [NSString stringWithFormat:@"http://127.0.0.1:54321/%@/",self.fileName];
        
        NSInteger count = [self.segmentInfoList count];
        // 填充片段数据
        for(int i = 0;i<count;i++){
            // _M3U8_SEGMENT_NAME_
            NSString *filename = [NSString stringWithFormat:@"%@%d.ts",_M3U8_SEGMENT_NAME_,i];
            
            MLSDownloaderM3u8SegmentInfo *segInfo = [self.segmentInfoList objectAtIndex:i];
            
            if (segInfo == nil) {
                
                NSError *error = [NSError errorWithDomain:errorDomain code:DownloaderM3u8OperationErrorCreateM3U8FileError userInfo:nil];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (self.completionCallBackBlock != nil) {
                        self.completionCallBackBlock(nil,[NSURL URLWithString:self.filePath],error,self);
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
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
            self.locaPlayUrlStr = [[NSString stringWithFormat:@"http://127.0.0.1:%d/%@/%@.m3u8",portNum,self.fileName,_M3U8_LOCAL_PLAY_NAME] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        }else {
            self.locaPlayUrlStr = [[NSString stringWithFormat:@"http://127.0.0.1:%d/%@/%@.m3u8",portNum,self.fileName,_M3U8_LOCAL_PLAY_NAME] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
#pragma clang diagnostic pop
    }
}
- (void)dealloc {
    NSLog(@"downloaderM3u8Operation dealloc ");
}


//===========================================================
//  Keyed Archiving
//
//===========================================================
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:self.totalTsCount forKey:@"totalTsCount"];
    [encoder encodeInteger:self.currentDownloadTsIndex forKey:@"currentDownloadTsIndex"];
    [encoder encodeObject:self.fileTsPath forKey:@"fileTsPath"];
    [encoder encodeObject:self.segmentInfoList forKey:@"segmentInfoList"];
    [encoder encodeObject:self.waitingDownloadArray forKey:@"waitingDownloadArray"];
    [encoder encodeObject:self.tempFileName forKey:@"tempFileName"];
    
    [encoder encodeObject:self.header forKey:@"header"];
    [encoder encodeObject:self.footer forKey:@"footer"];
    
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        self.totalTsCount = [decoder decodeIntegerForKey:@"totalTsCount"];
        self.currentDownloadTsIndex = [decoder decodeIntegerForKey:@"currentDownloadTsIndex"];
        self.fileTsPath = [decoder decodeObjectForKey:@"fileTsPath"];
        self.segmentInfoList = [decoder decodeObjectForKey:@"segmentInfoList"];
        self.waitingDownloadArray = [decoder decodeObjectForKey:@"waitingDownloadArray"];
        self.tempFileName = [decoder decodeObjectForKey:@"tempFileName"];
        
        self.header = [decoder decodeObjectForKey:@"header"];
        self.footer = [decoder decodeObjectForKey:@"footer"];

    }
    return self;
}

@end
