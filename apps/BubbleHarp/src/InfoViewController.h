//
//  InfoViewController.h
//  Bubble Harp
//
//  Created by Scott Snibbe on 5/30/10
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#include "defs.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

class Parameters;

@interface InfoViewController : UIViewController <UIWebViewDelegate> {
			
	IBOutlet UIWebView 	*__unsafe_unretained infoWebView;
}

@property(unsafe_unretained, readonly, nonatomic) UIWebView	*infoWebView;

- (IBAction)dismissAction:(id)sender;

@end

