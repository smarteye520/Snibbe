//
//  InfoViewController.h
//  Gravilux
//
//  Created by Colin Roache on 10/25/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfoViewController : UIViewController <UIWebViewDelegate> {
	IBOutlet UIWebView 	*infoWebView;
}

@property(readonly, nonatomic) UIWebView	*infoWebView;
- (IBAction)dismiss:(id)sender;
- (IBAction)learnMore:(id)sender;
@end
