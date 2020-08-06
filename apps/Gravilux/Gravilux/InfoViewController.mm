//
//  InfoViewController.m
//  Gravilux
//
//  Created by Colin Roache on 10/25/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "InfoViewController.h"
#import "GraviluxViewController.h"
#import "Parameters.h"
//#import "FlurryAnalytics.h"

@interface InfoViewController (Private)
- (void) syncControls;
@end
@implementation InfoViewController
@synthesize infoWebView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncControls) name:@"updateUI" object:nil];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self syncControls];
	
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
	
	for (UIView* subview in self.infoWebView.subviews) {
		if ([subview isKindOfClass:[UIScrollView class]]) {
			((UIScrollView*)subview).backgroundColor = [UIColor clearColor];
			((UIScrollView*)subview).clearsContextBeforeDrawing = YES;
			((UIScrollView*)subview).opaque = NO;
			
			break;
		}
	}
	self.infoWebView.clearsContextBeforeDrawing = YES;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
	[super dealloc];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.infoWebView layoutSubviews];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsPortrait(interfaceOrientation);
	if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		return interfaceOrientation == UIInterfaceOrientationPortrait;
	}
	
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		
	} else 
#endif
	{
		// make web font smaller on iPhone
//		[self.infoWebView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '85%'"];
	}
}

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType; {
	
    NSURL *requestURL = [ [ request URL ] retain ];
    // Check to see what protocol/scheme the requested URL is.
    if ( ( [ [ requestURL scheme ] isEqualToString: @"http" ]
		  || [ [ requestURL scheme ] isEqualToString: @"https" ] )
    	&& ( navigationType == UIWebViewNavigationTypeLinkClicked )) {
        return ![ [ UIApplication sharedApplication ] openURL: [ requestURL autorelease ] ];
   	}
    // Auto release
    [ requestURL release ];
    // If request url is something other than http or https it will open
    // in UIWebView. You could also check for the other following
    // protocols: tel, mailto and sms
    return YES;
}

#pragma mark - IB Actions

- (IBAction)dismiss:(id)sender
{
//	[FlurryAnalytics endTimedEvent:@"Help" withParameters:nil];
	[UIView animateWithDuration:.3f animations:^{
		self.view.alpha = 0;
	} completion:^(BOOL finished) {
		if (finished) {
			[self.view removeFromSuperview];
		}
	}];
}

- (IBAction)learnMore:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"presentProUpgrade" object:self];
}

#pragma mark - Private Methods

- (void)syncControls
{
	// Remove ad if the user has already upgraded
	/*if (upgradeButton && [upgradeButton isDescendantOfView:self.view]) {
		if (gGravilux->params()->pro()) {
			CGRect webFrame = infoWebView.frame;
			infoWebView.frame = CGRectMake(webFrame.origin.x, webFrame.origin.y, webFrame.size.width, webFrame.size.height + upgradeButton.frame.size.height);
			[upgradeButton removeFromSuperview];
		} else {
			UIImage* barImage = [UIImage imageNamed:@"ad_bar_ipad.png"];
			if ([barImage respondsToSelector:@selector(resizableImageWithCapInsets)]) {
				barImage = [barImage resizableImageWithCapInsets:UIEdgeInsetsMake(1., 355., 0., 130.)];
			} else {
				barImage = [barImage stretchableImageWithLeftCapWidth:355 topCapHeight:0];
			}
			[upgradeButton setBackgroundImage:barImage forState:UIControlStateNormal];
		}
	}*/
}
@end
