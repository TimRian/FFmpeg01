//
//  ViewController.m
//  FFmpeg01
//
//  Created by Tim Duncan on 2017/7/12.
//  Copyright © 2017年 Tim Duncan. All rights reserved.
//

#import "ViewController.h"
#import "ffmpeg.h"

//播放
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "MBProgressHUD.h"
#import <AVKit/AVKit.h>

@interface ViewController (){
    NSString *_inputPath;
    NSString *_outputPath;
}

@property (weak, nonatomic) IBOutlet UIButton *cutBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _inputPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mov"];
    _outputPath = [NSString stringWithFormat:@"%@/tmp/%@", NSHomeDirectory(), @"output.mov"];
    NSLog(@"inputPath = %@", _inputPath);
    NSLog(@"outputPath = %@", _outputPath);
    
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.playBtn setHidden:![[NSFileManager defaultManager]fileExistsAtPath:_outputPath]];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(threadWillExit) name:NSThreadWillExitNotification object:nil];

}

//ffmpeg命令行线程将要结束时调用
-(void)threadWillExit
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.playBtn setHidden:NO];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
}

/**
 裁剪

 @param sender cut
 */
- (IBAction)cut:(id)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [NSThread detachNewThreadSelector:@selector(working) toTarget:self withObject:nil];
}


-(void)working
{
    if([[NSFileManager defaultManager]fileExistsAtPath:_outputPath])
    {
        [[NSFileManager defaultManager]removeItemAtPath:_outputPath error:nil];
        NSLog(@"删除成功");
    }
    
    [self cutInputVideoPath:(char*)[_inputPath UTF8String] outPutVideoPath:(char*)[_outputPath UTF8String] startTime:(char*)[@"0" UTF8String] endTime:(char*)[@"2" UTF8String]];

}


/**
 播放

 @param sender paly
 */
- (IBAction)play:(id)sender {
    
    AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:_outputPath]];
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    playerViewController.player = player;
    [self presentViewController:playerViewController animated:YES completion:nil];
    [playerViewController.player play];
    
}


//裁剪视频函数, 命令行如下:
//ffmpeg -i input.mp4 -ss **START_TIME** -t **STOP_TIME** -acodec copy -vcodec copy output.mp4
- (void)cutInputVideoPath:(char*)inputPath outPutVideoPath:(char*)outputPath startTime:(char*)startTime endTime:(char*)endTime
{
    
    int argc = 14;
    char **arguments = calloc(argc, sizeof(char*));
    if(arguments != NULL)
    {
        arguments[0] = "ffmpeg";
        arguments[1] = "-ss";
        arguments[2] = startTime;
        arguments[3] = "-t";
        arguments[4] = endTime;
        arguments[5] = "-i";
        arguments[6] = inputPath;
        arguments[7] = "-acodec";
        arguments[8] = "copy";
        arguments[9] = "-vcodec";
        arguments[10]= "copy";
        arguments[11] = "-avoid_negative_ts";
        arguments[12] = "1";
        arguments[13]= outputPath;
        
        ffmpeg_main(argc, arguments);
    }
    
}




@end
