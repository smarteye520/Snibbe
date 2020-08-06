////
////  ToolbarViewController.mm
////  MotionPhone
////
////  Created by Scott Snibbe on 4/6/11.
////  Copyright 2011 Scott Snibbe. All rights reserved.
////
//
//#import "defs.h"
//#import "Parameters.h"
//#import "BrushViewController.h"
//#import "ColorViewController.h"
//#import "ToolbarViewController.h"
//#import "mcanvas.h"
//#import "MPNetworkManager.h"
//#import "MotionPhoneViewController.h"
//
//#define SEGMENT_BRUSH 0
//#define SEGMENT_HAND 1
//
//@implementation ToolbarViewController
//
//@synthesize toolbarView, toolSegmentedControl, brushViewController, colorViewController;
//
///*
//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}
//*/
//
//- (void)dealloc
//{
//    [super dealloc];
//}
//
//- (void)didReceiveMemoryWarning
//{
//    // Releases the view if it doesn't have a superview.
//    [super didReceiveMemoryWarning];
//    
//    // Release any cached data, images, etc that aren't in use.
//}
//
//#pragma mark - View lifecycle
//
//// Fill in text and graphic fields based on current values
//- (void)updateUIFields:(bool)animate
//{    
//	[self.view setNeedsDisplay];
//}
//
//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//    // Do any additional setup after loading the view from its nib.
//        
//    if (IS_IPAD)
//    {
//        self.brushViewController = 	
//        [[BrushViewController alloc] initWithNibName:@"brush-iPad" bundle:nil];
//
//        self.colorViewController = 	
//        [[ColorViewController alloc] initWithNibName:@"color-iPad" bundle:nil];
//
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];       
//
////            // register for orientation change notification
////            [[NSNotificationCenter defaultCenter] addObserver: self
////                                                     selector: @selector(orientationWillChange:)
////                                                         name: UIApplicationWillChangeStatusBarOrientationNotification
////                                                       object: nil];
////            [[NSNotificationCenter defaultCenter] addObserver: self
////                                                     selector: @selector(orientationDidChange:)
////                                                         name: UIApplicationDidChangeStatusBarOrientationNotification
////                                                       object: nil];
//        
//    } else
//    {
//        self.brushViewController = 	
//        [[BrushViewController alloc] initWithNibName:@"brush-iPhone" bundle:nil];
//            
//    }
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self 
//                                             selector:@selector(brushChangedHandler) name:@"BrushChanged" object:nil];
//	
//    [self updateUIFields:NO];	 
//}
//
//- (void)viewDidUnload
//{
//    [super viewDidUnload];
//    // Release any retained subviews of the main view.
//    // e.g. self.myOutlet = nil;
//}
//
//- (void)viewWillAppear:(BOOL)animated {
//	[super viewWillAppear:animated];
//	// these seem to get deleted unless re-done at each appear
////	[[NSNotificationCenter defaultCenter] addObserver:self 
////                                             selector:@selector(brushChangedHandler) name:@"BrushChanged" object:nil];	
//}
//
//-(void)viewWillDisappear:(BOOL)animated {
////	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"BrushChanged" object:nil];
//}
//
//// Override to allow orientations other than the default portrait orientation.
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//
//	// not rotating anymore at the top level!
//    return NO;
//    
//    if (IS_IPAD)
//	{		
//		if (interfaceOrientation == UIInterfaceOrientationPortrait ||
//			interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown ||
//			interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
//			interfaceOrientation == UIInterfaceOrientationLandscapeRight)
//			// The device is an iPad running iPhone 3.2 or later, support rotation, but ignore "face up"
//			return YES;
//		else 
//			return NO;
//	}
//	else
//	{
// 		// The device is an iPhone or iPod touch, exclude portrait upside down
//       if (interfaceOrientation == UIInterfaceOrientationPortrait ||
//			interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
//			interfaceOrientation == UIInterfaceOrientationLandscapeRight)
//           return YES;
//        else
//            return NO;
//	}	
//}
//
//- (bool) rotateViewToCurrent
//{
//    
//
//    // this method not needed
//    return false;
//    
//    
//    
//	bool change = true;
//	CGSize s = [[[UIApplication sharedApplication] keyWindow] bounds].size;
//	
//    
//    // now forcing portrait
//	UIDeviceOrientation orientation = UIDeviceOrientationPortrait;
//    
//    
//    
////	if (IS_IPAD)
////	{	
//    
//    //[UIView beginAnimations:nil context:NULL];
//    //[UIView setAnimationDuration:0.3];
//
//		//orientation = [[UIDevice currentDevice] orientation];
//        
//        if (orientation == UIDeviceOrientationPortrait) {
//            
//			self.view.transform = CGAffineTransformIdentity;
//            self.view.transform = CGAffineTransformMakeRotation(0);
//            self.view.bounds = CGRectMake(0.0, 0.0, s.width, s.height);
//            
//        } else if (orientation == UIDeviceOrientationLandscapeLeft) {
//            
//            self.view.transform = CGAffineTransformIdentity;
//            self.view.transform =CGAffineTransformMakeRotation(M_PI_2);
//            self.view.bounds = CGRectMake(0.0, 0.0, s.height, s.width);
//            
//        } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
//            
//            self.view.transform = CGAffineTransformIdentity;
//            self.view.transform = CGAffineTransformMakeRotation(M_PI);
//            self.view.bounds = CGRectMake(0.0, 0.0, s.width, s.height);
//            
//        } else if (orientation == UIDeviceOrientationLandscapeRight) {
//
//            self.view.transform = CGAffineTransformIdentity;
//            self.view.transform = CGAffineTransformMakeRotation(M_PI+M_PI_2);
//            self.view.bounds = CGRectMake(0.0, 0.0, s.height, s.width);
//            
//        }
//    
//    //[UIView commitAnimations];
////	}
//	return change;
//}
//
//- (void) didRotate:(NSNotification *)notification
//{		
//	// if hidden, just jump to correct rotation
////	if (self.view.hidden) {
//		if ([self rotateViewToCurrent]) {
//			// manually set the status bar orientation 
//			//[[UIApplication sharedApplication] setStatusBarOrientation:iOrientation];
//			
//			//[toolbarView setFrame:self.view.frame];
//		}		
////	}
//}
//
//-(void)brushChangedHandler
//{
//    // change the brush icon
//
//    // dgm - revisit this
//    
//    //UIImage *toolBarBrushImage = gParams->getToolImage(gParams->brushType(), true);    
//    //[self.toolSegmentedControl setImage:toolBarBrushImage forSegmentAtIndex:SEGMENT_BRUSH];
//
//}
//
//- (void)showToolbar:(bool)animated
//{
//    // display the UIViewController's view on top of the application window.
//    // start an animation block
//	
//	self.view.hidden = NO;
//	
//	[self updateUIFields:NO];
//	
//	[self.view setNeedsLayout];
//	[self.view layoutIfNeeded];
//	
////    // start position
////    // $$$$
////    
////	[UIView beginAnimations:nil context:NULL];
////    [UIView setAnimationDuration:0.5];
////    [UIView setAnimationDelegate:[[UIApplication sharedApplication] keyWindow]];
////    
////    // end position
////    // $$$$
////    
////    // do it
////    [UIView commitAnimations];	
//}
//
//- (void)hideToolbar:(bool)animated
//{
//}
//
//- (void)dismissPopups:(bool)animated
//{
//    if (IS_IPAD)
//    {
//        if (popoverController != nil) {
//            [popoverController dismissPopoverAnimated:animated];
//            [popoverController release];
//            popoverController = nil;
//        }
//    }
//}
//
//// called when the popover view is dismissed
//- (void)popoverControllerDidDismissPopover:
//(UIPopoverController *)pc {
//	
//    // NSLog(@"popover dismissed");  
//	popoverController = nil;
//}
//
//- (void)finishDismiss:(NSString *)animationId finished:(BOOL)finished context:(void *)context
//{
//    
//}
//
//- (IBAction)undoAction:(id)sender
//{
//    gMCanvas->onRequestUndo();
//    
//}
//
//- (IBAction)setMusic:(id)sender
//{
//    
//}
//
//- (IBAction)clearAction:(id)sender
//{
//    
//    gMCanvas->onRequestEraseCanvas();
//}
//
//- (IBAction)segmentedControlIndexChanged:(id)sender
//{
//    switch ([self.toolSegmentedControl selectedSegmentIndex]) {
//        case SEGMENT_BRUSH:
//            [self popupAction:self.toolSegmentedControl];
//            gParams->setTool( MotionPhoneTool_Brush );
//            break;
//        case SEGMENT_HAND:
//            gParams->setTool( MotionPhoneTool_Hand );
//            break;
//    }
//}
//
//- (IBAction)popupAction:(UIView*)sender
//{		
//	if (IS_IPAD)
//	{	UIViewController *contentController, *activeContentController = nil;
//		
//		if (popoverController != nil) {
//			// there's a popup already up, below we will check if it's the same one, and hide
//			activeContentController = popoverController.contentViewController;
//		}
//		
//		if (sender == toolSegmentedControl) {
//			contentController = brushViewController;
//            
//        } else if (sender == colorButton) {
//                contentController = colorViewController;
//                
//		} else if (sender == 0) {
//			contentController = nil;
//            
//		} else {
//			return;
//		}
//        
//		// hide any other popups
//		[self dismissPopups:NO];
//		
//		// just return without re-popping up the same popup we just hid
//		if (contentController == activeContentController) {
//			return;
//		}
//		
//        
//		CGSize size = [contentController.view bounds].size;
//		
//        // temp until we get new UI in
//        CGRect displayRect;
//        displayRect.size = CGSizeMake(1, 1); 
//        //displayRect.origin = CGPointMake( toolbarView.superview.frame.size.width * .5f, toolbarView.superview.frame.size.height * .5f);
//        displayRect.origin = CGPointMake( 384, 994);
//        
//        //NSLog( @"the size: %@\n", NSStringFromCGSize(size));
//        
//		contentController.contentSizeForViewInPopover = size;
//		
//		//create a popover controller
//		popoverController = [[UIPopoverController alloc]
//                             initWithContentViewController:contentController];
//		
//		popoverController.delegate = self;
//		
//
//        
//		//present the popover view non-modal with a
//		//reference to the toolbar button which was pressed
//		[popoverController presentPopoverFromRect:displayRect inView:gMPVC.view
//						 permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
//	}
//}
//
//- (IBAction)modalViewAction:(id)sender
//{
//}
//
////
////
//- (IBAction)goHomeAction:(id)sender
//{
//    [[NSNotificationCenter defaultCenter] postNotificationName: @"onHomeButtonPressed" object:nil];
//}
//
////
////
//- (IBAction)phoneAction:(id)sender
//{    
//    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationMultiplayerButtonPressed object:nil];        
//}
//
//
//@end
