//
//  NSFileManager+FileManager.m
//  testFileManager
//
//  Created by 袁航 on 16/1/8.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "NSFileManager+MLSFileManager.h"
NSString * const FileManagerEnumrateTypeKey = @"FileManagerEnumrateTypeKey";
NSString * const FileManagerEnumratePrefixKey = @"FileManagerEnumratePrefixKey";
NSString * const FileManagerEnumrateSkipDescendantsKey = @"FileManagerEnumrateSkipDescendantsKey";

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
    
    temp = [attrebutes valueForKey:FileManagerEnumrateTypeKey];
    if (temp != nil) {
        type = temp;
    }
    temp = [attrebutes valueForKey:FileManagerEnumratePrefixKey];
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



//- (void)enumratePath:(NSString *)path options:(NSDirectoryEnumerationOptions)options attributes:(NSDictionary<NSString *, id >*)attrebutes completionBlock:(void (^)(NSString *filePath, NSString *fileName, NSError *error))completion {
//    BOOL isDir = NO;
//    if (![self fileExistsAtPath:path isDirectory:&isDir]) {
//        NSError *error = [NSError errorWithDomain:path code:FileManagerFileDoseNotExist userInfo:nil];
//        completion(nil,nil,error);
//        return;
//    };
//    
//    
//    __block BOOL flag = NO;
//    BOOL isSkipDescendants = NO;
//    NSString *type = nil;
//    NSString *prefix = nil;
//    id temp = nil;
//    temp = [attrebutes valueForKey:FileManagerEnumrateSkipDescendantsKey];
//    if (temp != nil) {
//        isSkipDescendants = [temp boolValue];
//    }
//    temp = [attrebutes valueForKey:FileManagerEnumrateTypeKey];
//    if (temp != nil) {
//        type = temp;
//    }
//    temp = [attrebutes valueForKey:FileManagerEnumratePrefixKey];
//    if (temp != nil) {
//        prefix = temp;
//    }
//    // 遍历所有的文件
//    NSDirectoryEnumerator *enumerator = [self enumeratorAtURL:[NSURL URLWithString:path] includingPropertiesForKeys:@[NSURLNameKey, NSURLTypeIdentifierKey] options:options errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
//        if (error != nil) {
//            NSLog(@"%@",error);
//            completion(url,nil,error);
//            flag = YES;
//            return NO;
//        }
//        return YES;
//    }];
//    if (flag == YES) {
//        return;
//    }
//    
//    for (NSURL *fileURL in enumerator) {
//        NSString *filename;
//        [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];
////        NSLog(@"%@",filename);
//        NSNumber *isDirectory;
//        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
//        
//        // Skip directories with '_' prefix, for example
//        if ([filename hasPrefix:@"_"] && [isDirectory boolValue] && isSkipDescendants) {
//            [enumerator skipDescendants];
//            continue;
//        }
//        
//        if (type != nil) {
//            NSRange range = [filename rangeOfString:@"." options:NSBackwardsSearch];
//            if (range.location < filename.length) {
//                NSString *typeString = [filename substringFromIndex:range.location + range.length];
//                if ([type isEqualToString:typeString]) {
//                    completion(fileURL, filename, nil);
//                }
//            }
//        }
//        if (prefix != nil) {
//            if ([filename hasPrefix:prefix]) {
//                completion(fileURL, filename, nil);
//            }
//        }
//    }
//}
@end
