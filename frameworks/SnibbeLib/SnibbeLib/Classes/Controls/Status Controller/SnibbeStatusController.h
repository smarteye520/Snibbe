//
//  SnibbeStatusController.h
//  SnibbeLib
//
//  Created by Graham McDermott on 12/1/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>

//@protocol SnibbeStatusDelegate <NSObject>
//@optional
//
//- (void) onStatusCancel;
//
//@end



@interface SnibbeStatusController : UIViewController
{ 
    IBOutlet UIView *viewMainBG_;
    //IBOutlet UIButton *buttonCancel_;       
    IBOutlet UILabel *labelStatus_;
    //IBOutlet UIProgressView *progressView_;
        
    //id<SnibbeStatusController> statusDelegate_;
    
}

+ (void) showStatus: (NSString *) strStatus inView: (UIView *) parentView centeredAt: (CGPoint) centerPt bgColor: (UIColor *) col duration: (float) secondsAtFullOpacity;


//- (void) setProgress: (float) progress;
//- (void) showProgressBar: (bool) bShow;
- (void) setLabelText: (NSString *) text;
- (void) setBGColor: (UIColor *) col;
//- (void) showCancelButton: (bool) bShow;



- (void) fadeViewIn;
- (void) fadeViewOut;
//- (void) showLabelOnly;

//@property (nonatomic, assign) id<MPOrientingUIKitParent> orientingParentDelegate_;
//@property (nonatomic, assign) id<MPStatusDelegate> statusDelegate_;



//- (IBAction) onButtonCancel: (id)sender;



@end
