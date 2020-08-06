//
//  ShareViewController.m
//  Gravilux
//
//  Created by Colin Roache on 11/3/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "ShareViewController.h"
//#import "FlurryAnalytics.h"
#import "SHKFacebook.h"
#import "SHKMail.h"
#import "SHKPhotoAlbum.h"
#import "SHKTwitter.h"
#import "GraviluxViewController.h"
#import "GraviluxAppDelegate.h"

@interface ShareViewController() {
	SHKMail			*shareMail;
	SHKTwitter		*shareTwitter;
	SHKFacebook		*shareFacebook;
	SHKPhotoAlbum	*sharePhotoAlbum;
}
- (UIImage *)pdfToImage:(NSString*) filename size:(CGSize) size;
- (UIImage *)screenshotImage;
- (UIImage *)watermarkImage:(UIImage*)image;
@end

@implementation ShareViewController

static NSString* kEmailBody = @"Check out this work of art I made on my %@ with <a href=\"http://snibbe.com/store/gravilux\">Gravilux</a>.<br /><br />\
<a HREF=\"http://snibbe.com/store/gravilux\">http://snibbe.com/store/gravilux</a><br />\
";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		shareMail = [[SHKMail alloc] init];
		sharePhotoAlbum = [[SHKPhotoAlbum alloc] init];
		shareFacebook = [[SHKFacebook alloc] init];
		shareTwitter = [[SHKTwitter alloc] init];
    }
    return self;
}

- (void)dealloc
{
	// Sharekit instances
	[shareMail release];
	[shareTwitter release];
	[shareFacebook release];
	[sharePhotoAlbum release];
	
	// Screenshot data
	if (imageBuffer_) {
		free((void *)imageBuffer_);
		imageBuffer_ = nil;
	}
	if (renderedImage_) {
		[renderedImage_ release];
		renderedImage_	= nil;
	}
	
	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	[SHK setRootViewController:((GraviluxAppDelegate *)([UIApplication sharedApplication].delegate)).rotationController];
	
	if (![SHKMail canShare]) {
		emailButton.enabled = NO;
		emailButton.alpha = .5;
	}
	
	contentScaleFactor = 1.0;
	if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
		if ([[UIScreen mainScreen] scale] > 1)
			// code below doesn't work on iPad 3.2 OS, but doesn't need to because scale is 1.0
			contentScaleFactor = [[UIScreen mainScreen] scale];
	}
}

- (void)viewDidUnload
{
	[facebookButton release];
	facebookButton = nil;
	[twitterButton release];
	twitterButton = nil;
	[emailButton release];
	emailButton = nil;
	[photosButton release];
	photosButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark Screenshot
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

- (UIImage *)screenshotImage {
	CGRect rect = [[UIScreen mainScreen] bounds];
	int backingWidth = rect.size.width;
	int backingHeight =  rect.size.height;
	
	// scale for high-resolution screens
//	backingWidth *= contentScaleFactor;
//	backingHeight *= contentScaleFactor;
	
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

- (UIImage*)watermarkImage:(UIImage *)image
{
#ifndef WATERMARK_SCREENSHOT
	return image
#endif
	
	UIImage *logo = [UIImage imageNamed:WATERMARK_IMAGE];
	
	UIGraphicsBeginImageContext( image.size );
	
	[image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
	[logo drawInRect:CGRectMake(WATERMARK_OFFSET_X, image.size.height - logo.size.height - WATERMARK_OFFSET_Y,logo.size.width,logo.size.height) blendMode:kCGBlendModePlusLighter alpha:WATERMARK_ALPHA];
	
	UIImage *composite = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return composite;
}

#pragma mark - SHKSharerDelegate Methods
- (void)sharerStartedSending:(SHKSharer *)sharer
{
	//	[FlurryAnalytics logEvent:@"Share" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[sharer sharerTitle], @"Service", @"Started", @"Status", nil] timed:YES];
#ifdef DEBUG
	NSLog(@"Sharer %@ started", [sharer sharerTitle]);
#endif
}

- (void)sharerFinishedSending:(SHKSharer *)sharer
{
//	[FlurryAnalytics endTimedEvent:@"Share" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[sharer sharerTitle], @"Service", @"Finished", @"Status", nil]];
#ifdef DEBUG
	NSLog(@"Sharer %@ finished", [sharer sharerTitle]);
#endif
}

- (void)sharer:(SHKSharer *)sharer failedWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin
{
//	[FlurryAnalytics endTimedEvent:@"Share" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[sharer sharerTitle], @"Service", @"Failed", @"Status", [error description], @"Error", [NSNumber numberWithBool:shouldRelogin], @"Should Relogin", nil]];
#ifdef DEBUG
	NSLog(@"Sharer %@ failed", [sharer sharerTitle]);
#endif
}

- (void)sharerCancelledSending:(SHKSharer *)sharer
{
//	[FlurryAnalytics endTimedEvent:@"Share" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[sharer sharerTitle], @"Service", @"Canceled", @"Status", nil]];
#ifdef DEBUG
	NSLog(@"Sharer %@ canceled", [sharer sharerTitle]);
#endif
}

#pragma mark UI Actions

- (IBAction)share:(id)sender
{
	UIImage *screenImage = [self watermarkImage:[self screenshotImage]];
	
	SHKItem *item = [SHKItem image:screenImage
							 title:[NSString 
									stringWithFormat:@"I created this with Gravilux on my %@",
									[[UIDevice currentDevice] model]]];
	item.text = [NSString stringWithFormat:kEmailBody, [[UIDevice currentDevice] model]];
	
	SHKSharer * sharer = nil;
	
	if ([emailButton isEqual:sender]) {
		if ([SHKMail canShareImage]) {
//			[FlurryAnalytics logEvent:@"Share" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[SHKMail sharerTitle], @"Service", nil] timed:YES];
			sharer = [SHKMail shareItem:item];
		}
		else {
			NSLog(@"Cannot share images with email");
		}
	} else if ([photosButton isEqual:sender]) {
//		[FlurryAnalytics logEvent:@"Share" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[SHKPhotoAlbum sharerTitle], @"Service", nil] timed:NO];
		sharer = [SHKPhotoAlbum shareItem:item];
	} else if ([facebookButton isEqual:sender]) {
		if ([SHKFacebook canShareImage]) {
//			[FlurryAnalytics logEvent:@"Share" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[SHKFacebook sharerTitle], @"Service", nil] timed:YES];
			sharer = [SHKFacebook shareItem:item];
		}
		else {
			NSLog(@"Cannot share images to Facebook");
		}
	} else if ([twitterButton isEqual:sender]) {
//		[FlurryAnalytics logEvent:@"Share" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[SHKTwitter sharerTitle], @"Service", nil] timed:YES];
		sharer = [SHKTwitter shareItem:item];
	}
	
	if (sharer) {
		sharer.shareDelegate = self;
		[sharer share];
//		[sharer release];
	}
//	[screenImage release];
}

@end
