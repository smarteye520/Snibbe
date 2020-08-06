//
//  SaveViewController.h
//  bubbleharp
//
//  Created by Scott Snibbe on 9/11/10.
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "defs.h"
#import "ThumbnailView.h"

@interface SaveViewController : UIViewController  <UITextFieldDelegate> {
	//IBOutlet UIImageView		*thumbnailView;
	//IBOutlet UIWebView		*thumbnailWebView;
	IBOutlet ThumbnailView		*thumbnailView;
	IBOutlet UITextField		*titleField;
	IBOutlet UIView				*scrollView;
	
	float	deltaKbdOffset_;
	bool	kbdVisible_;
}

//@property(nonatomic,retain)		UIImageView	*thumbnailView;
//@property(nonatomic,retain)		UIWebView	*thumbnailWebView;
@property(nonatomic)		ThumbnailView	*thumbnailView;
@property(nonatomic)		UITextField		*titleField;
@property(nonatomic)		UIView			*scrollView;

- (IBAction)saveAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)didEndOnExitAction:(UITextField*)sender;

@end
