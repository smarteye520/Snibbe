/*
     File: ThumbnailView.h
 Abstract: A UIView subclass

*/

#include "defs.h"
#import <UIKit/UIKit.h>

@interface ThumbnailView : UIView
{
	NSURL	*pdfURL;
}

@property (nonatomic) NSURL *pdfURL;

//-(void)setURL:(NSURL *)url;

@end