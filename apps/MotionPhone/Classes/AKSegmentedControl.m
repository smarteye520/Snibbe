//
//  AKSegmentedControl.m
//  MotionPhone
//
//  Created by Scott Snibbe on 5/1/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import "AKSegmentedControl.h"


@implementation AKSegmentedControl

- (void)setSelectedSegmentIndex:(NSInteger)toValue {
    // Trigger UIControlEventValueChanged even when re-tapping the selected segment.
    if (toValue==self.selectedSegmentIndex) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    [super setSelectedSegmentIndex:toValue];        
}

@end