//
//  NSObject+ScheduledBlock.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/2/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//
//  From code by James Tang
//  http://ioscodesnippet.tumblr.com/



#import "UIKit/UIKit.h"

@interface NSObject( ScheduledBlock )

- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;
- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay cancelPreviousRequest:(BOOL)cancel;

@end
