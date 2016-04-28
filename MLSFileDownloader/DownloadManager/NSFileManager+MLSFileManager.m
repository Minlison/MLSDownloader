//
//  NSFileManager+FileManager.m
//  testFileManager
//
//  Created by 袁航 on 16/1/8.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "NSFileManager+MLSFileManager.h"
#import "MLSDownloaderCommon.h"
NSString * const MLSFileManagerEnumrateTypeKey = @"FileManagerEnumrateTypeKey";
NSString * const MLSFileManagerEnumratePrefixKey = @"FileManagerEnumratePrefixKey";

@implementation NSFileManager (MLSFileManager)
- (void)enumratePath:(NSString *)path options:(NSDirectoryEnumerationOptions)options attributes:(NSDictionary<NSString *,NSString *> *)attrebutes completionBlock:(void (^)( NSString *filePath, NSString *fileName, NSError *error))completion {

        BOOL isDir = NO;

        if (![self fileExistsAtPath:path isDirectory:&isDir]) {

                NSError *error = [NSError errorWithDomain:path code:FileManagerFileDoseNotExist userInfo:nil];
                completion(nil,nil,error);
                return;
        };

        NSString *type = nil;
        NSString *prefix = nil;

        id temp = nil;

        temp = [attrebutes valueForKey:MLSFileManagerEnumrateTypeKey];
        if (temp != nil) {
                type = temp;
        }
        temp = [attrebutes valueForKey:MLSFileManagerEnumratePrefixKey];
        if (temp != nil) {
                prefix = temp;
        }
        BOOL dir = NO;

        if ( [self fileExistsAtPath:path isDirectory:&dir] ) {

                if (dir == YES) {
                        NSError *error = nil;
                        NSArray *arr = [self contentsOfDirectoryAtPath:path error:&error];
                        if (error != nil) {
                                if (completion != nil) {
                                        completion(nil,nil,error);
                                }
                        }else {
                                for (NSString *temp in arr) {

                                        if (type != nil) {
                                                NSRange range = [temp rangeOfString:@"." options:NSBackwardsSearch];

                                                if (range.location < temp.length) {

                                                        NSString *typeString = [temp substringFromIndex:range.location + range.length];

                                                        if ([type isEqualToString:typeString]) {
                                                                if (completion != nil) {

                                                                        completion([path stringByAppendingPathComponent:temp], temp, nil);
                                                                }
                                                        }
                                                }
                                        }
                                        
                                        
                                        if (prefix != nil) {
                                                if ([temp hasPrefix:prefix]) {
                                                        if (completion != nil) {
                                                                completion([path stringByAppendingPathComponent:temp], temp, nil);
                                                                
                                                        }
                                                }
                                        }
                                        
                                }
                        }
                }
        }else {
                completion(nil,nil,nil);
        }
        
}
@end
