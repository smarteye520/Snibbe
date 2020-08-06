//
//  MPUIVCInfo.m
//  MotionPhone
//
//  Created by Graham McDermott on 2/3/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#import "MPUIVCInfo.h"


// MPUIVCInfo helper class implementation

@implementation MPUIVCInfo


@synthesize selCreate_;
@synthesize selDestroy_;
@synthesize ppVC_;
@synthesize bActive_;
@synthesize bHideCompleted_;
@synthesize pVCPreventHideOnShow_;

- (id) initWithCreate: (SEL) createSel destroy: (SEL) destroySel vc: (MPUIViewControllerHiding **) vc active: (bool) bAct
{
    if ( (self = [super init] ) )
    {
        selCreate_ = createSel;
        selDestroy_ = destroySel;
        ppVC_ = vc;
        bActive_ = bAct; 
        bHideCompleted_ = false;
        pVCPreventHideOnShow_ = nil;
    }
    
    return self;
}


- (void) hideComplete
{
    bHideCompleted_ = true;
}
//
//
- (void) onHideBeginWithTime: (float) sec
{
    [self performSelector: @selector(hideComplete) withObject:nil afterDelay:sec];    
}

//
//
- (void) onShowBegin
{
    bHideCompleted_ = false;
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector(hideComplete) object:nil];
}


@end
