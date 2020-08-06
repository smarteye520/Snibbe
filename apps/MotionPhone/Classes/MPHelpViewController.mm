//
//  MPHelpViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPHelpViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIOrientView.h"
#import "defs.h"

NSString * strHelpFile = @"help";


@implementation MPHelpViewController

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
    
    /*
    // create the html view beneath the orienting view    
    UIWebView *webView = [[UIWebView alloc] initWithFrame: CGRectMake(0, 0, orientView_.frame.size.width, orientView_.frame.size.height )];    
    
    [orientView_ addSubview:webView];    
    
    NSString *fullPath = [[NSBundle mainBundle] pathForResource:strHelpFile ofType:@"html"];
    NSString * strHTML = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];        
    [webView loadHTMLString:strHTML baseURL: nil];        
     
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    [webView release];
    
     */
     
    
#if MOTION_PHONE_MOBILE    
    
    
    float shortDim = MIN( orientView_.frame.size.width, orientView_.frame.size.height );
    float longDim = MAX( orientView_.frame.size.width, orientView_.frame.size.height );
    
    scrollView_.contentSize = CGSizeMake(shortDim, longDim);
    
    orientView_.adjustBoundsOnOrient_ = true;
    orientView_.orientCenter_ = orientView_.center;
        
    orientView_.orientBoundsPortrait_ = CGRectMake(0, 0, shortDim, longDim);
    orientView_.orientBoundsLandscape_ = CGRectMake(0, 0, longDim, shortDim);
    
    scrollView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
#endif
    
    
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

// we want this whole view to suck up touches so they aren't passed down to the 
// eagl view

//
//
- (void) onBGColorChanged
{ 
    [self updateViewBackground: viewMainBG_];
}

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
