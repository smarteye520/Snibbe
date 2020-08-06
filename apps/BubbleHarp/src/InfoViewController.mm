//
//  SettingsViewController.mm
//  Bubble Harp
//
//  Created by Scott Snibbe on 2/24/10.
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#include "defs.h"
#include "Parameters.h"
#import "InfoViewController.h"
#import <QuartzCore/QuartzCore.h>

#undef BOOL

@implementation InfoViewController

@synthesize infoWebView;

#pragma mark-

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	[super viewDidLoad];
	
	// load up the info text
	NSString *infoSouceFile = [[NSBundle mainBundle] pathForResource:@"info" ofType:@"html"];
	//NSLog(@"%@", infoSouceFile);
	NSString *infoText = [NSString stringWithContentsOfFile:infoSouceFile encoding:NSUTF8StringEncoding error:nil];
	//NSLog(@"%@", infoText);
	// allows html to reference images embedded in app
	NSString *path = [[NSBundle mainBundle] bundlePath];
	//NSLog(@"%@", path);
	NSURL *baseURL = [NSURL fileURLWithPath:path];
	
	[self.infoWebView loadHTMLString:infoText baseURL:baseURL];
	
	// change infoWebView delegate to self so that we can override URL clicks
	[self.infoWebView setDelegate:self];
	
	
	gBubbleHarp->resetIdleTimer(NO);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		
	} else 
	{
		// make web font smaller on iPhone
		[self.infoWebView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '85%'"];
	}
}


// Make links open in Safari

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType; {
	
    NSURL *requestURL = [ request URL ];
    // Check to see what protocol/scheme the requested URL is.
    if ( ( [ [ requestURL scheme ] isEqualToString: @"http" ]
		  || [ [ requestURL scheme ] isEqualToString: @"https" ] )
    	&& ( navigationType == UIWebViewNavigationTypeLinkClicked )
		&& !Parameters::params().galleryMode() ) {
        return ![ [ UIApplication sharedApplication ] openURL: requestURL ];
   	}
    // Auto release
    // If request url is something other than http or https it will open
    // in UIWebView. You could also check for the other following
    // protocols: tel, mailto and sms
    return YES;
}

// eat touches to prevent them from being passed to window below
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (IBAction)dismissAction:(id)sender {
	// for iPhone only
	[self dismissModalViewControllerAnimated:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RotateViewToCurrent" object:nil];
}

@end

