//
//  MLSTestCell.h
//  testFileDownloader
//
//  Created by MinLison on 16/1/14.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLSDownloadOperation.h"
@interface MLSTestCell : UITableViewCell
@property (strong, nonatomic) MLSDownloadOperation *operation;
@end
