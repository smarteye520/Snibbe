//
//  ToolbarViewController.h
//  MotionPhone
//
//  Created by Scott Snibbe on 4/6/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AKSegmentedControl.h"

@interface ToolbarViewController : UIViewController <UIPopoverControllerDelegate> {
    
    UIView                      *toolbarView;
	
	// Toolbar buttons
    AKSegmentedControl          *toolSegmentedControl;
    IBOutlet UIButton           *colorButton;

    // Subviews
    UIViewController            *brushViewController, *colorViewController;

    // Active popover
    UIPopoverController         *popoverController;
}

@property(readonly, nonatomic)  IBOutlet UIView                 *toolbarView;
@property(nonatomic,retain)		IBOutlet UISegmentedControl     *toolSegmentedControl;
@property(nonatomic,retain)		IBOutlet UIViewController       *brushViewController;
@property(nonatomic,retain)		IBOutlet UIViewController       *colorViewController;


- (void)updateUIFields:(bool)animate;

- (void)showToolbar:(bool)animated;
- (void)hideToolbar:(bool)animated;
- (void)dismissPopups:(bool)animated;
- (void)finishDismiss:(NSString *)animationId finished:(BOOL)finished context:(void *)context;

//- (bool)rotateViewToCurrent;
- (void)brushChangedHandler;

- (IBAction)segmentedControlIndexChanged:(id)sender;
- (IBAction)undoAction:(id)sender;
- (IBAction)setMusic:(id)sender;
- (IBAction)clearAction:(id)sender;
- (IBAction)popupAction:(UIView*)sender;
- (IBAction)modalViewAction:(id)sender;
- (IBAction)goHomeAction:(id)sender;
- (IBAction)phoneAction:(id)sender;

@end
