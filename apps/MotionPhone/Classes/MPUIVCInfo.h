//
//  MPUIVCInfo.h
//  MotionPhone
//
//  Created by Graham McDermott on 2/3/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//
//
//  Helper class for managing UI sub-views


@class MPUIViewControllerHiding;

//
// helper class to manage state for all view controllers in the UI
@interface MPUIVCInfo : NSObject 
{
    
    
@private
    
    SEL selCreate_;
    SEL selDestroy_;
    MPUIViewControllerHiding ** ppVC_;
    MPUIVCInfo * pVCPreventHideOnShow_;
    bool bActive_;
    bool bHideCompleted_;
    
    
}



@property (nonatomic) SEL selCreate_;
@property (nonatomic) SEL selDestroy_;
@property (nonatomic) MPUIViewControllerHiding ** ppVC_;
@property (nonatomic) bool bActive_;
@property (nonatomic, readonly) bool bHideCompleted_;
@property (nonatomic, assign) MPUIVCInfo * pVCPreventHideOnShow_;


- (id) initWithCreate: (SEL) createSel destroy: (SEL) destroySel vc: (MPUIViewControllerHiding **) vc active: (bool) bAct;
- (void) onHideBeginWithTime: (float) sec;
- (void) onShowBegin;



@end

