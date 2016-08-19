//
//  PlayViewController.h
//  IpCameraClient
//
//  Created by jiyonglong on 12-4-23.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPPPStatusProtocol.h"
#import "PPPPChannelManagement.h"
#import "ParamNotifyProtocol.h"
#import "ImageNotifyProtocol.h"
#import "PicPathManagement.h"
#import "CustomAVRecorder.h"
#import "RecPathManagement.h"
#import "NotifyEventProtocol.h"
#import "MyGLViewController.h"

#import "RunCarModeProtocol.h"




// new

#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <AssetsLibrary/AssetsLibrary.h>





@interface PlayViewController : UIViewController <UINavigationBarDelegate, PPPPStatusProtocol, ParamNotifyProtocol,ImageNotifyProtocol,RunCarModeProtocol,AVAudioRecorderDelegate,UIScrollViewDelegate>
{    
    UIImageView * imgView;
    IBOutlet UIActivityIndicatorView *progressView;
    IBOutlet UILabel *LblProgress;       
    IBOutlet UIBarButtonItem *btnTitle;
    IBOutlet UILabel *timeoutLabel;
    
    
    //行车记录仪
    IBOutlet UIBarButtonItem *btnRecord;
    IBOutlet UIBarButtonItem *btnUpDown;
    IBOutlet UIBarButtonItem *btnRemoteRecord;
    BOOL isSoSPressed;
    BOOL isResolutionVGA;
    
    int mType;
    
    NSTimer *timer;
    int timeNumber;
    IBOutlet UIBarButtonItem *btnUpdateTime;
    
    
    IBOutlet UIBarButtonItem *btnSnapshot;
    
    UILabel *labelContrast;
    UISlider *sliderContrast;
    UILabel *labelBrightness;
    UISlider *sliderBrightness; 

    UIImage *ImageBrightness;
    UIImage *ImageContrast;    
    NSString *cameraName;
    NSString *strDID;
    NSString *strUser;
    NSString *strPwd;
    
    
    CGPoint beginPoint;    
    int m_Contrast;
    int m_Brightness;
    BOOL bGetVideoParams;
    BOOL bPlaying;    
    BOOL bManualStop;  
    CPPPPChannelManagement *m_pPPPPChannelMgt;    
    int nResolution;
    UILabel *OSDLabel;
    UILabel *TimeStampLabel;    
    NSInteger nUpdataImageCount;    
    NSTimer *timeoutTimer;
    BOOL m_bAudioStarted;
    BOOL m_bTalkStarted;    
    BOOL m_bGetStreamCodecType;
    int m_StreamCodecType;
    int m_nP2PMode;
    int m_nTimeoutSec;    
    BOOL m_bToolBarShow;
    BOOL m_bPtzIsUpDown;
    BOOL m_bPtzIsLeftRight;
    BOOL m_bUpDownMirror;
    BOOL m_bLeftRightMirror;
    int m_nFlip;
    BOOL m_bBrightnessShow;
    BOOL m_bContrastShow;
    
    int m_nDisplayMode;
    int m_nVideoWidth;
    int m_nVideoHeight;
    
    int m_nScreenWidth;
    int m_nScreenHeight;
    
    PicPathManagement *m_pPicPathMgt;
    RecPathManagement *m_pRecPathMgt;
    
    CCustomAVRecorder *m_pCustomRecorder;
    NSCondition *m_RecordLock;
    
    id<NotifyEventProtocol> PicNotifyDelegate;
    id<NotifyEventProtocol> RecNotifyDelegate;
    
    MyGLViewController *myGLViewController;
    
    int m_videoFormat;
    
    Byte *m_pYUVData;
    NSCondition *m_YUVDataLock;
    int m_nWidth;
    int m_nHeight;
    BOOL isRecoding;
    int recordNum;
    NSString *strMemory;
    IBOutlet UIBarButtonItem *btnMemory;
    
    
    //wifi cam
    
    IBOutlet UIBarButtonItem *btnGoStop;
    BOOL isGo;
    
    IBOutlet UILabel *labelRecording;
    BOOL isRecordStart;
    BOOL isDataComeback;
    BOOL isStop;
    
    NSInteger deviceStatus;
    
    
    int m_mainScreenWidth;
    int m_mainScreenHeight;
    BOOL isLandScap;
    
    BOOL isIOS7;
    int takepicNum;
    
    
    
    //// new
    BOOL isRecording,isProcessing;
    CGFloat scaleValue;

    AVPlayer * liveVideoPlayer;
    
    AVPlayerItem *playerItem;
    
    NSMutableArray *numberOfScreenshots;
    
    CFAbsoluteTime      _timeOfFirstFrame;
    NSTimer*recordingTimerVideo;

    NSDate* startedAt;

    AVAudioRecorder *recorder;
    
    __weak IBOutlet UILabel *messageLabel;
    NSTimer*waitingTimer,*recordingTimer,*autometicStopTimer;
    int currentTimeInSeconds;
    
    NSMutableArray * tempDetailsArray, *p2pPathDetails;
    NSString * audioOrVideo, * connectionStatus;
    
    __weak IBOutlet UIButton *recordingButton;
    
    NSInteger counter;
    CGAffineTransform globalTransform;
    CGRect globalFrame;
    
    UIView * containerCiew;
}



#pragma mark - New changes to make the design same


- (IBAction)recordingButtonAction:(id)sender;

// For the imageView  zoom
@property (nonatomic,strong) IBOutlet UIScrollView *interfaceScrollView;
// For the video record time
@property (strong, nonatomic) IBOutlet UIView *viewRecordingTime;
@property (strong, nonatomic) IBOutlet UIView *bottomButtonView;

- (IBAction)actionResetButton:(id)sender;
- (IBAction)actionZoomIn:(id)sender;
- (IBAction)actionZoomOut:(id)sender;
- (IBAction)actionLeftRtate:(id)sender;
- (IBAction)actionRightRotate:(id)sender;
- (IBAction)moveImage:(UIPanGestureRecognizer*)recognizer;



#pragma mark - end


@property (nonatomic,strong)NSString * savedImagePathTemp;

@property (nonatomic,strong)NSURL *AudioURlP2P, *VideoURLP2P;

@property (nonatomic,retain)UIView  *portraitView;
@property (nonatomic,retain) IBOutlet UILabel *labelRecording;
@property (nonatomic,copy)NSString *strMemory;
@property BOOL isRecoding;
@property (nonatomic, assign) CPPPPChannelManagement *m_pPPPPChannelMgt;
@property (nonatomic, copy) NSString *cameraName;
@property (nonatomic, copy) NSString *strDID;
@property (nonatomic,copy)NSString *strPwd;
@property (nonatomic,copy)NSString *strUser;
@property (nonatomic, retain) UIActivityIndicatorView *progressView;
@property (nonatomic, retain) UILabel *LblProgress;
@property (nonatomic, retain) UIBarButtonItem *btnTitle;
@property (nonatomic, retain) UILabel *timeoutLabel;
@property int m_nP2PMode;


@property (nonatomic, retain) UIBarButtonItem *btnGoStop;
@property (nonatomic, retain) UIBarButtonItem *btnStatusPrompt;


@property (nonatomic, retain) IBOutlet UIBarButtonItem *btnMemory;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *btnRemoteRecord;

@property (nonatomic,retain)IBOutlet UIBarButtonItem *btnUpdateTime;


@property (nonatomic, assign) PicPathManagement *m_pPicPathMgt;
@property (nonatomic, retain) UIBarButtonItem *btnRecord;

@property (nonatomic, assign) RecPathManagement *m_pRecPathMgt;
@property (nonatomic, assign) id<NotifyEventProtocol> PicNotifyDelegate;
@property (nonatomic, assign) id<NotifyEventProtocol> RecNotifyDelegate;
@property (nonatomic, retain) UIBarButtonItem *btnSnapshot;


#pragma mark- JS Products Method



// Important
- (void)StopPlay: (int) bForce;
- (IBAction) btnSnapshot:(id)sender;
- (IBAction) btnRecord:(id)sender;
- (IBAction) btnRemoteRecord:(id)sender;

- (IBAction) btnGoStop:(id)sender;

- (IBAction)backButtonAction:(id)sender;
@end
