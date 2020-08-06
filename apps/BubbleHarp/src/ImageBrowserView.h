/* File: ImageBrowserView.h
 
 Abstract: Image browser scroll view header.
 
 (c) 2010 Scott Snibbe */

#import <UIKit/UIKit.h>

@class ImageBrowserViewController;
@class ImageBrowserSoftEdgeLayer;
@class ImageBrowserItemView;

@interface ImageBrowserView : UIScrollView <UIScrollViewDelegate>
{
@private	
	NSArray *_fileURLs;
	NSMutableArray *_itemViews;
	CGFloat _itemOffset;
	CGSize _itemSize;
	ImageBrowserSoftEdgeLayer *_softEdgeLayer;
	
	// for scrolling & UI
	CGPoint lastContentOffset;
	CGPoint lastTouchPt, firstTouchPt;
	ImageBrowserItemView *firstTouchView;
	CGFloat lastDeltaX;
	bool touchMovedYet;
	
	//CGFloat deltaContentXOffset;
}

@property(nonatomic, copy) NSArray *fileURLs;

- (void)viewDidLoad;
- (void)viewWillAppear:(BOOL)animated;
- (bool)markItemsToCache;
- (ImageBrowserItemView*) selectedView;
- (NSString*) selectedViewFilename;
- (NSURL*) selectedViewFileURL;
- (void)deleteSelectedItem;
- (void) unselectAll;

-(ImageBrowserItemView*) closestViewTo:(CGPoint)pt;
-(ImageBrowserItemView*) mostVisibleView;
-(void) scrolltoNextView:(float)dx view:(ImageBrowserItemView*) firstView;

@end
