//
//  ViewController.m
//  AudioPlayerTest
//
//  Created by huangjian on 2019/8/23.
//  Copyright © 2019 huangjian. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "AVPlayerTool.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIButton *preBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

@property(nonatomic,assign)BOOL isSlidering;
@property(nonatomic,assign)CGFloat playProgress;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[AVPlayerTool shareInstance]playWithUrl:@"http://7xt9bh.com2.z0.glb.qiniucdn.com/data/upload/b5aac03b9c017b8be66d8d627244662b.mp3"];
    self.playBtn.selected = YES;
    
    [AVPlayerTool shareInstance].isShowLog = YES;;
    [[AVPlayerTool shareInstance]observerWithStatus:^(PlayerStatus status) {
        switch (status) {
            case kPlayerStatusEnd:
                self.playBtn.selected = NO;
                break;
                
            default:
                break;
        }
    } buffer:^(CGFloat progress, CGFloat totalTime, CGFloat scale) {
         //NSLog(@"--%lf ---%lf ---%lf",progress,totalTime,scale);
    } play:^(CGFloat progress, CGFloat totalTime, CGFloat scale) {
         //NSLog(@"--%lf ---%lf ---%lf",progress,totalTime,scale);
        self.playProgress = scale;
        if (!self.isSlidering) {
            self.slider.value = scale;
        }
        
    }];
}
- (IBAction)preAction:(UIButton *)sender {
    
}
- (IBAction)nextAction:(UIButton *)sender {
    
}
- (IBAction)playAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [[AVPlayerTool shareInstance]play];
        
    }else{
        [[AVPlayerTool shareInstance]pause];
    }
}
- (IBAction)valueChange:(UISlider *)sender {
    self.isSlidering = YES;
}
- (IBAction)sliderEnd:(UISlider *)sender {
    
    [[AVPlayerTool shareInstance]seekToPlayWithTimeScale:sender.value];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.22 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isSlidering = NO;
    });
}

@end
