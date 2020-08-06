//
//  MPVideoRecordController.h
//  MotionPhone
//
//  Created by Graham McDermott on 12/1/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPProtocols.h"


@protocol MPVideoRecordDelegate <NSObject>

@required

- (void) onVideoCreated: (NSString *) path;
- (void) onVideoFailed;

@end



@interface MPVideoRecordController : UIViewController
{ 
    IBOutlet UIView *viewMainBG_;
    IBOutlet UIButton *buttonCancel_;
    IBOutlet UILabel *labelRecording_;
    
    NSMutableArray *arrayFrames_;
    
    NSString * videoPath_;
    
    UIDeviceOrientation recordingViewOrientation_;
    id<MPOrientingUIKitParent> orientingParentDelegate_;
    id<MPVideoRecordDelegate> videoDelegate_;
    
    int iCurFrameNum_;
    int totalFrames_;
    int totalFramesRendered_;
    int iFrameIncrement_;
    int totalFramesPerLoop_;
    int timeScale_;

    CGRect mainWindowBounds_;
    
    bool optimize_;
    
    float curMovieTime_;
    int dir_;
    unsigned int maxTimeScale_;
    
    float videoScaleFactor_;
    int   videoNumLoops_;
    bool bShowingRecordingLabel_;
}

@property (nonatomic, assign) id<MPOrientingUIKitParent> orientingParentDelegate_;
@property (nonatomic, assign) id<MPVideoRecordDelegate> videoDelegate_;
@property (nonatomic) float videoScaleFactor_;
@property (nonatomic) int   videoNumLoops_;
@property (nonatomic) unsigned int maxTimeScale_;
@property (nonatomic) int iFrameIncrement_;
@property (nonatomic) bool optimize_;

- (IBAction) onButtonCancel: (id)sender;



@end
