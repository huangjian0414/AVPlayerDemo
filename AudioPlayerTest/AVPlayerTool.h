//
//  AVPlayerTool.h
//  AudioPlayerTest
//
//  Created by huangjian on 2019/8/23.
//  Copyright © 2019 huangjian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PlayerStatus) {
    kPlayerStatusUnknown, //未知状态
    kPlayerStatusReadyToPlay,//准备播放
    kPlayerStatusFailed, // 播放失败
    kPlayerStatusEnd  //播放完成
};

typedef void(^StatusResponse)(PlayerStatus status);
typedef void(^BufferResponse)(CGFloat progress, CGFloat totalTime, CGFloat scale);
typedef void(^PlayResponse)(CGFloat progress, CGFloat totalTime, CGFloat scale);

@class ItemInfo;
@interface AVPlayerTool : NSObject
+(instancetype)shareInstance;
/**
 播放资源数组
 */
@property(nonatomic,strong)NSMutableArray<ItemInfo *> *items;

/**
 当前播放下标
 */
@property(nonatomic,assign)NSInteger currentItem;
/**
 初始化播放
 */
-(void)playWithUrl:(NSString *)url;

/**
 播放
 */
-(void)play;

/**
 暂停
 */
-(void)pause;

/**
 停止
 */
-(void)stop;

/**
 切换音频
 */
-(void)replaceItemWithUrl:(NSString *)url;

/**
 播放上一首
 */
-(void)playPre;

/**
 播放下一首
 */
-(void)playNext;

/**
 拖到指定比例播放  0-1
 */
-(void)seekToPlayWithTimeScale:(CGFloat)timeScale;

/**
 实时监听状态，缓冲进度，播放进度
 */
-(void)observerWithStatus:(StatusResponse _Nullable)status buffer:(BufferResponse _Nullable)buffer play:(PlayResponse _Nullable)play;

/**
 打印点东西
 */
@property(nonatomic,assign)BOOL isShowLog;

/**
 是否正在播放
 */
@property(nonatomic,assign)BOOL isPlaying;
@end

@interface ItemInfo : NSObject
@property(nonatomic,copy)NSString *url;//音频链接
@property(nonatomic,copy)NSString *title;//标题
@property(nonatomic,copy)NSString *singer;//歌手
@property(nonatomic,copy)NSString *image;//封面图
@property(nonatomic,assign)CGFloat duration;//音频总时长
@property(nonatomic,assign)CGFloat playedTime;//已播放时长
@end

NS_ASSUME_NONNULL_END
