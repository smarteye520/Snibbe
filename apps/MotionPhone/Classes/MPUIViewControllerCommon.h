//
//  MPUIViewControllerCommon.h
//  MotionPhone
//
//  Created by Graham McDermott on 1/31/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//
//
//  Common factored out interface and functionality between the
//  iPhone and iPad versions of the top-level UI view controller 

#import <UIKit/UIKit.h>

@class MPGradientController;
@class MPUIOrientButton;


@interface MPUIViewControllerCommon : UIViewController
{
    IBOutlet MPUIOrientButton * buttonShowToolbar_;
    
    
    IBOutlet UILabel * labelPlayer1_;
    IBOutlet UILabel * labelPlayer2_;
    IBOutlet UILabel * labelPlayer3_;
    IBOutlet UILabel * labelPlayer4_;
    NSMutableArray * playerLabels_;
    
    UIImageView * imageViewBusy_;
    
    MPGradientController * gradientController_;

}


- (void) ensureBrushMode;

// multiplayer labels
- (void) positionPlayerLabels;
- (void) setPlayerLabelText: ( NSString * ) text playerNum: (int) iNum;
- (void) updatePlayerLabels;
- (void) onMatchPlayersChanged;

// pending animation
- (void) startShowingPendingAnimation;
- (void) doStopShowingPendingAnim;
- (void) stopShowingPendingAnimation;

// bg gradient
- (void) startShowingGradient;
- (void) doStopShowingGradient;
- (void) stopShowingGradient;



@end
