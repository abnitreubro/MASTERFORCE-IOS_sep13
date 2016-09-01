//
//  PlayViewController.m
//  IpCameraClient
//
//  Created by jiyonglong on 12-4-23.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "PlayViewController.h"
#include "AppDelegate.h"

#import "obj_common.h"
#import "PPPPDefine.h"
#import "mytoast.h"
#import "cmdhead.h"
#import "moto.h"
#import "CustomToast.h"
#import <sys/time.h>
#import "APICommon.h"
#import "avilib.h"
#import <QuartzCore/QuartzCore.h>
#import  <AVFoundation/AVFoundation.h>

@implementation PlayViewController


@synthesize m_pPPPPChannelMgt;

@synthesize cameraName,strDID,strPwd,strUser,progressView,LblProgress,btnTitle,timeoutLabel;

@synthesize m_pPicPathMgt,btnRecord,m_pRecPathMgt,PicNotifyDelegate,RecNotifyDelegate,btnSnapshot;

@synthesize btnUpdateTime,isRecoding,btnRemoteRecord,btnMemory,strMemory,labelRecording,btnGoStop;

@synthesize AudioURlP2P,VideoURLP2P;








#pragma mark -
#pragma mark system


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.view layoutIfNeeded];
    [_interfaceScrollView layoutIfNeeded];
    counter = 0;
    
    containerCiew = [[UIView alloc] initWithFrame:_interfaceScrollView.frame];
    imgView = [[UIImageView alloc] initWithFrame:_interfaceScrollView.frame];
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    
    [_interfaceScrollView addSubview:containerCiew];
    [containerCiew addSubview:imgView];
    
    takepicNum=0;
    
    isLandScap=NO;
    
    deviceStatus=PPPP_STATUS_UNKNOWN;
    
    isGo=YES;
    isStop=NO;
    labelRecording.text=[NSString stringWithFormat:@"%@%@",NSLocalizedStringFromTable(@"play_recording", @STR_LOCALIZED_FILE_NAME, nil),@"00:00:00"];
    
    
    connectionStatus = NSLocalizedStringFromTable(@"PPPPStatusConnecting", @STR_LOCALIZED_FILE_NAME, nil);
    
    timeNumber=0;
    isRecoding=NO;
    isRecordStart=NO;
    
    m_videoFormat = -1;
    nUpdataImageCount = 0;
    m_nDisplayMode = 2;
    m_nVideoWidth = 0;
    m_nVideoHeight = 0;
    m_pCustomRecorder = NULL;
    m_pYUVData = NULL;
    m_nWidth = 0;
    m_nHeight = 0;
    m_YUVDataLock = [[NSCondition alloc] init];
    m_RecordLock = [[NSCondition alloc] init];
    
    [self.btnRecord setEnabled:NO];
    [self.btnSnapshot setEnabled:NO];
    
    CGRect getFrame = [[UIScreen mainScreen]applicationFrame];
    m_nScreenHeight = getFrame.size.width;
    m_nScreenWidth = getFrame.size.height;
    
    //create yuv displayController
    myGLViewController = nil;
    
    m_bToolBarShow = YES;
    
    self.btnTitle.title = cameraName;
    
    [timeoutLabel setHidden:YES];
    m_nTimeoutSec = 15;
    timeoutTimer = nil;
    
    bGetVideoParams = NO;
    bManualStop = NO;
    m_bGetStreamCodecType = NO;
    
    self.LblProgress.text = NSLocalizedStringFromTable(@"Connecting", @STR_LOCALIZED_FILE_NAME,nil);
    
    [self.progressView setHidden:NO];
    [self.progressView startAnimating];
    
    
    if (m_pPPPPChannelMgt!=nil) {
        m_pPPPPChannelMgt->pCameraViewController = self;
        m_pPPPPChannelMgt->Start([strDID UTF8String], [strUser UTF8String], [strPwd UTF8String]);
    }
    
    [self isOutOfMemory];
    [NSThread detachNewThreadSelector:@selector(switchActionlocal) toTarget:self withObject:nil];
    
    
    //----------------- Bar button for Camera and Video -----------------//
    
    UIImage * cameraImage = [UIImage imageNamed:@"Camera_Snapshot_Green"];
    UIButton * cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //    [cameraButton addTarget:self action:@selector(btnSnapshot:) forControlEvents:UIControlEventTouchUpInside];
    [cameraButton addTarget:self action:@selector(changeToCamera) forControlEvents:UIControlEventTouchUpInside];
    
    cameraButton.bounds = CGRectMake( 0, 0, cameraImage.size.width/1.7, cameraImage.size.height/1.7 );
    [cameraButton setImage:cameraImage forState:UIControlStateNormal];
    
    
    
    btnSnapshot = [[UIBarButtonItem alloc] initWithCustomView:cameraButton];
    
    recordingButton.enabled = NO;
    
    //    btnSnapshot = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(changeToCamera)];
    
    btnSnapshot.enabled=NO;
    
    [recordingButton setImage:[UIImage imageNamed:@"Camera_NotClicked"] forState:UIControlStateNormal];
    
    
    UIImage *recorderImage = [UIImage imageNamed:@"Camera_Record_Gray"];
    UIButton *recButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [recButton addTarget:self action:@selector(changeToVideo) forControlEvents:UIControlEventTouchUpInside];
    recButton.bounds = CGRectMake( 0, 0, recorderImage.size.width/1.7, recorderImage.size.height/1.7);
    [recButton setImage:recorderImage forState:UIControlStateNormal];
    
    btnRecord = [[UIBarButtonItem alloc] initWithCustomView:recButton];
    btnRecord.enabled=NO;
    
    self.navigationItem.rightBarButtonItems = @[btnSnapshot,btnRecord];
    
    //----------------- Bar button for Camera and Video -----------------//
    
    
    self.navigationItem.title=@"MX1020 Masterforce Wi-Fi Inspection Camera/Video";
    self.navigationController.navigationItem.backBarButtonItem.title = @"";
    
    [self setUpScrolling];
    
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnce:)];
    tap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(moveImage:)];
    [self.view addGestureRecognizer:pan];
    
    [self.view bringSubviewToFront:self.bottomButtonView];
    
    
}




- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    scaleValue = 1;
    globalTransform = CGAffineTransformIdentity;
    if (deviceStatus!=PPPP_STATUS_ON_LINE) {
        NSLog(@"btnStartPPPP.....connecting...");
        m_pPPPPChannelMgt->pCameraViewController = self;
        m_pPPPPChannelMgt->Start([strDID UTF8String], [strUser UTF8String], [strPwd UTF8String]);
        [self hiddenProgresssLabel:NO];
        imgView.image = nil;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!self.navigationController.navigationBarHidden)
        {
            [UIView  animateWithDuration:.5 animations:^{
                [[self navigationController] setNavigationBarHidden:YES animated:YES];
                _bottomButtonView.alpha = 0;
            }];
        }
    });
    
    [self.view layoutIfNeeded];
    [_interfaceScrollView layoutIfNeeded];
    
    imgView.frame = _interfaceScrollView.frame;
    containerCiew.frame = _interfaceScrollView.frame;
}




-(void) viewWillLayoutSubviews{
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(EnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(EnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}





- (void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    if (deviceStatus != PPPP_STATUS_ON_LINE)
        [self StopPlay:1];
    else
    {
        if (isRecording) {
            [self recordVideo:nil];
            
        }
        if (isRecording || isProcessing)
        {
            tempDetailsArray = [[NSMutableArray alloc] initWithObjects:@"Started",audioOrVideo,@"p2p", nil];
            [[NSUserDefaults standardUserDefaults] setValue:tempDetailsArray forKey:@"recording"];
        }
    }
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}





- (void)EnterBackground{
    if (isLandScap)
        [AppDelegate setEnterBackground:YES];
    
    [self.navigationController popViewControllerAnimated:NO];
}




- (void)EnterForeground{
    NSLog(@"EnterForeground");
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)viewDidUnload {
    [super viewDidUnload];
}



- (void)dealloc {
    
    NSLog(@"PlayViewController dealloc");
    m_pPPPPChannelMgt->SetRunCarDelegate((char *)[strDID UTF8String], nil);
    
    if (TimeStampLabel != nil) {
        [TimeStampLabel release];
        TimeStampLabel = nil;
    }
    
    if (self.labelRecording != nil) {
        self.labelRecording = nil;
    }
    
    if (imgView != nil) {
        imgView = nil;
    }
    
    if (self.cameraName != nil) {
        self.cameraName = nil;
    }
    
    if (self.strDID != nil) {
        self.strDID = nil;
    }
    
    
    if (self.btnTitle != nil) {
        self.btnTitle = nil;
    }
    
    if (self.btnMemory != nil) {
        self.btnMemory = nil;
    }
    
    
    //self.m_pPicPathMgt = nil;
    
    if (self.btnRecord != nil) {
        self.btnRecord = nil;
    }
    
    if (m_RecordLock != nil) {
        [m_RecordLock release];
        m_RecordLock = nil;
    }
    
    //self.m_pRecPathMgt = nil;
    
    if (self.PicNotifyDelegate != nil) {
        self.PicNotifyDelegate = nil;
    }
    
    if (myGLViewController != nil) {
        [myGLViewController release];
        myGLViewController = nil;
    }
    
    if (m_YUVDataLock != nil) {
        [m_YUVDataLock release];
        m_YUVDataLock = nil;
    }
    SAFE_DELETE(m_pYUVData);
    
    [super dealloc];
}





#pragma mark -
#pragma mark others


- (NSString*) GetRecordFileName
{
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];
    NSString* strDateTime = [formatter stringFromDate:date];
    
    NSString *strFileName = [NSString stringWithFormat:@"%@_%@.mov",strDID , strDateTime];
    
    [formatter release];
    
    return strFileName;
}




- (NSString*) GetRecordPath: (NSString*)strFileName
{
    //创建文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //获取路径
    //参数NSDocumentDirectory要获取那种路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];//去处需要的路径
    
    NSString *strPath =nil;
    
    strPath = [documentsDirectory stringByAppendingPathComponent:strDID];
    
    [fileManager createDirectoryAtPath:strPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    strPath = [strPath stringByAppendingPathComponent:strFileName];
    
    return strPath;
}




//- (void) stopRecord
//{
//    [m_RecordLock lock];
//    SAFE_DELETE(m_pCustomRecorder);
//    [RecNotifyDelegate NotifyReloadData];
//    [m_RecordLock  unlock];
//}




-(IBAction)btnRemoteRecord:(id)sender{
    if (isRecoding) {
        btnRemoteRecord.style = UIBarButtonItemStyleBordered;
        m_pPPPPChannelMgt->SetSDcardRecordParams((char *)[strDID UTF8String], (char *)[strUser UTF8String],  (char *)[strPwd UTF8String], 0);
    }else{
        btnRemoteRecord.style = UIBarButtonItemStyleDone;
        m_pPPPPChannelMgt->SetSDcardRecordParams((char *)[strDID UTF8String], (char *)[strUser UTF8String],  (char *)[strPwd UTF8String], 1);
    }
    isRecoding=!isRecoding;
    NSLog(@"");
    return;
}





- (IBAction) btnGoStop:(id)sender{
    if (isGo) {
        [btnGoStop setImage:[UIImage imageNamed:@"play_stop.png"]];
    }else{
        [btnGoStop setImage:[UIImage imageNamed:@"play_start.png"]];
    }
    isGo=!isGo;
}





// Do not Delete being used
- (IBAction) btnRecord:(id)sender
{
    [self recordVideo:sender];
}





-(NSString *)getRecordTime:(int)secTime{
    int hour = secTime / 60 / 60;
    int minute = (secTime - hour * 3600 ) / 60;
    int sec = (secTime - hour * 3600 - minute * 60) ;
    NSString *strTime = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, sec];
    return strTime;
}



-(void)updateRecordTime{
    
    timeNumber++;
    NSString *strTime=[self getRecordTime:timeNumber];
    NSLog(@"%@",strTime);
    labelRecording.text=[NSString stringWithFormat:@"%@%@",NSLocalizedStringFromTable(@"play_recording", @STR_LOCALIZED_FILE_NAME, nil),strTime];
    //    return;
    btnUpdateTime.title=[NSString stringWithFormat:@"Recording...%d",timeNumber];
    
    NSLog(@"startRecordTime  timeNumber=%d",timeNumber);
    
    NSLog(@"set Time%ld",[[[NSUserDefaults standardUserDefaults] valueForKey:@"recordingTime"] integerValue]);
    
    if (timeNumber==([[[NSUserDefaults standardUserDefaults] valueForKey:@"recordingTime"] integerValue])*60) {
        
        
        timeNumber=0;
        isRecordStart=NO;
        labelRecording.hidden=YES;
        labelRecording.text=[NSString stringWithFormat:@"%@%@",NSLocalizedStringFromTable(@"play_recording", @STR_LOCALIZED_FILE_NAME, nil),@"00:00:00"];
        [timer invalidate];
        timer=nil;
        
        SAFE_DELETE(m_pCustomRecorder);
        [RecNotifyDelegate NotifyReloadData];
        
        [m_RecordLock unlock];
    }
}







- (void) image: (UIImage*)image didFinishSavingWithError: (NSError*) error contextInfo: (void*)contextInfo
{
    if (error != nil) {
        NSLog(@"take picture failed");
    }
    else {
        //show message image successfully saved
        [CustomToast showWithText:NSLocalizedStringFromTable(@"TakePictureSuccess", @STR_LOCALIZED_FILE_NAME, nil)
                        superView:self.view
                        bLandScap:isLandScap];
    }
}





// Being used do not delete

- (IBAction) btnSnapshot:(id)sender
{
    //------save image--------
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];//Path place needed
    
    NSString *strPath = [documentsDirectory stringByAppendingPathComponent:strDID];
    
    [fileManager createDirectoryAtPath:strPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];
    NSString* strDateTime = [formatter stringFromDate:date];
    strDateTime=[NSString stringWithFormat:@"%@_%d",strDateTime,takepicNum];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString* strDate = [formatter stringFromDate:date];
    
    NSString *strFileName = [NSString stringWithFormat:@"%@_%@.jpg", strDID, strDateTime];
    
    strPath = [strPath stringByAppendingPathComponent:strFileName];
    
    NSData *dataImage = UIImageJPEGRepresentation(imgView.image, 1.0);
    if([dataImage writeToFile:strPath atomically:YES ])
    {
        [m_pPicPathMgt InsertPicPath:strDID PicDate:strDate PicPath:strFileName];
    }
    
    [pool release];
    
    [formatter release];
    
//    [CustomToast showWithText:NSLocalizedStringFromTable(@"TakePictureSuccess", @STR_LOCALIZED_FILE_NAME, nil)
//                    superView:self.interfaceScrollView
//                    bLandScap:isLandScap];
//    
    
    messageLabel.hidden = NO;
    messageLabel.alpha = 1;
    messageLabel.text = @"Snapshot saved successfully";
    
    [UIView animateWithDuration:2.5 animations:^{
        
        messageLabel.alpha = 0;
    }];
    
}




#pragma mark - chceck for new changes





- (void) StopPlay:(int)bForce
{
    NSLog(@"StopPlay....");
    isDataComeback=NO;
    isStop=YES;
    if (m_pCustomRecorder != nil) {
        isRecordStart=NO;
        SAFE_DELETE(m_pCustomRecorder);
        [RecNotifyDelegate NotifyReloadData];
    }
    if (m_pPPPPChannelMgt != NULL) {
        m_pPPPPChannelMgt->StopPPPPLivestream([strDID UTF8String]);
        m_pPPPPChannelMgt->StopPPPPAudio([strDID UTF8String]);
        m_pPPPPChannelMgt->StopPPPPTalk([strDID UTF8String]);
        m_pPPPPChannelMgt->Stop([strDID UTF8String]);
    }
    
    if (timeoutTimer != nil) {
        [timeoutTimer invalidate];
        timeoutTimer = nil;
    }
    
    
    if (bForce==100) {//100That enter the U disk
        AppDelegate *IPCAMDelegate = [[UIApplication sharedApplication] delegate];
        [IPCAMDelegate switchBack:strDID User:strUser Pwd:strPwd Type:bForce];
    }
    
    if (bForce != 1 && bForce!=100 && bManualStop == NO) {
        
        //        [CustomToast showWithText:NSLocalizedStringFromTable(@"PPPPStatusDisconnected", @STR_LOCALIZED_FILE_NAME, nil)
        //                        superView:self.view
        //                        bLandScap:YES];
        
        [self timeOutAlertMessagePopOut:@"Device Disconnected"];
    }
}






- (void) hideProgress:(id)param
{
    [self.progressView setHidden:YES];
    [self.LblProgress setHidden:YES];
    
    if (m_nP2PMode == PPPP_MODE_RELAY) {
        timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
    }
}




- (void)enableButton
{
    if (!isRecording) {
        [self.btnRecord setEnabled:YES];
        [self.btnSnapshot setEnabled:YES];
    }
    recordingButton.enabled = YES;
}




//handler the start timer
- (void)handleTimer:(NSTimer *)timer
{
    if(m_nTimeoutSec <= 0){
        [self StopPlay:1];
        return;
    }
    
    NSString *strTimeout = [NSString stringWithFormat:@"%@ %d %@", NSLocalizedStringFromTable(@"RelayModeTimeout", @STR_LOCALIZED_FILE_NAME, nil),m_nTimeoutSec,NSLocalizedStringFromTable(@"StrSeconds", @STR_LOCALIZED_FILE_NAME, nil)];
    timeoutLabel.text = strTimeout;
    m_nTimeoutSec = m_nTimeoutSec - 1;
}





- (void) updateTimeout:(id)data{
    NSString *strTimeout = [NSString stringWithFormat:@"%@ %d %@", NSLocalizedStringFromTable(@"RelayModeTimeout", @STR_LOCALIZED_FILE_NAME, nil),m_nTimeoutSec,NSLocalizedStringFromTable(@"StrSeconds", @STR_LOCALIZED_FILE_NAME, nil)];
    timeoutLabel.text = strTimeout;
    m_nTimeoutSec = m_nTimeoutSec - 1;
}



- (void) updateImage:(id)data
{
    UIImage *img = (UIImage*)data;
    
    NSLog(@"Updated ImgView h%f",img.size.height);
    NSLog(@"Updated ImgView w%f",img.size.width);
    
    imgView.image = img;
    
    
    NSLog(@"Updated height%f",imgView.frame.size.height);
    NSLog(@"Updated width%f",imgView.frame.size.width);
    [img release];
    
    //show timestamp
    [self updateTimestamp];
}



- (void) updateTimestamp
{
    //show timestamp
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString* str = [formatter stringFromDate:date];
    TimeStampLabel.text = str;
    [formatter release];
}



- (void) getCameraParams
{
    return;
    NSLog(@"getCameraParams...");
    m_pPPPPChannelMgt->GetCGI([strDID UTF8String], CGI_IEGET_CAM_PARAMS);
}





-(void)updateRecordStatus:(NSNumber *)num{
    int status=[num intValue];
    switch (status) {
        case 0:
            isRecoding=NO;
            btnRemoteRecord.style = UIBarButtonItemStyleBordered;
            
            break;
        case 1:
            isRecoding=YES;
            btnRemoteRecord.style = UIBarButtonItemStyleDone;
            
            break;
        default:
            break;
    }
}



// Check

- (void) CreateGLView
{
    myGLViewController = [[MyGLViewController alloc] init];
    
    myGLViewController.view.frame = CGRectMake(0, 0, m_nScreenWidth, m_nScreenHeight);
    [self.view addSubview:myGLViewController.view];
    [self.view bringSubviewToFront:TimeStampLabel];
    [self.view bringSubviewToFront:timeoutLabel];
    [self.view bringSubviewToFront:labelRecording];
}





- (void)switchActionlocal{
    //Set the time
    NSTimeZone *zone = [NSTimeZone localTimeZone];//Get the application default time zone current
    
    //NSInteger interval = [zone secondsFromGMTForDate:[NSDate date]];//In seconds, return to the current application and the world standard time ( Green Venice Time)
    
    NSInteger interval = -[zone secondsFromGMT];
    NSDate *date=[NSDate date];
    NSTimeInterval now=[date timeIntervalSince1970];
    //        time(0)/1000
    NSLog(@"interval=%ld",(long)interval);
    
    m_pPPPPChannelMgt->SetDateTime((char*)[strDID UTF8String], now, interval, 0, (char*)[@"" UTF8String]);
    m_pPPPPChannelMgt->CameraControl([strDID UTF8String], 40, 40);
}






#pragma mark -
#pragma mark PPPPStatusDelegate

- (void) PPPPStatus:(NSString *)astrDID statusType:(NSInteger)statusType status:(NSInteger)status
{
    NSLog(@"PlayViewController strDID: %@, statusType: %ld, status: %ld", astrDID, (long)statusType, (long)status);
    //deal with PPP Event notification
    if (bManualStop == YES) {
        return;
    }
    //Under normal circumstances this is not going to happen
    if ([astrDID isEqualToString:strDID] == NO) {
        return;
    }
    
    NSString *strPPPPStatus = nil;
    if (statusType == MSG_NOTIFY_TYPE_PPPP_STATUS) {
        
        deviceStatus = status;
        switch (status) {
            case PPPP_STATUS_UNKNOWN:
                strPPPPStatus = NSLocalizedStringFromTable(@"PPPPStatusUnknown", @STR_LOCALIZED_FILE_NAME, nil);
                break;
            case PPPP_STATUS_CONNECTING:
                strPPPPStatus = NSLocalizedStringFromTable(@"PPPPStatusConnecting", @STR_LOCALIZED_FILE_NAME, nil);
                break;
            case PPPP_STATUS_INITIALING:
                strPPPPStatus = NSLocalizedStringFromTable(@"PPPPStatusInitialing", @STR_LOCALIZED_FILE_NAME, nil);
                break;
            case PPPP_STATUS_CONNECT_FAILED:
                strPPPPStatus = NSLocalizedStringFromTable(@"PPPPStatusConnectFailed", @STR_LOCALIZED_FILE_NAME, nil);
                break;
            case PPPP_STATUS_DISCONNECT:
                strPPPPStatus = NSLocalizedStringFromTable(@"PPPPStatusDisconnected", @STR_LOCALIZED_FILE_NAME, nil);
                break;
            case PPPP_STATUS_INVALID_ID:
                strPPPPStatus = NSLocalizedStringFromTable(@"PPPPStatusInvalidID", @STR_LOCALIZED_FILE_NAME, nil);
                break;
            case PPPP_STATUS_ON_LINE:
                strPPPPStatus = NSLocalizedStringFromTable(@"PPPPStatusOnline", @STR_LOCALIZED_FILE_NAME, nil);
                
                [self performSelectorOnMainThread:@selector(getLivestream) withObject:nil waitUntilDone:NO];
                break;
            case PPPP_STATUS_DEVICE_NOT_ON_LINE:
                strPPPPStatus = NSLocalizedStringFromTable(@"CameraIsNotOnline", @STR_LOCALIZED_FILE_NAME, nil);
                break;
            case PPPP_STATUS_CONNECT_TIMEOUT:
                strPPPPStatus = NSLocalizedStringFromTable(@"PPPPStatusConnectTimeout", @STR_LOCALIZED_FILE_NAME, nil);
                break;
            default:
                strPPPPStatus = NSLocalizedStringFromTable(@"PPPPStatusUnknown", @STR_LOCALIZED_FILE_NAME, nil);
                break;
        }
        
        [self performSelectorOnMainThread:@selector(updateDeviceStatus:) withObject:strPPPPStatus waitUntilDone:NO];
        
        if (status == PPPP_STATUS_INVALID_ID
            || status == PPPP_STATUS_CONNECT_TIMEOUT
            || status == PPPP_STATUS_DEVICE_NOT_ON_LINE
            || status == PPPP_STATUS_CONNECT_FAILED||statusType==PPPP_STATUS_INVALID_USER_PWD) {
            [self performSelectorOnMainThread:@selector(StopPPPPByDID:) withObject:strDID waitUntilDone:NO];
        }
    }
}




- (void) StopPPPPByDID:(NSString*)did
{
    m_pPPPPChannelMgt->Stop([did UTF8String]);
}





-(void)updateDeviceStatus:(NSString*)strStatus{
    
    if (deviceStatus == PPPP_STATUS_CONNECTING) {
        counter = counter + 1;
        if (counter == 5) {
            [self timeOutAlertMessagePopOut:@"Connect Time Out, Please check if device is connected."];
        }
    }
    else
    {
        counter = 0;
    }
    
    if (deviceStatus!=PPPP_STATUS_CONNECTING && deviceStatus!=PPPP_STATUS_ON_LINE && deviceStatus!= PPPP_STATUS_DISCONNECT) {
        [self timeOutAlertMessagePopOut:@"Connect Time Out, Please check if device is connected."];
    }
    if (deviceStatus==PPPP_STATUS_CONNECTING) {
        self.LblProgress.text = NSLocalizedStringFromTable(@"Connecting", @STR_LOCALIZED_FILE_NAME,nil);
        self.LblProgress.hidden = NO;
        [self.progressView setHidden:NO];
        [self.progressView startAnimating];
    }
    if (deviceStatus == PPPP_STATUS_ON_LINE) {
        if(self.LblProgress.text == NSLocalizedStringFromTable(@"play_getvideofailed", @STR_LOCALIZED_FILE_NAME, nil))
            [self performSelector:@selector(reConnectLivestream) withObject:nil afterDelay:1];
        
        else
            [self hiddenProgresssLabel:YES];
        
    }
    
    if (deviceStatus== PPPP_STATUS_CONNECT_FAILED)
    {
        [self timeOutAlertMessagePopOut:@"Connect Time Out, Please check if device is connected."];
    }
    NSLog(@"The Status IS: %@",strStatus);
    
    connectionStatus = strStatus;
}




-(void)getLivestream{
    NSLog(@"PlayViewController...getLivestream...============");
    if (m_pPPPPChannelMgt != NULL) {
        
        [self hiddenProgresssLabel:NO];
        self.LblProgress.text=NSLocalizedStringFromTable(@"play_getvideo", @STR_LOCALIZED_FILE_NAME, nil);
        
        if( m_pPPPPChannelMgt->StartPPPPLivestream([strDID UTF8String], 10, self) == 0 ){
            NSLog(@"Failed to get video...");
            [self updateDeviceStatus:NSLocalizedStringFromTable(@"play_getvideofailed", @STR_LOCALIZED_FILE_NAME, nil)];
            self.LblProgress.text=NSLocalizedStringFromTable(@"play_getvideofailed", @STR_LOCALIZED_FILE_NAME, nil);
            
            [self onMainThread];
            return;
        }
        
        m_pPPPPChannelMgt->SetRunCarDelegate((char *)[strDID UTF8String], self);
        m_pPPPPChannelMgt->PPPPSetSystemParams((char *)[strDID UTF8String], MSG_TYPE_GET_STATUS, NULL, 0);
    }
}




-(void)onMainThread{
    [self performSelector:@selector(reConnectLivestream) withObject:nil afterDelay:5];
}



-(void)reConnectLivestream{
    NSLog(@"reConnectLivestream...");
    if( m_pPPPPChannelMgt->StartPPPPLivestream([strDID UTF8String], 10, self) == 0 ){
        [self performSelectorOnMainThread:@selector(StopPlay:) withObject:nil waitUntilDone:NO];
        
        return;
    }
    [NSTimer  scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkReconnectOk) userInfo:nil repeats:NO];
}


-(void)checkReconnectOk{
    NSLog(@"checkReconnectOk...isDataComeback=%d",isDataComeback);
    if (!isDataComeback) {
        [self performSelectorOnMainThread:@selector(StopPlay:) withObject:nil waitUntilDone:NO];
    }
}





#pragma mark- UI Update

-(void)hiddenProgresssLabel:(BOOL)bShow{
    [self.progressView setHidden:bShow];
    [self.LblProgress setHidden:bShow];
}




#pragma mark -
#pragma mark ParamNotify

- (void) ParamNotify:(int)paramType params:(void *)params
{
    //NSLog(@"PlayViewController ParamNotify");
    
    if (paramType == CGI_IEGET_CAM_PARAMS) {
        PSTRU_CAMERA_PARAM pCameraParam = (PSTRU_CAMERA_PARAM)params;
        m_Contrast = pCameraParam->contrast;
        m_Brightness = pCameraParam->bright;
        nResolution = pCameraParam->resolution;
        m_nFlip = pCameraParam->flip;
        bGetVideoParams = YES;
        NSLog(@"resolution:%d",nResolution);
        return;
    }
    
    if (paramType == STREAM_CODEC_TYPE) {
        //NSLog(@"STREAM_CODEC_TYPE notify");
        m_StreamCodecType = *((int*)params);
        m_bGetStreamCodecType = YES;
    }
}




#pragma mark -
#pragma mark ImageNotify
-(void)stopRecordForMemoryOver{
    
    
    if (isRecoding||isRecording) {
        recordNum=0;
        btnUpdateTime.title=@"Recording...0";
        UIButton *button= (UIButton*)btnRecord.customView;
        UIImage *recorderImage = [UIImage imageNamed:@"Video_Start"];
        [button setImage:recorderImage forState:UIControlStateNormal];
        [btnUpdateTime setEnabled:NO];
        [timer invalidate];
        timer=nil;
        timeNumber=0;
        //  SAFE_DELETE(m_pCustomRecorder);
        [self recordVideo:nil];  // new
        
    }
    [CustomToast showWithText:NSLocalizedStringFromTable(@"runcar_outofmemory", @STR_LOCALIZED_FILE_NAME, nil)
                    superView:self.view
                    bLandScap:YES];
}




- (void) H264Data:(Byte *)h264Frame length:(int)length type:(int)type timestamp:(NSInteger) timestamp
{
    if(isStop){
        return;
    }
    if (m_videoFormat == -1) {
        m_videoFormat = 2;
        [self performSelectorOnMainThread:@selector(enableButton) withObject:nil waitUntilDone:NO];
    }
    
    
    [m_RecordLock lock];
    if (isRecordStart) {
        if (m_pCustomRecorder != nil) {
            recordNum++;
            NSLog(@"recordNum=%d",recordNum);
            if (recordNum==100) {
                recordNum=0;
                BOOL flag=[self isOutOfMemory];
                if (flag) {
                    [self performSelectorOnMainThread:@selector(stopRecordForMemoryOver) withObject:self waitUntilDone:NO];
                }
            }
            
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            unsigned int unTimestamp = 0;
            struct timeval tv;
            struct timezone tz;
            gettimeofday(&tv, &tz);
            unTimestamp = tv.tv_usec / 1000 + tv.tv_sec * 1000 ;
            
            m_pCustomRecorder->SendOneFrame((char*)h264Frame, length, unTimestamp, type);
            [pool release];
        }
    }
    [m_RecordLock unlock];
}




// Dont know what this is used for ... Think this was for playback which currently we are not using
- (void) YUVNotify:(Byte *)yuv length:(int)length width:(int)width height:(int)height timestamp:(unsigned int)timestamp StreamID:(int)streamID
{
    
    
    mType=1;
    if (streamID==63) {
        //NSLog(@"YUVNotify.... streamID:%d",streamID);
    }
    
    isDataComeback=YES;
    if (!isGo) {
        return;
    }
    if(isStop){
        return;
    }
    
    if (bPlaying == NO)
    {
        
        [self performSelectorOnMainThread:@selector(CreateGLView) withObject:nil waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(hideProgress:) withObject:nil waitUntilDone:NO];
        bPlaying = YES;
    }
    
    [self performSelectorOnMainThread:@selector(updateTimestamp) withObject:nil waitUntilDone:NO];
    
    [myGLViewController WriteYUVFrame:yuv Len:length width:width height:height];
    
    [m_YUVDataLock lock];
    SAFE_DELETE(m_pYUVData);
    int yuvlength = width * height * 3 / 2;
    m_pYUVData = new Byte[yuvlength];
    memcpy(m_pYUVData, yuv, yuvlength);
    m_nWidth = width;
    m_nHeight = height;
    [m_YUVDataLock unlock];
    
    if (streamID==63) {
        takepicNum++;
        NSLog(@"yuv.. streamid=%d", streamID);
        [self performSelectorOnMainThread:@selector(btnSnapshot:) withObject:@"" waitUntilDone:NO];
    }
}





// live streaming data  capture image from device

- (void) ImageNotify:(UIImage *)image timestamp:(NSInteger)timestamp StreamID:(int)streamID
{
    // NSLog(@"ImageNotify.....StreamID=%d",streamID);
    
    isDataComeback=YES;
    if (!isGo) {
        return;
    }
    if(isStop){
        return;
    }
    mType=0;
    m_nWidth = image.size.width;
    m_nHeight = image.size.height;
    
    if (m_videoFormat == -1) {
        m_videoFormat = 0;
        [self performSelectorOnMainThread:@selector(enableButton) withObject:nil waitUntilDone:NO];
    }
    
    if (bPlaying == NO)
    {
        bPlaying = YES;
        [self performSelectorOnMainThread:@selector(hideProgress:) withObject:nil waitUntilDone:NO];
    }
    
    if (image != nil) {
        [image retain];
        [self performSelectorOnMainThread:@selector(updateImage:) withObject:image waitUntilDone:NO];
    }
    
    [m_RecordLock lock];
    if (isRecordStart) {
        if (m_pCustomRecorder != nil) {
            recordNum++;
            NSLog(@"recordNum=%d",recordNum);
            if (recordNum==100) {
                recordNum=0;
                BOOL flag=[self isOutOfMemory];
                if (flag) {
                    [self performSelectorOnMainThread:@selector(stopRecordForMemoryOver) withObject:self waitUntilDone:NO];
                }
            }
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            NSData *data = UIImageJPEGRepresentation(image, 1.0);
            unsigned int unTimestamp = 0;
            struct timeval tv;
            struct timezone tz;
            gettimeofday(&tv, &tz);
            unTimestamp = tv.tv_usec / 1000 + tv.tv_sec * 1000 ;
            //NSLog(@"unTimestamp: %d", unTimestamp);
            m_pCustomRecorder->SendOneFrame((char*)[data bytes], [data length], unTimestamp, 0);
            [pool release];
        }
    }
    
    
    [m_RecordLock unlock];
    if (streamID==63) {
        NSLog(@"ImageNotify.. streamid=%d", streamID);
        [self performSelectorOnMainThread:@selector(btnSnapshot:) withObject:@"" waitUntilDone:NO];
    }
}








#pragma mark- RuncarModeProtocol
-(void)runcarStatusResult:(NSString *)did Sysver:(NSString *)sysver DevName:(NSString *)devname Devid:(NSString *)devid AlarmStatus:(int)alarmstatus SdCardStatus:(int)sdstatus SdcardTotalSize:(int)totalsize SdcardRemainSize:(int)remainsize Mac:(NSString *)mac WifiMac:(NSString *)wifimac DNSstatus:(int)dns_status UPNPstatus:(int)upnp_status{
    NSLog(@"sysver=%@ devname=%@ Devid=%@ alarmstatus=%d sdstatus=%d totalsize=%d remainsize=%d ",sysver,devname,devid,alarmstatus,sdstatus,totalsize,remainsize);
    
    // From right to left , the first byte represents sd card is inserted ( 1 SD card inserted )，
    // Whether the second byte represents is recording ( 1 is recording )，
    // The third byte represents the recording mode ( 1 to local mode , drive mode 0 )
    
    // sixB = Integer.toHexString(statu);
    // int d = Integer.parseInt(sixB);
    Byte b1 = (Byte) (sdstatus & 0xFF);// sdCard is inserted ( 1 SD card inserted )
    
    Byte b2 = (Byte) ((sdstatus & 0xFF00) >> 8);// You Are Recording ( 1 is recording )，
    Byte b3 = (Byte) ((sdstatus & 0xFF0000) >> 16);// Represents the recording mode ( 1 to local mode , drive mode 0 )
    
    NSLog(@"b1=%d b2=%d b3=%d",b1,b2,b3);
    [self performSelectorOnMainThread:@selector(updateRecordStatus:) withObject:[NSNumber numberWithInt:b2] waitUntilDone:NO];
}
-(BOOL)isOutOfMemory {
    
    //    return NO;
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] ;
    NSFileManager* fileManager = [[NSFileManager alloc ]init];
    NSDictionary *fileSysAttributes = [fileManager attributesOfFileSystemForPath:path error:nil];
    NSNumber *freeSpace = [fileSysAttributes objectForKey:NSFileSystemFreeSize];
    NSNumber *totalSpace = [fileSysAttributes objectForKey:NSFileSystemSize];
    float free=([freeSpace longLongValue])/1024.0/1024.0/1024.0;
    float total=([totalSpace longLongValue])/1024.0/1024.0/1024.0;
    NSString *memory=@"";
    if (free>1.0) {
        memory=[NSString stringWithFormat:@"%0.1fG/%0.1fG",free,total];
        //strMemory=[[NSString alloc]initWithFormat:@"%0.1fG/%0.1fG",free,total];
    }else{
        free=([freeSpace longLongValue])/1024.0/1024.0;
        memory=[NSString stringWithFormat:@"%0.1fM/%0.1fG",free,total];
        if (free<100.0) {
            [self performSelectorOnMainThread:@selector(showMemory:) withObject:memory waitUntilDone:NO];
            return YES;
        }
    }
    NSLog(@"memory=%@",memory);
    
    [self performSelectorOnMainThread:@selector(showMemory:) withObject:memory waitUntilDone:NO];
    
    return NO;
}
-(void)showMemory:(NSString *)memory{
    
    btnMemory.title=memory;
}






//////////////////////////______________________________________________////////////////////////
//////////////////////////______________________________________________////////////////////////
//////////////////////////______________________________________________////////////////////////
//////////////////////////______________________________________________////////////////////////
//////////////////////////______________________________________________////////////////////////
//////////////////////////______________________________________________////////////////////////
//////////////////////////______________________________________________////////////////////////



#pragma mark- New Methods to capture video
# pragma mark
#pragma mark
#pragma mark



- (IBAction)backButtonAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
    
    
}



// Button Action to record video for curent event from live streaming

-(void)recordVideo :(id)sender{
    
    BOOL flag=[self isOutOfMemory];
    
    if (flag) {
        
        [CustomToast showWithText:@"No enough storage. Please clean up and try again."
                        superView:self.view
                        bLandScap:NO];
        
        
        return;
    }
    
    if (isProcessing && !isRecording) {
        return;
    }
    if (isRecording) {
        
        //        UIButton *button= (UIButton*)btnRecord.customView;
        //        UIImage *recorderImage = [UIImage imageNamed:@"Video_Start"];
        //        [button setImage:recorderImage forState:UIControlStateNormal];
        
        [btnSnapshot setEnabled:YES];
        [btnRecord setEnabled:YES];
        [self changeButtonImageForRecording];
        
        [recorder stop];
        self.viewRecordingTime.hidden = YES;
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:NO error:nil];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        recorder=nil;
        
        isRecording=NO;
        startedAt=nil;
        
        [recordingTimerVideo invalidate];
        recordingTimerVideo=nil;
        
        NSLog(@"numberOfScreenshots is %@",numberOfScreenshots);
        
        isRecording=NO;
        
        isProcessing=YES;
        
        [recordingTimer invalidate];
        recordingTimer=nil;
        [autometicStopTimer invalidate];
        autometicStopTimer=nil;
        self.labelRecording.hidden=YES;

        
        if(numberOfScreenshots.count > 0)
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                labelRecording.text = @"Saving...";
            }];
            [NSThread detachNewThreadSelector:@selector(createWriter) toTarget:self withObject:nil];
            
        }
        
        // Working For Audio Recording For Merging with Video
        
        
    }
    else{
        
        
        if ([connectionStatus isEqualToString:NSLocalizedStringFromTable(@"PPPPStatusOnline", @STR_LOCALIZED_FILE_NAME, nil)])
        {
            //            UIButton *button= (UIButton*)btnRecord.customView;
            //            UIImage *recorderImage = [UIImage imageNamed:@"Video_Recording"];
            //            [button setImage:recorderImage forState:UIControlStateNormal];
            
            
            [self changeButtonImageForRecording];
            [btnSnapshot setEnabled:NO];
            [btnRecord setEnabled:NO];
            
            
            startedAt = [NSDate date];
            self.viewRecordingTime.hidden=NO;
            
            isRecording=YES;
            
            NSLog(@"Audio Recording status is %@",[[NSUserDefaults standardUserDefaults]objectForKey:@"isRecordAudio"]);
            
            if ([[[NSUserDefaults standardUserDefaults]objectForKey:@"isRecordAudio"]integerValue]==1) {
                [self initializeAudioRecorder];
                AVAudioSession *session = [AVAudioSession sharedInstance];
                [session setActive:YES error:nil];
                
                audioOrVideo = @"Audio";
                // Start recording
                [recorder record];
                
            }
            else
                audioOrVideo = @"Video";
            
            currentTimeInSeconds = 0;
            
            self.labelRecording.text = [self formattedTime:currentTimeInSeconds];
            self.labelRecording.hidden=NO;
            // [screenCaptureView startRecording];
            
            // Working For Audio Recording For Merging with Video
            
            numberOfScreenshots=[[NSMutableArray alloc]init];
            
            recordingTimerVideo =[NSTimer scheduledTimerWithTimeInterval:0.25
                                                                  target:self
                                                                selector:@selector(timerMethodExecute:)
                                                                userInfo:nil
                                                                 repeats:YES];
            
            
            
            
            if (!currentTimeInSeconds) {
                currentTimeInSeconds = 0 ;
            }
            
            if (!recordingTimer) {
                recordingTimer = [self createTimer:1.0:YES];
            }
            
            if (!autometicStopTimer) {
                
                autometicStopTimer=[self createTimer:[[[NSUserDefaults standardUserDefaults]objectForKey:@"recordingTime"]floatValue]*60:NO];
            }
            
            
            
        }
        else
        {
            [CustomToast showWithText:connectionStatus
                            superView:self.view
                            bLandScap:NO];
        }
    }
}

#pragma mark- Screen Capture Functionality

-(void)timerMethodExecute:(id)info{
    
    if ([self isOutOfMemory]) {
        
        [self stopRecordForMemoryOver];
        
        return;
    }
    [self takeScreenshots];
}


-(void)takeScreenshots{
    
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]){
        
        
        NSData *tempData = UIImageJPEGRepresentation(imgView.image, 0.01);
        
        UIImage *image = [UIImage imageWithData:tempData];
        
        [numberOfScreenshots addObject:image];
        
    }
    else{
        
        UIGraphicsBeginImageContext(imgView.bounds.size);
        
        UIGraphicsBeginImageContextWithOptions(imgView.bounds.size,imgView.opaque, 0.0);
        [imgView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        [numberOfScreenshots addObject:image];
        
    }
    return;
    
    
}


#pragma end

#pragma mark- Generating Video From Screenshots

-(void)createWriter{
    
    NSError*error=nil;
    
    NSString *savedImagePath;
    if ([[[NSUserDefaults standardUserDefaults]objectForKey:@"isRecordAudio"]integerValue]==1) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat: @"yyyyMMddHHmmss"];
        NSString *strDate = [formatter stringFromDate:[NSDate date]]; // Convert date to string
        
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",@""]];
        
        
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])//Check
            [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Will Create folder
        
        savedImagePath = [dataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mov",strDate]];
        
        
        
    }
    else
    {
        NSString *strFileName = [self GetRecordFileName];
        savedImagePath = [self GetRecordPath: strFileName];
        
        NSDate * date = [NSDate date];
        NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSString * strDate = [formatter stringFromDate:date];
        
        [m_pRecPathMgt InsertPath:strDID Date:strDate Path:strFileName];
        
        p2pPathDetails = [[NSMutableArray alloc] initWithObjects:strDID,strDate,strFileName, nil];
        
        [[NSUserDefaults standardUserDefaults] setValue:p2pPathDetails forKey:@"p2pDetails"];
        
    }
    
    
    
    
    
    NSURL *videoTempURL = [NSURL fileURLWithPath:savedImagePath];
    
    
    VideoURLP2P=[NSURL fileURLWithPath:savedImagePath];
    
    [[NSUserDefaults standardUserDefaults] setObject:savedImagePath forKey:@"video"];
    
    // WARNING: AVAssetWriter does not overwrite files for us, so remove the destination file if it already exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[videoTempURL path]  error:NULL];
    
    int height = 480;
    
    int width = 640;
    
    
    [self writeImageAsMovie:numberOfScreenshots toPath:savedImagePath size:CGSizeMake(width, height)];
    numberOfScreenshots=nil;
}

-(void)writeImageAsMovie:(NSArray *)array toPath:(NSString*)path size:(CGSize)size

{
    NSError *error = nil;
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                  
                                                           fileType:AVFileTypeQuickTimeMovie
                                  
                                                              error:&error];
    
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   
                                   nil];
    
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                       
                                                                         outputSettings:videoSettings];
    
    
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    
    
    NSParameterAssert(writerInput);
    
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    
    [videoWriter addInput:writerInput];
    
    //Start a SESSION of writing.
    
    // After you start a session, you will keep adding image frames
    
    // until you are complete - then you will tell it you are done.
    
    [videoWriter startWriting];
    
    // This starts your video at time = 0
    
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    
    CVPixelBufferRef buffer = NULL;
    
    
    // This was just our utility class to get screen sizes etc.
    
    
    int i = 0;
    _timeOfFirstFrame = CFAbsoluteTimeGetCurrent();
    
    
    while (1)
        
    {
        
        // Check if the writer is ready for more data, if not, just wait
        
        if(writerInput.readyForMoreMediaData){
            
            
            CFAbsoluteTime current  = CFAbsoluteTimeGetCurrent();
            //            CFTimeInterval elapse   = current - _timeOfFirstFrame;
            CMTime present          = CMTimeMake( i * 150, 600);
            
            
            
            if (i >= [array count])
                
            {
                buffer = NULL;
            }
            
            else
                
            {
                // This command grabs the next UIImage and converts it to a CGImage
                buffer = [self pixelBufferFromCGImage:[[array objectAtIndex:i] CGImage]];
            }
            
            if (buffer)
                
            {
                // Give the CGImage to the AVAssetWriter to add to your video
                [adaptor appendPixelBuffer:buffer withPresentationTime:present];
                
                CVPixelBufferPoolRef bufferPool = adaptor.pixelBufferPool;
                //                NSParameterAssert(bufferPool != NULL);
                CVPixelBufferRelease(buffer);
                i++;
            }
            
            else
                
            {
                //Finish the session:
                // This is important to be done exactly in this order
                [writerInput markAsFinished];
                
                // WARNING: finishWriting in the solution above is deprecated.
                
                // You now need to give a completion handler.
                
                [videoWriter finishWritingWithCompletionHandler:^{
                    
                    NSLog(@"Finished writing...checking completion status...");
                    
                    if (videoWriter.status != AVAssetWriterStatusFailed && videoWriter.status == AVAssetWriterStatusCompleted)
                    {
                        isProcessing=NO;
                        NSLog(@"Video writing succeeded.");
                        // Move video to camera roll
                        
                        // NOTE: You cannot write directly to the camera roll.
                        
                        // You must first write to an iOS directory then move it!
                        
                        //    NSURL *videoTempURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@", path]];
                        
                        if ([[[NSUserDefaults standardUserDefaults]objectForKey:@"isRecordAudio"]integerValue]==1)
                        {
                            [self mergeAndSave];
                        }
                        else{
                            
                            
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                
                                tempDetailsArray = [[NSMutableArray alloc] initWithObjects:@"Success",audioOrVideo,@"p2p", nil];
                                [[NSUserDefaults standardUserDefaults] setValue:tempDetailsArray forKey:@"recording"];
                                
                                
                                
                                NSLog(@"%@", self.navigationController.viewControllers);
                                if ([self.navigationController.viewControllers containsObject:self]) {
                                    
//                                    [CustomToast showWithText:@"Video saved successfully"
//                                                    superView:self.interfaceScrollView
//                                                    bLandScap:NO];

                                    messageLabel.hidden = NO;
                                    messageLabel.alpha = 1;
                                    messageLabel.text = @"Video saved successfully";
                                    
                                    [UIView animateWithDuration:2.5 animations:^{
                                        
                                        messageLabel.alpha = 0;
                                    }];

                                }

                                
                            }];
//                            [self performSelectorOnMainThread:@selector(showVideoSuccessMessage) withObject:nil waitUntilDone:NO];
                        }
                    } else
                        
                    {
                        NSLog(@"Video writing failed: %@", videoWriter.error);
                    }
                    
                }]; // end videoWriter finishWriting Block
                
                CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
                
                NSLog (@"Done");
                
                adaptor=nil;
                videoWriter=nil;
                writerInput=nil;
                array=nil;
                buffer=NULL;
                
                break;
                
            }
        }
    }
}


-(void)showVideoSuccessMessage{
    
    tempDetailsArray = [[NSMutableArray alloc] initWithObjects:@"Success",audioOrVideo,@"p2p", nil];
    [[NSUserDefaults standardUserDefaults] setValue:tempDetailsArray forKey:@"recording"];
    
    
    
    NSLog(@"%@", self.navigationController.viewControllers);
    if ([self.navigationController.viewControllers containsObject:self]) {
        
        [CustomToast showWithText:@"Video saved successfully"
                        superView:self.interfaceScrollView
                        bLandScap:NO];
    }
}

-(CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image

{
    // This again was just our utility class for the height & width of the
    // incoming video (640 height x 480 width)
    
    int height = 1080;
    int width = 720;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width,
                                          
                                          height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          
                                          &pxbuffer);
    
    
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata, width,
                                                 
                                                 height, 8, 4*width, rgbColorSpace,
                                                 
                                                 kCGImageAlphaNoneSkipFirst);
    
    NSParameterAssert(context);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    CGContextDrawImage(context, CGRectMake(0, 0, width,
                                           
                                           height), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}



#pragma mark- end

#pragma mark- Audio Capture Functionality


-(void)initializeAudioRecorder{
    
    NSError*error=nil;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"yyyyMMddHHmmss"];
    NSString *strDate = [formatter stringFromDate:[NSDate date]]; // Convert date to string
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",@""]];
    
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])//Check
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Will Create folder
    }
    
    NSString *savedImagePath = [dataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a",strDate]];
    
    
    [[NSUserDefaults standardUserDefaults] setObject:savedImagePath forKey:@"audio"];
    
    NSURL *outputFileURL = [NSURL fileURLWithPath:savedImagePath];
    AudioURlP2P=[NSURL fileURLWithPath:savedImagePath];
    
    NSLog(@"Audio Path is %@",AudioURlP2P);
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryRecord error:&error];
    
    if (error) {
        NSLog(@"Erro! %@", error.debugDescription);
    }
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    [recorder prepareToRecord];
}

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    
    
}

#pragma mark- end


#pragma mark- Mixing Audio and Video


-(void)mergeAndSave
{
    //Create AVMutableComposition Object which will hold our multiple AVMutableCompositionTrack or we can say it will hold our video and audio files.
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    //Now first load your audio file using AVURLAsset. Make sure you give the correct path of your videos.
    //  NSURL *audio_url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Asteroid_Sound" ofType:@"mp3"]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // [fileManager removeItemAtPath:[AudioURl path]  error:NULL];
    
    NSLog(@"savedImagePathTemp is %@",[[NSUserDefaults standardUserDefaults] valueForKey:@"audio"]);
    
    AudioURlP2P=[NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults] valueForKey:@"audio"]];
    
    NSLog(@"AudioURlP2P is %@",AudioURlP2P);
    
    AVURLAsset  *audioAsset = [[AVURLAsset alloc]initWithURL:AudioURlP2P options:nil];
    CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    
    //Now we are creating the first AVMutableCompositionTrack containing our audio and add it to our AVMutableComposition object.
    AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    if([[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject]==NULL)
    {
        NSLog(@"Sound is not Present");
    }
    else
    {
        NSLog(@"Sound is Present");
        //You will initalise all things
    }
    
    
    [b_compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    //Now we will load video file.
    // NSURL *video_url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Asteroid_Video" ofType:@"m4v"]];
    
    VideoURLP2P=[NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults] valueForKey:@"video"]];
    
    
    AVURLAsset  *videoAsset = [[AVURLAsset alloc]initWithURL:VideoURLP2P options:nil];
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
    
    //Now we are creating the second AVMutableCompositionTrack containing our video and add it to our AVMutableComposition object.
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    //    NSError * error=nil;
    
    CMTime audioDuration = audioAsset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    
    CMTime vdioDuration = videoAsset.duration;
    float vdioDurationSeconds = CMTimeGetSeconds(vdioDuration);
    
    
    NSLog(@"audio time: %f, video time: %f",audioDurationSeconds,vdioDurationSeconds);
    
    NSString *strFileName = [self GetRecordFileName];
    NSString *strPath = [self GetRecordPath: strFileName];
    
    NSURL *outputFileUrl = [NSURL fileURLWithPath:strPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:strPath])
        [[NSFileManager defaultManager] removeItemAtPath:strPath error:nil];
    
    //Now create an AVAssetExportSession object that will save your final video at specified path.
    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    _assetExport.outputFileType = @"com.apple.quicktime-movie";
    _assetExport.outputURL = outputFileUrl;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         
         dispatch_async(dispatch_get_main_queue(), ^{
             
             // [self exportDidFinish:_assetExport];
             NSDate * date = [NSDate date];
             NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
             [formatter setDateFormat:@"yyyy-MM-dd"];
             NSString * strDate = [formatter stringFromDate:date];
             
             [m_pRecPathMgt InsertPath:strDID Date:strDate Path:strFileName];
             
             NSLog(@"File merged sucessfully");
             if ([fileManager fileExistsAtPath:[AudioURlP2P path]]) {
                 
                 NSFileManager *fileManager = [NSFileManager defaultManager];
                 [fileManager removeItemAtPath:[AudioURlP2P path]  error:NULL];
             }
             
             if ([fileManager fileExistsAtPath:[AudioURlP2P path]]) {
                 NSLog(@"File Available");
             }
             else{
                 NSLog(@"File not available");
             }
             
             
             [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                 
                 tempDetailsArray = [[NSMutableArray alloc] initWithObjects:@"Success",audioOrVideo,@"p2p", nil];
                 [[NSUserDefaults standardUserDefaults] setValue:tempDetailsArray forKey:@"recording"];
                 
                 
                 
                 NSLog(@"%@", self.navigationController.viewControllers);
                 if ([self.navigationController.viewControllers containsObject:self]) {
                     
//                     [CustomToast showWithText:@"Video saved successfully"
//                                     superView:self.interfaceScrollView
//                                     bLandScap:NO];

                     messageLabel.hidden = NO;
                     messageLabel.alpha = 1;
                     messageLabel.text = @"Video saved successfully";
                     
                     [UIView animateWithDuration:2.5 animations:^{
                         
                         messageLabel.alpha = 0;
                     }];

                 }
                 
                 
             }];
//             [self performSelectorOnMainThread:@selector(showVideoSuccessMessage) withObject:nil waitUntilDone:NO];
         });
     }
     ];
}



#pragma mark- Timer Functionality Implementation

- (NSTimer *)createTimer :(float)interval :(BOOL)shouldRepeat{
    return [NSTimer scheduledTimerWithTimeInterval:interval
                                            target:self
                                          selector:@selector(timerTicked:)
                                          userInfo:nil
                                           repeats:shouldRepeat];
}



- (void)timerTicked:(NSTimer *)timer1 {
    if (timer1==recordingTimer) {
        currentTimeInSeconds++;
        self.labelRecording.text = [self formattedTime:currentTimeInSeconds];
    }
    
    if (timer1== autometicStopTimer) {
        [self recordVideo:nil];
    }
}



- (NSString *)formattedTime:(int)totalSeconds
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}




-(void)timeOutAlertMessagePopOut:(NSString *)message
{
    [self hiddenProgresssLabel:YES];
    
    UIView *alertView = [[UIView alloc]initWithFrame:CGRectMake(20, 100, 250, 100)];
    
    alertView.center=CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2+80);
    alertView.backgroundColor=[UIColor clearColor];
    
    UIImageView*errorImage =[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"error"]];
    errorImage.frame=CGRectMake(0, 5, errorImage.frame.size.width, errorImage.frame.size.height);
    errorImage.center=CGPointMake(alertView.frame.size.width/2, errorImage.center.y);
    [alertView addSubview:errorImage];
    
    UILabel *errorLbl = [[UILabel alloc]initWithFrame:CGRectMake(10, errorImage.frame.origin.y+errorImage.frame.size.height/2, alertView.frame.size.width-20, 100)];
    errorLbl.numberOfLines=0;
    errorLbl.text = message;
    errorLbl.textAlignment=NSTextAlignmentCenter;
    errorLbl.font=[UIFont boldSystemFontOfSize:16];
    errorLbl.textColor=[UIColor whiteColor];
    [alertView addSubview:errorLbl];
    
    [self.view addSubview:alertView];
    
    [UIView animateWithDuration:3 animations:^{
        alertView.frame = CGRectMake(alertView.frame.origin.x, alertView.frame.origin.y, 0, 0);
        alertView.alpha = 0;
    } completion:^(BOOL finished) {
        [alertView removeFromSuperview];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}



#pragma mark - Image rotate, zoom controls



-(void)setUpScrolling
{
    [_interfaceScrollView layoutIfNeeded];
    _interfaceScrollView.delegate=self;
    _interfaceScrollView.zoomScale=1.0f;
    _interfaceScrollView.minimumZoomScale=0.6f;
    _interfaceScrollView.maximumZoomScale=2.0f;
    _interfaceScrollView.bounces=YES;
    _interfaceScrollView.bouncesZoom=YES;
    _interfaceScrollView.clipsToBounds = YES;
    imgView.hidden = NO;
}

- (IBAction)actionResetButton:(id)sender {
    [self.view layoutIfNeeded];
    
    _interfaceScrollView.zoomScale=1.0f;
    _interfaceScrollView.transform = CGAffineTransformIdentity;
    imgView.transform = CGAffineTransformIdentity;
    scaleValue = 1;
    
    _interfaceScrollView.center = CGPointMake(self.view.center.x ,
                                              self.view.center.y );
    
    imgView.frame = _interfaceScrollView.frame;
    containerCiew.frame = _interfaceScrollView.frame;
    
    //    imgView.center = _interfaceScrollView.center;
    NSLog(@"_interfaceScrollView w:%f",_interfaceScrollView.frame.size.width);
    NSLog(@"_interfaceScrollView h:%f",_interfaceScrollView.frame.size.height);
    NSLog(@"imgView w:%f",imgView.frame.size.width);
    NSLog(@"imgView h:%f",imgView.frame.size.height);
    NSLog(@"self.view w:%f",self.view.frame.size.width);
    NSLog(@"self.view h:%f",self.view.frame.size.height);
}





- (IBAction)actionZoomIn:(id)sender {
    
    if (scaleValue < 2.0) {
        [UIView animateWithDuration:.5 animations:^
         {
             scaleValue = scaleValue * 1.11;
             
             CGAffineTransform transform1 = CGAffineTransformMakeScale(scaleValue, scaleValue);
             
             CGAffineTransform transform = CGAffineTransformRotate(transform1,  atan2f(imgView.transform.b, imgView.transform.a));
             
             containerCiew.transform = transform1;
             globalTransform = transform;
         }];
        
    }
    
}




- (IBAction)actionZoomOut:(id)sender {
    if (scaleValue > 0.6) {
        
        [UIView animateWithDuration:.5 animations:^{
            
            scaleValue = scaleValue * 0.9;
            
            CGAffineTransform transform1 = CGAffineTransformMakeScale(scaleValue, scaleValue);
            
            CGAffineTransform transform = CGAffineTransformRotate(transform1,  atan2f(imgView.transform.b, imgView.transform.a));
            
            containerCiew.transform = transform1;
            globalTransform = transform;
        }];
    }
}




- (IBAction)actionLeftRtate:(id)sender {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView animateWithDuration:.5 animations:^
     {
         CGAffineTransform transform = CGAffineTransformRotate(imgView.transform, -M_PI_4);
         imgView.transform = transform;
         globalTransform = transform;
     }];
}





- (IBAction)actionRightRotate:(id)sender
{
    [UIView animateWithDuration:.5 animations:^
     {
         CGAffineTransform transform = CGAffineTransformRotate(imgView.transform, M_PI_4);
         imgView.transform = transform;
         globalTransform = transform;
     }];
}





- (IBAction)moveImage:(UIPanGestureRecognizer*)recognizer {
    
    CGPoint translation = [recognizer translationInView:self.view];
    containerCiew.center = CGPointMake(containerCiew.center.x + translation.x,
                                       containerCiew.center.y + translation.y);
    [recognizer setTranslation:CGPointMake(0, 0) inView:_interfaceScrollView];
}





#pragma mark - Handling Rotation


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    
    [self.view layoutIfNeeded];
    
    if (_interfaceScrollView.zoomScale != 1.0f || atan2f(imgView.transform.b, imgView.transform.a) != 0 )
    {
        _interfaceScrollView.zoomScale=1.0f;
        _interfaceScrollView.transform = CGAffineTransformIdentity;
        scaleValue = 1;
        
        imgView.transform = CGAffineTransformIdentity;
        _interfaceScrollView.center = CGPointMake(self.view.center.x ,
                                                  self.view.center.y );
        containerCiew.center = _interfaceScrollView.center;
    }
}


-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self.view layoutIfNeeded];
    [_interfaceScrollView layoutIfNeeded];
    
    imgView.frame = _interfaceScrollView.frame;
    containerCiew.frame = _interfaceScrollView.frame;
    
    [self.view layoutIfNeeded];
}








#pragma mark- UIScrollView Delegate

-(UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return containerCiew;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    // The scroll view has zoomed, so we need to re-center the contents
    [self centerScrollViewContents];
    
    scaleValue = scrollView.zoomScale;
    
}


- (void)centerScrollViewContents {
    // This method centers the scroll view contents also used on did zoom
    CGSize boundsSize = _interfaceScrollView.bounds.size;
    CGRect contentsFrame = containerCiew.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    //    contentsFrame.origin.x = boundsSize.width/2 -contentsFrame.size.width/2;
    //    contentsFrame.origin.y = boundsSize.height/2 -contentsFrame.size.height/2;
    
    containerCiew.frame = contentsFrame;
    
}



- (void)tapOnce:(UIGestureRecognizer *)gesture
{
    if (!self.navigationController.navigationBarHidden)
    {
        [UIView  animateWithDuration:.5 animations:^{
            [[self navigationController] setNavigationBarHidden:YES animated:YES];
            _bottomButtonView.alpha = 0;
            
        }];
    }
    else
    {
        [UIView animateWithDuration:.5 animations:^{
            [[self navigationController] setNavigationBarHidden:NO animated:YES];
            _bottomButtonView.alpha = 1;
            
        }];
    }
}





#pragma mark - Change the button Images/Switch

- (void) changeButtonImageForRecording{
    if ([recordingButton.currentImage isEqual:[UIImage imageNamed:@"Video_Start"]]) {
        [recordingButton setImage:[UIImage imageNamed:@"Video_Recording"] forState:UIControlStateNormal];
    }
    else{
        [recordingButton setImage:[UIImage imageNamed:@"Video_Start"] forState:UIControlStateNormal];
    }
}


- (void) changeButtonImageForCaptureImage{
    if ([recordingButton.currentImage isEqual:[UIImage imageNamed:@"Camera_NotClicked"]]) {
        [recordingButton setImage:[UIImage imageNamed:@"Camera_NotClicked"] forState:UIControlStateNormal];
    }
    else{
        [recordingButton setImage:[UIImage imageNamed:@"Camera_NotClicked"] forState:UIControlStateNormal];
    }
    
}





-(void) changeToCamera{
    [recordingButton setImage:[UIImage imageNamed:@"Camera_NotClicked"] forState:UIControlStateNormal];
    
    UIButton * button= (UIButton*)btnSnapshot.customView;
    UIImage * recorderImage = [UIImage imageNamed:@"Camera_Snapshot_Green"];
    [button setImage:recorderImage forState:UIControlStateNormal];
    
    UIButton * button1= (UIButton*)btnRecord.customView;
    UIImage * recorderImage1 = [UIImage imageNamed:@"Camera_Record_Gray"];
    [button1 setImage:recorderImage1 forState:UIControlStateNormal];
    
}

- (void) changeToVideo{
    [recordingButton setImage:[UIImage imageNamed:@"Video_Start"] forState:UIControlStateNormal];
    
    UIButton * button= (UIButton*)btnSnapshot.customView;
    UIImage * recorderImage = [UIImage imageNamed:@"Camera_Snapshot_Gray"];
    [button setImage:recorderImage forState:UIControlStateNormal];
    
    UIButton * button1= (UIButton*)btnRecord.customView;
    UIImage * recorderImage1 = [UIImage imageNamed:@"Camera_Record_Green"];
    [button1 setImage:recorderImage1 forState:UIControlStateNormal];
    
}




- (IBAction)recordingButtonAction:(id)sender {
    if ([recordingButton.currentImage isEqual:[UIImage imageNamed:@"Video_Start"]]||[recordingButton.currentImage isEqual:[UIImage imageNamed:@"Video_Recording"]])
    {
        [self recordVideo:sender];
    }
    else
    {
        [recordingButton setImage:[UIImage imageNamed:@"Camera_Clicked"] forState:UIControlStateNormal];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05
                                     * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self btnSnapshot:sender];
            [recordingButton setImage:[UIImage imageNamed:@"Camera_NotClicked"] forState:UIControlStateNormal];
        });
    }
}





@end
