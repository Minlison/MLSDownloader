//
//  LVRDownloadAccount.m
//  M3u8Download
//
//  Created by MinLison on 15/11/30.
//  Copyright © 2015年 apple. All rights reserved.
//

#import "MLSDownloadAccount.h"
#import "MLSDownloader.h"
#import "MLSDownloadFileTools.h"

#define NEW_DirectoryPathString @".com.downloader.downloadState"
#define OLD_DirectoryPathString @"com.downloader.downloadState"

#define NEW_ArchiverFileNameString @".archiver.downloadeAccount.downloader"
#define OLD_ArchiverFileNameString @"archiver.downloadeAccount.downloader"

#define ArchiverErrorFileNameString @".archiver.error"

@interface MLSDownloadAccount() 

@end
@implementation MLSDownloadAccount

+ (void)saveDownloadState {

        NSString *fileDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:NEW_DirectoryPathString];

        NSString *saveFilePath = [fileDirectoryPath stringByAppendingPathComponent:NEW_ArchiverFileNameString];

        NSFileManager *fileManager = [NSFileManager defaultManager];

        

        if (![fileManager fileExistsAtPath:fileDirectoryPath])
        {
                NSError *error = nil;
                [fileManager createDirectoryAtPath:fileDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error];

                if (error != nil)

                {
                        [NSKeyedArchiver archiveRootObject:error toFile:[fileDirectoryPath stringByAppendingPathComponent:ArchiverErrorFileNameString]];

                        NSLog(@"saveDownloadState %@",error);
                }
                else
                {
                        NSLog(@"saveDownloadState success");
                        [NSKeyedArchiver archiveRootObject:MLSDownloaderSingleton toFile:saveFilePath];
                }
        }
        else
        {
                [NSKeyedArchiver archiveRootObject:MLSDownloaderSingleton toFile:saveFilePath];
                NSLog(@"saveDownloadState success");
        }
}
+ (void)recoverDownloadState
{
        NSString *old_fileDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:OLD_DirectoryPathString];

        NSString *new_fileDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:NEW_DirectoryPathString];

        NSString *old_saveFilePath = [old_fileDirectoryPath stringByAppendingPathComponent:OLD_ArchiverFileNameString];

        NSString *new_saveFilePath = [new_fileDirectoryPath stringByAppendingPathComponent:NEW_ArchiverFileNameString];

        MLSDownloader *old_downloader = [NSKeyedUnarchiver unarchiveObjectWithFile:old_saveFilePath];

        MLSDownloader *new_downloader = [NSKeyedUnarchiver unarchiveObjectWithFile:new_saveFilePath];

        NSMutableDictionary *downloadingInfo = [NSMutableDictionary dictionary];

        if (old_downloader.downloadingInfo != nil)
        {
                [downloadingInfo setValuesForKeysWithDictionary:old_downloader.downloadingInfo];

                if ([[NSFileManager defaultManager] fileExistsAtPath:old_saveFilePath])
                {
                        [[NSFileManager defaultManager] removeItemAtPath:old_saveFilePath error:NULL];
                }
        }

        if (new_downloader.downloadingInfo != nil)
        {
                [downloadingInfo setValuesForKeysWithDictionary:new_downloader.downloadingInfo];
        }
    
        [downloadingInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, MLSDownloadOperation *  _Nonnull obj, BOOL * _Nonnull stop) {
            [obj changeFileRootPathWithPath:[MLSDownloadFileTools saveFilePath]];
        }];

        MLSDownloaderSingleton.downloadingInfo = downloadingInfo;
        [MLSDownloaderSingleton.downloadingArray removeAllObjects];
        [MLSDownloaderSingleton.downloadingArray addObjectsFromArray:downloadingInfo.allValues];


        [self saveDownloadState];

        NSLog(@"%@---\n%@",MLSDownloaderSingleton.downloadingInfo, MLSDownloaderSingleton.downloadingArray);

}

@end
