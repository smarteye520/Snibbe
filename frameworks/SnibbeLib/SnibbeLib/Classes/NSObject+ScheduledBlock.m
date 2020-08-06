//
//  NSObject+ScheduledBlock.m
//  SnibbeLib
//
//  Created by Graham McDermott on 11/2/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#import "NSObject+ScheduledBlock.h"


@implementation NSObject(ScheduledBlock)



//
//
- (void)delayedAddOperation:(NSOperation *)operation
{
    
    [[NSOperationQueue currentQueue] addOperation:operation];
    
}


//
//
- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
    
    [self performSelector:@selector(delayedAddOperation:)
               withObject:[NSBlockOperation blockOperationWithBlock:block]     
               afterDelay:delay];
    
}


//
//
- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay cancelPreviousRequest:(BOOL)cancel
{
    if (cancel)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
    
    [self performBlock:block afterDelay:delay];
    
}



@end
