//
//  ViewController.m
//  AudioPlayerTest
//
//  Created by huangjian on 2019/8/23.
//  Copyright © 2019 huangjian. All rights reserved.
//

#import "ViewController.h"
#import <FreeStreamer/FSAudioStream.h>
#import <AVFoundation/AVFoundation.h>

#import "AVPlayerTool.h"

@interface ViewController ()
@property(nonatomic,strong)FSAudioStream *player;

@property(nonatomic,strong)AVPlayer *avPlayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[AVPlayerTool shareInstance]playWithUrl:@"http://7xt9bh.com2.z0.glb.qiniucdn.com/data/upload/c7c135241b11117c7fd1e5672d6d8474.mp3"];
    
    [[AVPlayerTool shareInstance]observerWithStatus:^(PlayerStatus status) {
        
    } buffer:^(CGFloat progress, CGFloat totalTime, CGFloat scale) {
         NSLog(@"--%lf ---%lf ---%lf",progress,totalTime,scale);
    } play:^(CGFloat progress, CGFloat totalTime, CGFloat scale) {
         NSLog(@"--%lf ---%lf ---%lf",progress,totalTime,scale);
    }];
}

@end
