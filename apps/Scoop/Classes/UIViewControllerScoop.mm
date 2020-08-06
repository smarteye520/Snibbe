//
//  UIViewControllerScoop.m
//  Scoop
//
//  Created by Graham McDermott on 3/28/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import "UIViewControllerScoop.h"
#import "CCDirector.h"
#import "ScoopUtils.h"

@implementation UIViewControllerScoop

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
-(void) setRetinaEnabled: (bool) b
{
    retinaEnabled_ = b;
}

- (void)dealloc
{
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

    return YES;
    
    //return !getIsPaused();
}


//// here we can force the call to willRotateToInterfaceOrientation for instances
//// when we've been masking out interface orientation messages (such as when
//// we're 
//-(void) forceRotateToInterfaceOrientation: (NSNotification *) notification
//{
//    
//    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
//    
//    UIInterfaceOrientation interfaceOrientation = self.interfaceOrientation;
//    
//    if ( orientation == UIDeviceOrientationPortrait )
//    {
//        interfaceOrientation = UIInterfaceOrientationPortrait;
//    }
//    else if ( orientation == UIDeviceOrientationPortraitUpsideDown )
//    {
//        interfaceOrientation = UIInterfaceOrientationPortraitUpsideDown;
//    } 
//    else if ( orientation == UIDeviceOrientationLandscapeLeft )
//    {
//        interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
//    }
//    else if ( orientation == UIDeviceOrientationLandscapeRight )
//    {
//        interfaceOrientation = UIInterfaceOrientationLandscapeRight;
//    }
//    
//    [self willRotateToInterfaceOrientation: interfaceOrientation duration: 0.5f];
//    
//}

//
// The EAGLView MUST be resized manually
//
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{        
    
	CGRect rect;
    bool toLandscape = false;
	if(toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
		if ( gbIsIPad )
			rect = CGRectMake(0, 0, 768, 1024);
		else
        {
            if ( retinaEnabled_ )
            {
                rect = CGRectMake(0, 0, 640, 960 );
            }
            else
            {                            
                rect = CGRectMake(0, 0, 320, 480 );
            }
        }
        
	} else if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
		if ( gbIsIPad )
			rect = CGRectMake(0, 0, 1024, 768);
		else
        {
            
            if ( retinaEnabled_ )
            {
                rect = CGRectMake(0, 0, 960, 640 );
            }
            else
            {                            
                rect = CGRectMake(0, 0, 480, 320 );
            }
            
        }
        toLandscape = true;
	}


    // we're going to put this data into a dictionary and post it so that the main scene
    // can respond to it
    
    NSMutableDictionary * dictRotateVals = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSValue valueWithCGRect: rect], @"rect", [NSNumber numberWithDouble: duration], @"time", [NSNumber numberWithBool:toLandscape], @"tolandscape", nil];    
    [[NSNotificationCenter defaultCenter] postNotificationName: @"ScoopWillRotate" object: dictRotateVals];
    
    
}



@end
