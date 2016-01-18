//
//  DownloadOperation.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/13.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "MLSDownloadOperation.h"
#import "NSString+MLSEncrypt.h"
#import "MLSDownloaderM3u8Operation.h"
#import "MLSDownloadNomarlOperation.h"
dispatch_queue_t global_parser_queue(void) {
    
    static dispatch_queue_t mls_download_parser_queue;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        mls_download_parser_queue = dispatch_queue_create("com.mlsdownload.parser", DISPATCH_QUEUE_CONCURRENT );
    });
    
    return mls_download_parser_queue;
};


@interface MLSDownloadOperation() {
    NSInteger tempCountNetworkSpeed;
}
@end
@implementation MLSDownloadOperation



// 下载进度回调
- (void)setProgressBlock:(MLSDownloaderProgressCallBackBlock)progress {
    self.progressCallBackBlock = progress;
}
// 完成回调
- (void)setCompletionBlock:(MLSDownloaderCompletionCallBackBlock)completion {
    self.completionCallBackBlock = completion;
}
- (void)setNetworkSpeedBlock:(DownloaderNetworkSpeedCompletionBlock)networkSpeedBlock {
    self.networkSpeedCallBackBlock = networkSpeedBlock;
}
- (void)setCompletion:(BOOL)completion {
    if (_completion != completion) {
        _completion = completion;
        if (completion == YES) {
            self.suspend = !completion;
            self.downloading = !completion;
        }
    }
}
- (void)setSuspend:(BOOL)suspend {
    if (_suspend != suspend) {
        _suspend = suspend;
        if (suspend == YES) {
            self.completion = !suspend;
            self.downloading = !suspend;
        }
    }
}
- (void)setDownloading:(BOOL)downloading {
    if (_downloading != downloading) {
        _downloading = downloading;
        if (downloading == YES) {
            self.completion = !downloading;
            self.suspend = !downloading;
        }
    }
}
- (NSString *)locaPlayUrlStr {
    if (self.isCompletion) {
        return _locaPlayUrlStr;
    }
    return nil;
}
// 初始化下载操作
- (instancetype)initWithUrlStr:(NSString *)urlStr
                      fileName:(NSString *)fileName
                      fileSize:(CGFloat)fileSize
           fileDestinationPath:(NSString *)path
                   placeHolder:(UIImage *)placeHolder
                      progress:(MLSDownloaderProgressCallBackBlock)progressBlock
                    completion:(MLSDownloaderCompletionCallBackBlock)completion {
    
    if (self = [super init]) {
        
        self.completionPercent = 0;
        
        self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(countNetworkSpeed) userInfo:nil repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        
        self.key = [urlStr md5String];
        self.urlStr = urlStr;
        self.fileSize = fileSize;
        self.fileName = fileName;
        self.filePath = path;
        self.placeHolderImage = placeHolder;
        self.progressCallBackBlock = progressBlock;
        self.completionCallBackBlock = completion;
        self.name = fileName;
    }
    return self;
}

// 地址失效时，更改地址
- (instancetype)changeDownloadUrlString:(NSString *)urlString {
    return nil;
}

// 恢复指定下载操作
- (instancetype)resume {
    return nil;
}
- (void)cancelCurrentDownload {
    
    self.suspend = YES;
    
    [self cancel];
}
- (void)countNetworkSpeed {
    
    if (self.networkSpeedCallBackBlock != nil) {
        
        // 计算网速
//        NSLog(@"%@",self.countNetworkArr);
        if (self.countNetworkArr.count >= _NETWORK_SPPED_COUNT_) {
            
            [self.countNetworkArr enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                tempCountNetworkSpeed += obj.integerValue;
                
            }];
            
            tempCountNetworkSpeed = tempCountNetworkSpeed * 1.0 / self.countNetworkArr.count;
            // 移除之前的权重
            
            for (int i = 0; i < self.countNetworkArr.count - _NETWORK_SPPED_COUNT_ ; i++) {
                [self.countNetworkArr removeObjectAtIndex:i];
            }
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (tempCountNetworkSpeed == 0) {
                tempCountNetworkSpeed = _DEFAULT_NETWORK_SPEED;
            }
            self.networkSpeedCallBackBlock(tempCountNetworkSpeed);
        });
        
        // 临时计算属性清零
        tempCountNetworkSpeed = 0;
    }
}

// 删除本地文件
- (BOOL)deleteFile {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL result = NO;
    
    if ([self isKindOfClass:[MLSDownloaderM3u8Operation class]]) {
        
        NSError *error = nil;
        [fileManager removeItemAtPath:[self.filePath stringByAppendingPathComponent:self.fileName] error:&error];
        
        if (error == nil) {
            result = YES;
        }else {
            result = NO;
        }
    }else if ([self isKindOfClass:[MLSDownloadNomarlOperation class]]){
        NSError *error = nil;
        
        MLSDownloadNomarlOperation *operation = (MLSDownloadNomarlOperation *)self;
        
        [fileManager removeItemAtPath:[operation.filePath stringByAppendingString:operation.suggestedFilename] error:&error];
        
        if (error == nil) {
            result = YES;
        }else {
            result = NO;
        }
    }
    return result;
}
- (NSMutableArray<NSNumber *> *)countNetworkArr {
    if (_countNetworkArr == nil) {
        _countNetworkArr = [[NSMutableArray alloc] initWithCapacity:_NETWORK_SPPED_COUNT_];
    }
    return _countNetworkArr;
}

//===========================================================
//  Keyed Archiving
//
//===========================================================
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.video_id forKey:@"video_id"];
    [encoder encodeObject:self.cate_id forKey:@"cate_id"];
    [encoder encodeObject:self.video_type forKey:@"video_type"];
    [encoder encodeObject:self.key forKey:@"key"];
    [encoder encodeFloat:self.fileSize forKey:@"fileSize"];
    [encoder encodeObject:self.urlStr forKey:@"urlStr"];
    [encoder encodeObject:self.fileName forKey:@"fileName"];
    [encoder encodeObject:self.filePath forKey:@"filePath"];
    [encoder encodeObject:self.placeHolderImage forKey:@"placeHolderImage"];
    [encoder encodeObject:self.placeHolderImageUrl forKey:@"placeHolderImageUrl"];
    [encoder encodeBool:self.completion forKey:@"completion"];
    [encoder encodeBool:self.suspend forKey:@"suspend"];
    [encoder encodeBool:self.downloading forKey:@"downloading"];
    [encoder encodeFloat:self.completionPercent forKey:@"completionPercent"];
    [encoder encodeObject:self.locaPlayUrlStr forKey:@"locaPlayUrlStr"];
    [encoder encodeInteger:self.totalSeconds forKey:@"totalSeconds"];
    [encoder encodeObject:self.countNetworkArr forKey:@"countNetworkArr"];
//    [encoder encodeObject:self.resumeData forKey:@"resumeData"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.video_id = [decoder decodeObjectForKey:@"video_id"];
        self.cate_id = [decoder decodeObjectForKey:@"cate_id"];
        self.video_type = [decoder decodeObjectForKey:@"video_type"];
        self.key = [decoder decodeObjectForKey:@"key"];
        self.fileSize = [decoder decodeFloatForKey:@"fileSize"];
        self.urlStr = [decoder decodeObjectForKey:@"urlStr"];
        self.fileName = [decoder decodeObjectForKey:@"fileName"];
        self.filePath = [decoder decodeObjectForKey:@"filePath"];
        self.placeHolderImage = [decoder decodeObjectForKey:@"placeHolderImage"];
        self.placeHolderImageUrl = [decoder decodeObjectForKey:@"placeHolderImageUrl"];
        self.completion = [decoder decodeBoolForKey:@"completion"];
        self.suspend = [decoder decodeBoolForKey:@"suspend"];
        self.downloading = [decoder decodeBoolForKey:@"downloading"];
        self.completionPercent = [decoder decodeFloatForKey:@"completionPercent"];
        self.locaPlayUrlStr = [decoder decodeObjectForKey:@"locaPlayUrlStr"];
        self.totalSeconds = [decoder decodeIntegerForKey:@"totalSeconds"];
        self.countNetworkArr = [decoder decodeObjectForKey:@"countNetworkArr"];
//        self.resumeData = [decoder decodeObjectForKey:@"resumeData"];
    }
    return self;
}
@end

NSString *resumeDataLocalStr = @"resume.data";
NSString *waitingArrayLocalStr = @"waiting.data";
NSString *tmpM3u8TextLoacalStr = @"movie.m3u8.tmp";
NSString *realM3u8TextLocalStr = @"movie.m3u8";
NSString *errorDomain = @"com.mlsdownloader.errordomain";