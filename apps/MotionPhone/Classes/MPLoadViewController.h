//
//  MPLoadViewController.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPUIViewControllerHiding.h"

@interface MPLoadViewController : MPUIViewControllerHiding <UIScrollViewDelegate>
{
    IBOutlet UIView *viewMainBG_;
    IBOutlet UIImageView *imageViewTest_;

    // iPhone only
    IBOutlet UIView * viewBlackBar_;
    
    UIScrollView *scrollView_;
    UIScrollView *scrollViewDummy_;
    
    IBOutlet UIButton * buttonLoad_;
    IBOutlet UIButton * buttonDelete_;

    IBOutlet UIImageView * imageViewLeft_;
    IBOutlet UIImageView * imageViewRight_;

    int iLastPage_;
}


- (IBAction) onLoadButton: (id) sender;
- (IBAction) onDeleteButton: (id) sender;

@end
