//
//  NSFileManager+FileManager.h
//  testFileManager
//
//  Created by 袁航 on 16/1/8.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, FileManagerEnumrateErrorCode) {
    FileManagerFileDoseNotExist = 1,
};
extern NSString * const FileManagerEnumrateTypeKey;
extern NSString * const FileManagerEnumratePrefixKey;
// 如果是文件夹，是否递归搜索
extern NSString * const FileManagerEnumrateSkipDescendantsKey;

@interface NSFileManager (MLSFileManager)
- (void)enumratePath:(NSString *)path options:(NSDirectoryEnumerationOptions)options attributes:(NSDictionary<NSString *, id >*)attrebutes completionBlock:(void (^)(NSString *filePath, NSString *fileName, NSError *error))completion;
@end
