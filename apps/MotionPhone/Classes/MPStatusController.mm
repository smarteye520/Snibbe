//
//  MPStatusController.m
//  MotionPhone
//
//  Created by Graham McDermott on 12/1/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPStatusController.h"
#import <QuartzCore/QuartzCore.h>
#import "defs.h"
#import "MPUIKitViewController.h"


// private interface
@interface MPStatusController()


@end


@implementation MPStatusController

@synthesize orientingParentDelegate_;
@synthesize statusDelegate_;



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
    
        orientingParentDelegate_ = nil;
        statusDelegate_ = nil;
        
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

- (void) dealloc
{

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    viewMainBG_.layer.cornerRadius = UI_CORNER_RADIUS;
    
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
}

//
//
- (void) setProgress: (float) progress
{
    progressView_.progress = progress;
}

//
//
- (void) showProgressBar: (bool) bShow
{
    progressView_.hidden = !bShow;
}

//
//
- (void) setLabelText: (NSString *) text
{
    labelStatus_.text = text;
}

//
//
- (void) showCancelButton: (bool) bShow
{
    buttonCancel_.hidden = !bShow;
}

//
//
- (void) fadeViewIn
{
    self.view.alpha = 0.0f;
    
    [UIView beginAnimations: @"status_fade_in" context:nil];
    [UIView setAnimationDuration: STATUS_MESSAGE_FADE_DURATION ];
    self.view.alpha = 1.0f;
    [UIView commitAnimations];
}

//
//
- (void) fadeViewOut
{

    
    [UIView beginAnimations: @"status_fade_in" context:nil];
    [UIView setAnimationDuration: STATUS_MESSAGE_FADE_DURATION];
    self.view.alpha = 0.0f;
    [UIView commitAnimations];
}

//
//
- (void) showLabelOnly
{

    [self showProgressBar: false];
    [self showCancelButton: false];

    viewMainBG_.frame = CGRectMake(viewMainBG_.frame.origin.x, viewMainBG_.frame.origin.y, viewMainBG_.frame.size.width, 135.0f );
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, 135.0f );
    

}


//
//
- (IBAction) onButtonCancel: (id)sender
{
    if ( statusDelegate_ )
    {
        if ( [statusDelegate_ respondsToSelector: @selector( onStatusCancel )] )
        {
            [statusDelegate_ performSelector: @selector( onStatusCancel )];
        }
    }
}



#pragma mark private methods

@end
