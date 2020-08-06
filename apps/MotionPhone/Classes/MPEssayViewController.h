//
//  MPEssayViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPUIViewControllerHiding.h"
#import "UIOrientView.h"

@interface MPEssayViewController : MPUIViewControllerHiding<UIWebViewDelegate, UIOrientViewDelegate>
{
    IBOutlet UIView *viewMainBG_;
    IBOutlet UIOrientView * orientView_;
    UIWebView * webView_;
}

@end
