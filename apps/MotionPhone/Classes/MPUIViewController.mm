//
//  MPUIViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/9/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPUIViewController.h"
#import "MPToolbarViewController.h"
#import "defs.h"
#import "UIOrientButton.h"
#import "Parameters.h"
#import "MPFPSViewController.h"
#import "MPColorViewController.h"
#import "MPBrushViewController.h"
#import "MPRecordViewController.h"
#import "MPInfoViewController.h"
#import "MPEssayViewController.h"
#import "MPHelpViewController.h"
#import "MPSaveShareViewController.h"
#import "MPLoadViewController.h"
#import "MPMediaController.h"
#import "MPUIOrientButton.h"
#import "MPNetworkManager.h"



// private interface
@interface MPUIViewController()


- (void) showUI: (bool) bShow;

- (void) updateShowToolbarButton;

- (void) onViewOnOff: (MPUIVCInfo *) vcInfo time: (float) t;
- (void) onFPSViewOnOff: (float) time;
- (void) onGeneralViewOnOff: (float) time withVCInfo: (MPUIVCInfo *) vcInfo;
- (void) hideAllSubControlsExcept: (NSArray *) vcsNotToHide time: (float) t;
- (MPUIVCInfo *) vcInfoForVC: (MPUIViewControllerHiding **) ppVC;


// creation/destruction of sub-controls

- (void) destroyGeneral: (UIViewController **) vc;
- (void) createControllerGeneral: (NSString *) phoneNib iPadNib: (NSString *) padNib vc: (MPUIViewControllerHiding **) ppVC theClass: (id) classType posSelect: (SEL) posSelector notifyOn: (NSString *) notifyOn nofityOff: (NSString *) notifyOff;

- (void) createToolbarController;
- (void) destroyToolbarController;

- (void) createFPSController;
- (void) positionFPSController;
- (void) destroyFPSController;

- (void) createColorController;
- (void) positionColorController;
- (void) destroyColorController;

- (void) createBrushController;
- (void) positionBrushController;
- (void) destroyBrushController;

- (void) createRecordController;
- (void) positionRecordController;
- (void) destroyRecordController;

- (void) createInfoController;
- (void) positionInfoController;
- (void) destroyInfoController;

- (void) createEssayController;
- (void) positionEssayController;
- (void) destroyEssayController;

- (void) createHelpController;
- (void) positionHelpController;
- (void) destroyHelpController;

- (void) createSaveShareController;
- (void) positionSaveShareController;
- (void) destroySaveShareController;

- (void) createLoadController;
- (void) positionLoadController;
- (void) destroyLoadController;

- (void) createMediaController;
- (void) positionMediaController;
- (void) destroyMediaController;




// notification observers
- (void) onFPSViewOnOff;
- (void) onColorViewOnOff;
- (void) onBrushViewOnOff;
- (void) onRecordViewOnOff;
- (void) onInfoViewOnOff;
- (void) onHelpViewOnOff;
- (void) onEssayViewOnOff;
- (void) onSaveShareViewOnOff;
- (void) onLoadViewOnOff;
- (void) onMediaViewOnOff;

- (void) onCanvasTouchDown;
- (void) onToolModeChanged;

@end



@implementation MPUIViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        
    }
    return self;
}

//
//
- (void) dealloc
{
    
        
    for ( MPUIVCInfo * curInfo in arrayVCInfo_ )
    {
        [self performSelector: curInfo.selDestroy_];
    }
    
    [arrayVCInfo_ release];
    arrayVCInfo_ = nil;
        
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

- (void)viewDidLoad
{
    
    toolbarController_ = nil;
    fpsController_ = nil;
    brushController_ = nil;
    colorController_ = nil;
    recordController_ = nil;
    infoController_ = nil;
    helpController_ = nil;
    essayController_ = nil;
    saveShareController_ = nil;
    loadController_ = nil;
    mediaController_ = nil;
    
    // add here...
    
    
    MPUIVCInfo *infoToolbar = [[[MPUIVCInfo alloc] initWithCreate: @selector(createToolbarController) destroy: @selector(destroyToolbarController) vc: &toolbarController_ active: false ] autorelease];        
    MPUIVCInfo *infoFPS = [[[MPUIVCInfo alloc] initWithCreate: @selector(createFPSController) destroy: @selector(destroyFPSController) vc: &fpsController_ active: false ] autorelease];
    MPUIVCInfo *infoBrush = [[[MPUIVCInfo alloc] initWithCreate: @selector(createBrushController) destroy: @selector(destroyBrushController) vc: &brushController_ active: false ] autorelease];
    MPUIVCInfo *infoColor = [[[MPUIVCInfo alloc] initWithCreate: @selector(createColorController) destroy: @selector(destroyColorController) vc: &colorController_ active: false ] autorelease];
    MPUIVCInfo *infoRecord = [[[MPUIVCInfo alloc] initWithCreate: @selector(createRecordController) destroy: @selector(destroyRecordController) vc: &recordController_ active: false ] autorelease];
    MPUIVCInfo *infoInfo = [[[MPUIVCInfo alloc] initWithCreate: @selector(createInfoController) destroy: @selector(destroyInfoController) vc: &infoController_ active: false ] autorelease];
    MPUIVCInfo *infoHelp = [[[MPUIVCInfo alloc] initWithCreate: @selector(createHelpController) destroy: @selector(destroyHelpController) vc: &helpController_ active: false ] autorelease];
    MPUIVCInfo *infoEssay = [[[MPUIVCInfo alloc] initWithCreate: @selector(createEssayController) destroy: @selector(destroyEssayController) vc: &essayController_ active: false ] autorelease];
    MPUIVCInfo *infoSaveShare = [[[MPUIVCInfo alloc] initWithCreate: @selector(createSaveShareController) destroy: @selector(destroySaveShareController) vc: &saveShareController_ active: false ] autorelease];
    MPUIVCInfo *infoLoad = [[[MPUIVCInfo alloc] initWithCreate: @selector(createLoadController) destroy: @selector(destroyLoadController) vc: &loadController_ active: false ] autorelease];
    MPUIVCInfo *infoMedia = [[[MPUIVCInfo alloc] initWithCreate:@selector(createMediaController) destroy:@selector(destroyMediaController) vc:&mediaController_ active:false] autorelease];
    
    // set up the views that don't automatically get hidden when the targets are shown
    infoHelp.pVCPreventHideOnShow_ = infoInfo;
    infoEssay.pVCPreventHideOnShow_ = infoInfo;
    
    infoSaveShare.pVCPreventHideOnShow_ = infoRecord;
    infoLoad.pVCPreventHideOnShow_ = infoRecord;
    infoMedia.pVCPreventHideOnShow_ = infoRecord;
    
    
    arrayVCInfo_ = [[NSMutableArray alloc] initWithObjects: infoToolbar, infoFPS, infoBrush, infoColor, infoRecord, infoInfo, infoHelp, infoEssay, infoSaveShare, infoLoad, infoMedia, nil ];             
    
    
    // notification observers        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFPSViewOnOff) name:gNotificationRequestFPSViewOnOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onColorViewOnOff) name:gNotificationRequestColorViewOnOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrushViewOnOff) name:gNotificationRequestBrushViewOnOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecordViewOnOff) name:gNotificationRequestRecordViewOnOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onInfoViewOnOff) name:gNotificationRequestInfoViewOnOff object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCanvasTouchDown) name:gNotificationCanvasTouchDown object:nil];                        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onToolModeChanged) name:gNotificationToolModeChanged object:nil];                        
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onHelpViewOnOff) name:gNotificationRequestHelpViewOnOff object:nil];                
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEssayViewOnOff) name:gNotificationRequestEssayViewOnOff object:nil];                
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSaveShareViewOnOff) name:gNotificationRequestSaveShareViewOnOff object:nil];                
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLoadViewOnOff) name:gNotificationRequestLoadViewOnOff object:nil];                
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaViewOnOff) name:gNotificationRequestMediaViewOnOff object:nil];
    
       
    
    
    // set up the intial toolbar visibility
    [self showUI: gParams->toolbarShown()];
    
      

    
    
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
}

#pragma mark public implementation

//
//
- (int) numSubControlsShown
{

    int iNumShown = 0;
    
    for ( MPUIVCInfo * curInfo in arrayVCInfo_ )
    {
        MPUIViewControllerHiding * curVC = *curInfo.ppVC_;
        
        if ( curVC.bActive_ && curVC.bShown_ && curVC != toolbarController_ )
        {
            ++iNumShown;
        }

    }
    
    
    return iNumShown;
}



//
// show/hide toolbar button pressed (snibbe logo)
- (IBAction) showToolbarButtonPressed
{
    
    [self ensureBrushMode];
    
    MPUIVCInfo * toolbarInfo = [self vcInfoForVC: &toolbarController_];
    
    bool bShouldShow = !toolbarInfo.bActive_;
            
    [self showUI: bShouldShow];        
    gParams->setToolbarShown( bShouldShow );
    
    [self updateShowToolbarButton];
}

//
//
- (bool) anyUISubViewsActive
{
    return [self numSubControlsShown] > 0;
}


//
// per-frame update
- (void) update
{
    
 
    for ( MPUIVCInfo * curInfo in arrayVCInfo_ )
    {
        MPUIViewControllerHiding * curVC = *curInfo.ppVC_;
        
        if ( curVC )            
        {

            if ( curInfo.bHideCompleted_ )
            {            
                // this one should be removed
                if ( curInfo.selDestroy_ )
                {
                    //NSLog(@"destroying with sel: %@\n", NSStringFromSelector( curInfo.selDestroy_ ));                    
                    [self performSelector: curInfo.selDestroy_];            
                    break;
                }
                
            }
            }

        
        
    }
    
  
}

#pragma mark private implementation




//
// show or hide the active panes of the UI
- (void) showUI: (bool) bShow
{
    
    // update the state for the main toolbar info
    MPUIVCInfo * toolbarInfo = [self vcInfoForVC: &toolbarController_];
    toolbarInfo.bActive_ = bShow;
    
    
    if ( bShow )
    {
        // create all required view controllers that don't exist yet             
        for ( MPUIVCInfo * curInfo in arrayVCInfo_ )
        {
            if ( curInfo.bActive_ && curInfo.ppVC_ && !(*curInfo.ppVC_) )
            {
                [self performSelector: curInfo.selCreate_];  
                
                 //NSLog(@"creating with sel: %@\n", NSStringFromSelector( curInfo.selCreate_ ));
                
                [(*curInfo.ppVC_) toggleActive]; // make it active
            }
        }                                        
    }
    
    for ( MPUIVCInfo * curInfo in arrayVCInfo_ )
    {
        if ( bShow && (*curInfo.ppVC_).bActive_ )
        {                        
            // show it
            [(*curInfo.ppVC_) show:bShow withAnimation:true time:TOOLBAR_ANIMATION_TIME fullOpacity:TOOLBAR_FULL_OPACITY forceUpdate:false];                                                 
            [[NSNotificationCenter defaultCenter] postNotificationName: (*curInfo.ppVC_).notifyOn_ object:nil];
            [curInfo onShowBegin];                        
        }
        else if ( !bShow && (*curInfo.ppVC_).bActive_ )
        {
            // hide it
            [(*curInfo.ppVC_) show:bShow withAnimation:true time:TOOLBAR_ANIMATION_TIME fullOpacity:TOOLBAR_FULL_OPACITY forceUpdate:false];             
            //[[NSNotificationCenter defaultCenter] postNotificationName: (*curInfo.ppVC_).notifyOff_ object:nil];
            [curInfo onHideBeginWithTime: TOOLBAR_ANIMATION_TIME];
        }
        
    }
    
    
    [self updateShowToolbarButton];
    
}


//
//
- (void) updateShowToolbarButton
{
    if ( buttonShowToolbar_ )
    {   
        bool bIsShown = false;
        
        if ( toolbarController_ )
        {        
            bIsShown = toolbarController_.bShown_;    
        }
        
        //NSLog(@"shown: %d\n", bIsShown );
        
        [buttonShowToolbar_ setOn: bIsShown];
      
    }
    
}

//
//
- (void) onViewOnOff: (MPUIVCInfo *) vcInfo time: (float) t
{
    if ( *vcInfo.ppVC_ == fpsController_ )
    {
        // special case
        [self onFPSViewOnOff: t];
    }
    else
    {
        [self onGeneralViewOnOff:t withVCInfo: vcInfo ];                                
    }   


}


//
// special case here b/c of need to set global params
- (void) onFPSViewOnOff: (float) time
{
    
    if ( !fpsController_ )
    {
        [self createFPSController];
    }
    
    MPUIVCInfo *info = [self vcInfoForVC: &fpsController_];
    
    [fpsController_ toggleActive];    
    info.bActive_ = fpsController_.bActive_;
    [fpsController_ show:fpsController_.bActive_ withAnimation:true time:time fullOpacity:TOOLBAR_FULL_OPACITY forceUpdate:false];                                     
    
    
    if ( fpsController_.bActive_ )
    {
        gParams->setFPSShown( true );
        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationFPSViewOn object:nil];        
        [self hideAllSubControlsExcept: [NSArray arrayWithObject: fpsController_] time: TOOLBAR_ANIMATION_TIME_CANVAS_TOUCHDOWN ];
        
    }
    else
    {
        gParams->setFPSShown( false );
        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationFPSViewOff object:nil];
        
    }
    

    if ( info.bActive_ )
    {
        [info onShowBegin];
    }
    else
    {
        [info onHideBeginWithTime: TOOLBAR_ANIMATION_TIME];
    }
    
}

//
// generic  handling for toggling a subview on/off
- (void) onGeneralViewOnOff: (float) time withVCInfo: (MPUIVCInfo *) vcInfo
{
    
    if ( vcInfo.ppVC_ && !*vcInfo.ppVC_ )
    {
        //NSLog(@"creating with sel: %@\n", NSStringFromSelector( vcInfo.selCreate_ ));
        [self performSelector: vcInfo.selCreate_];
    }
    
    MPUIViewControllerHiding *vc = *vcInfo.ppVC_;
    
    if ( vc )
    {
        [vc toggleActive];        
        vcInfo.bActive_ = vc.bActive_;        
        
        [vc show: vc.bActive_ withAnimation:true time:time fullOpacity:TOOLBAR_FULL_OPACITY forceUpdate:false];                                     
        
        //NSLog( @"on: %@, off: %@\n", vc.notifyOn_, vc.notifyOff_ );
        
        if ( vc.bActive_ && [vc.notifyOn_ length] > 0)
        {            
            
            // turning view on!
            
            [[NSNotificationCenter defaultCenter] postNotificationName: vc.notifyOn_ object:nil];                                    
            
            NSArray * arrayAllToNotHide = 0;
            if ( vcInfo.pVCPreventHideOnShow_ && (vcInfo.pVCPreventHideOnShow_).ppVC_ && *((vcInfo.pVCPreventHideOnShow_).ppVC_) )
            {
                arrayAllToNotHide = [ NSArray arrayWithObjects: vc, *((vcInfo.pVCPreventHideOnShow_).ppVC_), nil ];
            }
            else
            {
                arrayAllToNotHide = [NSArray arrayWithObject: vc];                
            }            
            
            [self hideAllSubControlsExcept: arrayAllToNotHide time: TOOLBAR_ANIMATION_TIME_CANVAS_TOUCHDOWN ];
        }
        else if ( [vc.notifyOff_ length] > 0)
        {       
            // turning view off!
            
            [[NSNotificationCenter defaultCenter] postNotificationName: vc.notifyOff_ object:nil];
            
        }
        
        if ( vcInfo.bActive_ )
        {
            [vcInfo onShowBegin];
        }
        else
        {
            [vcInfo onHideBeginWithTime: TOOLBAR_ANIMATION_TIME];
        }
        
    }
}

//
// for managing view visibility
- (void) hideAllSubControlsExcept: (NSArray *) vcsNotToHide time: (float) t;
{
    
    
    for ( MPUIVCInfo * curInfo in arrayVCInfo_ )
    {
        MPUIViewControllerHiding * curVC = *curInfo.ppVC_;
            
        bool bHide = false;
        if ( curVC.bActive_ && curVC.bShown_ && curVC != toolbarController_ )
        {

            bool bExempt = false;
            for ( MPUIViewControllerHiding * notToHIde in vcsNotToHide )
            {
                if ( notToHIde == curVC )
                {
                    bExempt = true;
                }
            }
            
            bHide = !bExempt;
            
        }
        
        if ( bHide )
        {    
            [self onViewOnOff: curInfo time: TOOLBAR_ANIMATION_TIME_CANVAS_TOUCHDOWN];
        }
    }
    
}


//
//
- (MPUIVCInfo *) vcInfoForVC: (MPUIViewControllerHiding **) ppVC
{
 
    for ( MPUIVCInfo * curInfo in arrayVCInfo_ )
    {
        if ( curInfo.ppVC_ == ppVC )
        {
            return curInfo;
        }
    }
    
    return nil;
}


//
// general helper to factor out destroying sub-views
- (void) destroyGeneral: (UIViewController **) vc
{
    if ( vc && *vc )
    {
        [(*vc).view removeFromSuperview];        
        [(*vc) release];
        (*vc) = nil;
    }
}

//
// general helper to factor out creation of sub-views
- (void) createControllerGeneral: (NSString *) phoneNib iPadNib: (NSString *) padNib vc: (MPUIViewControllerHiding **) ppVC theClass: (id) classType posSelect: (SEL) posSelector notifyOn: (NSString *) notifyOn nofityOff: (NSString *) notifyOff
{
    
    
    NSString * nib = ( IS_IPAD ? padNib : phoneNib );        
    *ppVC = [[classType alloc] initWithNibName: nib bundle:nil];    
    (*ppVC).bActive_ = false;
    
    [self.view addSubview: (*ppVC).view];
    [self performSelector: posSelector];    
    
    (*ppVC).notifyOn_ = notifyOn;
    (*ppVC).notifyOff_ = notifyOff;
    
}


//
//
- (void) createToolbarController
{
 
    //imageToolbarOn_ = [UIImage imageNamed: @"symbol_on.png"];
    //imageToolbarOff_ = [UIImage imageNamed: @"symbol_off.png"];
    
    [buttonShowToolbar_ setImageNamesOn: @"symbol_on.png" off: @"symbol_off.png"];
    
    NSString * barNib = ( IS_IPAD ? @"MPToolbarViewController-iPad" : @"MPToolbarViewController" );        
    toolbarController_ = [[MPToolbarViewController alloc] initWithNibName: barNib bundle:nil];
    toolbarController_.bActive_ = false; 
    
    [self.view addSubview: toolbarController_.view];
    CGRect frame = self.view.frame;
    CGRect barFrame = toolbarController_.view.frame;
    
    toolbarController_.view.frame = CGRectMake( 0.0f, frame.size.height - barFrame.size.height, barFrame.size.width, barFrame.size.height );
    
    // send the toolbar behind the snibbe logo
    [self.view sendSubviewToBack: toolbarController_.view];
    
    

}

//
//
- (void) destroyToolbarController
{
    [self destroyGeneral: &toolbarController_];        
}

//
//
- (void) createFPSController
{    
    
    [self createControllerGeneral:@"MPFPSViewController" 
                          iPadNib:@"MPFPSViewController-iPad" 
                               vc:&fpsController_ 
                         theClass:[MPFPSViewController class] 
                        posSelect:@selector(positionFPSController) 
                         notifyOn:gNotificationFPSViewOn 
                        nofityOff:gNotificationFPSViewOff];
        
}

//
//
- (void) positionFPSController
{
    CGRect frame = self.view.frame;    
    CGRect fpsFrame = fpsController_.view.frame;
    CGRect barFrame = toolbarController_.view.frame;
    
    float xCenter = [toolbarController_ getFPSXPos];

    fpsController_.view.frame = CGRectMake( xCenter - fpsFrame.size.width * 0.5f, frame.size.height - barFrame.size.height - fpsFrame.size.height, fpsFrame.size.width, fpsFrame.size.height );
}

- (void) destroyFPSController
{ 
    [self destroyGeneral: &fpsController_];                
}   

//
//
- (void) createColorController
{    
    
    [self createControllerGeneral:@"MPColorViewController" 
                          iPadNib:@"MPColorViewController-iPad" 
                               vc:&colorController_ 
                         theClass:[MPColorViewController class] 
                        posSelect:@selector(positionColorController) 
                         notifyOn:gNotificationColorViewOn 
                        nofityOff:gNotificationColorViewOff];
    
}

//
//
- (void) positionColorController
{
    CGRect frame = self.view.frame;    
    CGRect colorFrame = colorController_.view.frame;
    CGRect barFrame = toolbarController_.view.frame;
    CGRect colorJoinFrame = [colorController_ getJoinFrame];
    
    
    float xCenter = [toolbarController_ getColorXPos];
    float joinXCenter = colorJoinFrame.origin.x + colorJoinFrame.size.width * .5f;
    

    colorController_.view.frame = CGRectMake( xCenter - joinXCenter, frame.size.height - barFrame.size.height - colorFrame.size.height, colorFrame.size.width, colorFrame.size.height );
}

- (void) destroyColorController
{
    
    [self destroyGeneral: &colorController_];    
    
} 

//
//
- (void) createBrushController
{
    
    [self createControllerGeneral:@"MPBrushViewController" 
                          iPadNib:@"MPBrushViewController-iPad" 
                               vc:&brushController_ 
                         theClass:[MPBrushViewController class] 
                        posSelect:@selector(positionBrushController) 
                         notifyOn:gNotificationBrushViewOn 
                        nofityOff:gNotificationBrushViewOff];
        
}
//
//
- (void) positionBrushController
{
    CGRect frame = self.view.frame;    
    CGRect brushFrame = brushController_.view.frame;
    CGRect barFrame = toolbarController_.view.frame;
    CGRect joinFrame = [brushController_ getJoinFrame];
    
    
    float xCenter = [toolbarController_ getBrushXPos];
    float joinXCenter = joinFrame.origin.x + joinFrame.size.width * .5f;

    brushController_.view.frame = CGRectMake( xCenter - joinXCenter, frame.size.height - barFrame.size.height - brushFrame.size.height, brushFrame.size.width, brushFrame.size.height );
}

//
//
- (void) destroyBrushController
{
    [self destroyGeneral: &brushController_];    
    
}


//
//
- (void) createRecordController
{    
    
    [self createControllerGeneral:@"MPRecordViewController" 
                          iPadNib:@"MPRecordViewController-iPad" 
                               vc:&recordController_ 
                         theClass:[MPRecordViewController class] 
                        posSelect:@selector(positionRecordController) 
                         notifyOn:gNotificationRecordViewOn 
                        nofityOff:gNotificationRecordViewOff];
    
        
}

//
//
- (void) positionRecordController
{
    CGRect frame = self.view.frame;    
    CGRect recordFrame = recordController_.view.frame;
    CGRect barFrame = toolbarController_.view.frame;
    
    float xCenter = [toolbarController_ getRecordXPos];
    
    recordController_.view.frame = CGRectMake( xCenter - recordFrame.size.width * 0.5f, frame.size.height - barFrame.size.height - recordFrame.size.height, recordFrame.size.width, recordFrame.size.height );
}

- (void) destroyRecordController
{
    [self destroyGeneral: &recordController_];    
    
}   

//
//
- (void) createInfoController
{    
    
    [self createControllerGeneral:@"MPInfoViewController" 
                          iPadNib:@"MPInfoViewController-iPad" 
                               vc:&infoController_ 
                         theClass:[MPInfoViewController class] 
                        posSelect:@selector(positionInfoController) 
                         notifyOn:gNotificationInfoViewOn 
                        nofityOff:gNotificationInfoViewOff];
    
}

//
//
- (void) positionInfoController
{
    CGRect frame = self.view.frame;    
    CGRect infoFrame = infoController_.view.frame;
    CGRect barFrame = toolbarController_.view.frame;
    
    float xCenter = [toolbarController_ getInfoXPos];
    
    infoController_.view.frame = CGRectMake( xCenter - infoFrame.size.width * 0.5f, frame.size.height - barFrame.size.height - infoFrame.size.height, infoFrame.size.width, infoFrame.size.height );
}

- (void) destroyInfoController
{    
    [self destroyGeneral: &infoController_];        
}   

//
//
- (void) createEssayController
{
    
    [self createControllerGeneral:@"MPEssayViewController" 
                          iPadNib:@"MPEssayViewController-iPad" 
                               vc:&essayController_ 
                         theClass:[MPEssayViewController class] 
                        posSelect:@selector(positionEssayController) 
                         notifyOn:gNotificationEssayViewOn 
                        nofityOff:gNotificationEssayViewOff];
}

//
//
- (void) positionEssayController
{
    
    CGRect frame = self.view.frame;    
    CGRect subFrame = essayController_.view.frame;
    
    // todo - update for phone
    essayController_.view.frame = CGRectMake( frame.size.width * (12.0f / 768.0f), frame.size.height * (332.0f / 1024.0f), subFrame.size.width, subFrame.size.height );

    
}

//
//
- (void) destroyEssayController
{
    [self destroyGeneral: &essayController_];    
}

//
//
- (void) createHelpController
{
    
    [self createControllerGeneral:@"MPHelpViewController" 
                          iPadNib:@"MPHelpViewController-iPad" 
                               vc:&helpController_ 
                         theClass:[MPHelpViewController class] 
                        posSelect:@selector(positionHelpController) 
                         notifyOn:gNotificationHelpViewOn 
                        nofityOff:gNotificationHelpViewOff];
}

//
//
- (void) positionHelpController
{
    CGRect frame = self.view.frame;    
    CGRect subFrame = helpController_.view.frame;
    
    // todo - update for phone
    helpController_.view.frame = CGRectMake( frame.size.width * (12.0f / 768.0f), frame.size.height * (332.0f / 1024.0f), subFrame.size.width, subFrame.size.height );

}

//
//
- (void) destroyHelpController
{
    [self destroyGeneral: &helpController_];    
}

//
//
- (void) createSaveShareController
{
    [self createControllerGeneral:@"MPSaveShareViewController" 
                          iPadNib:@"MPSaveShareViewController-iPad" 
                               vc:&saveShareController_ 
                         theClass:[MPSaveShareViewController class] 
                        posSelect:@selector(positionSaveShareController) 
                         notifyOn:gNotificationSaveShareViewOn 
                        nofityOff:gNotificationSaveShareViewOff];
}

//
//
- (void) positionSaveShareController
{
    CGRect frame = self.view.frame;    
    CGRect subFrame = saveShareController_.view.frame;
    CGRect barFrame = toolbarController_.view.frame;
    
    // todo - update for phone
    saveShareController_.view.frame = CGRectMake( 120.0f, 
                                                  frame.size.height - subFrame.size.height - barFrame.size.height - 12.0f, 
                                                  subFrame.size.width, 
                                                  subFrame.size.height );

}

//
//
- (void) destroySaveShareController
{
    [self destroyGeneral: &saveShareController_];
}

//
//
- (void) createLoadController
{
    [self createControllerGeneral:@"MPLoadViewController" 
                          iPadNib:@"MPLoadViewController-iPad" 
                               vc:&loadController_
                         theClass:[MPLoadViewController class] 
                        posSelect:@selector(positionLoadController) 
                         notifyOn:gNotificationLoadViewOn 
                        nofityOff:gNotificationLoadViewOff];
}

//
//
- (void) positionLoadController
{
    CGRect frame = self.view.frame;    
    CGRect subFrame = loadController_.view.frame;
    CGRect barFrame = toolbarController_.view.frame;
    
    // todo - update for phone
    loadController_.view.frame = CGRectMake( 120.0f, 
                                            frame.size.height - subFrame.size.height - barFrame.size.height - 12.0f, 
                                            subFrame.size.width, 
                                            subFrame.size.height );
}

//
//
- (void) destroyLoadController
{
    [self destroyGeneral: &loadController_];    
}


//
//
- (void) createMediaController
{
    [self createControllerGeneral:@"MPMediaController" 
                          iPadNib:@"MPMediaController-iPad" 
                               vc:&mediaController_
                         theClass:[MPMediaController class] 
                        posSelect:@selector(positionMediaController) 
                         notifyOn:gNotificationMediaViewOn 
                        nofityOff:gNotificationMediaViewOff];
}

//
//
- (void) positionMediaController
{
    CGRect frame = self.view.frame;    
    CGRect subFrame = mediaController_.view.frame;
    CGRect barFrame = toolbarController_.view.frame;
    
    // todo - update for phone
    mediaController_.view.frame = CGRectMake( 120.0f, 
                                                 frame.size.height - subFrame.size.height - barFrame.size.height - 12.0f, 
                                                 subFrame.size.width, 
                                                 subFrame.size.height );
}

//
//
- (void) destroyMediaController
{
    [self destroyGeneral: &mediaController_];    
}



#pragma mark notification observers

//
//
- (void) onFPSViewOnOff
{  
    [self onFPSViewOnOff: TOOLBAR_ANIMATION_TIME];            
}

- (void) onColorViewOnOff
{
    [self onGeneralViewOnOff:TOOLBAR_ANIMATION_TIME withVCInfo: [self vcInfoForVC: &colorController_]];
}

- (void) onBrushViewOnOff
{
    [self onGeneralViewOnOff:TOOLBAR_ANIMATION_TIME withVCInfo: [self vcInfoForVC: &brushController_ ]];    
}

- (void) onRecordViewOnOff
{
    MPUIVCInfo * vcRecord = [self vcInfoForVC: &recordController_ ];
    if ( vcRecord && vcRecord.bActive_ )
    {
        // going to be turning off - turn off dependencies as well if required
        
        MPUIVCInfo * vcSaveShare = [self vcInfoForVC: &saveShareController_ ];
        MPUIVCInfo * vcLoad = [self vcInfoForVC: &loadController_ ];
        
        if ( vcSaveShare && vcSaveShare.bActive_ )
        {
            [self onGeneralViewOnOff:TOOLBAR_ANIMATION_TIME withVCInfo: vcSaveShare];        
        }
        
        if ( vcLoad && vcLoad.bActive_ )
        {
            [self onGeneralViewOnOff:TOOLBAR_ANIMATION_TIME withVCInfo: vcLoad];        
        }
        
    }
    
    [self onGeneralViewOnOff:TOOLBAR_ANIMATION_TIME withVCInfo: vcRecord];    
}

- (void) onInfoViewOnOff
{
    
    
    MPUIVCInfo * vcInfo = [self vcInfoForVC: &infoController_ ];
    if ( vcInfo && vcInfo.bActive_ )
    {
        // going to be turning off - turn off dependencies as well if required
        
        MPUIVCInfo * vcHelp = [self vcInfoForVC: &helpController_ ];
        MPUIVCInfo * vcEssay = [self vcInfoForVC: &essayController_ ];
        
        if ( vcHelp && vcHelp.bActive_ )
        {
            [self onGeneralViewOnOff:TOOLBAR_ANIMATION_TIME withVCInfo: vcHelp];        
        }

        if ( vcEssay && vcEssay.bActive_ )
        {
            [self onGeneralViewOnOff:TOOLBAR_ANIMATION_TIME withVCInfo: vcEssay];        
        }

    }
    
    [self onGeneralViewOnOff:TOOLBAR_ANIMATION_TIME withVCInfo: [self vcInfoForVC: &infoController_ ]];    
}

- (void) onHelpViewOnOff
{
    [self onGeneralViewOnOff:TOOLBAR_ANIMATION_TIME withVCInfo: [self vcInfoForVC: &helpController_ ]];    
}

- (void) onEssayViewOnOff
{
    [self onGeneralViewOnOff:TOOLBAR_ANIMATION_TIME withVCInfo: [self vcInfoForVC: &essayController_ ]];    
}

- (void) onSaveShareViewOnOff
{
    [self onGeneralViewOnOff:TOOLBAR_ANIMATION_TIME withVCInfo: [self vcInfoForVC: &saveShareController_ ]];    
}

- (void) onLoadViewOnOff
{
    [self onGeneralViewOnOff:TOOLBAR_ANIMATION_TIME withVCInfo: [self vcInfoForVC: &loadController_ ]];    
}

- (void) onMediaViewOnOff
{
    [self onGeneralViewOnOff:TOOLBAR_ANIMATION_TIME withVCInfo: [self vcInfoForVC: &mediaController_ ]];    
}
//
//
- (void) onCanvasTouchDown
{
    
    if ( gParams->drawingHidesUI() )
    {
    
        // hide the UI when we start drawing
        for ( MPUIVCInfo * curInfo in arrayVCInfo_ )
        {
            MPUIViewControllerHiding * curVC = *curInfo.ppVC_;

            if ( curVC.bActive_ && curVC.bShown_ && curVC != toolbarController_ )
            {
                [self onViewOnOff: curInfo time: 0.0f];            
            }
        }
    }
        
}

//
//
- (void) onToolModeChanged
{
    if ( gParams->tool() == MotionPhoneTool_Hand )
    {
        // make sure we close all other controls if we're selecting the
        // hand tool
        
        for ( MPUIVCInfo * curInfo in arrayVCInfo_ )
        {
            MPUIViewControllerHiding * curVC = *curInfo.ppVC_;            
            if ( curVC.bActive_ && curVC.bShown_ && curVC != toolbarController_ )
            {
                [self onViewOnOff: curInfo time: 0.0f];            
            }
        }
    }
}




@end
