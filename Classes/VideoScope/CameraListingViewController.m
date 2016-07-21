//
//  CameraListingViewController.m
//  VideoScope
//
//  Created by JS Products on 04/03/16.
//  Copyright © 2016  JS Products. All rights reserved.
//

#import "CameraListingViewController.h"
#import "AppDelegate.h"
#import "Constant.h"
#import "CameraPreviewViewController.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@interface CameraListingViewController (){
    
    NSMutableArray *H_allValueInDataBase;
    NSString*sSIDName;
}

@end

@implementation CameraListingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tabBarController.tabBar setTintColor:[UIColor colorWithRed:0.2968 green:0.84765625 blue:0.390625 alpha:1]];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO];
    sSIDName=nil;
    NSDictionary *ssidDic = [NSDictionary new];
    ssidDic =[self fetchSSIDInfo];
    sSIDName =[ssidDic objectForKey:@"SSID"];
    if (sSIDName == nil || [sSIDName isKindOfClass:[NSNull class]] || [sSIDName isEqualToString:@""]) {
        NSLog(@"No Wifi Connected");
    }
    else
        NSLog(@"The Connected WIFI Device Detail is %@",ssidDic);
    
    [self.tableView reloadData];
}



/** Returns first non-empty SSID network info dictionary.
 *  @see CNCopyCurrentNetworkInfo */
- (NSDictionary *)fetchSSIDInfo
{
    NSArray *interfaceNames = CFBridgingRelease(CNCopySupportedInterfaces());
    NSLog(@"%s: Supported interfaces: %@", __func__, interfaceNames);
    
    NSDictionary *SSIDInfo;
    for (NSString *interfaceName in interfaceNames) {
        SSIDInfo = CFBridgingRelease(
                                     CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName));
        NSLog(@"%s: %@ => %@", __func__, interfaceName, SSIDInfo);
        
        BOOL isNotEmpty = (SSIDInfo.count > 0);
        if (isNotEmpty) {
            break;
        }
    }
    return SSIDInfo;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CameraList" forIndexPath:indexPath];
    // Settng Two Static Camera name and Image for same
    
    if (sSIDName == nil || [sSIDName isKindOfClass:[NSNull class]] || [sSIDName isEqualToString:@""] ) {
        NSLog(@"No Wifi Connected");
        if (indexPath.row==0)
        {
            cell.cameraName.text= @"MX1020 Masterforce Wi-Fi Inspection Camera/Video";
            cell.cameraImage.image = [UIImage imageNamed:@"MX1020-200"];
        }
        else
        {
            cell.cameraName.text=@"MX1021 Masterforce Wi-Fi Inspection Camera/Video";
            cell.cameraImage.image = [UIImage imageNamed:@"MX1021-200"];
        }
        cell.userInteractionEnabled=NO;
        cell.cameraName.enabled=NO;
        
    }
    else{
        
        if ([sSIDName isEqualToString:@"Masterforce_MX1020_Inspec_Camera"] || [sSIDName isEqualToString:@"CAM9B1F"] || [sSIDName isEqualToString:@"Masterforce _MX1020_Inspec_camera"] || [sSIDName isEqualToString:@"Masterforce_MX1020_Inspec_camera"]) {
            if (indexPath.row==0)
            {
                cell.cameraName.text= @"MX1020 Masterforce Wi-Fi Inspection Camera/Video";
                cell.cameraImage.image = [UIImage imageNamed:@"MX1020-200"];
                cell.userInteractionEnabled=YES;
                cell.cameraName.enabled=YES;
                
            }
            else
            {
                cell.cameraName.text=@"MX1021 Masterforce Wi-Fi Inspection Camera/Video";
                cell.cameraImage.image = [UIImage imageNamed:@"MX1021-200"];
                cell.userInteractionEnabled = NO;
                cell.cameraName.enabled = NO;
                
            }
        }
        else if ([sSIDName isEqualToString:@"Masterforce_MX1021_Inspec_Camera"]||[sSIDName isEqualToString:@"Steelman_PRO_Video_Scope"]) {
            if (indexPath.row==0)
            {
                cell.cameraName.text= @"MX1020 Masterforce Wi-Fi Inspection Camera/Video";
                cell.cameraImage.image = [UIImage imageNamed:@"MX1020-200"];
                cell.userInteractionEnabled=NO;
                cell.cameraName.enabled=NO;
                
            }
            else
            {
                cell.cameraName.text=@"MX1021 Masterforce Wi-Fi Inspection Camera/Video";
                cell.cameraImage.image = [UIImage imageNamed:@"MX1021-200"];
                cell.userInteractionEnabled=YES;
                cell.cameraName.enabled=YES;
                
            }
            
            
        }
        
        else{
            
            if (indexPath.row==0)
            {
                cell.cameraName.text= @"MX1020 Masterforce Wi-Fi Inspection Camera/Video";
                cell.cameraImage.image = [UIImage imageNamed:@"MX1020-200"];
            }
            else
            {
                cell.cameraName.text=@"MX1021 Masterforce Wi-Fi Inspection Camera/Video";
                cell.cameraImage.image = [UIImage imageNamed:@"MX1021-200"];
            }
            cell.userInteractionEnabled=NO;
            cell.cameraName.enabled=NO;
            
        }
        
    }
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row == 1)
    {
        // Setting stream URL for IP Camera
        
        CameraPreviewViewController *cameraPreviewViewController = [[AppDelegate instance].appStoryboard instantiateViewControllerWithIdentifier:@"CameraPreviewViewController"];
        cameraPreviewViewController.hidesBottomBarWhenPushed=YES;
        cameraPreviewViewController.cameraName=@"Steelman PRO Video Scope";
        cameraPreviewViewController.cameraURL=@"http://192.168.1.1:8080/?action=stream";
        cameraPreviewViewController.folderName=[[NSUserDefaults standardUserDefaults]objectForKey:@"folderName1"];
        [self.navigationController pushViewController:cameraPreviewViewController animated:YES];
    }
    // Implemented as per the OLD code.
    else if (indexPath.row == 0)
    {
        
        // P2P Camera settingon selection
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
        
        PlayViewController *playViewController = appDelegate.playViewController;
        
        playViewController.m_pPPPPChannelMgt = appDelegate.m_pPPPPChannelMgt;
        playViewController.strDID = @"OBJ-002864-STBZD";//OBJ-002864-STBZD/OBJ-003816-JVTGK
        playViewController.strUser=@"admin";
        playViewController.strPwd=@"";
        playViewController.cameraName = @"";
        playViewController.m_nP2PMode =1;// [nPPPPMode intValue];
        
        playViewController.m_pPicPathMgt = appDelegate.m_pPicPathMgt;
        playViewController.m_pRecPathMgt = appDelegate.m_pRecPathMgt;
        playViewController.PicNotifyDelegate = appDelegate.picViewController;
        playViewController.RecNotifyDelegate = appDelegate.recViewController;
        
        playViewController.hidesBottomBarWhenPushed=YES;
        [self.navigationController pushViewController:playViewController animated:YES];
    }
}






-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return 130;
    else
        return 100;
}

@end
