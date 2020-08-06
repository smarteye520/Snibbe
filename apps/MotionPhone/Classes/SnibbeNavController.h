//
//  SnibbeNavController.h
//  MotionPhone
//
//  Created by Graham McDermott on 1/30/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//
//  NavigationController-style class to handle a stack of view controllers
//
//  Usage:
//  
// 
//  - first assign parentVC_.  All pushed VCs will be parented to this view controller's view
//    this class doesn't own the parent view, unlike the UIKit nav controller.
//  
//  - pushed view controllers' views become child views of parentVC_'s view.  The view
//    controllers are retained and can be released by the calling code.
//  
//  - when a VC is popped, its view is optionally animated off, then removed from the parent view.
//    The view controller is then released.
//
//  Notes:
// 
//  currently assumed that the views fill the window, or at least do so in the dimension
//  that is being animated
//
//  current doesn't hide/show views based on which is active

#import <UIKit/UIKit.h>



typedef  enum
{
    eSnibbeAnimNone = 0,
    eSnibbeAnimSlide,
    
} SnibbeNavControllerAnimStyleT;


typedef  enum
{
    eSNCUp = 0,
    eSNCRight,
    eSNCDown,
    eSNCLeft
    
} SnibbeNavControllerDirT;



@class SnibbeNavController;



//
//
@protocol SnibbeNavControllerDelegate <NSObject>

- (void) setSnibbeNavController: (SnibbeNavController *) snc;

@end


//
//
@interface SnibbeNavController : NSObject
{
    
    NSMutableArray * vcStack_;
    SnibbeNavControllerAnimStyleT animStyle_;

    SnibbeNavControllerDirT pushDir_;

    UIViewController * parentVC_;
    
}

@property (nonatomic) SnibbeNavControllerAnimStyleT animStyle_;
@property (nonatomic) SnibbeNavControllerDirT pushDir_;
@property (nonatomic, assign) UIViewController * parentVC_;


- (void) pushVC: (UIViewController<SnibbeNavControllerDelegate> *) vc;
- (void) pushVC: (UIViewController<SnibbeNavControllerDelegate> *) vc withStyle: (SnibbeNavControllerAnimStyleT) s;

- (void) popLastVC;
- (void) popLastVCWithStyle: (SnibbeNavControllerAnimStyleT) s;

- (int) numVCs;
- (UIViewController *) vcAtIndex: (int) iIndex;

- (void) clear;
- (void) clearToIndex: (int) iIndex;

@end
