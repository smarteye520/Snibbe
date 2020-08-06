/* File: ImageBrowserItemView.h

   Abstract: Header file for image thumbnail view.

   (c) 2010 Scott Snibbe */

#import <UIKit/UIKit.h>

@interface ImageBrowserItemView : UIView
{
	//UILabel *label;
}
+ (ImageBrowserItemView *)itemViewWithFrame:(CGRect)r fileURL:(NSURL *)url;

- (id)initWithFrame:(CGRect)r fileURL:(NSURL *)url;
- (NSString *) fileName;

@property(unsafe_unretained, nonatomic, readonly) NSURL *fileURL;
@property(unsafe_unretained, nonatomic, readonly) NSString *titleString;
@property(nonatomic) bool drawImage;
@property(nonatomic) bool selected;

@end
