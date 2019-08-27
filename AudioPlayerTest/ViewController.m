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
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTime;
@property (weak, nonatomic) IBOutlet UILabel *currentUrl;

@property(nonatomic,assign)BOOL isSlidering;
@property(nonatomic,assign)CGFloat playProgress;

@property(nonatomic,strong)NSArray<NSString *> *urls;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[AVPlayerTool shareInstance]playWithUrl:@"http://7xt9bh.com2.z0.glb.qiniucdn.com/data/upload/b5aac03b9c017b8be66d8d627244662b.mp3"];
    
    [AVPlayerTool shareInstance].urlArray = self.urls.mutableCopy;
    [AVPlayerTool shareInstance].currentItem = 0;
    self.currentUrl.text = self.urls[0];
    
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
            NSInteger min = totalTime/60;
            NSInteger second = totalTime - min*60;
            self.totalTime.text = [NSString stringWithFormat:@"%ld:%ld",min,second];
            NSInteger currentMin = progress/60;
            NSInteger currentSecond = progress - currentMin*60;
            self.progressLabel.text = [NSString stringWithFormat:@"%ld:%ld",currentMin,currentSecond];
        }
        
    }];
}
- (IBAction)preAction:(UIButton *)sender {
    [[AVPlayerTool shareInstance]playPre];
    self.currentUrl.text = self.urls[[AVPlayerTool shareInstance].currentItem];
}
- (IBAction)nextAction:(UIButton *)sender {
    [[AVPlayerTool shareInstance]playNext];
    self.currentUrl.text = self.urls[[AVPlayerTool shareInstance].currentItem];
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

-(NSArray<NSString *> *)urls{
    if (!_urls) {
        _urls = @[@"http://7xt9bh.com2.z0.glb.qiniucdn.com/data/upload/b5aac03b9c017b8be66d8d627244662b.mp3",@"http://7xt9bh.com2.z0.glb.qiniucdn.com/data/upload/f157dd9f589c9f0f442fe949290d2056.mp3",@"http://7xt9bh.com2.z0.glb.qiniucdn.com/data/upload/0a958abea324628d6621cc79ba1a4b8a.mp3",
                  @"http://7xt9bh.com2.z0.glb.qiniucdn.com/data/upload/b16fa647e22ed8e6a6331c5df067fef4.mp3"];
    }
    return _urls;
}

@end
