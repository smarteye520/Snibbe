/*
     File: ScaleView.h
	(c) 2010 Scott Snibbe
 
 */

#import <UIKit/UIKit.h>

@interface ScaleView : UIView
{
	NSString	*title;
	float		*color;
	int			scaleIndex;
}

@property (nonatomic) NSString *title;
@property (nonatomic) float* color;
@property (nonatomic) int scaleIndex;

+ (CGFloat)viewWidth;
+ (CGFloat)viewHeight;

@end
