////
////  BrushViewController.mm
////  Motion Phone
////
////  Created by Scott Snibbe on 4/29/11
////  Copyright 2011 Scott Snibbe. All rights reserved.
////
//
//#include "defs.h"
////#include "Parameters.h"
//#import "BrushViewController.h"
////#import <QuartzCore/QuartzCore.h>
//#import "Parameters.h"
//#import "mcanvas.h"
//#import "mbrush.h"
//
////#undef BOOL
//
//#define NOORIENT_SEGMENT_INDEX 0
//#define ORIENT_SEGMENT_INDEX 1
//
//#define FILLED_SEGMENT_INDEX 0
//#define OUTLINE_SEGMENT_INDEX 1
//
//
//#define NBRUSHTYPES 5
//
////static NSString *kFilledIconNames[] = {
////	@"line-filled-button.png", 
////	@"square-filled-button.png",
////	@"triangle-filled-button.png",
////	@"circle-filled-button.png",
////	@"chevron-filled-button.png"
////};
////
////static NSString *kUnfilledIconNames[] = {
////	@"line-line-button.png", 
////	@"square-line-button.png",
////	@"triangle-line-button.png",
////	@"circle-line-button.png",
////	@"chevron-line-button.png"
////};
////
////static NSString *kFilledOrientIconNames[] = {
////	@"line-filled-orient-button.png", 
////	@"square-filled-orient-button.png",
////	@"triangle-filled-orient-button.png",
////	@"circle-filled-orient-button.png",
////	@"chevron-filled-orient-button.png"
////};
////
////static NSString *kUnfilledOrientIconNames[] = {
////	@"line-line-orient-button.png", 
////	@"square-line-orient-button.png",
////	@"triangle-line-orient-button.png",
////	@"circle-line-orient-button.png",
////	@"chevron-line-orient-button.png"
////};
//
//@implementation BrushViewController
//
//@synthesize sizeSlider, alphaSlider, brushSegmentedControl, orientSegmentedControl, fillSegmentedControl, brushImageView;
////    filledIcons, unfilledIcons, filledOrientIcons, unfilledOrientIcons;
//
////static MBrush *mBrush_; // $$$$ make global
//
//#pragma mark-
//
//// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
//- (void)viewDidLoad {
//	
//	[super viewDidLoad];
//
////    self.filledIcons = [NSMutableArray arrayWithCapacity:NBRUSHTYPES];
////    self.unfilledIcons = [NSMutableArray arrayWithCapacity:NBRUSHTYPES];
////    self.filledOrientIcons = [NSMutableArray arrayWithCapacity:NBRUSHTYPES];
////    self.unfilledOrientIcons = [NSMutableArray arrayWithCapacity:NBRUSHTYPES];
////    
////    // load array of brush icons for all possible states
////    for (int i=0; i < NBRUSHTYPES; i++) {
////        [self.filledIcons addObject:[UIImage imageNamed:kFilledIconNames[i]]];	
////        [self.unfilledIcons addObject:[UIImage imageNamed:kUnfilledIconNames[i]]];	
////        [self.filledOrientIcons addObject:[UIImage imageNamed:kFilledOrientIconNames[i]]];	
////        [self.unfilledOrientIcons addObject:[UIImage imageNamed:kUnfilledOrientIconNames[i]]];	
////    }
//	
//	[self updateUIFields:NO];	 
//}
//
//- (void)viewWillAppear:(BOOL)animated
//{         
//	[self updateUIFields:NO];
//}
//
//- (void)viewWillDisappear:(BOOL)animated
//{
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"SessionParamsChanged" object:nil];     
//}
//
//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
//    // Release anything that's not essential, such as cached data
//}
//
//- (void)dealloc {
//	// $$$
//	
//    [super dealloc];
//}
//
//// Override to allow orientations other than the default portrait orientation.
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//	if (IS_IPAD)
//	{		
//		return YES;
//	}
//	else
//	{
//        return NO;
//	}	
//}
//
//- (void)drawBrush
//{
//    
//    // dgm - this will be replaced
//    
//    
////    MColor c;
////    
////    UIGraphicsBeginImageContext(brushImageView.frame.size);
////    
////    [brushImageView.image drawInRect:CGRectMake(0, 0, brushImageView.frame.size.width, brushImageView.frame.size.height)];
////    
////    CGContextRef ctx = UIGraphicsGetCurrentContext();
////    
////    gParams->getBGColor(c);
////    CGContextSetRGBFillColor(ctx, c[0], c[1], c[2], 1.0);
////    CGContextAddRect(ctx, CGRectMake(0, 0, brushImageView.frame.size.width, brushImageView.frame.size.height));
////    CGContextFillPath(ctx);
////    
////    gMBrush->fill = gParams->brushFill();
////    gMBrush->setBrushType( (MBrushType) gParams->brushType() );
////    gParams->getFGColor(c);
////    MCOLOR_COPY(gMBrush->color, c);
////    
////    float p1[2], p2[2], w = gParams->brushWidth(), theta=M_PI;
////   
////    p1[X] = brushImageView.frame.size.width * 0.5 - w * 0.5;
////    p2[X] = brushImageView.frame.size.width * 0.5 + w * 0.5;
////    
////    // special cases
////    // not sure what's up here - dgm
////    /*
////    if (gMBrush->type == LINE) {
////        p1[X] = brushImageView.frame.size.width * 0.5 - w * 0.125;
////        p2[X] = brushImageView.frame.size.width * 0.5 + w * 0.125;
////    }
////    if (gMBrush->type == CLOVER) {
////        theta = 0.0f;
////    }
////     */
////    
////    p1[Y] = p2[Y] = brushImageView.frame.size.height * 0.5;
////    
////    // rotate points if orienting
////    if (gParams->brushOrient())
////        theta += 20.0f * DEGREES_TO_RADIANS;
////    
////    gMBrush->set_pts(p1, p2, w, theta);
////    CGContextSetLineCap(ctx, kCGLineCapButt);
////    CGContextSetLineWidth(ctx, 3.0f);
////    gMBrush->drawOntoCanvas(ctx, false);    // draw without alpha
////    
////    brushImageView.image = UIGraphicsGetImageFromCurrentImageContext();
////    
////    UIGraphicsEndImageContext();
//}
//
//// Fill in text and graphic fields based on current values
//- (void)updateUIFields:(bool)animate
//{
////    bool brushChanged = false;
//    
////    // avoids infinite loops
////    if (self.brushSegmentedControl.selectedSegmentIndex != gParams->brushType()) {
////        self.brushSegmentedControl.selectedSegmentIndex = gParams->brushType();
////        brushChanged = true;
////    }
////    
////    if (self.orientSegmentedControl.selectedSegmentIndex != gParams->brushOrient()) {
////        self.orientSegmentedControl.selectedSegmentIndex = gParams->brushOrient();
////        brushChanged = true;
////    }
////    
////    if (self.fillSegmentedControl.selectedSegmentIndex != !gParams->brushFill()) {
////        self.fillSegmentedControl.selectedSegmentIndex = !gParams->brushFill();
////        brushChanged = true;
////    }
//    
//    // change brush images based on orient/fill
//
//    for (int i=0; i<NBRUSHTYPES; i++)
//        [self.brushSegmentedControl setImage:gParams->getToolImage(i) forSegmentAtIndex:i];
//    
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"BrushChanged" object:nil];
//
//    // orientation
//    
//    [self.orientSegmentedControl setSelectedSegmentIndex:(gParams->brushOrient() ? ORIENT_SEGMENT_INDEX : NOORIENT_SEGMENT_INDEX)];
//    
//    // fill
//
//    [self.fillSegmentedControl setSelectedSegmentIndex:(gParams->brushFill() ? FILLED_SEGMENT_INDEX : OUTLINE_SEGMENT_INDEX)];
//
//    // set brush width
//    [self.sizeSlider setValue: (gParams->brushWidth() - MIN_BRUSH_WIDTH)/(MAX_BRUSH_WIDTH - MIN_BRUSH_WIDTH) ];
//    
//    // set brush alpha
//    [self.alphaSlider setValue:gParams->brushAlpha()];
//    
//    [self drawBrush];
//    
//	[self.view setNeedsDisplay];
//}
//
//// eat touches to prevent them from being passed to window below
////- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
////}
////- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
////}
////- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
////}
//
//-(IBAction) brushIndexChanged:(id)sender {
//    
//    // this until we integrate new UI which actually hooks up shape IDs we can pass directly
//    gParams->setBrushShape( [self.brushSegmentedControl selectedSegmentIndex] + 1 );
//    
//    
//    ///gParams->setBrushType((MBrushType)[self.brushSegmentedControl selectedSegmentIndex]);
////    gMCanvas->set_brush_type([self.brushSegmentedControl selectedSegmentIndex]);
//    
//    [self updateUIFields:NO];
//}
//
//-(IBAction) orientIndexChanged:(id)sender {
//    
//    switch (self.orientSegmentedControl.selectedSegmentIndex) {
//        case NOORIENT_SEGMENT_INDEX:
//            gParams->setBrushOrient(false);
////            gMCanvas->set_auto_orient(false);
//            break;
//        case ORIENT_SEGMENT_INDEX:
//            gParams->setBrushOrient(true);
////            gMCanvas->set_auto_orient(true);
//            break;
//    }
//    
//    [self updateUIFields:NO];
//}
//
//-(IBAction) fillIndexChanged:(id)sender {
//    
//    switch (self.fillSegmentedControl.selectedSegmentIndex) {
//        case FILLED_SEGMENT_INDEX:
//            gParams->setBrushFill(true);
////            gMCanvas->set_fill(true);
//            break;
//        case OUTLINE_SEGMENT_INDEX:
//            gParams->setBrushFill(false);
////            gMCanvas->set_fill(false);
//            break;
//    }
//    
//    [self updateUIFields:NO];
//}
//
//-(IBAction) setBrushWidth:(UISlider *)sender {
//    
//    gParams->setBrushWidth(sender.value * (MAX_BRUSH_WIDTH - MIN_BRUSH_WIDTH) + MIN_BRUSH_WIDTH );
//    
//	[self updateUIFields:NO];    
//}
//
//-(IBAction) setBrushAlpha:(UISlider *)sender {
//    
//    gParams->setBrushAlpha(sender.value);
//    
//	[self updateUIFields:NO];    
//}
//
////// for done button
////- (IBAction)doneAction:(id)sender {
////	// for iPhone only
////	// dismiss this modal window
////	[self dismissModalViewControllerAnimated:YES];	
////	// rotate fixes a bug where view is resized and transparent part overlays interaction area, disabling interaction
////	[[NSNotificationCenter defaultCenter] postNotificationName:@"RotateViewToCurrent" object:nil];
////}
//
//
//@end
//
