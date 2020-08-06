//
//  MPStatusController.h
//  MotionPhone
//
//  Created by Graham McDermott on 12/1/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPProtocols.h"


@interface MPStatusController : UIViewController
{ 
    IBOutlet UIView *viewMainBG_;
    IBOutlet UIButton *buttonCancel_;       
    IBOutlet UILabel *labelStatus_;
    IBOutlet UIProgressView *progressView_;
        
    id<MPOrientingUIKitParent> orientingParentDelegate_;
    id<MPStatusDelegate> statusDelegate_;
    
}

- (void) setProgress: (float) progress;
- (void) showProgressBar: (bool) bShow;
- (void) setLabelText: (NSString *) text;
- (void) showCancelButton: (bool) bShow;
- (void) fadeViewIn;
- (void) fadeViewOut;
- (void) showLabelOnly;

@property (nonatomic, assign) id<MPOrientingUIKitParent> orientingParentDelegate_;
@property (nonatomic, assign) id<MPStatusDelegate> statusDelegate_;



- (IBAction) onButtonCancel: (id)sender;



@end
