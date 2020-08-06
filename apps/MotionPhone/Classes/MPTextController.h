//
//  MPTextController.h
//  MotionPhone
//
//  Created by Graham McDermott on 12/7/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPProtocols.h"

@protocol MPTextControllerDelegate <NSObject>

@optional

- (void) onCancel;
- (void) onPost: (NSString *) strPosting;

@end

@interface MPTextController : UIViewController
{
    IBOutlet UITextView * textView_;
    IBOutlet UINavigationBar * navBar_;
    
    NSString * strTitle_;
    NSString * strButtonPostText_;
    NSString * strButtonCancelText_;
    NSString * strTextViewInitialContents_;
    
    id<MPOrientingUIKitParent> orientingParentDelegate_;
    id<MPTextControllerDelegate> textDelegate_;
}

@property (nonatomic, assign) id<MPOrientingUIKitParent> orientingParentDelegate_;
@property (nonatomic, assign) id<MPTextControllerDelegate> textDelegate_;


@property (nonatomic, retain) NSString * strTitle_;
@property (nonatomic, retain) NSString * strButtonPostText_;
@property (nonatomic, retain) NSString * strButtonCancelText_;
@property (nonatomic, retain) NSString * strTextViewInitialContents_;

- (IBAction) onButtonPost: (id) sender;
- (IBAction) onButtonCancel: (id) sender;

@end
