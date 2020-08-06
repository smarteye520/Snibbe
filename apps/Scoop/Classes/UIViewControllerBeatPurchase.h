//
//  UIViewControllerBeatPurchase.h
//  Scoop
//
//  Created by Graham McDermott on 4/4/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIViewControllerBeatPurchase : UIViewController {
    
    IBOutlet UIImageView *imageViewBackground_;
    IBOutlet UIButton *buttonBuy_;
    IBOutlet UILabel *labelCopy_;
    IBOutlet UILabel *labelExplain_;
    

}

@property (nonatomic, retain) UIImageView *imageViewBackground_;

- (void) setImageName: (NSString *) imageName;
- (void) setCopy: (NSString *) copy;

- (IBAction)onTouchedBuy:(id)sender;



@end
