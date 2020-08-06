//
//  GenericShareViewController.h
//
//  Created by Scott Snibbe on 6/7/10
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#include "defs.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "FacebookAgent.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

class Parameters;

@interface GenericShareViewController : UIViewController <FacebookAgentDelegate, MFMailComposeViewControllerDelegate> {
			
	Parameters			*params;
	FacebookAgent 		*fbAgent; 
	
	GLuint *imageBuffer_;
	UIImage	*renderedImage_;
}

// Notifications

// responds to message "EmailPDF" with parameters:
//
// (NSString *)emailSubject	
// (NSString *)emailBody 
// (NSString *)filePrefix
	
- (void) emailPDFNotification:(NSNotification *)notification;

// Internal functions

//-(void)screenCaptureAndSaveAsPhoto;
//-(void)renderImageToPDFandSaveAsPhoto:(NSString*)fileprefix;
//-(void)postImageToFacebook;
-(void)emailPDF:(NSString*)subject body:(NSString*)body fileprefix:(NSString*)fileprefix;
//-(void)emailAntialiasedImage:(NSString*)subject body:(NSString*)body fileprefix:(NSString*)fileprefix;

-(NSString*)pdfFileName:(NSString*)fileprefix;
-(void)releaseScreenshotData;
-(UIImage *)screenshotImage;
-(UIImage*)pdfToImage:(NSString*) filename size:(CGSize) size;

-(void)mailWithAttachment:(NSString*) fileName 
					 type:(NSString*) attachmentType
					 data:(NSData*)	  attachmentData
				  subject:(NSString*) subject 
					 body:(NSString*) body;

-(UIAlertView*)waitPrompt:(NSString*) title;
-(void)dismissWaitPrompt:(UIAlertView*)alert; 

@end

