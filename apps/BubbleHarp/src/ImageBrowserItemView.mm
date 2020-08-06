/* File: ImageBrowserItemView.m
 
 Abstract: Implementation of image thumbnail view.
 
 (c) 2010 Scott Snibbe
 */

#import "ImageBrowserItemView.h"
#import "ImageBrowserItemLayer.h"
#import "ImageBrowserViewController.h"

@implementation ImageBrowserItemView

//@synthesize label;

+ (ImageBrowserItemView *)itemViewWithFrame:(CGRect)r fileURL:(NSURL *)url
{
	return [[self alloc] initWithFrame:r fileURL:url];
}

+ (Class)layerClass
{
	return [ImageBrowserItemLayer class];
}

- (id)initWithFrame:(CGRect)r fileURL:(NSURL *)url
{
	self = [super initWithFrame:r];
	if (self == nil)
		return nil;
	
	((ImageBrowserItemLayer *)self.layer).fileURL = url;
	
	return self;
}

- (NSURL *)fileURL
{
	return ((ImageBrowserItemLayer *)self.layer).fileURL;
}

- (NSString*)titleString
{
	return ((ImageBrowserItemLayer *)self.layer).titleString;
}

- (bool)drawImage
{
	return ((ImageBrowserItemLayer *)self.layer).drawImage;
}

- (void)setDrawImage:(bool)draw
{
	((ImageBrowserItemLayer *)self.layer).drawImage = draw;
}

- (bool)selected
{
	return ((ImageBrowserItemLayer *)self.layer).selected;
}

- (void)setSelected:(bool)s
{
	((ImageBrowserItemLayer *)self.layer).selected = s;
}

- (NSString *) fileName
{
	//$$$$ need to remove URL symbols like %20
	// get last part of fileURL
	NSString *urlString = [self.fileURL relativePath];
	NSArray *components = [urlString componentsSeparatedByString:@"/"];
	return [components objectAtIndex:components.count-1];
}

/*
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	[super touchesEnded:touches withEvent:event];
	
    NSLog(@"TOUCHES ENDED: ImageBrowserItemView: %@",self.titleString);
	
	//self.selected = !self.selected;
	
	self.superview.touchedView = self;
	
	// $$$$ at higher level - unselect all others
    
    //UITouch* touch = [touches anyObject];
    //CGPoint touchUp = [touch locationInView:[[self subviews] objectAtIndex:0]];
} 
*/

@end
