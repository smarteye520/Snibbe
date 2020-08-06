//
//  UIImage (SnibbeMaskable).m
//  SnibbeLib
//
//  Created by Graham McDermott on 2/8/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#import "UIImage+SnibbeMaskable.h"

@implementation UIImage (SnibbeMaskable)


- (UIImage *) imageByMasking:(UIImage *) maskImage
{
    
    CGImageRef maskRef = maskImage.CGImage;     
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef masked = CGImageCreateWithMask([self CGImage], mask);
    CGImageRelease( mask );  
    
    return [UIImage imageWithCGImage:masked];

    
}


@end
