//
//  MLSTestCell.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/14.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "MLSTestCell.h"
#import "MLSDownloader.h"
typedef NS_ENUM(NSInteger, ControlButtonType) {
        ControlButtonTypePause = 1,
        ControlButtonTypeDownlading = 2,
        ControlButtonTypeCompletion = 3,
        ControlButtonTypeWaiting = 4,
};
@interface MLSTestCell()
@property (weak, nonatomic) IBOutlet UIButton *controlButton;

@property (weak, nonatomic) IBOutlet UILabel *networkSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *downloadProgressLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UISlider *sliderView;

@end
@implementation MLSTestCell

- (void)setOperation:(MLSDownloadOperation *)operation {

        _operation = operation;

        self.nameLabel.text = operation.fileName;
        self.downloadProgressLabel.text = [NSString stringWithFormat:@"%f",operation.completionPercent];
        self.sliderView.value = operation.completionPercent;

        [operation  setProgressBlock:^(MLSDownloadOperation *operation, CGFloat progress) {
                self.sliderView.value = progress;
                self.downloadProgressLabel.text = [NSString stringWithFormat:@"%f",progress];
        }];

        [operation setCompletionBlock:^(MLSDownloadOperation *operation, NSURL *filePath, NSError *error) {
                [self setTitleForControlButton];
        }];
        [operation setNetworkSpeedBlock:^(CGFloat networkSpeed) {
                self.networkSpeedLabel.text = [NSString stringWithFormat:@"%f",networkSpeed];
        }];
        [self setTitleForControlButton];
}
- (void)setTitleForControlButton {

        if ([self.operation isCompletion])
        {
                self.controlButton.tag = ControlButtonTypeCompletion;

                self.controlButton.selected = NO;
                [self.controlButton setTitle:@"已完成" forState:(UIControlStateNormal)];

        }else if ([self.operation isPaused]){
                self.controlButton.tag = ControlButtonTypePause;

                self.controlButton.selected = NO;
                [self.controlButton setTitle:@"已暂停" forState:(UIControlStateNormal)];

        }else if ([self.operation isExecuting]) {
                self.controlButton.tag = ControlButtonTypeDownlading;

                self.controlButton.selected = YES;
                [self.controlButton setTitle:@"缓存中" forState:(UIControlStateSelected)];
        }else if ([self.operation isReady])
        {
                self.controlButton.tag = ControlButtonTypeWaiting;

                self.controlButton.selected = YES;
                [self.controlButton setTitle:@"等待中" forState:(UIControlStateSelected)];
        }
}

- (IBAction)pauseButton:(UIButton *)sender {

        if (sender.tag == ControlButtonTypePause) {

                [[MLSDownloader shareDownloader] resumeDownloadWithKey:self.operation.key completion:^(MLSDownloadOperation *operation, NSError *error) {
                        if (error == nil) {
                                self.operation = operation;
                        }else {
                                sender.tag = ControlButtonTypePause;
                        }
                }];
                [self setTitleForControlButton];

        }else if (sender.tag == ControlButtonTypeCompletion) {

                NSLog(@"播放");
        }else if (sender.tag == ControlButtonTypeDownlading) {
                
                [[MLSDownloader shareDownloader] pauseDownloadWithKey:self.operation.key completion:^(MLSDownloadOperation *operation, NSError *error) {
                        
                        self.operation = operation;
                        
                        [self setTitleForControlButton];
                }];
        }
        
        
}

@end
