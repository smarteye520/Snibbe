
//  MPPhoneUIViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 1/31/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#import "MPPhoneUIViewController.h"
#import "defs.h"
#import "Parameters.h"
#import "MPPhoneToolbarViewController.h"
#import "MPColorViewController.h"
#import "SnibbeNavController.h"
#import "MPBrushViewController.h"
#import "MPMediaController.h"
#import "MPEssayViewController.h"
#import "MPHelpViewController.h"
#import "MPSaveShareViewController.h"
#import "MPLoadViewController.h"
#import "MPUIOrientButton.h"

// private interface
@interface MPPhoneUIViewController()

- (void) showUI: (bool) bShow;
- (void) updateShowToolbarButton;
- (bool) toolbarShown;

// notification observers
- (void) onColorViewOnOff;
- (void) onBrushViewOnOff;
- (void) onSaveShareViewOnOff;
- (void) onMediaViewOnOff;
- (void) onLoadViewOnOff;
- (void) onHelpViewOnOff;
- (void) onEssayViewOnOff;

- (void) onDismissUIDeep;



@end




@implementation MPPhoneUIViewController

@synthesize parentVC_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.parentVC_ = nil;
    }
    return self;
}

//
//
- (void) dealloc
{
    [snibbeNavController release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
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

//
//
- (void) postLoad
{
    snibbeNavController = [[SnibbeNavController alloc] init];
    snibbeNavController.parentVC_ = self;  //self.parentVC_;
    snibbeNavController.animStyle_ = eSnibbeAnimSlide;
    snibbeNavController.pushDir_ = eSNCRight;
    
    toolbarController_ = [[MPPhoneToolbarViewController alloc] initWithNibName: @"MPPhoneToolbarViewController" bundle:nil];
    toolbarController_.bActive_ = false; 
    [self.view addSubview: toolbarController_.view];
    [snibbeNavController pushVC: toolbarController_];   
    
    // set up the intial toolbar visibility    
    [self showUI: gParams->toolbarShown()];
    [self updateShowToolbarButton];
    

}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    
    // notification observers        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onColorViewOnOff) name:gNotificationRequestColorViewOnOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrushViewOnOff) name:gNotificationRequestBrushViewOnOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onHelpViewOnOff) name:gNotificationRequestHelpViewOnOff object:nil];                
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEssayViewOnOff) name:gNotificationRequestEssayViewOnOff object:nil];                
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSaveShareViewOnOff) name:gNotificationRequestSaveShareViewOnOff object:nil];                
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLoadViewOnOff) name:gNotificationRequestLoadViewOnOff object:nil];                
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaViewOnOff) name:gNotificationRequestMediaViewOnOff object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDismissUIDeep) name:gNotificationDismissUIDeep object:nil];
    
    
    // do we want this? probably
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCanvasTouchDown) name:gNotificationCanvasTouchDown object:nil];                        
    
 
    
    [super viewDidLoad];
    
    // give chance to set up hierarchy first
    [self performSelector:@selector(postLoad) withObject:nil afterDelay:.01];
    
    
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//
//
- (void) update
{
    
}

//
// show/hide toolbar button pressed (snibbe logo)
- (IBAction) showToolbarButtonPressed
{
    
    [self ensureBrushMode];
    
    bool bShouldShow = ![self toolbarShown];    
    [self showUI: bShouldShow];        
    gParams->setToolbarShown( bShouldShow );
    
    [self updateShowToolbarButton];
}


#pragma mark private implementation

- (void) showUI: (bool) bShow
{
    

    // doing this on view load now
    
//    if ( !toolbarController_ && bShow )
//    {
//        toolbarController_ = [[MPPhoneToolbarViewController alloc] initWithNibName: @"MPPhoneToolbarViewController" bundle:nil];
//        toolbarController_.bActive_ = false; 
//        [self.view addSubview: toolbarController_.view];
//        [snibbeNavController pushVC: toolbarController_];
//    }            
    
    
    if ( bShow )
    {
        CGRect frame = self.view.frame;    
        toolbarController_.view.frame = frame;
            
        // send the toolbar behind the snibbe logo
        [self.view sendSubviewToBack: toolbarController_.view];
    }
    
    
    if ( toolbarController_ )
    {
        [toolbarController_ setActive: bShow];                                
        [toolbarController_ show: toolbarController_.bActive_ withAnimation:true time:TOOLBAR_ANIMATION_TIME_PHONE fullOpacity:TOOLBAR_FULL_OPACITY forceUpdate:false];                                     
        
        //NSLog( @"on: %@, off: %@\n", vc.notifyOn_, vc.notifyOff_ );
        
        if ( toolbarController_.bActive_ )
        {                        
            // turning view on!                                  
            
        }
        else 
        {                   
            
        }
        
                
    }
    
    
}

//
//
- (void) updateShowToolbarButton
{
    if ( buttonShowToolbar_ )
    {   
        //bool bIsShown = [self toolbarShown];                        
        //[buttonShowToolbar_ setOn: bIsShown];
        
        
        
         
         bool bIsShown = [self toolbarShown];                        
         
         // this is sort of hard to follow since we're doubling up on this button
         // to give the illusion of one button
         
         [buttonShowToolbar_ setOn: false];
         
         [UIView beginAnimations: @"buttonhide" context:nil];
         [UIView setAnimationDuration: bIsShown ? TOOLBAR_ANIMATION_TIME_PHONE : 0.0f];
         buttonShowToolbar_.alpha = bIsShown ? 0.0f : 1.0f;        
         [UIView commitAnimations];
         
         
        
        
        
    }
    
}

//
//
- (bool) toolbarShown
{    
    
    if ( toolbarController_ )
    {
        return toolbarController_.bActive_;
    }
    
    
    return false;
}


//
// helper for factoring out commong code for creating phone sub-views
- (void) viewOnCommon: (NSString *) className notifyOn: (NSString *) notOn notifyOff: (NSString *) notOff
{
    // create the controller, push it on the navigation stack
    
    id theClass = NSClassFromString(className);
    MPUIViewControllerHiding * pController = [[theClass alloc] initWithNibName:className bundle:nil];
    
    [self.parentVC_.view addSubview: pController.view];
    [pController show:true withAnimation:false time:0.0f fullOpacity:1.0f forceUpdate:false];    
    
    [toolbarController_ hideSubControls: 0.0f];
    
    pController.notifyOn_ = notOn;
    pController.notifyOff_ = notOff;
    
    [snibbeNavController pushVC: pController];
    
    [pController release];
}


//
//
- (void) onColorViewOnOff
{
    // create the color controller, push it on the navigation stack
    
    MPColorViewController * pColorController = [[MPColorViewController alloc] initWithNibName:@"MPColorViewController" bundle:nil];
    pColorController.colorPickerXIBOverride_ = @"SnibbePhoneColorPickerController";
    [self.parentVC_.view addSubview: pColorController.view];
    [pColorController show:true withAnimation:false time:0.0f fullOpacity:1.0f forceUpdate:false];    

    [toolbarController_ hideSubControls: 0.0f];
    
    pColorController.notifyOn_ = gNotificationColorViewOn;
    pColorController.notifyOff_ = gNotificationColorViewOff;
    
    [snibbeNavController pushVC: pColorController];

    
    [pColorController release];
}

//
//
- (void) onBrushViewOnOff
{
    // create the brush controller and push it on the navigation stack
    
    [self viewOnCommon: @"MPBrushViewController" notifyOn:gNotificationBrushViewOn notifyOff:gNotificationBrushViewOff];
}

//
//
- (void) onSaveShareViewOnOff
{
    // create the save/share controller, push it on the navigation stack
    
    [self viewOnCommon: @"MPSaveShareViewController" notifyOn:gNotificationSaveShareViewOn notifyOff:gNotificationSaveShareViewOff];
}

//
//
- (void) onMediaViewOnOff
{
    // create the media controller, push it on the navigation stack
    
    [self viewOnCommon: @"MPMediaController" notifyOn:gNotificationMediaViewOn notifyOff:gNotificationMediaViewOff];
}

//
//
- (void) onLoadViewOnOff
{
    [self viewOnCommon:@"MPLoadViewController" notifyOn:gNotificationLoadViewOn notifyOff:gNotificationLoadViewOff];
}

//
//
- (void) onHelpViewOnOff
{
    // create the help controller, push it on the navigation stack
    
    [self viewOnCommon: @"MPHelpViewController" notifyOn:gNotificationHelpViewOn notifyOff:gNotificationHelpViewOff];
}

//
//
- (void) onEssayViewOnOff
{
    [self viewOnCommon: @"MPEssayViewController" notifyOn:gNotificationEssayViewOn notifyOff:gNotificationEssayViewOff];
    
}


//
//
- (void) postDismissDeep
{
    [snibbeNavController clearToIndex: 1]; // pop off everything but the first controller
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationDismissUIDeepComplete object:nil];
}

//
//
- (void) onDismissUIDeep
{
    
    // start fading out all pushed views
    int iNumPushed = [snibbeNavController numVCs];
    for ( int i = 1; i < iNumPushed; ++i )
    {
    
        MPUIViewControllerHiding * curVc = (MPUIViewControllerHiding *) [snibbeNavController vcAtIndex: i];
        if ( curVc )
        {
            if ( curVc.notifyOff_ )
            {
                // we do this notification here instead of in the object itself b/c of differences
                // between the iPad and iPhone structure for UI creation/destruction.
                
                [[NSNotificationCenter defaultCenter] postNotificationName:curVc.notifyOff_ object:nil];
            }
            
            [curVc show: false withAnimation:true time:TOOLBAR_ANIMATION_TIME_PHONE fullOpacity:TOOLBAR_FULL_OPACITY forceUpdate:false];                                                              
        }        

    }
    
    [self showToolbarButtonPressed];
    [self performSelector: @selector(postDismissDeep) withObject:nil afterDelay:TOOLBAR_ANIMATION_TIME_PHONE];
}


#pragma mark  SnibbeNavControllerDelegate methods

//
//
- (void) setSnibbeNavController:(SnibbeNavController *)snc
{
    // nothing here since we create the nav controller in this object
}

@end
