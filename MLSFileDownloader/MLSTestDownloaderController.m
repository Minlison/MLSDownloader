//
//  MLSTestDownloaderController.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/14.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "MLSTestDownloaderController.h"
#import "MLSDownloader.h"
#import "MLSTestCell.h"

@interface MLSTestDownloaderController ()

@end

@implementation MLSTestDownloaderController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"%@",[MLSDownloader shareDownloader].downloadingArray);
    NSLog(@"%@",[MLSDownloader shareDownloader].downloadQueue.operations);
    [[MLSDownloader shareDownloader].downloadQueue.operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"\n%@ ----- isCancelled %d \n isExecuting %d \n isFinished  %d \n isReady  %d \n isConcurrent  %d  \n isAsynchronous%d\n",obj.name,obj.isCancelled,obj.isExecuting,obj.isFinished,obj.isReady,obj.isConcurrent,obj.isAsynchronous);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [MLSDownloader shareDownloader].downloadingArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MLSTestCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    cell.operation = [MLSDownloader shareDownloader].downloadingArray[indexPath.row];
    // Configure the cell...
    
    return cell;
}

@end
