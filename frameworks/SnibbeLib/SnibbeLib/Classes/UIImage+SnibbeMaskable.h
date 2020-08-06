//
//  UIImage+SnibbeMaskable.h
//  SnibbeLib
//
//  Created by Graham McDermott on 2/8/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (SnibbeMaskable)

- (UIImage *) imageByMasking:(UIImage *)maskImage;

@end
