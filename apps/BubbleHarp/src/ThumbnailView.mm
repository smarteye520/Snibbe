/*
     File: ThumbnailView.m
 Abstract: A UIView subclass
  Version: 2.5
 
 */

#import "ThumbnailView.h"

@implementation ThumbnailView

@synthesize pdfURL;

-(id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self != nil)
	{
		self.backgroundColor = [UIColor blackColor];
		self.opaque = YES;
		self.clearsContextBeforeDrawing = YES;
	}
	
	pdfURL = nil;
	
	return self;
}


- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	// PDF might be transparent, assume white paper
	[[UIColor blackColor] set];
	CGContextFillRect(ctx, rect);
	
	// Flip coordinates
	CGContextGetCTM(ctx);
	CGContextScaleCTM(ctx, 1, -1);
	CGContextTranslateCTM(ctx, 0, -rect.size.height);
	
	if (pdfURL) {
		// url is a file URL
		
#if 0	// test of creating PDF from NSData
		NSData *pdfData = [NSData dataWithContentsOfURL:pdfURL options:NSUncachedRead error:nil];	
		CGDataProviderRef pdfDataProvider = CGDataProviderCreateWithCFData((CFDataRef)pdfData);
		CGPDFDocumentRef pdf = CGPDFDocumentCreateWithProvider (pdfDataProvider);
#else
		CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)pdfURL);
#endif
		CGPDFPageRef page1 = CGPDFDocumentGetPage(pdf, 1);
		
		// get the rectangle of the cropped inside
		CGRect mediaRect = CGPDFPageGetBoxRect(page1, kCGPDFCropBox);
		CGContextScaleCTM(ctx, rect.size.width / mediaRect.size.width,
						  rect.size.height / mediaRect.size.height);
		CGContextTranslateCTM(ctx, -mediaRect.origin.x, -mediaRect.origin.y);
		
		// draw it
		CGContextDrawPDFPage(ctx, page1);
		CGPDFDocumentRelease(pdf);
	}
}

-(void)setURL:(NSURL *)url
{
	pdfURL = url;
}

@end