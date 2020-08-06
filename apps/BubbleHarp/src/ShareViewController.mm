//
//  ShareViewController.mm
//  Bubble Harp
//
//  Created by Scott Snibbe on 6/1/10.
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#include "defs.h"
#include "Parameters.h"
#import "ShareViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "SaveViewController.h"
#import "LoadViewController.h"

#undef BOOL


static NSString* kApiKey = @"b7b1548e66749a36e92518956e1c2d29";
// Enter either your API secret or a callback URL (as described in documentation):
static NSString* kApiSecret =  @"4c312982da4fa23fc11c4b27060c87ad";
static NSString* kImageCaption = @"created with Bubble Harp for iPhone and iPad: http://snibbe.com/store/bubbleharp";

@implementation ShareViewController

//@synthesize sharePDFButton;

@synthesize photoButton, facebookPhotoButton, nameLabel, fbConnectButton, saveButton, loadButton,
saveViewController, loadViewController;

#pragma mark-

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		_session = [[FBSession sessionForApplication:kApiKey secret:kApiSecret delegate:self] retain];
	}
	return self;
}

- (void)viewDidLoad {
	
	[super viewDidLoad];
	
	params = gBubbleHarp->params();	 
	
	/*
	fbAgent = [[FacebookAgent alloc] initWithApiKey:@"b7b1548e66749a36e92518956e1c2d29"
										  ApiSecret:@"4c312982da4fa23fc11c4b27060c87ad"
										   ApiProxy:nil];
	fbAgent.delegate = self;
	*/
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		self.saveViewController = 	
		[[SaveViewController alloc] initWithNibName:@"save-iPad" bundle:nil];
		self.loadViewController = 	
		[[LoadViewController alloc] initWithNibName:@"load-iPad" bundle:nil];
	} else {
		self.saveViewController = 	
		[[SaveViewController alloc] initWithNibName:@"save-iPhone" bundle:nil];
		self.loadViewController = 	
		[[LoadViewController alloc] initWithNibName:@"load-iPhone" bundle:nil];
	}
		
	imageBuffer_ = nil;
	renderedImage_ = nil;
	queryType = ShareFBQuery_NONE;
	userName = @"";
	
	resumed = false;
	askedPermission = false;
	[_session resume];
	fbConnectButton.style = FBLoginButtonStyleNormal;
	
	if (_session.isConnected) {
		//[self queryUserInfo];	// get username
		resumed = true;
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	if (gBubbleHarp->nVPoints() == 0) {
		saveButton.enabled = false;
	} else {
		saveButton.enabled = true;
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
	
	[self releaseScreenshotData];
	[renderedImage_ dealloc];
	[_session release];
	//[fbAgent dealloc];
    [super dealloc];
	
	//NSLog(@"ShareViewController:dealloc");
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {		
		// The device is an iPad running iPhone 3.2 or later, support rotation
		return YES;
	}
	else {
		// The device is an iPhone or iPod touch, only support portrait
		return (interfaceOrientation == UIInterfaceOrientationPortrait);		 
	}
}

// handle the photo button
- (IBAction)photoAction:(id)sender
{
	//gBubbleHarp->dismissPopups(NO);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DismissPopups" object:nil];
	
	//NSLog(@"Take Photo");
	[self screenCapture];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
	} else 
	{
		[self dismissAction:nil];	// also dismiss modal view with buttons -- iPhone UI
	}
}

/*
-(IBAction)pdfAction:(id)sender
{
	gBubbleHarp->resetIdleTimer(NO);
	
	NSString *emailSubject = [NSString 
							  stringWithFormat:@"I created this with Bubble Harp on my %@",
							  [[UIDevice currentDevice] model]];
	
	
	NSString *emailBody = 
	[NSString stringWithFormat:@"Check out this work of art I made with <a HREF=\"http://snibbe.com/store/bubbleharp\">Bubble Harp</a> on my %@.", [[UIDevice currentDevice] model]];
	
	
	
	NSMutableDictionary *mailArgs = [[NSMutableDictionary alloc] init];
	[mailArgs setObject:emailSubject forKey:@"emailSubject"];
	[mailArgs setObject:emailBody forKey:@"emailBody"];
	[mailArgs setObject:@"bubbleharp" forKey:@"filePrefix"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EmailPDF" object:nil userInfo:mailArgs];

	// dismiss popup (iPad) 
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DismissPopups" object:nil];
	// or modal view (iPhone)
	[self dismissAction:sender];
}
*/

// handle the pdf button
- (IBAction)pdfAction:(id)sender
{
	gBubbleHarp->resetIdleTimer(NO);
	
	//[[NSNotificationCenter defaultCenter] postNotificationName:@"DismissPopups" object:nil];
	//[self dismissAction:sender];

	//NSLog(@"Email PDF");
	
	if (gBubbleHarp->drawToPDF(PDF_FILENAME, 
							   params->pdfDotSize(), params->pdfLineWidth(), 
							   params->pdfPointWidth(), params->pdfPointHeight())) {
		
		// load in PDF data from saved file
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *saveDirectory = [paths objectAtIndex:0];
		NSString *pdfFilePath = [saveDirectory stringByAppendingPathComponent:PDF_FILENAME];
		
		NSURL *url = [NSURL fileURLWithPath:pdfFilePath];
		NSError *error = nil;		
		
		// replace generic filename with date formatted filename
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateFormat:@"'bubbleharp-'yyyy-MM-dd-HHmm'.pdf'"];		
		NSString *emailFilename = [dateFormatter stringFromDate:[NSDate date]];

		NSData *pdfData = [NSData dataWithContentsOfURL:url options:NSUncachedRead error:&error];	
		[self mailWithAttachment:emailFilename 
							type:@"application/pdf" data:pdfData];	
	}
}

/*
// handle the photo button ($ not in ui - not necessary with PDF)
- (IBAction)emailPhoto:(id)sender
{
	gBubbleHarp->resetIdleTimer(NO);
	
	//NSLog(@"Email Photo");

	// render PDF image for antialiasing
		UIImage *smoothImage = [self pdfToImage:CGSizeMake(384, 512)];

	if (smoothImage != nil) {
		// replace generic filename with date formatted filename
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateFormat:@"'bubbleharp-'yyyy-MM-dd-HHmm'.png'"];		
		NSString *emailFilename = [dateFormatter stringFromDate:[NSDate date]];
		
		NSData *pngData = UIImagePNGRepresentation(smoothImage);
		[self mailWithAttachment:emailFilename 
							type:@"image/png" data:pngData];	
	}
}
*/

///////////////////////////////////////////////////////////////////////////////////////////////////
/*
-(IBAction) facebookConnectAction:(id)sender{
	
	gBubbleHarp->resetIdleTimer(NO);	// so that popup remains
	
	if(fbConnectButton.selected){
		[fbAgent logout];
	}else {
		[fbAgent login];
	}
}
*/

// handle the link button
- (IBAction)facebookAction:(id)sender
{
	gBubbleHarp->resetIdleTimer(NO);
	
	//NSLog(@"Post to Facebook");
	
	//UIImage *screenImage = [self screenshotImage];
	
	// render PDF image for antialiasing
	UIImage *smoothImage = nil;
	
	float dotSize, lineWidth, imageWidth, imageHeight;
	
	dotSize = params->pdfDotSize()*1.5;
	lineWidth = params->pdfLineWidth()*1.75;
	imageWidth = ofGetScreenWidth();
	imageHeight = ofGetScreenHeight();
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
	// save at half size for facebook/iPad, means we need to scale up lines/dots to look good when filtered
		//dotSize *= 1.5;
		//lineWidth = params->pdfLineWidth()*1.75;
		imageWidth *= 0.5;
		imageHeight *= 0.5;
	} 
	
	if (gBubbleHarp->drawToPDF(PDF_FILENAME, 
							   dotSize, lineWidth, 
							   params->pdfPointWidth(), params->pdfPointHeight())) {
		
		smoothImage = 
		[self pdfToImage:PDF_FILENAME 
					size:CGSizeMake(imageWidth, imageHeight)];		
		
		if (smoothImage) {
			renderedImage_ = smoothImage;
			[renderedImage_ retain]; // de-allocated in releaseScreenshotData

			[self postPhotoToFacebook];

		}
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DismissPopups" object:nil];
	} else 
	{
		[self dismissAction:nil];	// also dismiss modal view with buttons -- iPhone UI
	}
}

-(void)postPhotoToFacebook
{	
	/*
	[fbAgent uploadPhotoAsData:(NSData*)renderedImage_ 
				   withCaption:@"created with Bubble Harp for iPhone and iPad: http://snibbe.com/store/bubbleharp"
					   toAlbum:nil]; 
	*/
	
	// FBConnect method for uploading photo with caption
	NSDictionary *photoParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:kImageCaption,@"caption",nil];
	[[FBRequest requestWithDelegate:self] call:@"facebook.photos.upload" params:photoParams dataParam:(NSData*)renderedImage_];
	
}

-(IBAction)saveAction:(id)sender
{
	//gBubbleHarp->setRunning(false);
	// bring up save view
	if (IS_IPAD) {
		saveViewController.modalPresentationStyle = UIModalPresentationFormSheet;
		saveViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	} else {

	}
	
	gBubbleHarp->resetIdleTimer(NO);

	if (IS_IPAD)	// present from base controller to avoid problems when rotating view
		[gBubbleHarp->interfaceViewController() presentModalViewController: saveViewController animated: YES];
	else 
		[self presentModalViewController: saveViewController animated: YES];

}

-(IBAction)loadAction:(id)sender
{
	gBubbleHarp->setRunning(false);
	
	// bring up load view
	if (IS_IPAD) {
		loadViewController.modalPresentationStyle = UIModalPresentationFormSheet;
		loadViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	} else {

	}
	
	gBubbleHarp->resetIdleTimer(NO);
	
	if (IS_IPAD)	// present from base controller to avoid problems when rotating view
		[gBubbleHarp->interfaceViewController() presentModalViewController: loadViewController animated: YES];
	else
		[self presentModalViewController: loadViewController animated: YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// FBDialogDelegate

- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError*)error {

	// catch permission error and bring up dialogue? $$$$
	
	if (error.code == 102) {
	}
	
	nameLabel.text = [NSString stringWithFormat:@"Error(%d) %@", error.code,
					  error.localizedDescription];
	
	NSLog(@"dialog:didFailWithError: %@", nameLabel.text);
	
	[self releaseScreenshotData];
}

- (void)dialogDidSucceed:(FBDialog*)dialog
{
	if ([dialog isMemberOfClass:[FBPermissionDialog class]])
		[self queryPermissions];	// get permissions to enable/disable photo button - might have canceled permission dialog
	//facebookPhotoButton.enabled = YES;
}


- (void)dialogDidCancel:(FBDialog *)dialog 
{
	//if ([dialog isMemberOfClass:[FBPermissionDialog class]])
	//	facebookPhotoButton.enabled = NO;
	
	//[self queryPermissions];	// get permissions to enable/disable photo button - might have canceled permission dialog
	//facebookPhotoButton.enabled = NO;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
// FBSessionDelegate

- (void) queryUserInfo
{
	NSString* fql = [NSString stringWithFormat:
					 @"select uid,name from user where uid == %lld", _session.uid];
	queryType = ShareFBQuery_UserInfo;
	
	NSDictionary* userParams = [NSDictionary dictionaryWithObject:fql forKey:@"query"];
	[[FBRequest requestWithDelegate:self] call:@"facebook.fql.query" params:userParams];
}

- (void) queryPermissions
{
	NSString* fql = [NSString stringWithFormat:@"select photo_upload from permissions where uid = %lld"
					 ,_session.uid];
	NSDictionary* permissions = [NSDictionary dictionaryWithObject:fql forKey:@"query"];
	queryType = ShareFBQuery_Permissions;
	[[FBRequest requestWithDelegate:self] call:@"facebook.fql.query" params:permissions];
}

- (void)session:(FBSession*)session didLogin:(FBUID)uid {
	
	NSLog(@"session didLogin");
	
	nameLabel.text = @"";
	userName = @"";
	
	facebookPhotoButton.enabled = YES;
	
	[self queryUserInfo];
}

- (void)sessionDidNotLogin:(FBSession*)session {
	NSLog(@"sessionDidNotLogin");
	//nameLabel.text = @"Canceled login";
	nameLabel.text = @"";
	userName = @"";
	askedPermission = NO;
}

- (void)sessionDidLogout:(FBSession*)session {
	NSLog(@"sessionDidLogout");
	nameLabel.text = @"";
	facebookPhotoButton.enabled = NO;
	userName = @"";
	askedPermission = NO;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// FBRequestDelegate

- (void)request:(FBRequest*)request didLoad:(id)result {
	if ([request.method isEqualToString:@"facebook.fql.query"]) {
		
		// switch on query
		switch (queryType) {
			case ShareFBQuery_UserInfo: {
				NSDictionary* user = [result objectAtIndex:0];
				// do this so the text is retained
				userName = [user objectForKey:@"name"];
				//[nameLabel retain];
				
				//nameLabel.text = [NSString stringWithFormat:@"Logged in as %@", userName];
				nameLabel.text = userName;
			
				[self queryPermissions];
			}
				break;
				
			case ShareFBQuery_Permissions: {
				queryType = ShareFBQuery_NONE;
			
				NSArray* permissionStatus  = [result objectAtIndex:0];
				bool hasPhotoPermission = [[permissionStatus valueForKey:@"photo_upload"] boolValue];

				if (!hasPhotoPermission) {
					facebookPhotoButton.enabled = NO;
					
					if (resumed || askedPermission) {
						// if we've just resumed and we get here, it means the person has changed
						// permissions, or never allowed permissions, but logged in. Instead
						// of obtrusively popping up a dialogue, just log out so they have to press
						// the button to login and get re-queried to authorize
						[_session logout];
						resumed = NO;
						askedPermission = NO;
					} else {
						// ask permission to publish photos
						FBPermissionDialog* dialog = [[[FBPermissionDialog alloc] init] autorelease];
						dialog.delegate = self;
						dialog.permission = @"photo_upload";
						[dialog show];
						
						askedPermission = YES;
						
						//[self queryPermissions];
					}
				} else {
					facebookPhotoButton.enabled = YES;
				}
			}
				break;
		}
		
	} else if ([request.method isEqualToString:@"facebook.users.setStatus"]) {
		NSString* success = result;
		if ([success isEqualToString:@"1"]) {
			nameLabel.text = [NSString stringWithFormat:@"Status successfully set"]; 
		} else {
			nameLabel.text = [NSString stringWithFormat:@"Problem setting status"]; 
		}
		
	} else if ([request.method isEqualToString:@"facebook.photos.upload"]) {
		/*
		NSDictionary* photoInfo = result;
		NSString* pid = [photoInfo objectForKey:@"pid"];
		nameLabel.text = [NSString stringWithFormat:@"Uploaded with pid %@", pid];
		 */
		
		gBubbleHarp->resetIdleTimer(YES);
		[self releaseScreenshotData];
		
		NSString* title = @"Photo posted to Facebook";
		UIAlertView *alert = [[[UIAlertView alloc]   
							   initWithTitle:title  
							   message:nil delegate:self cancelButtonTitle:@"OK"  
							   otherButtonTitles: nil] autorelease];  
		
		//[alert setDimsBackground:NO];
		
		[alert show];  
	}
	
	NSLog(@"request: method: %@, result: %@", request.method, nameLabel.text);
}

- (void)request:(FBRequest*)request didFailWithError:(NSError*)error {
	nameLabel.text = [NSString stringWithFormat:@"Error(%d) %@", error.code,
				   error.localizedDescription];
	
	NSLog(@"request didFailWithError: %@", nameLabel.text);
	
	switch (error.code) {
		case FBAPI_EC_PARAM_SESSION_KEY:	// stale session (e.g. if user disallowed permissions)
			[_session logout];
			break;
	}
	
	[self releaseScreenshotData];
}



#if 0
-(void) facebookAgent:(FacebookAgent*)agent loginStatus:(BOOL) loggedIn{ 
	NSLog(@"FaceBookAgent: logged in: %d", loggedIn);
	
	fbConnectButton.selected = loggedIn;
	if(!loggedIn){
		nameLabel.text = @"";
		//[self.facebookButton setEnabled:NO];
		facebookPhotoButton.enabled = NO;
	}else {
		facebookPhotoButton.enabled = YES;
		//[self.facebookButton setEnabled:YES];
	}
	[self.view setNeedsDisplay];
} 

-(void) facebookAgent:(FacebookAgent*)agent statusChanged:(BOOL) success {
	NSLog(@"FaceBookAgent: status changed: %d", success);
}


- (void) facebookAgent:(FacebookAgent*)agent permissionGranted:(FacebookAgentPermission)permission
{
	NSLog(@"FaceBookAgent: permission granted: %d", permission);
	
	[fbAgent getPermissions];
}
- (void) facebookAgent:(FacebookAgent*)agent didLoadFQL:(NSArray*) data
{
	NSLog(@"FaceBookAgent: didLoadFQL");
}

- (void) facebookAgent:(FacebookAgent*)agent didLoadPermissions:(NSArray*) data
{
	NSLog(@"FaceBookAgent: didLoadPermissions");
	
	if (![fbAgent hasPermission:FacebookAgentPermissionPhotoUpload]) {
		[fbAgent grantPermission:FacebookAgentPermissionPhotoUpload];
	} 
}

- (void) facebookAgent:(FacebookAgent*)agent didLoadInfo:(NSDictionary*) info
{
	NSLog(@"FaceBookAgent: didLoadInfo");	
	nameLabel.text = [fbAgent getUserName];
	[fbAgent getPermissions];
}

- (void) facebookAgent:(FacebookAgent*)agent didLoadFriendList:(NSArray*) data onlyAppUsers:(BOOL)yesOrNo
{
	NSLog(@"FaceBookAgent: didLoadFriendList");
}


-(void) facebookAgent:(FacebookAgent*)agent photoUploaded:(NSString*) pid {
	NSLog(@"FaceBookAgent: photo uploaded");
	
	gBubbleHarp->resetIdleTimer(YES);
	[self releaseScreenshotData];
	
	NSString *accountName = [fbAgent getUserName];
	if (accountName == nil) accountName = @"";

	NSString* title = [NSString stringWithFormat:@"Photo posted to Facebook account: %@", accountName];
	//NSString* title = @"Photo posted to Facebook account";
	UIAlertView *alert = [[[UIAlertView alloc]   
						   initWithTitle:title  
						   message:nil delegate:self cancelButtonTitle:@"OK"  
						   otherButtonTitles: nil] autorelease];  
	
	//[alert setDimsBackground:NO];
	
	[alert show];  
	
	//[self dismissWaitPrompt:alert];

}

-(void) facebookAgent:(FacebookAgent*)agent requestFaild:(NSString*) message {
	NSLog(@"FaceBookAgent: request failed: %@", message);
	
	// reset UI
		//[fbAgent logout];
	/*
	fbConnectButton.selected = NO;
	nameLabel.text = @"";
	facebookPhotoButton.enabled = NO;
	*/
	
	[self releaseScreenshotData];
	
	/*
	NSString *accountName = [fbAgent getUserName];
	if (accountName == nil) accountName = @"";
	
	NSString* title = [NSString stringWithFormat:@"Unable to upload photo to Facebook account %@ at this time. Sorry.", [fbAgent getUserName]];
	*/
	UIAlertView *alert = [[[UIAlertView alloc]   
						   initWithTitle:@"Unable to upload photo at this time. Sorry!"  
						   message:nil delegate:self cancelButtonTitle:@"OK"  
						   otherButtonTitles: nil] autorelease];  
	
	[alert show];  
	
	//[fbAgent logout];
	//facebookButton.enabled = YES;
	
	gBubbleHarp->resetIdleTimer(YES);
}

- (void) facebookAgent:(FacebookAgent*)agent dialog:(FBDialog*)dialog didFailWithError:(NSError*)error
{
	NSLog(@"FaceBookAgent: didFailWithError");
}
#endif


-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	
	switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Result: canceled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Result: saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Result: sent");
			//[self.parentViewController dismissModalViewControllerAnimated:YES];
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Result: failed");
            break;
        default:
            NSLog(@"Result: not sent");
            break;
    }
		
	[self becomeFirstResponder];
	[self dismissModalViewControllerAnimated:YES];

	// recompute bounds in case device rotated
	//[[NSNotificationCenter defaultCenter] postNotificationName:@"RotateViewToCurrent" object:nil];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DismissPopups" object:nil];
	} else 
	{
		[self dismissAction:nil];	// also dismiss modal view with buttons -- iPhone UI
	}
	
}

-(void)mailWithAttachment:(NSString *) fileName 
					 type:(NSString*) attachmentType
					 data:(NSData *) attachmentData {
	
	MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
	mc.mailComposeDelegate = self;
	
	if ([MFMailComposeViewController canSendMail]) {
		//mc.modalPresentationStyle = UIModalPresentationFullScreen;
		
		[mc setSubject:[NSString stringWithFormat:@"I created this with Bubble Harp on my %@", [[UIDevice currentDevice] model]]];
		
		NSString *emailBody = 
		[NSString stringWithFormat:@"Check out this work of art I made with <a HREF=\"http://snibbe.com/store/bubbleharp\">Bubble Harp</a> on my %@.", [[UIDevice currentDevice] model]];
		[mc setMessageBody:emailBody isHTML:YES];
		
		[mc addAttachmentData:attachmentData 
					 mimeType:attachmentType
					 fileName:fileName];
		
		[self presentModalViewController:mc animated:YES];
	}
	[mc release];
}

- (UIImage*)pdfToImage:(NSString*) filename size:(CGSize) size
	{
	UIGraphicsBeginImageContext(size); 
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *saveDirectory = [paths objectAtIndex:0];
	NSString *newFilePath = [saveDirectory stringByAppendingPathComponent:filename];
	const char *filepath = [newFilePath UTF8String];	
	
	// This code block sets up our PDF Context so that we can draw to it
	CFStringRef path;
	CFURLRef url;
	// Create a CFString from the filename we provide to this method when we call it
	path = CFStringCreateWithCString (NULL, filepath,
									  kCFStringEncodingUTF8);
	// Create a CFURL using the CFString we just defined
	url = CFURLCreateWithFileSystemPath (NULL, path,
										 kCFURLPOSIXPathStyle, 0);
	CFRelease (path);
	
	CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((CFURLRef)url);	
	CGContextTranslateCTM(context, 0.0, size.height);	
	CGContextScaleCTM(context, 1.0, -1.0);	
	CGPDFPageRef page = CGPDFDocumentGetPage(pdf, 1);	
	CGContextSaveGState(context);	
	CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, CGRectMake(0, 0, size.width, size.height), 0, true);	
	CGContextConcatCTM(context, pdfTransform);	
	CGContextDrawPDFPage(context, page);	
	CGContextRestoreGState(context);
	
	UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();  
	UIGraphicsEndImageContext();
	return resultingImage;
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
	[self releaseScreenshotData];
}

-(void)screenCapture
{
	UIAlertView *alert = [self waitPrompt:@"Saving to Photos..."];
/*
	UIImage *screenImage = [self screenshotImage];
	UIImageWriteToSavedPhotosAlbum(screenImage, self,  @selector(image:didFinishSavingWithError:contextInfo:), nil);
*/
		
	// render PDF image for antialiasing
	UIImage *smoothImage = nil;
	
	if (gBubbleHarp->drawToPDF(PDF_FILENAME, 
							   3, 1, // $$ magic numbers - make constants/params
							   ofGetScreenWidth(), ofGetScreenHeight())) {
		
		smoothImage = 
		[self pdfToImage:PDF_FILENAME 
					size:CGSizeMake(ofGetScreenWidth(), ofGetScreenHeight())];		
		
		if (smoothImage) {
			//renderedImage_ = smoothImage;
			UIImageWriteToSavedPhotosAlbum(smoothImage, self,  @selector(image:didFinishSavingWithError:contextInfo:), nil);
		}
	}
	
	[self dismissWaitPrompt:alert];
}
/*
-(void)writeEPS
{
	float ptWidth = 72.0 * 8.0; // 8 inches
	float scale = ptWidth / ofGetWidth();
	float ptHeight = scale * ofGetHeight();
	NSString *epsString = gBubbleHarp->writeEPSToString(1.5, 1, ptWidth, ptHeight);
	
	[self sendEmailTo:@"scott@snibbe.com" withSubject:@"bubble harp eps" withBody:epsString];
}

-(void)sendEmailTo:(NSString *)to withSubject:(NSString *) subject withBody:(NSString *)body
{
	NSString *mailString = [NSString stringWithFormat:@"mailto:?to=%@&subject=%@&body=%@",
							[to stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
							[subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
							[body stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:mailString]];
}
*/

-(void)releaseScreenshotData
{
	if (imageBuffer_) {
		free((void *)imageBuffer_);
		imageBuffer_ = nil;
	}
	if (renderedImage_) {
		[renderedImage_ release];
		renderedImage_	= nil;
	}
}

- (UIImage *)screenshotImage {
	CGRect rect = [[UIScreen mainScreen] bounds];
	int backingWidth = rect.size.width;
	int backingHeight =  rect.size.height;
	
	NSInteger myDataLength = backingWidth * backingHeight * 4;
	
	// allocate array and read pixels into it.
	GLuint *buffer = (GLuint *) malloc(myDataLength);
	imageBuffer_ = buffer;
	glReadPixels(0, 0, backingWidth, backingHeight, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
	
	// gl renders “upside down” so swap top to bottom into new array.
	for(int y = 0; y < backingHeight / 2; y++) {
		for(int x = 0; x < backingWidth; x++) {
			//Swap top and bottom bytes
			GLuint top = buffer[y * backingWidth + x];
			GLuint bottom = buffer[(backingHeight - 1 - y) * backingWidth + x];
			buffer[(backingHeight - 1 - y) * backingWidth + x] = top;
			buffer[y * backingWidth + x] = bottom;
		}
	}
	
	// make data provider with data.
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, myDataLength, NULL);
	
	// prep the ingredients
	const int bitsPerComponent = 8;
	const int bitsPerPixel = 4 * bitsPerComponent;
	const int bytesPerRow = 4 * backingWidth;
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	
	// make the cgimage
	CGImageRef imageRef = CGImageCreate(rect.size.width, rect.size.height, bitsPerComponent, bitsPerPixel, 
										bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
	CGColorSpaceRelease(colorSpaceRef);
	CGDataProviderRelease(provider);
	
	// then make the UIImage from that
	UIImage *myImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	
	return myImage;
}

// eat touches to prevent them from being passed to window below
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (IBAction)dismissAction:(id)sender {

	[self dismissModalViewControllerAnimated:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ResetTimer" object:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RotateViewToCurrent" object:nil];
}

-(UIAlertView*) waitPrompt:(NSString*) title
{  
	UIAlertView *alert = [[[UIAlertView alloc]   
						   initWithTitle:title   
						   message:nil delegate:self cancelButtonTitle:nil  
						   otherButtonTitles: nil] autorelease];  
	
	//[alert setDimsBackground:NO];
	
	[alert show];  
	
	UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]  
										  initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];  
	
	indicator.center = CGPointMake(alert.bounds.size.width / 2,   
								   alert.bounds.size.height - 50);  
	[indicator startAnimating];  
	[alert addSubview:indicator];  
	[indicator release];  
	
	// 250ms pause for the dialog to become active...  
	int n=0;  
	
	while(n < 250)  
	{  
		[[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];  
		ofSleepMillis(1);  
		n++;  
	}  
	
	return alert;  
} 

-(void) dismissWaitPrompt:(UIAlertView*)alert  
{  
    [alert dismissWithClickedButtonIndex:0 animated:YES];  
} 

@end
