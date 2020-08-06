//
//  UIImage+SnibbeTransformable.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/30/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//
//
//  Code originally created by Hardy Macia
//  http://www.catamount.com/blog/1015/uiimage-extensions-for-cutting-scaling-and-rotating-uiimages/

#import <UIKit/UIKit.h>

@interface UIImage (SnibbeTransformable)

- (UIImage *)imageAtRect:(CGRect)rect;
- (UIImage *)imageByScalingProportionallyToMinimumSize:(CGSize)targetSize;
- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize;
- (UIImage *)imageByScalingToSize:(CGSize)targetSize;
- (UIImage *)imageRotatedByRadians:(CGFloat)radians;
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;

@end
