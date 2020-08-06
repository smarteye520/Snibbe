/* File: ImageBrowserView.m
 
 Abstract: Image browser scroll view implementation file.
 (c) 2010 Scott Snibbe
 
 */

#import "ImageBrowserView.h"
#import "ImageBrowserItemView.h"
#import "ImageBrowserSoftEdgeLayer.h"
#import "defs.h"
#include "Parameters.h"

#import <QuartzCore/QuartzCore.h>

@implementation ImageBrowserView


- (void)viewDidLoad
{
	//self.decelerationRate = UIScrollViewDecelerationRateFast;
	//self.delaysContentTouches = NO;
	//self.scrollEnabled = NO;
	//self.canCancelContentTouches = YES;
}

- (void)viewWillAppear:(BOOL)animated 
{
	[self unselectAll];
	[self setNeedsLayout];
}

- (NSArray *)fileURLs
{
	return _fileURLs;
}

- (void)setFileURLs:(NSArray *)array
{
	if (_fileURLs != array)
    {
		_fileURLs = [array copy];
		[self setNeedsLayout];
    }
}

- (void)layoutSubviews
{
	NSInteger i, j, item_count, old_view_count;
	NSURL *url;
	//UILabel *label;
	ImageBrowserItemView *view;
	NSMutableArray *old_views;
	CGFloat x, y, sideMargin;
	CGRect bounds, frame;
	
	item_count = [_fileURLs count];
	old_views = _itemViews;
	_itemViews = [[NSMutableArray alloc] init];
	old_view_count = [old_views count];
	bounds = [self bounds];
	_itemSize = Parameters::params().thumnailSize();
	
	sideMargin = (bounds.size.width - _itemSize.width) * 0.5;
	x = sideMargin;
	y = ((bounds.size.height - _itemSize.height) - TITLE_HEIGHT) * 0.5;
	
	_itemOffset = _itemSize.width + ITEM_SPACING;
	
	for (i = 0; i < item_count; i++)
    {
		frame = CGRectMake (x, y, _itemSize.width, _itemSize.height+TITLE_SPACING+TITLE_HEIGHT);
		
		url = [_fileURLs objectAtIndex:i];
		
		for (j = 0; j < old_view_count; j++)
        {
			view = [old_views objectAtIndex:j];
			if ([[view fileURL] isEqual:url])
            {
				[view setFrame:frame];
				[old_views removeObjectAtIndex:j];
				old_view_count--;
				goto got_view;
            }
        }
		
		view = [ImageBrowserItemView itemViewWithFrame:frame fileURL:url];
		view.opaque = OPAQUE_ITEM_VIEWS ? YES : NO;
		
		[self addSubview:view];

    got_view:
		[_itemViews addObject:view];
		x += _itemSize.width + ITEM_SPACING;		
    }
	
	// expand right edge so that window scrolls to keep last item in center of window
	[self setContentSize:CGSizeMake (x+(sideMargin-ITEM_SPACING), bounds.size.height)];
	
	for (view in old_views) {
		[view removeFromSuperview];
	}
	
#if SOFT_SCROLLER_EDGES != 0
	if (_softEdgeLayer == nil)
		_softEdgeLayer = [ImageBrowserSoftEdgeLayer layer];
	
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	
	if (SOFT_SCROLLER_EDGES == 1)
		self.layer.mask = _softEdgeLayer;
	else
		[self.layer addSublayer:_softEdgeLayer];
	
	_softEdgeLayer.frame = self.bounds;
	
	[CATransaction commit];
#endif
	
	[self markItemsToCache];
}


- (bool)markItemsToCache
{
	bool changed = false;
	
	ImageBrowserItemView *view;
	for (view in _itemViews) {
		view.selected = false;	// deselect as soon as scrolling starts
		
		if (CGRectIntersectsRect(self.bounds, view.frame)) {
			if (!view.drawImage) {
				view.drawImage = true;
				changed = true;
				[view setNeedsLayout];
			}
		} else {
			if (view.drawImage) {
				view.drawImage = false;
				changed = true;
				[view setNeedsLayout];
			}
		}
	}
	return changed;
}

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
	// Return NO if you don’t want the scroll view to send event messages to view. 
	// If you want view to receive those messages, return YES (the default).
	return YES;
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
	// YES to cancel further touch messages to view, NO to have view continue to receive those messages. 
	// The default returned value is YES if view is not a UIControl object; otherwise, it returns NO.
	return NO;
}

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog(@"touchesBegan");

	for (UITouch *touch in touches) {
		firstTouchPt = [touch locationInView:self.superview];
		lastTouchPt = firstTouchPt;
		//firstTouchView = [self closestViewTo:[touch locationInView:self]];	// get first touch in scroll view coordinates
		firstTouchView = [self mostVisibleView];	// get first touch in scroll view coordinates
	}	
	lastContentOffset = self.contentOffset;
	touchMovedYet = false;
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{  
	//NSLog(@"touchesMoved");
	
	touchMovedYet = true;
	CGPoint curTouchPt;
	
	for (UITouch *touch in touches){
		curTouchPt = [touch locationInView:self.superview];
	}
	
	float deltaX = curTouchPt.x - lastTouchPt.x;
	lastDeltaX = deltaX;
	//NSLog(@"touchesMoved::deltaX = %f", deltaX);
	
	lastContentOffset.x -= deltaX;
	
	float rightStop = self.contentSize.width - _itemSize.width * 0.5;
	if (lastContentOffset.x < 0) lastContentOffset.x = 0;
	if (lastContentOffset.x > rightStop) {
		lastContentOffset.x = rightStop;
	}
	
	[self setContentOffset:lastContentOffset animated:NO];
	
	lastTouchPt = curTouchPt;
}

// Handles the continuation of a touch.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{  
	CGPoint curTouchPt;
	
	//NSLog(@"touchesEnded");

	if (touchMovedYet) {
		//[self centerScrollView];
		for (UITouch *touch in touches){
			curTouchPt = [touch locationInView:self.superview]; 
		}
		
		[self scrolltoNextView:firstTouchPt.x - curTouchPt.x view:firstTouchView];
		 
	} else {
		for (UITouch *touch in touches){
			curTouchPt = [touch locationInView:self];	// get point in scroll view
		}
		
		ImageBrowserItemView *view;
		// select the view under the finger
		for (view in _itemViews) {
			if (CGRectContainsPoint(view.frame, curTouchPt)) {
				if (view.alpha != 0)	// means it's not deleted
					view.selected = !view.selected;
			} else {
				view.selected = false;
			}
		}
	}
	// update load/delete buttons based on selection
	[[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLoadUI" object:nil];
}

-(ImageBrowserItemView*) closestViewTo:(CGPoint)pt
{
	ImageBrowserItemView *view, *closestView = nil;
	float minDx = 1e10;
	
	for (view in _itemViews) {
		if (CGRectIntersectsRect(self.bounds, view.frame)) {
			CGPoint viewCenter = CGPointMake(view.frame.origin.x + (view.frame.size.width / 2), 
											 view.frame.origin.y + (view.frame.size.height / 2));
			
			float dx = ABS(viewCenter.x - pt.x);
			
			if (dx < minDx) {
				closestView = view;
				minDx = dx;
			}
		}
	}
	return closestView;
}

-(void) scrolltoNextView:(float)dx view:(ImageBrowserItemView*) firstView
{
	if (firstView == nil) return;
	
	ImageBrowserItemView *nextView = nil;	
	
	int thisIndex = [_itemViews indexOfObject:firstView];
	int nextIndex = thisIndex + (dx > 0 ? 1 : -1);
	if (nextIndex < 0 || nextIndex >= _itemViews.count) nextIndex = thisIndex;
	nextView = [_itemViews objectAtIndex:nextIndex];
	
	if (nextView) {
		// scroll to it
		CGPoint offset = self.contentOffset;
		float sideMargin = (self.bounds.size.width - _itemSize.width) * 0.5;
		offset.x = nextView.frame.origin.x - sideMargin;
		[self setContentOffset:offset animated:YES];
	}
}

-(ImageBrowserItemView*)mostVisibleView
{
	ImageBrowserItemView *view, *mostVisibleView = nil;
	
	float maxIntersectWidth = 0;
	for (view in _itemViews) {
		if (CGRectIntersectsRect(self.bounds, view.frame)) {
			CGRect intersect = CGRectIntersection(self.bounds, view.frame);
			if (intersect.size.width > maxIntersectWidth) {
				mostVisibleView = view;
				maxIntersectWidth = intersect.size.width;
			}
		}
	}
	
	return mostVisibleView;
}

-(void)centerScrollView
{
	ImageBrowserItemView *view = [self mostVisibleView];
	
	if (view) {
		// scroll to it
		CGPoint offset = self.contentOffset;
		float sideMargin = (self.bounds.size.width - _itemSize.width) * 0.5;
		offset.x = view.frame.origin.x - sideMargin;
		[self setContentOffset:offset animated:YES];
	}
}

- (ImageBrowserItemView*) selectedView
{
	ImageBrowserItemView *view;
	for (view in _itemViews) {
		if (view.selected) {
			return view;
		}
	}
	return nil;
}

- (void) unselectAll
{
	ImageBrowserItemView *view;
	for (view in _itemViews) {
		view.selected = false;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLoadUI" object:nil];
}

- (NSString*) selectedViewFilename
{
	ImageBrowserItemView *view = [self selectedView];
	if (view)
		return [view fileName];
	
	return nil;
}

- (NSURL*) selectedViewFileURL
{
	ImageBrowserItemView *view = [self selectedView];
	if (view)
		return [view fileURL];
	
	return nil;
}

- (void)finishDelete:(NSString *)animationId finished:(BOOL)finished context:(void *)context 
{
	ImageBrowserItemView *view = (__bridge ImageBrowserItemView*)context;
	
	NSURL *deleteURL = view.fileURL;
	if (deleteURL) {
		if (![[NSFileManager defaultManager] removeItemAtPath:deleteURL.path error:nil]) {
		}
	}
	
	view.selected = false;
	view.drawImage = false;
	
	// update buttons to stop displaying trash and load
	[[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLoadUI" object:nil];

}

- (void)deleteSelectedItem
{
	// delete
	ImageBrowserItemView *view = [self selectedView];
	
	if (view) {
		// animate deletion with fade
		[UIView beginAnimations:nil context:(void *)view];
		[UIView setAnimationDuration:1.0];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(finishDelete:finished:context:)];
		
		view.alpha = 0.0;
        
		// do it
		[UIView commitAnimations];	
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	// unload images other than those visible
	if ([self markItemsToCache]) {	// returns true if there's a change

	}
	
	//NSLog(@"offset: %f", self.contentOffset.x);

	
	//deltaContentXOffset = self.contentOffset.x - lastContentOffset.x;
	//lastContentOffset = self.contentOffset;
}

#if 0
// save for another day - need to completely override scrolling and manually track, 
// keeping under thumb while touch down, and then springing to closes view on touch up

//- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	//self.decelerationRate = 0.0;	// override
	//self.decelerating = false;
	
	// compute offset to most visible view
	CGPoint offset = self.contentOffset;
	
	ImageBrowserItemView *view, *sideMostView = nil;
	bool movingLeft = deltaContentXOffset > 0;
	float lastX;
	
	if (movingLeft) lastX = 1e10;
	else lastX = -1e10;
	
	for (view in _itemViews) {
		if (CGRectIntersectsRect(self.bounds, view.frame)) {
			float centerX = view.frame.origin.x + view.frame.size.width*0.5;
			if ((movingLeft && centerX < lastX) || (!movingLeft && centerX > lastX)) {
				sideMostView = view;
				lastX = centerX;
			}
		}
	}
	
	if (sideMostView) {
		// scroll to it
		//NSLog(@"sideMostView origin.x: %f", sideMostView.frame.origin.x);
		float sideMargin = (self.bounds.size.width - _itemSize.width) * 0.5;
		offset.x = sideMostView.frame.origin.x - sideMargin;
		//offset.x -= (self.bounds.size.width - _itemSize.width) * 0.5;	// initial margin, centers view
		[self setContentOffset:offset animated:YES];
		//[view setNeedsLayout];
	}
/*	
	ImageBrowserItemView *view, *mostVisibleView = nil;
	float maxIntersectWidth = 0;
	for (view in _itemViews) {
		if (CGRectIntersectsRect(self.bounds, view.frame)) {
			CGRect intersect = CGRectIntersection(self.bounds, view.frame);
			if (intersect.size.width > maxIntersectWidth) {
				mostVisibleView = view;
				maxIntersectWidth = intersect.size.width;
			}
		}
	}
	
	if (mostVisibleView) {
		// scroll to it
		offset.x = mostVisibleView.frame.origin.x + mostVisibleView.frame.size.width*0.5;
		offset.x += (self.bounds.size.width - _itemSize.width) * 0.5;	// initial margin
		[self setContentOffset:offset animated:YES];
		[view setNeedsLayout];
	}
	*/
}
#endif
@end
