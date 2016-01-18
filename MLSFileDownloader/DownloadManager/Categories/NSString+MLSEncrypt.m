//
//  NSString+Encrypt.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/8.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "NSString+MLSEncrypt.h"
#import "NSData+MLSEncrypt.h"
@implementation NSString (MLSEncrypt)
- (NSString *)md5String {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] md5String];
}
@end
