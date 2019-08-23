
//
//  AVPlayerTool.m
//  AudioPlayerTest
//
//  Created by huangjian on 2019/8/23.
//  Copyright © 2019 huangjian. All rights reserved.
//

#import "AVPlayerTool.h"
#import <AVFoundation/AVFoundation.h>

@interface AVPlayerTool ()
@property(nonatomic,strong)AVPlayer *avPlayer;

@property(nonatomic,copy)StatusResponse statusBlock;
@property(nonatomic,copy)BufferResponse bufferBlock;
@property(nonatomic,copy)PlayResponse playBlock;
@end
@implementation AVPlayerTool

+(instancetype)shareInstance
{
    static AVPlayerTool * singleClass = nil;
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        singleClass = [[AVPlayerTool alloc] init];
    }) ;
    
    return singleClass ;
}
//MARK: - 初始化播放
-(void)playWithUrl:(NSString *)url{
    NSString *urlString = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:urlString]];
    [self checkPlayWithItem:playerItem];
}
//MARK: - 播放
-(void)play{
    if (self.avPlayer) {
        [self addObserver];
        [self.avPlayer play];
    }
}
//MARK: - 添加监听
-(void)addObserver{
    [self.avPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监听缓冲状态
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //播放结束事件的监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playFinied:) name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.avPlayer.currentItem];
    __weak typeof(self) weakSelf = self;
    [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        //当前播放的时间
        float current = CMTimeGetSeconds(time);
        //总时间
        float total = CMTimeGetSeconds(weakSelf.avPlayer.currentItem.duration);
        if (current) {
            float progress = current / total;
            //更新播放进度条
            [strongSelf checkLogShowWithString:[NSString stringWithFormat:@"-播放进度--%f,---%f,---%f",current,total,progress]];
            !strongSelf.playBlock?:strongSelf.playBlock(current,total,progress);
        }
    }];
}
//MARK: - 暂停
-(void)pause{
    if (self.avPlayer) {
        [self.avPlayer pause];
    }
}
//MARK: - 停止
-(void)stop{
    [self.urlArray removeAllObjects];
    [self.avPlayer removeObserver:self forKeyPath:@"status"];
    [self.avPlayer removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}
//MARK: - Observer  Method
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {//状态
        switch (self.avPlayer.status) {
            case AVPlayerStatusUnknown:
                [self checkLogShowWithString:@"未知状态"];
                !self.statusBlock?:self.statusBlock(kPlayerStatusUnknown);
                break;
            case AVPlayerStatusReadyToPlay:
                [self checkLogShowWithString:@"准备播放"];
                !self.statusBlock?:self.statusBlock(kPlayerStatusReadyToPlay);
                break;
            case AVPlayerStatusFailed:
                [self checkLogShowWithString:@"加载失败"];
                !self.statusBlock?:self.statusBlock(kPlayerStatusFailed);
                break;
                
            default:
                [self checkLogShowWithString:@"未知错误"];
                !self.statusBlock?:self.statusBlock(kPlayerStatusUnknown);
                break;
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {//缓冲
        
        NSArray *timeRanges = self.avPlayer.currentItem.loadedTimeRanges;
        //本次缓冲的时间范围
        CMTimeRange timeRange = [timeRanges.firstObject CMTimeRangeValue];
        //缓冲总长度
        NSTimeInterval totalLoadTime = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
        //音乐的总时间
        NSTimeInterval duration = CMTimeGetSeconds(self.avPlayer.currentItem.duration);
        //计算缓冲百分比例
        NSTimeInterval scale = totalLoadTime/duration;
    
        [self checkLogShowWithString:[NSString stringWithFormat:@"-缓冲进度--%f,---%f,---%f",totalLoadTime,duration,scale]];
        //更新缓冲进度条
        !self.bufferBlock?:self.bufferBlock(totalLoadTime,duration,scale);
        
    }
}
//MARK: - 播放结束
-(void)playFinied:(AVPlayerItem *)item{
    [self checkLogShowWithString:@"播放结束"];
    !self.statusBlock?:self.statusBlock(kPlayerStatusEnd);
}

//MARK: - 切换音频
-(void)replaceItemWithUrl:(NSString *)url{
    NSString *urlString = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:urlString]];
    [self checkPlayWithItem:playerItem];
}
//MARK: - 拖到指定比例播放 0-1
-(void)seekToPlayWithTimeScale:(CGFloat)timeScale{
    CGFloat timeTotal = CMTimeGetSeconds(self.avPlayer.currentItem.duration);
    [self.avPlayer seekToTime:CMTimeMake(timeTotal*timeScale, 1)];
}

//MARK: - 实时监听状态，缓冲进度，播放进度
-(void)observerWithStatus:(StatusResponse _Nullable)status buffer:(BufferResponse _Nullable)buffer play:(PlayResponse _Nullable)play{
    self.statusBlock = status;
    self.bufferBlock = buffer;
    self.playBlock = play;
}

//MARK: - 校验播放
-(void)checkPlayWithItem:(AVPlayerItem *)item{
    if (self.avPlayer) {
        [self.avPlayer replaceCurrentItemWithPlayerItem:item];
    }else{
        AVPlayer *player = [[AVPlayer alloc]initWithPlayerItem:item];
        self.avPlayer = player;
        [self play];
    }
}
//MARK: - 打印log
-(void)checkLogShowWithString:(NSString *)string{
    if (self.isShowLog) {
        NSLog(@"AVPlayerToolLog : %@",string);
    }
}

-(NSMutableArray<NSString *> *)urlArray{
    if (!_urlArray) {
        _urlArray = [NSMutableArray array];
    }
    return _urlArray;
}

@end
