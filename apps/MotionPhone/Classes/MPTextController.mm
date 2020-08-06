//
//  MPFBTextController.m
//  MotionPhone
//
//  Created by Graham McDermott on 12/7/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPTextController.h"
#import <QuartzCore/QuartzCore.h>
#import "defs.h"


@interface MPTextController()

- (void) closeWindow;

@end



@implementation MPTextController

@synthesize orientingParentDelegate_;
@synthesize strTitle_;
@synthesize strButtonPostText_;
@synthesize strButtonCancelText_;
@synthesize strTextViewInitialContents_;
@synthesize textDelegate_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        orientingParentDelegate_ = nil;
        textDelegate_ = nil;
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:strButtonPostText_       
                                                                    style:UIBarButtonItemStylePlain target:self action:@selector(onButtonPost:)];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:strButtonCancelText_       
                                                                    style:UIBarButtonItemStylePlain target:self action:@selector(onButtonCancel:)];    
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:strTitle_];


    item.rightBarButtonItem = rightButton;
    item.leftBarButtonItem = backButton;    
    item.hidesBackButton = YES;
    
    [navBar_ pushNavigationItem:item animated:NO];
    
    [rightButton release];
    [backButton release];
    [item release];
    
    
    textView_.text = strTextViewInitialContents_;    

    [textView_ becomeFirstResponder];
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
- (IBAction) onButtonPost: (id) sender
{
    
    if ( textDelegate_ && [textDelegate_ respondsToSelector: @selector(onPost:)] )
    {
        [textDelegate_ onPost: textView_.text];
    } 
    
    [self closeWindow];
    
}

//
//
- (IBAction) onButtonCancel: (id) sender
{
 
    if ( textDelegate_ && [textDelegate_ respondsToSelector: @selector(onButtonCancel)] )
    {        
        [textDelegate_ onCancel];
    } 
        
    [self closeWindow];
}


//
//
- (void) closeWindow
{
    
    if ( orientingParentDelegate_ )
    {
        // using the motionphone pseudo-modal view controller method
        [orientingParentDelegate_ onViewControllerRequestDismissal: self];
    }
    else
    {
        
        // presented modally?                
        
        if ( [self respondsToSelector:@selector(presentingViewController)] )
        {
            [[self presentingViewController] dismissModalViewControllerAnimated:true];
        }
        else
        {
            [[self parentViewController] dismissModalViewControllerAnimated:true];        
        }
        
    }
}

@end
