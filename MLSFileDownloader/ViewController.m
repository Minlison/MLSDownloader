//
//  ViewController.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/8.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "MLSDownloaderSessionManager.h"
#import "MLSDownloader.h"
static NSInteger count = 0;
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label;

@property (weak, nonatomic) IBOutlet UIImageView *iconView;

@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (strong, nonatomic)  MLSDownloadOperation *operation;
@property (strong, nonatomic) MLSDownloader *downloader;
@property (copy, nonatomic) NSString *filePath;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"Download"];
    
    self.downloader = [MLSDownloader shareDownloader];
    
    
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL URLWithString:self.filePath] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL];
    NSLog(@"%@",array);

    NSString *urlString = @"http://36.250.240.84/ws.cdn.baidupcs.com/file/089794a032f1858aa9bca7df81598396?bkt=p3-0000089794a032f1858aa9bca7df81598396&xcode=a4917c9df03a1c1d012b0c79b9d345bea8623322c24b7d09a271ffda32bcb45b&fid=3692544880-250528-852050494772481&time=1452837645&sign=FDTAXGERLBH-DCb740ccc5511e5e8fedcff06b081203-vRKUwqjDfWQD%2FG6wmgIEACUQGkE%3D&to=cb&fm=Nan,B,U,nc&sta_dx=682&sta_cs=3&sta_ft=mp4&sta_ct=5&fm2=Nanjing02,B,U,nc&newver=1&newfm=1&secfm=1&flow_ver=3&pkey=0000089794a032f1858aa9bca7df81598396&sl=72286286&expires=8h&rt=pr&r=475781649&mlogid=338240852178807312&vuk=3692544880&vbdid=1362062792&fin=Lesbian%20Jacuzzi%20-%20Onix%20Babe%20%26%20Eris%20Maximo.mp4&slt=pm&uta=0&rtype=1&iv=0&isw=0&dp-logid=338240852178807312&dp-callid=0.1.1&wshc_tag=0&wsts_tag=56988b0d&wsid_tag=76c2f6bb&wsiphost=ipdbm";
    
    
    for (int i = 0; i < 5; i++) {
        urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"%@",[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
    }
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pause:(id)sender {
}

- (IBAction)start:(id)sender {
    NSString *urlString = nil;
    
    count++;
    if (count == 1) {
        urlString = @"http:​/​/​pl.youku.com/​playlist/​m3u8?​vid=XMTQ0ODU3NzU1Ng==&​type=flv&​ts=1453091615&​keyframe=0&​ep=diaRGUmEV8gB4CvciD8bYyi2ISIGXJZ3kn6F%2FqYHA8VuLenBzjPcqJ%2BxTvs%3D&​sid=44530916158301244dee9&​token=2104&​ctype=12&​ev=1&​oip=996984932";
    }else if (count == 2) {
        urlString = @"http://36.250.240.84/ws.cdn.baidupcs.com/file/089794a032f1858aa9bca7df81598396?bkt=p3-0000089794a032f1858aa9bca7df81598396&xcode=a4917c9df03a1c1d012b0c79b9d345bea8623322c24b7d09a271ffda32bcb45b&fid=3692544880-250528-852050494772481&time=1452837645&sign=FDTAXGERLBH-DCb740ccc5511e5e8fedcff06b081203-vRKUwqjDfWQD%2FG6wmgIEACUQGkE%3D&to=cb&fm=Nan,B,U,nc&sta_dx=682&sta_cs=3&sta_ft=mp4&sta_ct=5&fm2=Nanjing02,B,U,nc&newver=1&newfm=1&secfm=1&flow_ver=3&pkey=0000089794a032f1858aa9bca7df81598396&sl=72286286&expires=8h&rt=pr&r=475781649&mlogid=338240852178807312&vuk=3692544880&vbdid=1362062792&fin=Lesbian%20Jacuzzi%20-%20Onix%20Babe%20%26%20Eris%20Maximo.mp4&slt=pm&uta=0&rtype=1&iv=0&isw=0&dp-logid=338240852178807312&dp-callid=0.1.1&wshc_tag=0&wsts_tag=56988b0d&wsid_tag=76c2f6bb&wsiphost=ipdbm";
    }
   
    
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
    
    self.operation =  [self.downloader startDownloadWithUrlStr:urlString fileName:[NSString stringWithFormat:@"%ld",count] fileSize:1000 placeHolderImage:nil fileDestinationPath:self.filePath progress:^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, CGFloat progress, MLSDownloadOperation *operation) {
        
//        NSLog(@"%f",progress);
    } completion:^(NSURLResponse *response, NSURL *filePath, NSError *error, MLSDownloadOperation *operation) {
        
        NSLog(@"%@",error);
    }];

    
//    [[[MLSDownloaderSessionManager shareDownloadManager] addDownloadTaskWithUrlString:@"http://7xj71p.com2.z0.glb.qiniucdn.com/kxko1qHbwFq7aF4GLe5f0lNbzMw=/ll7Qf34j_1MMJkKg8rZEkYOgqj1f/000000.ts" destination:[self.filePath stringByAppendingPathComponent:@"01.ts"] downloadProgress:^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
//        NSLog(@"%lld",bytesWritten);
//    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
//        NSLog(@"%@",filePath);
//    }] resume];
    
    
}
- (IBAction)cancel:(id)sender {
    
}
- (IBAction)resume:(id)sender {
    
}
@end
