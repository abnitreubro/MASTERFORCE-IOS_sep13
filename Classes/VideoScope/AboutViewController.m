//
//  AboutViewController.m
//  VideoScope
//
//  Created by JS Products on 31/03/16.
//  Copyright © 2016  JS Products. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}




- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad))
    {       
        return UIInterfaceOrientationMaskPortrait;
    }
    return UIInterfaceOrientationMaskPortrait;

}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationMaskPortrait;
}




- (IBAction)phoneCallAction:(id)sender {
    //1-800-255-7011
    
    NSString *phNo = @"1-800-255-7011";
    NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt:%@",phNo]];
    
    if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
        [[UIApplication sharedApplication] openURL:phoneUrl];
    } else
    {
        UIAlertView * callAlert = [[UIAlertView alloc]initWithTitle:@"Alert" message:@"Call facility is not available!!!" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
        [callAlert show];
    }
}


@end






