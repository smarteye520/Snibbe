/* File: ImageBrowserItemLayer.h

   Abstract: Header file for thumbnail view's backing layer.

   (c) 2010 Scott Snibbe */

#import <QuartzCore/QuartzCore.h>

@class NSURL, UIImage;

@interface ImageBrowserItemLayer : CALayer
{
	float aspect;
	bool justLoaded;
}

@property(nonatomic, copy) NSURL *fileURL;
@property(nonatomic) NSData *pdfData;
@property(nonatomic) NSString *titleString;
@property(nonatomic) bool drawImage;
@property(nonatomic) bool selected;

@end
