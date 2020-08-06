/* File: ImageBrowserItemLayer.m
 
 Abstract: Implementation of thumbnail view's backing layer.
 
 (c) 2010 Scott Snibbe 
 */

#import "ImageBrowserItemLayer.h"
#include "defs.h"
#define LABEL_OFFSET 20

@interface ImageBrowserItemLayer ()
- (NSData*)loadImage;
- (NSData*)loadImageInForeground;
- (void)loadImageInBackground;
@end

@implementation ImageBrowserItemLayer

@dynamic fileURL;
@dynamic pdfData;
@dynamic titleString;
@dynamic drawImage;
@dynamic selected;

static BOOL _imageThreadRunning;
static NSMutableArray *_imageQueue;
//static CGFloat outlineColor[] = {1.0,0.0,0.0,1.0};

- (id)init
{
	self = [super init];
	if (self == nil)
		return nil;
	/*
#if DOWNSAMPLE_IMAGES
	self.needsDisplayOnBoundsChange = YES;
#else
	self.contentsGravity = kCAGravityResizeAspect;
	self.shadowOpacity = .5;
	self.shadowRadius = 5;
	self.shadowOffset = CGSizeMake (0, 6);
# if USE_SHADOW_PATH
	self.shadowPath = [UIBezierPath bezierPath].CGPath;
# endif
#endif
	 */
	self.drawImage = false;
	self.pdfData = nil;
	justLoaded = false;
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	aspect = screenBounds.size.height / screenBounds.size.width;
	
	return self;
}

- (void)didChangeValueForKey:(NSString *)key
{
	if ([key isEqualToString:@"fileURL"])
    {
		self.pdfData = nil;
		//[self loadImage];
    }
	
	else if ([key isEqualToString:@"pdfData"] || [key isEqualToString:@"titleString"] || [key isEqualToString:@"selected"])
    {
		[self setNeedsDisplay];	// redraw layer if pdf or file label changes
    }
	else if ([key isEqualToString:@"drawImage"])
	{
		if (self.drawImage) {
			if (!self.pdfData) {
				self.pdfData = [self loadImage];		// load and cache image data
				//NSLog(@"load %@", self.titleString);
				[self setNeedsDisplay];	
			}
		} else {
			self.pdfData = nil;		// unload image data
			[self setNeedsDisplay];	
			//NSLog(@"unload %@", self.titleString);
		}
	}
	
	[super didChangeValueForKey:key];
}

- (NSData *) loadImage
{
	NSData *pdfData;
	
	/* In case we're being called from the background thread. */
	
	[CATransaction lock];
	pdfData = self.pdfData;
	[CATransaction unlock];
	
	if (pdfData == nil)
    {
#if !USE_IMAGE_THREAD
		pdfData = [self loadImageInForeground];
#else
		[self loadImageInBackground];
#endif
    }
	
	return pdfData;
}

- (void)layoutSublayers	// ?
{
	
}

-(void) drawCenteredText:(CGContextRef)ctx atPoint:(CGPoint)pt withText:(NSString*)text
{	
	const char *cString = [text UTF8String];

	CGAffineTransform ctm = CGAffineTransformMakeScale(1,-1);
	CGContextSetTextMatrix(ctx, ctm);
	
	CGContextSelectFont(ctx, "Helvetica", 18, kCGEncodingMacRoman);

	CGContextSetTextDrawingMode(ctx, kCGTextInvisible);
	CGContextShowTextAtPoint(ctx, pt.x, pt.y, cString, text.length);
	
	CGContextSetTextDrawingMode(ctx, kCGTextFill);
	CGContextSetRGBStrokeColor(ctx, 0,0,0,1); 
	CGContextSetRGBFillColor(ctx, 0,0,0,1);
	
	CGContextShowTextAtPoint(ctx, pt.x - (CGContextGetTextPosition(ctx).x - pt.x)/2,
							 pt.y, cString, text.length);
}

- (void)drawInContext:(CGContextRef)ctx
{
	CGRect bounds = self.bounds;
	
	if (!self.drawImage) {
		// erases image, if cached
		//CGContextSetGrayFillColor (ctx, 0.8, 1);
		//CGContextFillRect (ctx, bounds);
		
    } else {
		
		// draw thumbnail
		CGColorRef color = [[UIColor colorWithWhite:0 alpha:.5] CGColor];
		CGContextSetShadowWithColor (ctx, CGSizeMake (0, 6), 10, color);

		CGRect emptyBounds = bounds;
		emptyBounds.size.height = emptyBounds.size.width * aspect;
		
		if (self.pdfData == nil) {
			// clear area
			//CGContextSetGrayFillColor (ctx, 0, 1);
			//CGContextFillRect (ctx, emptyBounds);
		} else {			
			//NSLog(@"drawinContext:got image:%@", self.titleString);

			CGContextSaveGState (ctx);
			
			CGDataProviderRef pdfDataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)self.pdfData);
			CGPDFDocumentRef pdfDoc = CGPDFDocumentCreateWithProvider(pdfDataProvider);
			
			CGPDFPageRef page1 = CGPDFDocumentGetPage((CGPDFDocumentRef)pdfDoc, 1);
			
//			CGRect r = CGRectInset (bounds, 8, 8);
			
			// get the rectangle of the cropped pdf inside
			CGRect mediaRect = CGPDFPageGetBoxRect(page1, kCGPDFCropBox);
			//CGContextScaleCTM(ctx, bounds.size.width / mediaRect.size.width,
			//				  bounds.size.height / mediaRect.size.height);
			
			// only scale based on width, fitting to top of box
			float scale = bounds.size.width / mediaRect.size.width;
			
			CGContextScaleCTM(ctx, scale, -scale);
			CGContextTranslateCTM(ctx, -mediaRect.origin.x, -mediaRect.size.height);
			
			// draw it
			CGContextDrawPDFPage(ctx, page1);
			
			[UIView commitAnimations];
			
			CGPDFDocumentRelease(pdfDoc);
			CGDataProviderRelease(pdfDataProvider);
			
			CGContextRestoreGState (ctx);
			// release anything else?
		}
		
		if (self.selected) {
			emptyBounds = CGRectInset(emptyBounds, 2, 2);
			CGContextSetLineWidth(ctx, 5);
			//CGContextSetStrokeColor(ctx, outlineColor);
			CGContextSetRGBStrokeColor(ctx, 36.0/255.0, 99.0/255.0, 222.0/255.0, 1.0);
			CGContextStrokeRect(ctx, emptyBounds);
		}
		
		color = [[UIColor colorWithWhite:1 alpha:0] CGColor];
		CGContextSetShadowWithColor (ctx, CGSizeMake (0, 0), 0, color);
		
		// draw label
		CGPoint textOrigin;
		textOrigin.x = bounds.origin.x + bounds.size.width / 2;
		textOrigin.y = (bounds.origin.y + bounds.size.height) - TITLE_HEIGHT*0.5;
		
		[self drawCenteredText:ctx atPoint:textOrigin withText:self.titleString];
	}
}

- (NSData *)loadImageInForeground
{
	NSData *pdfData = nil;
	NSData *fileData = [NSData dataWithContentsOfURL:self.fileURL];
	
	if (fileData) {
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:fileData];
		
		if (unarchiver) {
			self.pdfData = [unarchiver decodeObjectForKey:kThumbnailPDFKey];
			self.titleString = [unarchiver decodeObjectForKey:kTitleKey];
			
			[CATransaction lock];
			pdfData = self.pdfData;
			[CATransaction unlock];
		}
		//justLoaded = true;
		//if (justLoaded) {
			//NSLog(@"drawinContext:justLoaded, animating in: %@", self.titleString);
			// animate appearance of image when it loads
			CABasicAnimation* appear = [CABasicAnimation animationWithKeyPath:@"opacity"];
			appear.fromValue = [NSNumber numberWithFloat:0.0];
			appear.toValue = [NSNumber numberWithFloat:1.0];
			appear.duration = 0.5;
			appear.autoreverses = NO;
			appear.repeatCount = 1;
			appear.delegate = self;
			[self addAnimation:appear forKey:@"appear"];
			
			//justLoaded = false;
		//}
	}
	
	return pdfData;
}

- (void)loadImageInBackground
{
	if (self.fileURL != nil)
	{
		[CATransaction lock];
		
		if (!_imageQueue)
			_imageQueue = [[NSMutableArray alloc] init];
		
		if ([_imageQueue indexOfObjectIdenticalTo:self] == NSNotFound)
		{
			[_imageQueue addObject:self];
			
			if (!_imageThreadRunning)
			{
				[NSThread detachNewThreadSelector:@selector(imageThread:)
										 toTarget:[self class] withObject:nil];
				_imageThreadRunning = YES;
			}
		}
		
		[CATransaction unlock];
	}
}

+ (void)imageThread:(id)unused
{
	[CATransaction lock];
	
	while ([_imageQueue count] != 0)
	{
		@autoreleasepool {
		
			ImageBrowserItemLayer *layer = [_imageQueue objectAtIndex:0];
			
			[CATransaction unlock];
			[layer loadImageInForeground];
			[CATransaction flush];
			[CATransaction lock];
			
			NSInteger idx = [_imageQueue indexOfObjectIdenticalTo:layer];
			if (idx != NSNotFound)
				[_imageQueue removeObjectAtIndex:idx];
		
		}
	}
	
	_imageThreadRunning = NO;
	[CATransaction unlock];
}

@end
