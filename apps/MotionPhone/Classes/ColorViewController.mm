//
//  ColorViewController.mm
//  MotionPhone
//
//  Created by Scott Snibbe on 5/16/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import "defs.h"
#import "Parameters.h"
#import "ColorViewController.h"
#import "mcanvas.h"
#import "mbrush.h"

//#define COLORWIDTH 28
//#define COLORHEIGHT 14

//@implementation ColorViewController
//
//@synthesize alphaSlider;
//
//
//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}
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
///*
//// Implement loadView to create a view hierarchy programmatically, without using a nib.
//- (void)loadView
//{
//}
//*/
//
//#define SWATCH_TOUCH_EXPAND 40
//
//// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//    
//    alphaSlider.transform = CGAffineTransformRotate(alphaSlider.transform, -M_PI_2);
//    
//    [self buildColorView:bgSwatchesImageView];
//    [self buildColorView:fgSwatchesImageView];
//    
//    bgSwatchesTouchRect = CGRectMake(bgSwatchesImageView.frame.origin.x - SWATCH_TOUCH_EXPAND,
//                                     bgSwatchesImageView.frame.origin.y - SWATCH_TOUCH_EXPAND,
//                                     bgSwatchesImageView.frame.size.width + 2*SWATCH_TOUCH_EXPAND,
//                                     bgSwatchesImageView.frame.size.height + 2*SWATCH_TOUCH_EXPAND);
//    
//    fgSwatchesTouchRect = CGRectMake(fgSwatchesImageView.frame.origin.x - SWATCH_TOUCH_EXPAND,
//                                     fgSwatchesImageView.frame.origin.y - SWATCH_TOUCH_EXPAND,
//                                     fgSwatchesImageView.frame.size.width + 2*SWATCH_TOUCH_EXPAND,
//                                     fgSwatchesImageView.frame.size.height + 2*SWATCH_TOUCH_EXPAND);
//    
//    [self updateUIFields:false];
//}
//
//- (void)viewWillAppear:(BOOL)animated
//{
//    [self updateUIFields:false];
//}
//
////
////
//- (void) viewWillDisappear:(BOOL)animated
//{  
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"SessionParamsChanged" object:nil];  
//}
//
//// Override to allow orientations other than the default portrait orientation.
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//	
//    
//    return NO;
//    
//    if (IS_IPAD)
//	{		
//		return YES;
//	}
//	else
//	{
//        return NO;
//	}	
//}
//
//static void
//drawSwatch(CGContextRef ctx, float r, float g, float b, CGRect box, int i, int rows, int cols)
//{	
//    
//    
//	CGContextSetRGBFillColor(ctx, r, g, b, 1.0);
//	
//	// draw rectangle
//	box.origin.x = (float) (i % COLORWIDTH) * box.size.width;
//	box.origin.y = (float) (i / COLORWIDTH) * box.size.height;
//	
//	CGContextFillRect(ctx, box);
//}
//
//- (void) buildColorView:(UIImageView *)cView
//{
//	CGSize size = cView.frame.size;
//	UIGraphicsBeginImageContext(size);
//    [cView.image drawInRect:CGRectMake(0, 0, size.width, size.height)];
//	
//    //sets the style for the endpoints of lines drawn in a graphics context
//    CGContextRef ctx = UIGraphicsGetCurrentContext();	
//    //CGContextSaveGState(ctx);
//    
//    //cgcontextset
//    
//
//    
//    //CGContextScaleCTM( ctx, 2.0, 2.0 );
//    
//	swatchBoxSize.width = size.width / COLORWIDTH;
//	swatchBoxSize.height = size.height / COLORHEIGHT;
//    
//	CGRect box = CGRectMake(0, 0, swatchBoxSize.width, swatchBoxSize.height);
//
//    // dgm - just using image view to get old UI working
//    
//    MColor c;
//    for (int i=0; i < NCOLORS; i++) {
//        gParams->indexToColor(i, c);
//        drawSwatch(ctx, c[0], c[1], c[2], box, i, COLORWIDTH, COLORHEIGHT);
//    }
//	
//	cView.image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//    //CGContextRestoreGState(ctx);
//}
//
//
//- (void)viewDidUnload
//{
//    [super viewDidUnload];
//    // Release any retained subviews of the main view.
//    // e.g. self.myOutlet = nil;
//}
//
//- (void)drawBrush
//{
//    
//    // dgm - come back to this with new UI
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
////    CGContextSetRGBFillColor(ctx, c[0], c[1], c[2], c[3]);
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
////    // override width
////    w = brushImageView.frame.size.height / 2;
////    
////    p1[X] = brushImageView.frame.size.width * 0.5 - w * 0.5;
////    p2[X] = brushImageView.frame.size.width * 0.5 + w * 0.5;
////    
////    /*
////     // not sure what's up here - dgm
////    // special cases
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
////    gMBrush->set_pts(p1, p2, w, theta);
////    CGContextSetLineCap(ctx, kCGLineCapButt);
////    CGContextSetLineWidth(ctx, 3.0f);
////    gMBrush->drawOntoCanvas(ctx);
////    
////    brushImageView.image = UIGraphicsGetImageFromCurrentImageContext();
////    
////    UIGraphicsEndImageContext();
//}
//
//// Fill in text and graphic fields based on current values
//- (void)updateUIFields:(bool)animate
//{
//    // set brush alpha
//    [alphaSlider setValue:gParams->brushAlpha()];
//    
//    [self drawBrush];
//    
//    // move crosshairs to selected colors
//    CGPoint p;
//    p.x = bgSwatchesImageView.frame.origin.x + (gParams->getBGColorIndex()%COLORWIDTH) * swatchBoxSize.width + swatchBoxSize.width* 0.5;
//    p.y = bgSwatchesImageView.frame.origin.y + (gParams->getBGColorIndex()/COLORWIDTH) * swatchBoxSize.height + swatchBoxSize.height * 0.5;
//    [self animateView:bgCrossHairs toPosition: p];
// 
//    p.x = fgSwatchesImageView.frame.origin.x + (gParams->getFGColorIndex()%COLORWIDTH) * swatchBoxSize.width + swatchBoxSize.width* 0.5;
//    p.y = fgSwatchesImageView.frame.origin.y + (gParams->getFGColorIndex()/COLORWIDTH) * swatchBoxSize.height + swatchBoxSize.height * 0.5;
//    [self animateView:fgCrossHairs toPosition: p];
//
//	[self.view setNeedsDisplay];
//}
//
//-(IBAction) setBrushAlpha:(UISlider *)sender {
//    
//    gParams->setBrushAlpha(sender.value);
//    
//	[self updateUIFields:NO];    
//}
//
//// Scales down the view and moves it to the new position. 
//- (void)animateView:(UIImageView *)theView toPosition:(CGPoint) thePosition
//{
//	[UIView beginAnimations:nil context:NULL];
//	[UIView setAnimationDuration:0.05];
//	// Set the center to the final postion
//	theView.center = thePosition;
//	// Set the transform back to the identity, thus undoing the previous scaling effect.
//	theView.transform = CGAffineTransformIdentity;
//	[UIView commitAnimations];	
//}
//
//-(int) updateColorWithPosition:(CGPoint) position view:(UIView*)colorView
//{
//	CGPoint p;
//	
////	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
////	{	// iPhone only: compensate for subview location
////		position.x -= swatchesSubView.frame.origin.x;
////		position.y -= swatchesSubView.frame.origin.y;
////	}
//	
//	p.x = position.x - colorView.frame.origin.x;	
//	p.y = position.y - colorView.frame.origin.y;
//	
//	if (p.x <= 0) p.x = 1;
//	if (p.y <= 0) p.y = 1;
//	if (p.x >= colorView.frame.size.width) 
//		p.x = colorView.frame.size.width-1;
//	if (p.y >= colorView.frame.size.height) 
//		p.y = colorView.frame.size.height-1;
//	
//    
//    
//    UIImageView *crossHairView = colorView == bgSwatchesImageView ? bgCrossHairs : fgCrossHairs;
//    
//	CGPoint crossHairPos = CGPointMake(colorView.frame.origin.x + p.x,
//									   colorView.frame.origin.y + p.y);
//	
//	[self animateView:crossHairView toPosition: crossHairPos];
//	
//	
//	// get color from image
//    int colorIndex = floor(p.y / swatchBoxSize.height) * COLORWIDTH + floor(p.x / swatchBoxSize.width);
//	
////    MCOLOR_COPY(color, colors[colorIndex]);
//    return colorIndex;
//}
//
//-(void) dispatchTouchEvent:(CGPoint)position
//{
////    MColor c;
//	
//	//if (CGRectContainsPoint(swatchesImageView.frame,position))
//    if (CGRectContainsPoint(bgSwatchesTouchRect, position))
//	{
//		int colorIndex = [self updateColorWithPosition:position view:bgSwatchesImageView];    
//        gParams->setBGColorIndex(colorIndex);
//        
//        [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationChangedBGColor object:nil];
//	}
//	else if (CGRectContainsPoint(fgSwatchesTouchRect, position))
//    {
//		int colorIndex = [self updateColorWithPosition:position view:fgSwatchesImageView]; 
//         gParams->setFGColorIndex(colorIndex);
//	}	
//    
//	[self updateUIFields:NO];
//}
//
//
//
//// Handles the start of a touch
//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//{
//	for (UITouch *touch in touches) {
//		[self dispatchTouchEvent:[touch locationInView:self.view]];
//		//	printf("X IS %f\n",[touch locationInView:self].x);
//		//		printf("Y IS %f\n",[touch locationInView:self].y);
//	}	
//}
//
//// Handles the continuation of a touch.
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
//{  
//	for (UITouch *touch in touches){
//		[self dispatchTouchEvent:[touch locationInView:self.view]];
//	}
//	
//}
// 
//
//@end
