//
//  MPEssayViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPEssayViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "defs.h"
#import "UIOrientView.h"

NSString * strEssayFile = @"essay";
NSString * strEssayFilePhone = @"essay_phone";

// private interface
@interface MPEssayViewController()

- (void) onOrientChanged:(UIDeviceOrientation) orient;

@end

@implementation MPEssayViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

//
//
- (void) dealloc
{
    if ( orientView_ )
    {
        [orientView_ setOrientDelegate: nil];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];    
    [super dealloc];    
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
    if ( IS_IPAD )
    {
        viewMainBG_.layer.cornerRadius = UI_CORNER_RADIUS;
    }
    
    // create the html view beneath the orienting view    
    
    CGRect webFrame = orientView_.frame;
    
#ifndef MOTION_PHONE_MOBILE
    // shrink it a bit only on ipad version
    float shrinkPixels = orientView_.frame.size.width * .025f;    
    webFrame = CGRectMake(shrinkPixels, shrinkPixels, orientView_.frame.size.width - shrinkPixels * 2, orientView_.frame.size.height - shrinkPixels * 2 );
#endif
    
    webView_ = [[UIWebView alloc] initWithFrame: webFrame];    
    webView_.delegate = self;
    [orientView_ setOrientDelegate: self];
    
    [orientView_ addSubview:webView_];    
    
    
#ifdef MOTION_PHONE_MOBILE
    
    [orientView_ forceUpdate: 0.0f];
    
    webView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
#endif
    
    
    NSString *fileName = (IS_IPAD ? strEssayFile : strEssayFilePhone);
    NSString *fullPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"html"];
    
    NSString *pathDir = [fullPath stringByDeletingLastPathComponent];
    NSURL *urlFileLocation = [NSURL fileURLWithPath: pathDir];
    
    NSString * strHTML = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];        
    [webView_ loadHTMLString:strHTML baseURL: urlFileLocation];        
    
    webView_.backgroundColor = [UIColor clearColor];
    webView_.opaque = NO;
    [webView_ release];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBGColorChanged) name:gNotificationBGColorChanged object:nil];                
    [self updateViewBackground: viewMainBG_];
    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return NO;
}

#pragma mark UIWebViewDelegate methods

//
//
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType 
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSURL *url = [request URL];
        if (![[url scheme] hasPrefix:@"file"]) {
            [[UIApplication sharedApplication] openURL:url];
            
            return NO;
        }
    }
    
    return YES;
}

//
//
- (void) onBGColorChanged
{ 
    [self updateViewBackground: viewMainBG_];
}


#pragma mark private implementation

#pragma UIOrientViewDelegate methods

//
//
- (void) onOrientChanged:(UIDeviceOrientation) orient
{
  
#ifdef MOTION_PHONE_MOBILE
    
    // we change the bounds of the web view here based on orientation since it doesn't work well to do this
    // using the bounds of the orienting view and a resize mask.  applying a transform to a view while also 
    // adjusting center/bounds seems to cause unexpected results with subviews.
    
    float shortDim = MIN( webView_.frame.size.width, webView_.frame.size.height );
    float longDim = MAX( webView_.frame.size.width, webView_.frame.size.height );
    
    if ( UIDeviceOrientationIsLandscape( orient ) )        
    {     
        webView_.bounds = CGRectMake(0, 0, longDim, shortDim);
    }
    else
    {
        webView_.bounds = CGRectMake(0, 0, shortDim, longDim);
    }
    
    
    
        
#endif
    
}


// we want this whole view to suck up touches so they aren't passed down to the 
// eagl view

//
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}

//
//
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
}

//
//
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
}

//
//
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
{
}


@end
