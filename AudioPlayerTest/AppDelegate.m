//
//  AppDelegate.m
//  AudioPlayerTest
//
//  Created by huangjian on 2019/8/23.
//  Copyright © 2019 huangjian. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

#import <MediaPlayer/MediaPlayer.h>
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    //设置后台播放功能
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
    // 开始接受远程控制
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    //锁屏信息
    NSMutableDictionary *songInfo = [ [NSMutableDictionary alloc] init];
    //锁屏图片
    UIImage *img = [UIImage imageNamed:@"解锁弹窗图"];
    if (img) {
        MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc]initWithImage:img];
        [songInfo setObject: albumArt forKey:MPMediaItemPropertyArtwork ];
    }
    //锁屏标题
    NSString *title = @"music";
    [songInfo setObject:[NSNumber numberWithFloat:100] forKey:MPMediaItemPropertyPlaybackDuration];
    [songInfo setObject:title forKey:MPMediaItemPropertyTitle];
    [songInfo setObject:title forKey:MPMediaItemPropertyAlbumTitle];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo ];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
