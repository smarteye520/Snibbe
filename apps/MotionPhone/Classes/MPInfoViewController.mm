//
//  MPInfoViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/22/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPInfoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MPUIOrientButton.h"
#import "defs.h"

// private interface
@interface MPInfoViewController()

- (void) onHelpShown;
- (void) onHelpHidden;
- (void) onEssayShown;
- (void) onEssayHidden;

@end


@implementation MPInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

//
//
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [super dealloc];
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
    
    [buttonHelp_ setImageNamesOn: @"help_on.png" off:@"help_off.png" ];
    [buttonEssay_ setImageNamesOn: @"essay_on.png" off:@"essay_off.png" ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onHelpShown) name:gNotificationHelpViewOn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onHelpHidden) name:gNotificationHelpViewOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEssayShown) name:gNotificationEssayViewOn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEssayHidden) name:gNotificationEssayViewOff object:nil];
 
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
	return YES;
}

#pragma mark public implementation

//
//
- (IBAction) onButtonHelp: (id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestHelpViewOnOff object:nil];
}

//
//
- (IBAction) onButtonEssay: (id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationRequestEssayViewOnOff object:nil];
}

#pragma mark private implementation

//
//
- (void) onHelpShown
{
    [buttonHelp_ setOn: true];
}

//
//
- (void) onHelpHidden
{
    [buttonHelp_ setOn: false];    
}

//
//
- (void) onEssayShown
{
    [buttonEssay_ setOn: true];
}

//
//
- (void) onEssayHidden
{
    [buttonEssay_ setOn: false];    
}

//
//
- (void) onBGColorChanged
{ 
    [self updateViewBackground: viewMainBG_];
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
