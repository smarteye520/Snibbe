//
//  LoadViewController.h
//
//  Created by Scott Snibbe on 9/11/10.
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "defs.h"
#import "ImageBrowserViewController.h"

@interface LoadViewController : UIViewController <UIScrollViewDelegate> {
	IBOutlet UIBarButtonItem	*loadButton, *deleteButton;
@private
	ImageBrowserView *__unsafe_unretained _scrollView;
}

@property(nonatomic, unsafe_unretained) IBOutlet ImageBrowserView *scrollView;
@property(nonatomic)		UIBarButtonItem		*loadButton;
@property(nonatomic)		UIBarButtonItem		*deleteButton;

- (IBAction)loadAction:(id)sender;
- (IBAction)deleteAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

- (void)cacheFilesToLoad;
- (void)updateUI;

@end
