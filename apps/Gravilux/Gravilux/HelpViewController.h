//
//  HelpViewController.h
//  Gravilux
//
//  Created by Colin Roache on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpViewController : UIViewController
@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, nonatomic) IBOutlet UIImageView *imageView;
- (IBAction)dismiss:(id)sender;

@end
