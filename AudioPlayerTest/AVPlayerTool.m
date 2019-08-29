
//
//  AVPlayerTool.m
//  AudioPlayerTest
//
//  Created by huangjian on 2019/8/23.
//  Copyright © 2019 huangjian. All rights reserved.
//

#import "AVPlayerTool.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>
#import <MediaPlayer/MediaPlayer.h>

@interface AVPlayerTool ()
@property(nonatomic,strong)AVPlayer *avPlayer;

@property(nonatomic,copy)StatusResponse statusBlock;
@property(nonatomic,copy)BufferResponse bufferBlock;
@property(nonatomic,copy)PlayResponse playBlock;

@property(nonatomic,strong)CTCallCenter *callCenter;//电话监听

@property(nonatomic,assign)BOOL isBuffering;//缓冲中

@property(nonatomic,assign)CGFloat bufferProgress;//缓冲进度
@property(nonatomic,assign)CGFloat playProgress;//播放进度

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
        [self.avPlayer play];
        self.isPlaying = YES;
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
        if (current&&self.isPlaying) {
            float progress = current / total;
            strongSelf.items[strongSelf.currentItem].duration = total;
            strongSelf.items[strongSelf.currentItem].playedTime = current;
            [strongSelf lockScreenConfig];
            [strongSelf checkLogShowWithString:[NSString stringWithFormat:@"-播放进度--%f,---%f,---%f",current,total,progress]];
            //更新播放进度条
            !strongSelf.playBlock?:strongSelf.playBlock(current,total,progress);
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChange:)   name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
    
    self.callCenter = [[CTCallCenter alloc] init];
    [self.callCenter setCallEventHandler:^(CTCall * _Nonnull call) {
        if ([[call callState] isEqual:CTCallStateIncoming]) {
            //电话接通
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf pause];
            });
        }
    }];
    
    [self lockScreenConfig];
    
    [self createRemoteCommandCenter];
}
//MARK: - 锁屏相关
-(void)lockScreenConfig {
    
    // 1.获取锁屏界面中心
    MPNowPlayingInfoCenter *playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
    
    // 2.设置展示的信息
    NSMutableDictionary *playingInfo = [NSMutableDictionary dictionary];
    // 设置歌曲标题
    if (self.items[self.currentItem].title) {
        [playingInfo setObject:self.items[self.currentItem].title forKey:MPMediaItemPropertyAlbumTitle];
        [playingInfo setObject:self.items[self.currentItem].title forKey:MPMediaItemPropertyTitle];
    }
    // 设置歌手
    if (self.items[self.currentItem].singer) {
        [playingInfo setObject:self.items[self.currentItem].singer forKey:MPMediaItemPropertyArtist];
    }
    
    // 设置封面
    if (self.items[self.currentItem].image) {
        MPMediaItemArtwork *artWork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:self.items[self.currentItem].image]];
        [playingInfo setObject:artWork forKey:MPMediaItemPropertyArtwork];
    }
    // 设置歌曲播放的总时长
    [playingInfo setObject:@(self.items[self.currentItem].duration) forKey:MPMediaItemPropertyPlaybackDuration];
    //设置已经播放时长
    [playingInfo setObject:@(self.items[self.currentItem].playedTime) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    
    playingInfoCenter.nowPlayingInfo = playingInfo;
    
    // 3.让应用程序可以接受远程事件
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
}

//锁屏界面开启和监控远程控制事件
- (void)createRemoteCommandCenter{
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    //耳机线控的暂停/播放
    commandCenter.togglePlayPauseCommand.enabled = YES;
    commandCenter.playCommand.enabled = YES;
    commandCenter.pauseCommand.enabled = YES;
    __weak typeof(self) weakSelf = self;
    [commandCenter.togglePlayPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if (weakSelf.isPlaying) {
            [weakSelf pause];
        }else {
            [weakSelf play];
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        NSLog(@"暂停");
        [weakSelf pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.stopCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        NSLog(@"停止");
        [weakSelf stop];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        NSLog(@"播放");
        [weakSelf play];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        NSLog(@"上一首");
        [weakSelf playPre];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        NSLog(@"下一首");
        [weakSelf playNext];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

//    [commandCenter.seekForwardCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
//        MPSeekCommandEvent * playbackPositionEvent = (MPSeekCommandEvent *)event;
//        [weakSelf seekWithTime:playbackPositionEvent.timestamp];
//        return MPRemoteCommandHandlerStatusSuccess;
//    }];
//    [commandCenter.seekBackwardCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
//        MPSeekCommandEvent * playbackPositionEvent = (MPSeekCommandEvent *)event;
//        [weakSelf seekWithTime:playbackPositionEvent.timestamp];
//        return MPRemoteCommandHandlerStatusSuccess;
//    }];
}

//关闭远程控制中心
- (void)closeRemoteCommandCenter {
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.pauseCommand removeTarget:self];
    [commandCenter.playCommand removeTarget:self];
    [commandCenter.previousTrackCommand removeTarget:self];
    [commandCenter.nextTrackCommand removeTarget:self];
    [commandCenter.seekBackwardCommand removeTarget:self];
    [commandCenter.seekForwardCommand removeTarget:self];
    commandCenter = nil;
}
//MARK: - 暂停
-(void)pause{
    if (self.avPlayer&&self.isPlaying) {
        [self.avPlayer pause];
        self.isPlaying = NO;
    }
}
//MARK: - 停止
-(void)stop{
    [self.items removeAllObjects];
    [self.avPlayer removeObserver:self forKeyPath:@"status"];
    [self.avPlayer removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self closeRemoteCommandCenter];
    if (self.isPlaying) {
        self.isPlaying = NO;
    }
}
//MARK: - Observer  Method
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {//状态
        switch (self.avPlayer.status) {
            case AVPlayerStatusUnknown:
                [self checkLogShowWithString:@"未知状态"];
                [self stop];
                !self.statusBlock?:self.statusBlock(kPlayerStatusUnknown);
                break;
            case AVPlayerStatusReadyToPlay:
                [self checkLogShowWithString:@"准备播放"];
                self.isPlaying = YES;
                !self.statusBlock?:self.statusBlock(kPlayerStatusReadyToPlay);
                break;
            case AVPlayerStatusFailed:
                [self checkLogShowWithString:@"加载失败"];
                [self stop];
                !self.statusBlock?:self.statusBlock(kPlayerStatusFailed);
                break;
                
            default:
                [self checkLogShowWithString:@"未知错误"];
                [self stop];
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
        self.bufferProgress = scale;
        //更新缓冲进度条
        !self.bufferBlock?:self.bufferBlock(totalLoadTime,duration,scale);
        
    }
}

- (void)audioRouteChange:(NSNotification*)notification
{
    
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            //耳机插入
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            //耳机拔出
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self pause];
            });
        }
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            
            break;
    }
}

- (void)audioInterruption:(NSNotification *)notification{
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger interuptionType = [[interuptionDict     valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    NSNumber* seccondReason = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey] ;
    switch (interuptionType) {
        case AVAudioSessionInterruptionTypeBegan:
        {
            NSLog(@"收到中断，停止音频播放");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self pause];
            });
            break;
        }
        case AVAudioSessionInterruptionTypeEnded:
            NSLog(@"系统中断结束");
            break;
    }
    switch ([seccondReason integerValue]) {
        case AVAudioSessionInterruptionOptionShouldResume:
            NSLog(@"恢复音频播放");
            break;
        default:
            break;
    }
}

//MARK: - 播放结束
-(void)playFinied:(AVPlayerItem *)item{
    [self checkLogShowWithString:@"播放结束"];
    [self pause];
    !self.statusBlock?:self.statusBlock(kPlayerStatusEnd);
}

//MARK: - 切换音频
-(void)replaceItemWithUrl:(NSString *)url{
    NSString *urlString = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:urlString]];
    [self checkPlayWithItem:playerItem];
}
//MARK: - 播放上一首
-(void)playPre{
    if (self.currentItem - 1 < 0) {
        return;
    }
    self.currentItem--;
    [self playWithItemIndex:self.currentItem];
    [self lockScreenConfig];
}
//MARK: - 播放下一首
-(void)playNext{
    if (self.currentItem + 1 >= self.items.count) {
        return;
    }
    self.currentItem++;
    [self playWithItemIndex:self.currentItem];
    [self lockScreenConfig];
}
//MARK: - 播放指定下标音乐
-(void)playWithItemIndex:(NSInteger)index{
    if (self.items.count<=1) {
        return;
    }
    [self replaceItemWithUrl:self.items[self.currentItem].url];
}

//MARK: - 拖到指定比例播放 0-1
-(void)seekToPlayWithTimeScale:(CGFloat)timeScale{
    if (timeScale > 1) {
        timeScale = 1;
    }
    if (timeScale < 0) {
        timeScale = 0;
    }
    CGFloat timeTotal = CMTimeGetSeconds(self.avPlayer.currentItem.duration);
    [self seekWithTime:timeTotal*timeScale];
}
-(void)seekWithTime:(NSInteger)time{
    CMTime seekTime = CMTimeMake(time, 1);
    [self.avPlayer.currentItem cancelPendingSeeks];
    [self.avPlayer.currentItem seekToTime:seekTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:nil];
}

//MARK: - 实时监听状态，缓冲进度，播放进度
-(void)observerWithStatus:(StatusResponse _Nullable)status buffer:(BufferResponse _Nullable)buffer play:(PlayResponse _Nullable)play{
    self.statusBlock = status;
    self.bufferBlock = buffer;
    self.playBlock = play;
}

//MARK: - 校验播放
-(void)checkPlayWithItem:(AVPlayerItem *)item{
    if (@available(iOS 9.0, *)) {
        item.canUseNetworkResourcesForLiveStreamingWhilePaused = NO;
    }
    if (@available(iOS 10.0, *)) {
        //防止新系统有时播放不了情况
        item.preferredForwardBufferDuration = 1;
    }
    if (self.avPlayer&&self.avPlayer.currentItem) {
        [self.avPlayer replaceCurrentItemWithPlayerItem:item];
        self.isPlaying = YES;
    }else{
        AVPlayer *player = [[AVPlayer alloc]initWithPlayerItem:item];
        self.avPlayer = player;
        [self addObserver];
        [self play];
    }
    if (@available(iOS 10.0, *)) {
        self.avPlayer.automaticallyWaitsToMinimizeStalling = NO;//直接播放，不管缓冲完没有
    } 
}
//MARK: - 打印log
-(void)checkLogShowWithString:(NSString *)string{
    if (self.isShowLog) {
        NSLog(@"AVPlayerToolLog : %@",string);
    }
}

-(NSMutableArray<ItemInfo *> *)items{
    if (!_items) {
        _items = [NSMutableArray array];
    }
    return _items;
}

@end

@implementation ItemInfo


@end
