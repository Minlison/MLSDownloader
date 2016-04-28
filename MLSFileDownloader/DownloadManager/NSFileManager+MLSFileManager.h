//
//  NSFileManager+FileManager.h
//  testFileManager
//
//  Created by 袁航 on 16/1/8.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MLSFileManagerEnumrateErrorCode) {
        FileManagerFileDoseNotExist = 1,
};
extern NSString * const MLSFileManagerEnumrateTypeKey;
extern NSString * const MLSFileManagerEnumratePrefixKey;

@interface NSFileManager (MLSFileManager)
- (void)enumratePath:(NSString *)path options:(NSDirectoryEnumerationOptions)options attributes:(NSDictionary<NSString *, id >*)attrebutes completionBlock:(void (^)(NSString *filePath, NSString *fileName, NSError *error))completion;
@end
