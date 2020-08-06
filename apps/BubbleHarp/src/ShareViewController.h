//
//  SettingsViewController.h
//  Bubble Harp
//
//  Created by Scott Snibbe on 5/30/10
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#include "defs.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
//#import "FacebookAgent.h"
#import "FBConnect.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

class Parameters;

@class FBSession;

typedef enum ShareFBQueryType {
	ShareFBQuery_NONE =0,
	ShareFBQuery_UserInfo,
	ShareFBQuery_Permissions
};

//@interface ShareViewController : UIViewController <FacebookAgentDelegate, MFMailComposeViewControllerDelegate> {
@interface ShareViewController : UIViewController 
<FBDialogDelegate,
FBSessionDelegate,
FBRequestDelegate, 
MFMailComposeViewControllerDelegate> {
	
	UIButton			*photoButton;
	UIButton			*facebookPhotoButton;
	UIButton			*saveButton;
	UIButton			*loadButton;
	UILabel				*nameLabel;
	//FBLoginButton		*fbConnectButton;
	//	UIButton			*fbConnectButton;
	//	UIButton			*sharePDFButton;
	
	UIViewController	*saveViewController, *loadViewController;
	
	Parameters			*params;
	//FacebookAgent 		*fbAgent; 
	FBSession			*_session;
	
	GLuint		*imageBuffer_;
	UIImage		*renderedImage_;
	NSString	*deviceName;
	
	NSString		*userName;
	bool			resumed, askedPermission;
	ShareFBQueryType queryType;
}

@property(nonatomic,retain) IBOutlet UIButton	*photoButton;
@property(nonatomic,retain) IBOutlet UIButton	*facebookPhotoButton;
@property(nonatomic,retain) IBOutlet UIButton	*saveButton;
@property(nonatomic,retain) IBOutlet UIButton	*loadButton;
//@property(nonatomic,retain) IBOutlet FBLoginButton	*fbConnectButton;
@property(nonatomic,retain) IBOutlet UILabel	*nameLabel;
//@property(nonatomic,retain) IBOutlet UIButton	*sharePDFButton;
@property(nonatomic,retain)		UIViewController *saveViewController;
@property(nonatomic,retain)		UIViewController *loadViewController;

-(IBAction)photoAction:(id)sender;
-(IBAction)facebookAction:(id)sender;
//-(IBAction)facebookConnectAction:(id)sender;
-(IBAction)pdfAction:(id)sender;
-(IBAction)dismissAction:(id)sender;
//-(IBAction)emailPhoto:(id)sender;
-(IBAction)saveAction:(id)sender;
-(IBAction)loadAction:(id)sender;

- (void)queryUserInfo;
- (void)queryPermissions;
-(void)postPhotoToFacebook;
-(void)releaseScreenshotData;
-(UIImage *)screenshotImage;
-(UIImage*)pdfToImage:(NSString*) filename size:(CGSize) size;
-(void)screenCapture;
//-(NSString*)savePDF;

-(void)mailWithAttachment:(NSString *) fileName 
					 type:(NSString*) attachmentType
					 data:(NSData *) attachmentData;

-(UIAlertView*)waitPrompt:(NSString*) title;
-(void)dismissWaitPrompt:(UIAlertView*)alert; 

@end

