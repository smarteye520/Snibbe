//
//  GenericShareViewController.mm
//  Bubble Harp
//
//  Created by Scott Snibbe on 6/1/10.
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#include "defs.h"
#include "Parameters.h"
#import "GenericShareViewController.h"
#include "ofAppRunner.h"
#import <QuartzCore/QuartzCore.h>
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"

#undef BOOL

@implementation GenericShareViewController

#pragma mark-

- (void)loadView {
	// create this view
	
	CGSize s = [[[UIApplication sharedApplication] keyWindow] bounds].size;
	
	self.view = [[UIView alloc] initWithFrame:CGRectMake(0,0,s.width, s.height)];
	self.view.backgroundColor = [UIColor yellowColor];
	// etc.
	
	
	/*
	 fbAgent = [[FacebookAgent alloc] initWithApiKey:@"b7b1548e66749a36e92518956e1c2d29"
	 ApiSecret:@"4c312982da4fa23fc11c4b27060c87ad"
	 ApiProxy:nil];
	 fbAgent.delegate = self;
	 */
	
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {	
	[super viewDidLoad];
	
	self.view.hidden = YES;
	
	imageBuffer_ = nil;
	renderedImage_ = nil;
	
	params = gBubbleHarp->params();	
	
	// register messages
	[[NSNotificationCenter defaultCenter] 
	 addObserver:self
	 selector:@selector(emailPDFNotification:)
	 name:@"EmailPDF" object:nil];	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
	// $$$
	
	[self releaseScreenshotData];
	[renderedImage_ dealloc];
	[fbAgent dealloc];
	
    [super dealloc];
	
	NSLog(@"GenericShareViewController:dealloc");
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{		
		return YES;
	}
	else
#endif
	{
		// The device is an iPhone or iPod touch, only support portrait
		return (interfaceOrientation == UIInterfaceOrientationPortrait);		 
	}
	
}

-(NSString*)pdfFileName:(NSString*)fileprefix
{
	return [NSString stringWithFormat:@"%@.pfd", fileprefix];
}

#pragma mark Notifications

- (void) emailPDFNotification:(NSNotification *)notification
{
	NSString *emailSubject = [[notification userInfo] objectForKey:@"emailSubject"];
	NSString *emailBody = [[notification userInfo] objectForKey:@"emailBody"];
	NSString *filePrefix = [[notification userInfo] objectForKey:@"filePrefix"];	
	
	[self emailPDF:emailSubject body:emailBody fileprefix:filePrefix];
}

#pragma mark Functions

- (void)emailPDF:(NSString*)subject body:(NSString*)body fileprefix:(NSString*)fileprefix
{
	self.view.hidden = NO;
	
	if (gBubbleHarp->drawToPDF([self pdfFileName:fileprefix], 
							   params->pdfDotSize(), params->pdfLineWidth(), 
							   params->pdfPointWidth(), params->pdfPointHeight())) {
		
		// load in PDF data from saved file
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *saveDirectory = [paths objectAtIndex:0];
		NSString *pdfFilePath = [saveDirectory stringByAppendingPathComponent:[self pdfFileName:fileprefix]];
		
		NSURL *url = [NSURL fileURLWithPath:pdfFilePath];
		NSError *error = nil;		
		
		// replace generic filename with date formatted filename
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateFormat:[NSString stringWithFormat:@"'%@-'yyyy-MM-dd-HHmm'.pdf'", fileprefix]];		
		NSString *emailFilename = [dateFormatter stringFromDate:[NSDate date]];
		
		NSData *pdfData = [NSData dataWithContentsOfURL:url options:NSUncachedRead error:&error];	
		[self mailWithAttachment:emailFilename 
							type:@"application/pdf" data:pdfData
						 subject:subject body:body];	
	}
}

// render to PDF, then image, and email photo
- (void)emailAntialiasedImage:(NSString*)subject body:(NSString*)body fileprefix:(NSString*)fileprefix
{
	gBubbleHarp->resetIdleTimer(NO);
	
	//NSLog(@"Email Photo");
	
	UIImage *smoothImage = 
	[self pdfToImage:[self pdfFileName:fileprefix] 
				size:CGSizeMake(ofGetScreenWidth(), ofGetScreenHeight())];		
	
	if (smoothImage) {
		renderedImage_ = smoothImage;
		
		// replace generic filename with date formatted filename
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateFormat:@"'bubbleharp-'yyyy-MM-dd-HHmm'.png'"];		
		NSString *emailFilename = [dateFormatter stringFromDate:[NSDate date]];
		
		NSData *pngData = UIImagePNGRepresentation(smoothImage);
		[self mailWithAttachment:emailFilename 
							type:@"image/png" data:pngData
						 subject:subject body:body];	
	}
}

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
	self.view.hidden = YES;
}
		 
-(void)mailWithAttachment:(NSString *) fileName 
					 type:(NSString*) attachmentType
					 data:(NSData *) attachmentData
				  subject:(NSString*) subject 
					 body:(NSString*) body
{
	
	MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
	mc.mailComposeDelegate = self;
	
	if ([MFMailComposeViewController canSendMail]) {
		//mc.modalPresentationStyle = UIModalPresentationFullScreen;
		
		[mc setSubject:subject];
		[mc setMessageBody:body isHTML:YES];
		
		[mc addAttachmentData:attachmentData 
					 mimeType:attachmentType
					 fileName:fileName];
		
		[self presentModalViewController:mc animated:YES];
	}
	//[mc release];
}

-(void)releaseScreenshotData
{
	if (imageBuffer_) {
		free((void *)imageBuffer_);
		imageBuffer_ = nil;
	}
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
	[self releaseScreenshotData];
}

-(void)screenCaptureAndSaveAsPhoto
{
	UIAlertView *alert = [self waitPrompt:@"Saving to Photos..."];
	
	UIImage *screenImage = [self screenshotImage];
	UIImageWriteToSavedPhotosAlbum(screenImage, self,  @selector(image:didFinishSavingWithError:contextInfo:), nil);
	
	[self dismissWaitPrompt:alert];
}

-(void)renderImageToPDFandSaveAsPhoto:(NSString*)fileprefix
{
	UIAlertView *alert = [self waitPrompt:@"Saving to Photos..."];

	// render PDF image for antialiasing
	UIImage *smoothImage = nil;
	
	if (gBubbleHarp->drawToPDF([self pdfFileName:fileprefix], 
							   3, 1, // $$ magic numbers - make constants/params
							   ofGetScreenWidth(), ofGetScreenHeight())) {
		
		smoothImage = 
		[self pdfToImage:[self pdfFileName:fileprefix] 
					size:CGSizeMake(ofGetScreenWidth(), ofGetScreenHeight())];		
		
		if (smoothImage) {
			renderedImage_ = smoothImage;
			UIImageWriteToSavedPhotosAlbum(smoothImage, self,  @selector(image:didFinishSavingWithError:contextInfo:), nil);
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DismissPopups" object:nil];
	[self dismissWaitPrompt:alert];
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

-(void) facebookAgent:(FacebookAgent*)agent loginStatus:(BOOL) loggedIn{ 
	NSLog(@"FaceBookAgent: logged in: %d", loggedIn);
	// change button title from Log in to Logged in? $$
}  

-(void) facebookAgent:(FacebookAgent*)agent statusChanged:(BOOL) success {
	NSLog(@"FaceBookAgent: status changed: %d", success);
}

-(void) facebookAgent:(FacebookAgent*)agent photoUploaded:(NSString*) pid {
	NSLog(@"FaceBookAgent: photo uploaded");
	
	gBubbleHarp->resetIdleTimer(YES);
}

-(void) facebookAgent:(FacebookAgent*)agent requestFaild:(NSString*) message {
	NSLog(@"FaceBookAgent: request failed: %@", message);
	
	gBubbleHarp->resetIdleTimer(YES);
}

-(UIAlertView*) waitPrompt:(NSString*) title
{  
	UIAlertView *alert = [[[UIAlertView alloc]   
						   initWithTitle:title   
						   message:nil delegate:nil cancelButtonTitle:nil  
						   otherButtonTitles: nil] autorelease];  
	
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
