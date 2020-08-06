//
//  InterfaceViewController.h
//  Bubble Harp
//
//  Created by Scott Snibbe on 5/30/10
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#include "defs.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
//#import "GenericShareViewController.h"

#define LINK_URL "http://www.snibbe.com"
#define MAX_IDLE_TIME 10.0 
class Parameters;

//@class GenericShareViewController;

typedef enum BHTool {
	BHTool_Streaming,
	BHTool_Single,
	BHTool_Eraser
} BHTool;

@interface InterfaceViewController : UIViewController <UIPopoverControllerDelegate> {
	
	IBOutlet UIToolbar	*__unsafe_unretained toolbarView;
	
	IBOutlet UILabel *streamLabel;
	IBOutlet UISlider *streamSlider;
	// Toolbar buttons
	IBOutlet UIBarButtonItem	*streamingButton;
	IBOutlet UIBarButtonItem	*nonStreamingButton;
	IBOutlet UIBarButtonItem	*eraserButton;
	IBOutlet UIBarButtonItem	*musicButton;
	
	IBOutlet UIBarButtonItem	*settingsButton, *shareButton, *infoButton;
	IBOutlet UIButton			*infoButton2;
	
	// iPhone only
	IBOutlet UIBarButtonItem	*toolButton;
	IBOutlet UIBarButtonItem	*toolButton2;
	IBOutlet UIBarButtonItem	*toolButton3;
	IBOutlet UIView				*toolView;
	
	UIImageView			*splashView;
	
	UIViewController	*settingsViewController, *infoViewController, 
						*shareViewController, *musicViewController;

	UIPopoverController	*popoverController;	// iPad only, ignored on older iPhones due to "weak" linking of UIKit

	NSTimer				*idleTimer;
	float				maxIdleTime;
	//CGRect				interactionRect;
	bool				appearing;
}
@property(unsafe_unretained, readonly, nonatomic)  UIToolbar	*toolbarView;
@property(nonatomic)		UIBarButtonItem	*streamingButton;
@property(nonatomic)		UIBarButtonItem	*nonStreamingButton;
@property(nonatomic)		UIBarButtonItem	*eraserButton;
@property(nonatomic)		UIBarButtonItem	*musicButton;

@property(nonatomic)		UIBarButtonItem	*settingsButton;
@property(nonatomic)		UIBarButtonItem	*shareButton;
@property(nonatomic)		UIBarButtonItem	*infoButton;
@property(nonatomic)		UIButton		*infoButton2;

// iPhone only
@property(nonatomic)		UIBarButtonItem	*toolButton, *toolButton2, *toolButton3;
@property(nonatomic)		UIView			*toolView;

@property(nonatomic)		UIViewController *settingsViewController;
@property(nonatomic)		UIViewController *shareViewController;
@property(nonatomic)		UIViewController *infoViewController;
@property(nonatomic)		UIViewController *musicViewController;

@property(nonatomic)		    bool			appearing;

//- (void)isVisible();
- (void)updateUIFields:(bool)animate;

- (void)fadeSplash;

- (void)addView;
- (void)showView;
- (void)dismissModalViewControllerAnimated:(bool)animated;
- (void)dismissToolbar:(bool)animated;
- (void)dismissPopups:(bool)animated;
- (void)finishDismiss:(NSString *)animationId finished:(BOOL)finished context:(void *)context;
- (void)scheduleFirstShow; // schedule first display of toolbar if no taps

- (void)freeStartupViews;
- (bool)rotateViewToCurrent;
- (void)idleTimerExceeded;
- (void)resetIdleTimer:(bool)set;

- (void)undoDoubleTap;
- (bool)isInCorner:(CGPoint) p;
- (bool)isInBottom:(CGPoint) p;
- (bool)isOnSides:(CGPoint) p;

//iPhone
- (IBAction)setTool:(id)sender;	// iPhone only
- (BHTool) getCurrentTool;		// iPhone only

- (IBAction)setStreaming:(id)sender;
- (IBAction)setNonStreaming:(id)sender;
- (IBAction)setEraser:(id)sender;
//- (IBAction)setMusic:(id)sender;
- (IBAction)clearAction:(id)sender;
- (IBAction)popupAction:(id)sender;
- (IBAction)modalViewAction:(id)sender;

@end

