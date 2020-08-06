    //
//  SaveViewController.mm
//  bubbleharp
//
//  Created by Scott Snibbe on 9/11/10.
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#import "SaveViewController.h"
#include "BubbleHarp.h"
#include "Parameters.h"

#define kAnimationDuration 0.5f
#define kKbdOffset 20
#define kDefaultTitle @"Untitled"

@implementation SaveViewController

@synthesize scrollView, thumbnailView, titleField;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	titleField.delegate = self;
	kbdVisible_ = false;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasShown:)
												 name:UIKeyboardWillShowNotification object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasHidden:)
												 name:UIKeyboardWillHideNotification object:nil];
	
//	CGSize screenSize = [[UIScreen mainScreen] bounds].size;
	
	/*
	// load in thumbnail - photo
	UIImage *thumbImage = gBubbleHarp->thumbnailImage(CGSizeMake(screenSize.width/2, screenSize.height/2));
	if (thumbImage) {
		[thumbnailView setImage:thumbImage];
	}
	*/
	
	// reset title
	[titleField setText:kDefaultTitle];
	
    /*
	// PDF thumbnail
	if (gBubbleHarp->drawToPDF(PDF_FILENAME, 
							   gParams->pdfDotSize(), gParams->pdfLineWidth(), 
							   gParams->pdfPointWidth(), gParams->pdfPointHeight())) {
		
		// load in PDF data from saved file
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *saveDirectory = [paths objectAtIndex:0];
		NSString *pdfFilePath = [saveDirectory stringByAppendingPathComponent:PDF_FILENAME];
		
		NSURL *pdfUrl = [NSURL fileURLWithPath:pdfFilePath];
		
		//[thumbnailWebView loadRequest:[NSURLRequest requestWithURL:pdfUrl]];
		thumbnailView.pdfURL = pdfUrl;
		[thumbnailView setNeedsDisplay];
          
	}
     */
    
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	
	//UIImage *screenImage = thumbnailView.image;
	//[thumbnailWebView setImage:nil];
	
	// free thumbnail image
	//if (screenImage) [screenImage release];
	//gBubbleHarp->freeScreenshotData();
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
	if (kbdVisible_) return;
	//NSLog(@"keyboardWasShown");
	NSDictionary* info = [aNotification userInfo];
	
	// Get the size of the keyboard.
	//NSValue* aValue = [info objectForKey:UIKeyboardFrameBeginUserInfoKey]; // for 3.2 and up
	NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
	CGSize keyboardSize = [aValue CGRectValue].size;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:kAnimationDuration];
	
	CGRect titleRect = [scrollView convertRect:titleField.frame toView:nil];
	CGPoint textBottom = CGPointMake(0, titleRect.origin.y + titleRect.size.height);	// bottom of text field
	
	float screenHeight;
	
	BOOL isPortrait = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
	
	if (isPortrait) {
		screenHeight = [[UIScreen mainScreen] bounds].size.height;
	} else {
		screenHeight = [[UIScreen mainScreen] bounds].size.width;
	}
	
	float targetY = screenHeight - (keyboardSize.height + kKbdOffset);
	deltaKbdOffset_ = targetY - textBottom.y;
	
	//Transform view up to show keyboard
	CGAffineTransform myTransform = CGAffineTransformMakeTranslation(0.0, deltaKbdOffset_);
	[scrollView setTransform:myTransform];
	
	// do it
	[UIView commitAnimations];	
	
	kbdVisible_ = true;
}

- (void)keyboardWasHidden:(NSNotification*)aNotification
{
	if (!kbdVisible_) return;
	
	//NSLog(@"keyboardWasHidden");
	kbdVisible_ = false;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:kAnimationDuration];
	
	//Transform view up to show keyboard
	CGAffineTransform myTransform = CGAffineTransformMakeTranslation(0,0);
	[scrollView setTransform:myTransform];
	
	// do it
	[UIView commitAnimations];	
}

// when RETURN is pressed on keyboard
- (IBAction)didEndOnExitAction:(UITextField*)sender
{
	if (sender == titleField) {		
		[self saveAction:sender];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (IS_IPAD || interfaceOrientation == UIInterfaceOrientationPortrait)
		return YES;
	else 
		return NO;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}



- (IBAction)saveAction:(id)sender
{
	// put up alert?
	
	NSString *filePrefix = titleField.text;
	// check for null string in filename
	if (filePrefix.length == 0) {
		filePrefix = kDefaultTitle;
	}
	
	gBubbleHarp->saveToFile(filePrefix, thumbnailView.pdfURL);
	
	// take down alert?
	
	[self dismissModalViewControllerAnimated:YES];
	if (kbdVisible_) [self keyboardWasHidden:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ResetTimer" object:nil]; // turn on auto-hide timer for UI
}

- (IBAction)cancelAction:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
	if (kbdVisible_) [self keyboardWasHidden:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ResetTimer" object:nil]; // turn on auto-hide timer for UI
}

@end
