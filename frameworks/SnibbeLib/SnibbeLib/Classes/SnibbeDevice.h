//
//  SnibbeDevice.h
//  SnibbeLib
//
//  Created by Graham McDermott on 1/23/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SnibbeDevice : NSObject

+ (NSString *) platform;
+ (NSString *) platformString;
+ (NSString *) platformStringMatch;
+ (int) amountOfRAM;


@end
