//
//  MotionPhoneViewController.m
//  MotionPhone
//
//  Created by Scott Snibbe on 11/12/10.
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "defs.h"
#import "MotionPhoneViewController.h"
#import "ToolbarViewController.h"
#import "MPUIKitViewController.h"
#import "SSEAGLView.h"
#import "SnibbeUtils.h"
#import "MTouchTracker.h"
#import "defs.h"
#import "SnibbeTexManager.h"
#import "MPNetworkManager.h"
#import "MPUIOrientButton.h"

#ifndef MOTION_PHONE_MOBILE
#import "MPUIViewController.h"
#else 
#import "MPPhoneUIViewController.h"
#endif


#import "UIImage+SnibbeTransformable.h"
#import "MPActionQueue.h"

#include "ofxMSAShape3D.h"
#include "Parameters.h"
#include "mcanvas.h"
#import "MShapeLibrary.h"
#import "MPStrokeTracker.h"
#import "MPUtils.h"






// Uniform index.
enum {
    UNIFORM_TRANSLATE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_COLOR,
    NUM_ATTRIBUTES
};



////////////////////////////////////////////////////////////////////////////
// private interface
////////////////////////////////////////////////////////////////////////////

@interface MotionPhoneViewController ()

    @property (nonatomic, retain) EAGLContext *context;
    @property (nonatomic, assign) CADisplayLink *displayLink;

    // general helpers

    
    - (void) randomizeColors;
    - (void) presentFadingSplash;

    - (void) updateOrientation; 
    - (CGPoint) orientVector: (CGPoint) srcVec;
    - (CGPoint) orientVectorGL: (CGPoint) srcVec;


    - (void) onDeviceOrientationChanged:(NSNotification *)notification;
    - (void) onToolModeChanged;
    - (void) onMinFrameTimeChanged;

    - (void) onMatchBegin;
    - (void) onMatchEnd;

    - (void) onChangedBGColor;

    - (void) onCanvasLoaded;

    // interface notification handlers

    - (void) onRequestEraseCanvas;
    - (void) onRequestGoHome;
    - (void) onRequestUndo;
    
    - (void) onDismissUIDeep;
    - (void) onDismissUIDeepComplete;

    // EAGLTouchDelegate methods

    - (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
    - (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
    - (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
    - (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

    // touch handling helpers

    - (void) handlePinchGesture: (UIGestureRecognizer *)sender;
    - (void) handlePanGesture: (UIGestureRecognizer *)sender; 

    - (void) createGestureRecognizers;
    - (void) releaseGestureRecognizers;
    - (void) enableGestureRecognizers;
    - (void) disableGestureRecognizers;
    - (void) updateGestureRecognizers;

    - (void) handleTouchesBeganGeneral:(NSSet *)touches;
    - (void) handleTouchesEndedGeneral:(NSSet *)touches;

    - (void) handleTouchesBeganMovedBrush:(NSSet *)touches;
    - (void) handleTouchesEndedBrush:(NSSet *)touches;

    - (void) handleTouchesBeganMovedHand:(NSSet *)touches;
    - (void) handleTouchesEndedHand:(NSSet *)touches;


    // view controller methods

    - (void) didReceiveMemoryWarning;

    // shader methods

    - (BOOL)loadShaders;
    - (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
    - (BOOL)linkProgram:(GLuint)prog;
    - (BOOL)validateProgram:(GLuint)prog;


    // session methods

    - (void) onSessionParamsChanged;


    // performance mode

    - (void) initPerformanceMode;
    - (void) updatePerformanceFGColorIndicator;
    - (bool) touchesBeganMovedPerformance:(NSSet *)touches withEvent:(UIEvent *)event;
    - (void) touchesEndedPerformance:(NSSet *)touches withEvent:(UIEvent *)event;
    - (void) updatePerformanceMode;

@end



////////////////////////////////////////////////////////////////////////////
// MotionPhoneViewController implementation
////////////////////////////////////////////////////////////////////////////

@implementation MotionPhoneViewController


@synthesize animating, context, displayLink, toolbarViewController;



//void deleteFloatCallback (CFAllocatorRef allocator,
//                          const void *value)
//{
//    delete (float*) value;
//}
//
//void deletePointCallback (CFAllocatorRef allocator,
//                          const void *value)
//{
//    delete (CGPoint*) value;
//}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ( ( self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil] ) )
    {
        //    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        //    
        //    if (!aContext)
        //    {
        //        aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        //    }
        
        // force to 1.1 OpenGL
        EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!aContext)
            NSLog(@"Failed to create ES context");
        else if (![EAGLContext setCurrentContext:aContext])
            NSLog(@"Failed to set ES context current");
        
        self.context = aContext;
        [aContext release];
        
        
        // performance mode data
        
        performanceMode_ = false;
        performanceModeFGColorUpdateTime_ = 0.0f;
        
        performanceModeBrushSizeUpdateTime_ = 0.0f;
        
        lastParamSaveCheckTime_ = 0.0f;
        curTime_ = 0.0f;
        //timeAllowNextBrushTouch_ = 0.0f;
        
#ifdef PERFORMANCE_MODE
        performanceMode_ = true;
#endif
        
        
        
        // available in iOS 4.0 and later, so we're fine here                    
        float modeDim = MAX( [UIScreen mainScreen].currentMode.size.width, [UIScreen mainScreen].currentMode.size.height );
        float screenDim = MAX( [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height );
        
        gContentScaleFactor = modeDim / screenDim;
        self.view.contentScaleFactor = gContentScaleFactor;
        SSLog( @"content scale factor is: %f\n", gContentScaleFactor );

        [(SSEAGLView *)self.view setContext:context];
        [(SSEAGLView *)self.view setFramebuffer];
        
        
        if ([context API] == kEAGLRenderingAPIOpenGLES2)
            [self loadShaders];
        
        seenValidOrientation_ = false;
        //imageViewFadeSplash = nil;
        
        animating = FALSE;
        [self setAnimationFrameInterval: 1];
        self.displayLink = nil;
        panGestureTranslationPrev_ = CGPointZero;
        pinchGestureScaleBaseline_ = SCALE_DEFAULT;
        
        gestureRecognizersInstalled_ = false;
        [self createGestureRecognizers];
        
        
        //    CFDictionaryValueCallBacks vc;
        //    vc.release = deletePointCallback;    
        //    vc.release = deleteFloatCallback;
        
        self.view.multipleTouchEnabled = true;
        
        
        [MPNetworkManager startup];
        //[SnibbeTexManager startup];
        [MShapeLibrary initLibrary];          
        
        shape3D_ = new ofxMSAShape3D;
        
        shape3D_->setSafeMode(false);
        shape3D_->enableNormal(false);
        shape3D_->enableTexCoord(true);
        shape3D_->enableColor(true);
        
        shape3D_->reserve(40000);
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        gParams = new Parameters();
        mCanvas_ = new MCanvas(screenRect.size.width, screenRect.size.height, gParams, shape3D_);
        gMCanvas = mCanvas_;
        gMBrush = new MBrush;
                
        
        if ( performanceMode_ )
        {
            [self initPerformanceMode];
        }                       
        
        [self randomizeColors];        
        gParams->setBrushWidth( (MAX_BRUSH_WIDTH - MIN_BRUSH_WIDTH) * .10 + MIN_BRUSH_WIDTH );        
        
        // load the persistent session state
        gParams->load();
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];    
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSessionParamsChanged) name:@"SessionParamsChanged" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onToolModeChanged) name:gNotificationToolModeChanged object:nil];        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMinFrameTimeChanged) name:gNotificationMinFrameTimeChanged object:nil];                
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatchBegin) name:gNotificationBeginMatch object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatchEnd) name:gNotificationEndMatch object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChangedBGColor) name:gNotificationBGColorChanged object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRequestEraseCanvas) name:gNotificationRequestEraseCanvas object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRequestGoHome) name:gNotificationRequestGoHome object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRequestUndo) name:gNotificationRequestUndo object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( presentFadingSplash ) name:gNotificationFirstValidOrientation object:nil];            
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( onCanvasLoaded ) name:gNotificationLoadedCanvas object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( onDismissUIDeep ) name:gNotificationDismissUIDeep object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( onDismissUIDeepComplete ) name:gNotificationDismissUIDeepComplete object: nil];

        
        // update brush icon
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BrushChanged" object:nil]; 
        
   
        
        // make the ui view and add it as a subview of the MotionPhoneViewController's view           
        
#ifndef MOTION_PHONE_MOBILE   
                
        uiViewController = [[MPUIViewController alloc] initWithNibName:@"MPUIViewController-iPad" bundle:nil];             
#else
        
        uiViewController = [[MPPhoneUIViewController alloc] initWithNibName:@"MPPhoneUIViewController" bundle:nil];
        uiViewController.parentVC_ = self;    

        orientButtonBackupLogo_ = [[MPUIOrientButton alloc] initWithFrame: CGRectMake(8.0f, 424.0f, 48.0f, 48.0f) ];
        [orientButtonBackupLogo_ setImageNamesOn: @"symbol_off.png" off: @"symbol_off.png"]; // the backup logo is always off
        [self.view addSubview: orientButtonBackupLogo_];
        [self.view bringSubviewToFront: orientButtonBackupLogo_];
        [orientButtonBackupLogo_ release];
        orientButtonBackupLogo_.hidden = true;
        
#endif
     
        
        [uiViewController.view setFrame: self.view.frame];
        
        [self.view addSubview: uiViewController.view];                
        [self.view bringSubviewToFront: uiViewController.view];          
        
        // hide UI in performance mode
        uiViewController.view.hidden = performanceMode_;   
        

    }
    
    return self;
    
}

- (void)awakeFromNib
{

        
}

- (void)dealloc
{
    
    
    
    
    [self releaseGestureRecognizers];
    
    [MShapeLibrary releaseLibrary];  
    //[SnibbeTexManager shutdown];
    [MPNetworkManager shutdown];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [uiViewController release];
    
    if (program)
    {
        glDeleteProgram(program);
        program = 0;
    }
    
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    
    [context release];
    
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    

    // interface
    // load ToolbarViewController from NIB
    /*
	if (IS_IPAD) {
		toolbarViewController = 	
		[[ToolbarViewController alloc] initWithNibName:@"ToolbarViewController-iPad" bundle:nil];
	} else {
		toolbarViewController = 	
		[[ToolbarViewController alloc] initWithNibName:@"ToolbarViewController" bundle:nil];
	}
        
    // Add the toolbar as a subview of the MotionPhoneViewController's view

    CGRect toolbarOrigFrame =toolbarViewController.view.frame;
    CGRect toolbarFrame = CGRectMake( toolbarOrigFrame.origin.x, self.view.frame.size.height - toolbarOrigFrame.size.height, toolbarOrigFrame.size.width, toolbarOrigFrame.size.height);
    toolbarViewController.view.frame = toolbarFrame;
    
    [self.view addSubview:toolbarViewController.view];
    [self.view bringSubviewToFront:toolbarViewController.view];
    
//    [[[UIApplication sharedApplication] keyWindow] addSubview:toolbarViewController.view];
//    [[[UIApplication sharedApplication] keyWindow] bringSubviewToFront:toolbarViewController.view];
    
    if ( performanceMode_ )
    {
        toolbarViewController.view.hidden = true;
    }
    else
    {
        toolbarViewController.view.hidden = false;
        [toolbarViewController showToolbar:false];

    }
     */
    
    //[self startAnimation];
    
}

- (void)viewWillAppear:(BOOL)animated
{
//    [self startAnimation];
    
    
    [super viewWillAppear:animated];
}
 

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAnimation];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
    if (program)
    {
        glDeleteProgram(program);
        program = 0;
    }

    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	self.context = nil;	
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    
    // only support portrait
    return (interfaceOrientation == UIInterfaceOrientationPortrait);	
    
//	if (IS_IPAD)
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
//		// The device is an iPhone or iPod touch, only support portrait
//		return (interfaceOrientation == UIInterfaceOrientationPortrait);		 
//	}	
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
//    self.view.transform = CGAffineTransformMakeRotation(0);
}



- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    /*
	 Frame interval defines how many display frames must pass between each time the display link fires.
	 The display link will only fire 30 times a second when the frame internal is two on a display that refreshes 60 times a second. The default frame interval setting of one will fire 60 times a second when the display refreshes at 60 times a second. A frame interval setting of less than one results in undefined behavior.
	 */
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;
        
        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating)
    {
        CADisplayLink *aDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawFrame)];
        [aDisplayLink setFrameInterval:animationFrameInterval];
        [aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = aDisplayLink;
        
        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
        animating = FALSE;
    }
}

- (void)drawFrame
{
    
    
    //curTime_ = CACurrentMediaTime();
    
    curTime_ = displayLink.timestamp;
    //NSLog( @"dur: %f\n", displayLink.duration );
    
    
    
    if ( performanceMode_ )
    {
        [self updatePerformanceMode];
    }
    
    if ( curTime_ - lastParamSaveCheckTime_ > SESSION_VAR_SAVE_INTERVAL )
    {
        gParams->saveIfDirty();
        lastParamSaveCheckTime_ = curTime_;
    }
    
    [self updateGestureRecognizers];
    
    [uiViewController update];
    
    //NSLog( @"%f\n", self.displayLink.duration );
    
    /*
    [UIDevice currentDevice] orientation
    */
    
    [(SSEAGLView *)self.view setFramebuffer];
    
	mCanvas_->drawGL(false);	// draw first to catch brushes just drawn
	mCanvas_->update( curTime_ );
    
    [[MPNetworkManager man] update: curTime_];
    
    // maybe do pen-downs here to deal with multi-touch issue? $$$
    
    [(SSEAGLView *)self.view presentFramebuffer];
    

     
}

-(void)rotatePointsToView:(int)nPoints points:(CGPoint*)points invert:(bool)invert
{
	CGSize screenSize = [[UIScreen mainScreen] bounds].size;
	CGAffineTransform xform = CGAffineTransformIdentity;
	
    //UIInterfaceOrientation currentOrientation = (UIInterfaceOrientation) [[UIDevice currentDevice] orientation];
    
	switch (deviceOrientation_) {
		default:
		case UIInterfaceOrientationPortrait:
			break;	// do nothing
		case UIInterfaceOrientationPortraitUpsideDown:
			xform = CGAffineTransformMakeTranslation(screenSize.width, screenSize.height);
			xform = CGAffineTransformRotate(xform, M_PI);
			break;
		case UIInterfaceOrientationLandscapeLeft:
			xform = CGAffineTransformMakeTranslation(screenSize.height, 0);
			xform = CGAffineTransformRotate(xform,M_PI_2);
			break;
		case UIInterfaceOrientationLandscapeRight:
			xform = CGAffineTransformMakeRotation(-M_PI_2);
			xform = CGAffineTransformTranslate(xform, -screenSize.width, 0);
			break;
	}
	
	if (invert) {
		xform = CGAffineTransformInvert(xform);
	}
	
	for (int i=0; i< nPoints; i++) {
		points[i] = CGPointApplyAffineTransform(points[i], xform);
	}
}

-(void)rotatePointsToView:(int)nPoints points:(CGPoint*)points
{
	[self rotatePointsToView:nPoints points:points invert:false];
}

-(void)rotatePointsFromView:(int)nPoints points:(CGPoint*)points
{
	[self rotatePointsToView:nPoints points:points invert:true];
}

- (void)drawBrush:(CGPoint)lastPoint currentPoint:(CGPoint)currentPoint theta:(float)theta frame: (int) curFrame forceStroke: (bool) bForce alphaCoef: (float) a touchKey: (MTouchKeyT) key;
{	    
    mCanvas_->setPenDown(true);            
	mCanvas_->draw_onto_cframe(lastPoint, currentPoint, gParams->brushWidth(), theta, key, curFrame, bForce, a );
}




#pragma mark -
#pragma mark -- private implementation -- 


#pragma mark -
#pragma mark general helper methods

////////////////////////////////////////////////////////////////////////////
// general helper methods
////////////////////////////////////////////////////////////////////////////



#pragma mark -
#pragma mark EAGLTouchDelegate methods

////////////////////////////////////////////////////////////////////////////
// EAGLTouchDelegate methods
////////////////////////////////////////////////////////////////////////////

//
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
 
    
//    bool uiActive = [uiViewController anyUISubViewsActive];
//    if ( uiActive && gParams->tool() == MotionPhoneTool_Brush && timeAllowNextBrushTouch_ < curTime_ )
//    {
//        // delay the first touch to allow the fade to process (avoid chugging artifacts)
//        timeAllowNextBrushTouch_ = curTime_ + TOOLBAR_ANIMATION_TIME_CANVAS_TOUCHDOWN + .03;
//    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationCanvasTouchDown object:nil];
    
    // special case for "performance mode"    
    if ( performanceMode_ )
    {
        [self touchesBeganMovedPerformance:touches withEvent:event];        
    }
    
    
    [self handleTouchesBeganGeneral: touches];
    
    if ( gParams->tool() == MotionPhoneTool_Brush )
    {                
        [self handleTouchesBeganMovedBrush:touches];
    }
    else if ( gParams->tool() == MotionPhoneTool_Hand )
    {
        [self handleTouchesBeganMovedHand:touches];          
    }
}

//
//
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{  
    
    // special case for "performance mode"    
    if ( performanceMode_ )
    {
        [self touchesBeganMovedPerformance:touches withEvent:event];                
    }
    
    if ( gParams->tool() == MotionPhoneTool_Brush )
    {
        [self handleTouchesBeganMovedBrush:touches];  
    }
    else if ( gParams->tool() == MotionPhoneTool_Hand )
    {
        [self handleTouchesBeganMovedHand:touches];  
    }
    
	  
}

//
//
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    
    
    
    // special case for "performance mode"    
    if ( performanceMode_ )
    {
        [self touchesEndedPerformance:touches withEvent:event];
    }
    
    if ( gParams->tool() == MotionPhoneTool_Brush )
    {
        [self handleTouchesEndedBrush:touches];
    }
    else if ( gParams->tool() == MotionPhoneTool_Hand )
    {
        [self handleTouchesEndedHand:touches];
    }
    
    [self handleTouchesEndedGeneral: touches];
	
}

//
//
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // special case for "performance mode"    
    if ( performanceMode_ )
    {
        [self touchesEndedPerformance:touches withEvent:event];
    }
    
    if ( gParams->tool() == MotionPhoneTool_Brush )
    {
        [self handleTouchesEndedBrush:touches];  
    }
    else if ( gParams->tool() == MotionPhoneTool_Hand )
    {
        [self handleTouchesEndedHand:touches];
    }
    
        [self handleTouchesEndedGeneral: touches];
	  
}



#pragma mark -
#pragma mark touch handling helper methods

////////////////////////////////////////////////////////////////////////////
// touch handling methods
////////////////////////////////////////////////////////////////////////////





//
//
- (void) handlePinchGesture: (UIGestureRecognizer *)sender 
{
    CGFloat factor = [(UIPinchGestureRecognizer *)sender scale];
    //NSLog( @"pinch factor: %f\n", factor );        
    
    mCanvas_->setScale( factor * pinchGestureScaleBaseline_ );
} 

//
//
- (void) handlePanGesture: (UIPanGestureRecognizer *)sender 
{
    
    //sender.to
    
    CGPoint translate = [sender translationInView:self.view];              
    CGPoint glTranslate = CGPointMake( translate.x, -translate.y );
    CGSize frameSize = self.view.frame.size;
    
    CGPoint normalizedGl = CGPointMake( glTranslate.x / frameSize.width, glTranslate.y / frameSize.height );
    
            
    //NSLog( @"normalized gl: %@\n", NSStringFromCGPoint( normalizedGl) );
    
    CGPoint translateDelta = CGPointSub( normalizedGl, panGestureTranslationPrev_ );
    
    float translation[2] = { translateDelta.x, translateDelta.y };
    mCanvas_->translateNormalized( translation );
        
    panGestureTranslationPrev_ = normalizedGl;

}


//
//
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return ( ( gestureRecognizer == gestureRecognizerPan_ && otherGestureRecognizer == gestureRecognizerPinch_ ) ||
            ( gestureRecognizer == gestureRecognizerPinch_ && otherGestureRecognizer == gestureRecognizerPan_ ) );
}

//
//
- (void) createGestureRecognizers
{
    
    gestureRecognizerPan_ = [[UIPanGestureRecognizer alloc]
                             initWithTarget:self action:@selector(handlePanGesture:)];
    
    gestureRecognizerPan_.delegate = self;
    
    gestureRecognizerPinch_ = [[UIPinchGestureRecognizer alloc]
                               initWithTarget:self action:@selector(handlePinchGesture:)];    
        
    gestureRecognizerPinch_.delegate = self;
}

//
//
- (void) releaseGestureRecognizers
{
    
    
    if ( gestureRecognizerPan_ )
    {
        [gestureRecognizerPan_ release];
        gestureRecognizerPan_ = 0;
    }
    
    if ( gestureRecognizerPinch_ )
    {
        [gestureRecognizerPinch_ release];
        gestureRecognizerPinch_ = 0;
    }
    
}

//
//
- (void) enableGestureRecognizers
{

    //panGestureTranslationBaseline_ = CGPointZero;
    
    [self.view addGestureRecognizer:gestureRecognizerPan_];
    [self.view addGestureRecognizer:gestureRecognizerPinch_];
    gestureRecognizersInstalled_ = true;
    
}


//
//
- (void) disableGestureRecognizers
{
    [self.view removeGestureRecognizer:gestureRecognizerPan_];
    [self.view removeGestureRecognizer:gestureRecognizerPinch_];
    gestureRecognizersInstalled_ = false;
}


//
//
- (void) updateGestureRecognizers
{

    // helps with edge cases for gesture recognizers - they shouldn't be active when
    // any toolbar sub-controls are active because they continue to absorb touches
    // and prevent UIKit controls from functioning
    
    
    
#ifndef MOTION_PHONE_MOBILE
    
    if ( gParams->tool() == MotionPhoneTool_Hand )
    {
        int iNumSubs = [uiViewController numSubControlsShown];
        if ( iNumSubs > 0 && gestureRecognizersInstalled_ )
        {
            [self disableGestureRecognizers];
        }
        else if ( iNumSubs == 0 && !gestureRecognizersInstalled_ )
        {
            [self enableGestureRecognizers];
        }
        
    }
    else
    {
        // brush mode.. no gestures
        if ( gestureRecognizersInstalled_ )
        {
            [self disableGestureRecognizers];
        }
    }
    
#else
    
    // dgm todo - gesture recoginizers on the phone
    
#endif
    
    
        
}


// 
// splash fade helper
- (void) beginSplashFade
{
    [UIView beginAnimations:@"fade_splash_screen" context:nil];
    [UIView setAnimationDuration:SPLASH_FADE_DURATION];
    
    imageViewFadeSplash.alpha = 0.0f;    
    
    [UIView commitAnimations];
}

// 
// splash fade helper
- (void) splashFadeComplete
{
    if ( imageViewFadeSplash )
    {
        [imageViewFadeSplash removeFromSuperview];
        imageViewFadeSplash = nil;
    }
}



// Select random FG and BG colors the differ enough in brightness to provide
// contrast
- (void) randomizeColors
{
    
    CGColorSpaceRef cSpaceRef = CGColorSpaceCreateDeviceRGB();
    
    
    int iNumMaxTries = 100;
    for ( int iTry = 0; iTry < iNumMaxTries; ++iTry )
    {        
        
        const MColor * fgCandidate = gParams->randomPaletteColor();
        const MColor * bgCandidate = gParams->randomPaletteColor();
        const float  * fFG = *fgCandidate;
        const float  * fBG = *bgCandidate;
        
        // determine whether there's enough brightness difference between them    
        
        CGColorRef refFG = CGColorCreate( cSpaceRef, fFG );
        CGColorRef refBG = CGColorCreate( cSpaceRef, fBG );
        
        float brightnessFG = colorBrightness( refFG );
        float brightnessBG = colorBrightness( refBG );
        
        CGColorRelease( refFG );
        CGColorRelease( refBG );
        
        const float minBrightnessDelta = .30f;        
        
        if ( fabsf( brightnessBG - brightnessFG ) >= minBrightnessDelta )
        {
            gParams->setFGColor( *fgCandidate );
            gParams->setBGColor( *bgCandidate );
            break;
        }
        
    }
    
    CGColorSpaceRelease( cSpaceRef );
}


//
//
- (void) presentFadingSplash
{
     
    
    
    NSString * imageName = nil;
    float rotation = 0.0f;
    
    CGRect iPadBounds = CGRectZero;
    
    float longDim = MAX( self.view.frame.size.width, self.view.frame.size.height );
    float shortDim = MIN( self.view.frame.size.width, self.view.frame.size.height );
    
    // due to some wonkiness with iPad retina, doing a huge workaround here to properly
    // load and display a @2x image as a fading splash screen
    
    if ( IS_IPAD )
    {

        
        switch (deviceOrientation_)
        {
            case UIDeviceOrientationLandscapeLeft:
            {
                imageName = @"Splash-Landscape.png";
                rotation = M_PI * 0.5f;
                iPadBounds = CGRectMake(0, 0, longDim, shortDim);
                break;
            }
            case UIDeviceOrientationLandscapeRight:
            {               
                imageName = @"Splash-Landscape.png";
                rotation = -M_PI * 0.5f;
                iPadBounds = CGRectMake(0, 0, longDim, shortDim);
                break;
            }
            case UIDeviceOrientationPortraitUpsideDown:
            {                                
                imageName = @"Splash-Portrait.png";
                rotation = M_PI;
                iPadBounds = CGRectMake(0, 0, shortDim, longDim);
                break;
            }
            case UIDeviceOrientationPortrait:
            default:
            {                
                imageName = @"Splash-Portrait.png";
                iPadBounds = CGRectMake(0, 0, shortDim, longDim);
                break;
            }
            
        }
                
    }
    else
    {
        imageName = @"Splash.png";
    }
    
   
    
   
    UIImage * imageFadeSplash = [UIImage imageNamed: imageName];

    
    if ( imageFadeSplash )
    {
        [self.view bringSubviewToFront: imageViewFadeSplash];
        imageViewFadeSplash.image = imageFadeSplash;
        
        if ( IS_IPAD )
        {        
            // manually position and rotate on the iPad
            imageViewFadeSplash.transform = CGAffineTransformMakeRotation( rotation );
            imageViewFadeSplash.bounds = iPadBounds;
        }
        

        // now start the fade anim
        [self performSelector:@selector(beginSplashFade) withObject:nil afterDelay:SPLASH_FADE_DELAY];
        [self performSelector:@selector(splashFadeComplete) withObject:nil afterDelay:SPLASH_FADE_DELAY + SPLASH_FADE_DURATION + .1f ]; // add small fudge factor to ensure fade is complete
    }
    
    
    
}

//
//
- (void) updateOrientation
{
    
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    switch (orientation)
	{
		case UIDeviceOrientationPortrait:
  		case UIDeviceOrientationPortraitUpsideDown:
        case UIDeviceOrientationLandscapeLeft:
  		case UIDeviceOrientationLandscapeRight:
        {
            
  			deviceOrientation_ = orientation;   

            UIDeviceOrientation oldOrient = gDeviceOrientation;
            gDeviceOrientation = orientation;
            
            if ( !seenValidOrientation_ )
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationFirstValidOrientation object:nil];
                seenValidOrientation_ = true;
            }
            
            if ( oldOrient != gDeviceOrientation )
            {
                [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationGlobalOrientationChanged object:nil];
            }

            break;
        }               
		case UIDeviceOrientationFaceUp :
  		case UIDeviceOrientationFaceDown :
  		default:
        {
			// do nothing
    		break;
        }
	}        
    
    
}



// modify the vector based on the device orientation.
// the view is always oriented the same way (portrait), so 
// use the device orientation to get the viewer oriented vector
- (CGPoint) orientVectorGL: (CGPoint) srcVec
{
    
    // in the case where we aren't orienting the brush to the direction of the stroke
    // we need to modify the theta to reflect the user's device orientation so that
    // the symbol appears face-up
    switch (deviceOrientation_) 
    {
        case UIDeviceOrientationPortrait:
        {
           return CGPointMake( srcVec.x, -srcVec.y );                      
        }
        case UIDeviceOrientationPortraitUpsideDown:
        {
            return CGPointMake( -srcVec.x, -srcVec.y );
        }
        case UIDeviceOrientationLandscapeLeft:
        {
            return CGPointMake( srcVec.y, srcVec.x );
        }
        case UIDeviceOrientationLandscapeRight:
        {
            return CGPointMake( -srcVec.y, -srcVec.x );
        }                        
        default:
        {
            break;
        }
    }
    
    return srcVec;
}

// modify the vector based on the device orientation.
// the view is always oriented the same way (portrait), so 
// use the device orientation to get the viewer oriented vector
- (CGPoint) orientVector: (CGPoint) srcVec
{
    
    // in the case where we aren't orienting the brush to the direction of the stroke
    // we need to modify the theta to reflect the user's device orientation so that
    // the symbol appears face-up
    switch (deviceOrientation_) 
    {
        case UIDeviceOrientationPortrait:
        {
            return srcVec;                        
        }
        case UIDeviceOrientationPortraitUpsideDown:
        {
            return CGPointMake( -srcVec.x, -srcVec.y );
        }
        case UIDeviceOrientationLandscapeLeft:
        {
            return CGPointMake( -srcVec.y, -srcVec.x );
        }
        case UIDeviceOrientationLandscapeRight:
        {
            return CGPointMake( srcVec.y, -srcVec.x );
        }                        
        default:
        {
            break;
        }
    }

    return srcVec;
    
}

//
//
- (void) onDeviceOrientationChanged:(NSNotification *)notification
{
    [self updateOrientation];
    
    //UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];    
    //NSLog( @"orientation: %d\n", orientation );
}

//
// notification that the tool mode has changed (hand vs. brush)
- (void) onToolModeChanged
{

    [self disableGestureRecognizers];
    
    if ( gParams->tool() == MotionPhoneTool_Hand )
    {
        [self enableGestureRecognizers];
        mCanvas_->setDrawGrid( true );        
        
    }
    else
    {
        mCanvas_->setDrawGrid( false );
    }
    
    
}

//
// notification handler for change to minimum frame time
- (void) onMinFrameTimeChanged       
{
    mCanvas_->setMinFrameTime( gParams->minFrameTime() );
    mCanvas_->set_frame_direction( gParams->frameDir() );
}


//
// notification handler for change to frame dir
- (void) onFrameDirectionChanged       
{
    mCanvas_->setMinFrameTime( gParams->minFrameTime() );
    mCanvas_->set_frame_direction( gParams->frameDir() );
}




//
// send the initial canvas state to all peers
- (void) doSendCanvas
{       
    mCanvas_->sendCanvasToPeers();
}

//
// notification responder for multiplayer match beginning
- (void) onMatchBegin
{
    mCanvas_->destroyPeerFramesForAllPlayers();
    
    
    // now create separate frame collections for each peer    
    std::vector<unsigned int> peerHashIDs;
    [[MPNetworkManager man] collectPeerIDHashValues: &peerHashIDs];
    
    int iNumPeers = peerHashIDs.size();
    for ( int i = 0; i < iNumPeers; ++i )
    {
        mCanvas_->ensurePeerFramesCreatedForPlayer( peerHashIDs[i] );
    }
       
    // delay here so that the network manager has time to recognize it's in a network seesion
    // (order of ops issue)
    [self performSelector:@selector(doSendCanvas) withObject:nil afterDelay:.1f];    
    
}

//
// notification responder for multiplayer match ending
- (void) onMatchEnd
{
    mCanvas_->destroyPeerFramesForAllPlayers();    
}

//
// the background color has changed
- (void) onChangedBGColor
{    
    if ( mCanvas_ )
    {
        mCanvas_->onBGColorChanged();
    }
}

//
// a load has taken place
- (void) onCanvasLoaded
{
    
    if ( [[MPNetworkManager man] multiplayerSessionActive] )
    {
        // a message to erase the canvase should have already been taken care of in the
        // loading process.
        
        // finally sync the canvas
        mCanvas_->sendCanvasToPeers();
    }
}

#pragma mark interface notification handlers

- (void) onRequestEraseCanvas
{
    mCanvas_->onRequestEraseCanvas();
}

- (void) onRequestGoHome
{
    mCanvas_->goHome();
}

- (void) onRequestUndo
{
    mCanvas_->onRequestUndo();
}

//
//
- (void) onDismissUIDeep
{
#ifdef  MOTION_PHONE_MOBILE    
    orientButtonBackupLogo_.hidden = false;    
#endif
}

- (void) onDismissUIDeepComplete
{
#ifdef  MOTION_PHONE_MOBILE    
    orientButtonBackupLogo_.hidden = true;
#endif
}


#pragma mark EAGLTouchDelegate methods


//
//
- (void) handleTouchesBeganGeneral:(NSSet *)touches
{
 
    // general regarless of mode
    if ( MTouchTracker::Tracker().numTouchesTracked() == 0 )
    {
        // reset the translation baseline
        panGestureTranslationPrev_ = CGPointZero;
        
        // reset the scale baseline
        pinchGestureScaleBaseline_ = mCanvas_->scale();
    }
}

//
//
- (void) handleTouchesEndedGeneral:(NSSet *)touches
{
    
    for (UITouch *touch in touches)     
    {
        MPStrokeTracker::Tracker().removeStroke( touch );
    }
                                                 
    
    if ( MTouchTracker::Tracker().numTouchesTracked() == 0 )
    {
        mCanvas_->setPenDown(false);
        mCanvas_->onTouchSequenceEnd();
    }    
}



- (void)handleTouchesBeganMovedBrush:(NSSet *)touches
{
    
    
//    if ( timeAllowNextBrushTouch_ > curTime_ )
//    {
//        return;
//    }
    
    bool bFirstTouch = MTouchTracker::Tracker().numTouchesTracked() == 0;     
    

    if ( bFirstTouch )
    {
        if ( gParams->brushOrient() )
        {
            // smooth out single touches a bit for brushes that orient
            mCanvas_->queueBrushStrokes( true );
            mCanvas_->setNumBrushStrokesToQueue( 3 );
        }
        
        // initial touch in a sequence
        mCanvas_->onTouchSequenceBegin();
    }
    
	for (UITouch *touch in touches)     
    {
        
		CGPoint currentPoint = [touch locationInView: [touch view]];
        
        // this is no longer necessary
        
        //NSLog( @"touch pt: %@\n", NSStringFromCGPoint( currentPoint ) );        
        // convert to transformation of current device orientation, so that openGL screen remains fixed
        //
        // under current coordinate system the device gl window is considered to be in portrait
        // with the origin at the upper left corner.        
        //[self rotatePointsFromView:1 points:&currentPoint];        
        //NSLog( @"pt: %@\n", NSStringFromCGPoint( currentPoint ) );

        
        
        MTouchData trackedTouchData;
        bool    bTouchIsTracked = MTouchTracker::Tracker().getDataForTouch( touch, trackedTouchData );
                       
		if ( !bTouchIsTracked ) 
        {	
			// beginning, don't do any drawing, start tracking the touch		
            
            
            
            trackedTouchData.posOriginal_ = trackedTouchData.pos_ = trackedTouchData.prevPos_ = trackedTouchData.posLastOrient_ = currentPoint;
            trackedTouchData.orientation_ = UNINIT_ORIENTATION;            
            trackedTouchData.orientationValid_ = false;  
            
            // when we're not orienting we don't need to wait until the stroke has moved a distance to determine orientation
            if ( !gParams->brushOrient() )
            {
                trackedTouchData.orientation_ = [MPUtils thetaAugForBrushStroke];            
                trackedTouchData.orientationValid_ = true;                              
            }
            
            trackedTouchData.drawnThisFrame_ = true; // we skip the first frame
            trackedTouchData.everDrawn_ = false;
            trackedTouchData.numFrames_ = 1;            
            trackedTouchData.touchKey_ = touch;
            
            MTouchTracker::Tracker().setDataForTouch( touch, trackedTouchData );                     			            
		} 
        else 
        {                        
            
            if ( trackedTouchData.performanceTouch_ )
            {
                // this touch was initiated in a hidden performance control - skip this processing
                continue;
            }
            
			// continuing a touch

            float currentTheta = 0.0f;            
            float thetaAugForOrientation = 0.0f;                                                                                                
            bool bDraw = true;

            thetaAugForOrientation = [MPUtils thetaAugForBrushStroke];            
            
            
            if ( gParams->brushOrient() )
            {
                
                
                
                
                bool bFarEnoughFromOrig = true;
                
                if ( !trackedTouchData.orientationValid_ )
                {
                                
                    CGPoint deltaOrig;
                    deltaOrig.x = trackedTouchData.posOriginal_.x - currentPoint.x;
                    deltaOrig.y = trackedTouchData.posOriginal_.y - currentPoint.y;
                    
                    float deltaOrigDistSquared = deltaOrig.x * deltaOrig.x + deltaOrig.y * deltaOrig.y;
                    bFarEnoughFromOrig = deltaOrigDistSquared >  MIN_DIST_ORIENT_SECOND_TOUCH_SQUARED;
                }
                
                
                if ( !trackedTouchData.orientationValid_ && !bFarEnoughFromOrig )
                {
                    // waiting for far enough second point, do nothing                
                    bDraw = false;
                } 
                else                                         
                {    
                    CGPoint delta;
                    delta.x = trackedTouchData.posLastOrient_.x - currentPoint.x;
                    delta.y = trackedTouchData.posLastOrient_.y - currentPoint.y;
                    
                    float deltaDistSquared = delta.x * delta.x + delta.y * delta.y;

                                        
                    if ( deltaDistSquared > MIN_DIST_ORIENT_UPDATE_SQUARED || trackedTouchData.numFrames_ < FRAME_NUM_ORIENT_DIST_TEST_BEGIN )
                    {
                        currentTheta = -atan2f(delta.y, delta.x);                                                                            
                        currentTheta += thetaAugForOrientation;                        
                        
                        
                        // keep both cur and last theta positive and in the range of (0, pi*2)
                        if( currentTheta < 0 )
                        {                            
                            currentTheta += TWOPI;
                        }
                        else
                        {       
                            currentTheta = fmodf(currentTheta, TWOPI);
                        }                                                
                        
                        float lastTheta = trackedTouchData.orientation_;
                        if ( lastTheta < 0 )
                        {
                            lastTheta += TWOPI;
                        }
                        else
                        {       
                            lastTheta = fmodf(lastTheta, TWOPI);
                        }
                                                

                        if ( fabs( currentTheta - lastTheta ) > MIN_RADIANS_WRAP_AROUND )
                        {
                            // here we catch the wrap around from 2 pi to 0 and augment the
                            // low value so that our filter calculation doesn't produce an
                            // in appropriate middle value
                            
                            float * pMin = &currentTheta;
                            float * pMax = &lastTheta;
                            if ( lastTheta < currentTheta )
                            {
                                pMax = &currentTheta;
                                pMin = &lastTheta;
                            }
                            
                            *pMin += TWOPI;
                            
                            
                        }
                        
                        // filter point to smooth out
                        if ( trackedTouchData.numFrames_ >= FRAME_NUM_THETA_FILTER_BEGIN )
                        {
                            currentTheta = (1.0f - THETA_FILTER) * lastTheta + THETA_FILTER * currentTheta;                            
                        }

                        if ( !trackedTouchData.orientationValid_ )
                        {
                            // first time... since we're waiting to draw until we have a clear line in the case
                            // don't interp from the prev position because we get an unwanted intermediate shape

                            CGPoint toOrig = CGPointSub( trackedTouchData.posOriginal_, currentPoint );
                            CGPoint shortened = CGPointMult(toOrig, .001);
                            CGPoint newPreviousPt = CGPointAdd( currentPoint, shortened );
                            
                            trackedTouchData.prevPos_ = newPreviousPt;
                            trackedTouchData.pos_ = newPreviousPt;
                            
                        }
                        
                        currentTheta = fmodf(currentTheta, TWOPI);                                                
                        trackedTouchData.orientationValid_ = true;
                        trackedTouchData.posLastOrient_ = currentPoint;

                        
                        
                    }
                    else
                    {
                        currentTheta = trackedTouchData.orientation_;
                        trackedTouchData.orientationValid_ = true;
                    }
                                                                            
                }                

            }
            else
            {
                currentTheta = thetaAugForOrientation;
            }
            
            if ( bDraw )
            {
                
                if ( trackedTouchData.drawnThisFrame_ && !gParams->allowMultipleSamplesPerFrameAtCurrentFramerate() )
                {
                    // skip this - special case so we don't draw 2 frames at once at max framerate
                    // and cause an alpha flicker effect
                    
                }
                else
                {
                
                    ++trackedTouchData.numFrames_;
                    float alpha = gParams->fadeStrokes() ? trackedTouchData.calculateTouchAlpha() : 1.0f;                                                            
                    
                    [self drawBrush: trackedTouchData.prevPos_ currentPoint:currentPoint theta: currentTheta frame: mCanvas_->inq_cframe() forceStroke:false alphaCoef:alpha touchKey: trackedTouchData.touchKey_ ];                                          
                    
                    
                    // store last values   
                    trackedTouchData.prevPos_ = trackedTouchData.pos_;                    
                    trackedTouchData.pos_ = currentPoint;
                    trackedTouchData.orientation_ = currentTheta;
                    trackedTouchData.drawnThisFrame_ = true;
                    trackedTouchData.everDrawn_ = true;
                    
                    MTouchTracker::Tracker().setDataForTouch( touch, trackedTouchData );
                }
            }

            
		}
		
	}
    
}

//
//
- (void)handleTouchesEndedBrush:(NSSet *)touches
{
    
    mCanvas_->flushBrushStrokeQueue();
    
    

    
    
	for (UITouch *touch in touches) 
    {                
        
        mCanvas_->processStrokeEndForTouch( touch );
                        
        
        // intent of this was to provide feedback from a tap, but need to do this another way as it produces an unsatisfying blip
        
        /*
         
        MTouchData trackedTouchData;
        bool bTouchIsTracked = MTouchTracker::Tracker().getDataForTouch( touch, trackedTouchData );
        if ( bTouchIsTracked )
        {
            if ( !trackedTouchData.everDrawn_ )
            {
                // draw it!
                
                // fake the prev and next points - exploits the brush implementation.
                // not great style but special case.
                
                CGPoint prev = CGPointMake( trackedTouchData.pos_.x + 1.0f, trackedTouchData.pos_.y + 1.0f );
                CGPoint cur = CGPointMake( trackedTouchData.pos_.x - 1.0f, trackedTouchData.pos_.y - 1.0f );
                
                [self drawBrush: prev currentPoint: cur theta: 0.0f ];
            }
        }
         */
        
        
        // here we can fade out the stroke
        // this isn't reading well
        
//        MTouchData touchData;
//        bool bFoundData = MTouchTracker::Tracker().getDataForTouch( touch, touchData );
//        int curFrame = mCanvas_->inq_cframe();
//        float alphaIncrement = 1.0f / (NUM_TOUCH_FADE_FRAMES + 1);        
//        float curAlpha = 1.0f - alphaIncrement;
//        
//        
//        if ( bFoundData )
//        {
//            for ( int i = 0; i < NUM_TOUCH_FADE_FRAMES; ++i )
//            {
//
//                [self drawBrush:touchData.pos_ currentPoint:touchData.pos_ theta:touchData.orientation_ frame:curFrame forceStroke:true alphaCoef: curAlpha];
//                
//                curAlpha -= alphaIncrement;
//                curFrame += 1;
//                curFrame = curFrame % N_FRAMES;
//            }
//            
//            
//        }
        
        MTouchTracker::Tracker().removeTouch( touch );                
	}
    

}



//
// touch handling for hand tool mode
- (void)handleTouchesBeganMovedHand:(NSSet *)touches
{
    

    
	for (UITouch *touch in touches)     
    {                
        
        MTouchData trackedTouchData;
        bool    bTouchIsTracked = MTouchTracker::Tracker().getDataForTouch( touch, trackedTouchData );
        
		if ( !bTouchIsTracked ) 
        {	

            // store dummy values (hand tool mode)
            trackedTouchData.prevPos_ = CGPointZero;
            trackedTouchData.pos_ = CGPointZero;
            trackedTouchData.posLastOrient_ = CGPointZero;
            trackedTouchData.orientation_ = UNINIT_ORIENTATION;
            trackedTouchData.drawnThisFrame_ = false;
            trackedTouchData.everDrawn_ = false;
            
            MTouchTracker::Tracker().setDataForTouch( touch, trackedTouchData );  
            
		} 
        else 
        {                        
            // nothing
			                        
		}
		
	}
         
    
}

//
// touch handling for hand tool mode
- (void)handleTouchesEndedHand:(NSSet *)touches
{
    
    
	for (UITouch *touch in touches) 
    {                
        MTouchTracker::Tracker().removeTouch( touch );                
	}
        
    
    if ( MTouchTracker::Tracker().numTouchesTracked() == 0 )
    {
        // nothing
    }
    
}




#pragma mark -
#pragma mark UIViewController methods

////////////////////////////////////////////////////////////////////////////
// UIViewController methods
////////////////////////////////////////////////////////////////////////////


//
//
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}



#pragma mark -
#pragma mark shader methods

////////////////////////////////////////////////////////////////////////////
// shader methods
////////////////////////////////////////////////////////////////////////////

//
//
- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(program, ATTRIB_COLOR, "color");
    
    // Link program.
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        
        return FALSE;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_TRANSLATE] = glGetUniformLocation(program, "translate");
    
    // Release vertex and fragment shaders.
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return TRUE;
}

//
//
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}

//
//
- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

//
//
- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}


#pragma mark -
#pragma mark session methods

////////////////////////////////////////////////////////////////////////////
// multiplayer methods
// -------------------
// most Multiplayer functionality is handled in the MPNetworkManager module,
// but code that interacts with UIKit classes is done 
////////////////////////////////////////////////////////////////////////////



//
//
- (void) multiplayerInit;
{

    // this will authenticate the local player... always should be done as soon as
    // possible after startup
    [[MPNetworkManager man] onMultiplayerInit];
    [MPUIKitViewController getUIKitViewController].matchMakerDelegate_ = [MPNetworkManager man];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationFinalizeMultiplayerInit object:nil];
    
    
}






#pragma mark -
#pragma mark session methods

////////////////////////////////////////////////////////////////////////////
// session methods
////////////////////////////////////////////////////////////////////////////

// method called when notification is received that session parameters have changed.
// save them so that they persist.
- (void) onSessionParamsChanged
{
    if ( gParams )
    {
        gParams->save();
    }
}

#pragma mark -
#pragma mark performance mode methods

////////////////////////////////////////////////////////////////////////////
// performance mode methods
// ------------------------
// these methods are specifically for a particular mode of operation intended for
// performances - standard controls are hidden though some functionality is
// exposed through invisible controls.
////////////////////////////////////////////////////////////////////////////

#define PERF_CONT_WIDTH_PERCENT 0.050f

#define TIME_SINCE_UPDATE_FADE_CONTROL 0.1f
#define TIME_SINCE_UPDATE_HIDE_CONTROL 0.3f

#define TIME_IN_PERFORMANCE_CONTROL_REGISTER_THRESHOLD 0.1f

//
// small color swatch in the top right corner that shows the current foreground color
- (void) updatePerformanceFGColorIndicator
{
    // for now update both each time
    performanceModeFGColorUpdateTime_ = curTime_;
    gDrawPerformanceFGColorIndicator = true;
    gPerformanceFGColorIndicatorAlpha = 1.0f;
    
    performanceModeBrushSizeUpdateTime_ = curTime_;
    gDrawPerformanceBrushSizeIndicator = true;
    gPerformanceBrushSizeIndicatorAlpha = 1.0f;
}

//
// small color swatch in the top right corner that shows the current foreground color
- (void) updatePerformanceBrushSizeIndicator
{
    // for now update both each time
    performanceModeFGColorUpdateTime_ = curTime_;
    gDrawPerformanceFGColorIndicator = true;
    gPerformanceFGColorIndicatorAlpha = 1.0f;
    
    performanceModeBrushSizeUpdateTime_ = curTime_;
    gDrawPerformanceBrushSizeIndicator = true;
    gPerformanceBrushSizeIndicatorAlpha = 1.0f;
    
}



//
//
- (void) initPerformanceMode
{
        
    gDrawPerformanceFGColorIndicator = false;
    gPerformanceFGColorIndicatorAlpha = 0.0f;
    
    gDrawPerformanceBrushSizeIndicator = false;
    gPerformanceBrushSizeIndicatorAlpha = 0.0f;
    
}
                                                                            


//
//
- (bool) ptIsInPerformanceControlBGColor: (CGPoint) pt;
{
    CGSize frameSize = self.view.frame.size;    
    float controlWidth = frameSize.height * PERF_CONT_WIDTH_PERCENT;
    
    float stripTotal = frameSize.width - controlWidth;
    float grayArea = stripTotal * .25;
    // only grays
    
    return ( pt.y >= frameSize.height - controlWidth &&
             pt.x <= frameSize.width - controlWidth &&
             pt.x >= ( stripTotal - grayArea ) );
    
}

//
//
- (bool) ptIsInPerformanceControlFGColor: (CGPoint) pt;
{

    CGSize frameSize = self.view.frame.size;    
    float controlWidth = frameSize.height * PERF_CONT_WIDTH_PERCENT;
 
    return ( pt.y <= controlWidth &&                     
             pt.x <= frameSize.width - controlWidth );
}

//
//
- (bool) ptIsInPerformanceControlBrushSize: (CGPoint) pt;
{
    CGSize frameSize = self.view.frame.size;    
    float controlWidth = frameSize.height * PERF_CONT_WIDTH_PERCENT;
    
    return ( pt.x > frameSize.width - controlWidth );
    
}

//
//
- (bool) ptIsInPerformanceControlAreaAny: (CGPoint) pt
{
    return ( [self ptIsInPerformanceControlBGColor: pt] ||
             [self ptIsInPerformanceControlFGColor: pt] ||
             [self ptIsInPerformanceControlBrushSize: pt] );
}

// No real controls are used for performance mode - just tracking touches and interpreting
// positions to indicate control value changes.  All done in code.
// calculations assume portrait mode.  
- (bool) touchesBeganMovedPerformance:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    
    bool bHandled = false;
    CGSize frameSize = self.view.frame.size;

    float controlWidth = frameSize.height * PERF_CONT_WIDTH_PERCENT;
    
    
    for ( UITouch * touch in touches )
    {
        
        MTouchData trackedTouchData;
        bool    bTouchIsTracked = MTouchTracker::Tracker().getDataForTouch( touch, trackedTouchData );
        bool    bPerformanceTouch = false;
        if ( bTouchIsTracked )
        {
            bPerformanceTouch = trackedTouchData.performanceTouch_;
        }
                

        CGPoint pt = [touch locationInView: touch.view];
        
        // we're getting some unexpected numbers back from this call - the x range
        // seems to be off by about 8 pixels despite the view hierarchy all looking correct.
        
        pt.x = MAX( pt.x, 0 );
        pt.x = MIN( pt.x, frameSize.width );
        
        //NSLog( @"pt: %@\n", NSStringFromCGPoint(pt ) );
        
        
        bool bPerformanceAreaAny = [self ptIsInPerformanceControlAreaAny: pt];
        if ( !bTouchIsTracked && bPerformanceAreaAny )
        {
            // we need to start a timer to delay activation of the performance control
            
            trackedTouchData.performanceControlTouchBeginTime_ = curTime_;
        }
        
        double performanceControlElapsedTime = curTime_ - trackedTouchData.performanceControlTouchBeginTime_;
        bool timeThresholdPassed = performanceControlElapsedTime > TIME_IN_PERFORMANCE_CONTROL_REGISTER_THRESHOLD;
                 
        bool bPerformanceAreaBG = [self ptIsInPerformanceControlBGColor: pt];
        bool bPerformanceAreaFG = [self ptIsInPerformanceControlFGColor: pt];
        bool bPerformanceAreaBrushSize = [self ptIsInPerformanceControlBrushSize: pt];
        
                
        // here we check for whether the touch is has remained in the performance control zone for the
        // entirety of a fixed threshold of time.  If it exits at any point before the time threshold it
        // never gets considered a control gesture
        
        if ( !timeThresholdPassed )
        {          

            if ( ( trackedTouchData.performanceBGColorTouch_ && !bPerformanceAreaBG ) ||
                 ( trackedTouchData.performanceFGColorTouch_ && !bPerformanceAreaFG ) ||
                 ( trackedTouchData.performanceBrushSizeTouch_ && !bPerformanceAreaBrushSize ) )                    
            {
                // we're outside any controls and the time threshold has not passed
                MTouchTracker::Tracker().removeTouch( touch );
                continue;
            }            
            
        }
        
        if ( !bTouchIsTracked || bPerformanceTouch )
        {
            if ( trackedTouchData.performanceBGColorTouch_ ||
                 ( !bTouchIsTracked && 
                  [self ptIsInPerformanceControlBGColor: pt] ) )
            {
                // we're changing the bgcolor
                
                //float stripHeight = frameSize.width - controlWidth;
                //float normalized = pt.x / stripHeight;     
                
                float stripTotal = frameSize.width - controlWidth;
                float grayArea = stripTotal * .25;
                float colorArea = stripTotal - grayArea;
                float normalized = (pt.x - colorArea) / grayArea;
                
                normalized = .75f + normalized * .25f;
                
                //normalized = 1.0f - normalized; // switch it
                normalized = MIN( normalized, 0.999f );
                normalized = MAX( normalized, 0.75f );
             
                if ( timeThresholdPassed )
                {
                    gParams->setBGColorIndex( normalized * NCOLORS );
                }
                
                //NSLog( @"setting bg color norm: %f, index: %d\n", normalized, (int)(normalized * NCOLORS) );
                
                trackedTouchData.performanceBGColorTouch_ = true;
                
                bHandled = true;
            }
            else if ( trackedTouchData.performanceFGColorTouch_ ||
                      (!bTouchIsTracked && 
                       [self ptIsInPerformanceControlFGColor: pt] ) )                                
            {
                // we're changing the fg color
                
                // the color indicator area should also prevent shape drawing
                if ( pt.x < controlWidth )
                {
                    pt.x = controlWidth;
                }
                
                float stripHeight = frameSize.width - controlWidth;
                float normalized = pt.x / stripHeight;                
                
                normalized = MIN( normalized, 0.999f );
                normalized = MAX( normalized, 0.0f );                                
                
                if ( timeThresholdPassed )
                {
                    gParams->setFGColorIndex( normalized * NCOLORS );                    
                    [self updatePerformanceFGColorIndicator];
                }
                
                //NSLog( @"setting fg color norm: %f, index: %d\n", normalized, (int)(normalized * NCOLORS) );
                
                trackedTouchData.performanceFGColorTouch_ = true;
                
                bHandled = true;
            }
            else if ( trackedTouchData.performanceBrushSizeTouch_ ||
                     ( !bTouchIsTracked &&
                      [self ptIsInPerformanceControlBrushSize: pt] ) )                
            {
                // brush size!

                
                float stripLen = frameSize.height;
                float normalized = pt.y / stripLen;
                normalized = 1.0f - normalized;
                
                float brushWidth = normalized * (MAX_BRUSH_WIDTH - MIN_BRUSH_WIDTH) + MIN_BRUSH_WIDTH;
                
                if ( timeThresholdPassed )
                {
                    gParams->setBrushWidth( brushWidth );
                    [self updatePerformanceBrushSizeIndicator];
                }
                
                trackedTouchData.performanceBrushSizeTouch_ = true;
                bHandled = true;
                
                
            }
            
            if ( !bTouchIsTracked && bHandled )
            {
                // we register this touch as a performance touch to avoid conflict with drawing in regular mode
                trackedTouchData.performanceTouch_ = true;
                MTouchTracker::Tracker().setDataForTouch( touch, trackedTouchData );  
            }
        }
        
        
        //NSLog( @"frame: %@, pt: %@\n", NSStringFromCGRect( self.view.frame ), NSStringFromCGPoint(pt) );
    }
    
    //NSLog( @"frame: %@\n", NSStringFromCGRect( self.view.frame ) );
    
    return bHandled;
}

// No real controls are used for performance mode - just tracking touches and interpreting
// positions to indicate control value changes.  All done in code.
// calculations assume portrait mode. 
- (void) touchesEndedPerformance:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGSize frameSize = self.view.frame.size;
    float controlWidth = frameSize.height * PERF_CONT_WIDTH_PERCENT;
    
    for ( UITouch * touch in touches )
    {
        
        CGPoint pt = [touch locationInView: self.view];
        
        if ( pt.x >= frameSize.width - controlWidth &&
            pt.y <= controlWidth &&
            touch.tapCount == 1 )
        {
            // it's an erase         
            gMCanvas->onRequestEraseCanvas();
        }
        
    }
    
}


// called once a frame in performance mode, updating any control values
// that require it.
//
// a bit messy copied code for both controls right now.  code should be encapsulated in
// control objects if we actually expand this
- (void) updatePerformanceMode
{
    
    if ( performanceMode_ )
    {

        
        // first update the fg color indicator alpha
        
        if ( !fuzzyCompare( gPerformanceFGColorIndicatorAlpha, 0.0f ) )
        {
            
            // do we have any active touches that apply to the fg color control?

            MTouchData * curData = MTouchTracker::Tracker().getFirstData();
            while( curData )
            {
                if ( curData->performanceFGColorTouch_ )
                {
                    // reset the clock for hiding the fg color indicator
                    performanceModeFGColorUpdateTime_ = curTime_;
                }
                curData = MTouchTracker::Tracker().getNextData();
            }
            
            
            if ( curTime_ - performanceModeFGColorUpdateTime_ > TIME_SINCE_UPDATE_FADE_CONTROL )
            {
                if ( curTime_ - performanceModeFGColorUpdateTime_ > TIME_SINCE_UPDATE_HIDE_CONTROL )
                {
                    gPerformanceFGColorIndicatorAlpha = 0.0f;
                    gDrawPerformanceFGColorIndicator = false;
                }
                else
                {
                    float timeIntoFade = ((curTime_ - performanceModeFGColorUpdateTime_) - TIME_SINCE_UPDATE_FADE_CONTROL);
                    float totalFadeTime = TIME_SINCE_UPDATE_HIDE_CONTROL - TIME_SINCE_UPDATE_FADE_CONTROL;
                    gPerformanceFGColorIndicatorAlpha = 1.0f - timeIntoFade / totalFadeTime;
                    gPerformanceFGColorIndicatorAlpha = MIN( gPerformanceFGColorIndicatorAlpha, 1.0f );
                    gPerformanceFGColorIndicatorAlpha = MAX( gPerformanceFGColorIndicatorAlpha, 0.0f );
                }
            }
    
        }
    
        // now the brush size indicator alpha
    
        if ( !fuzzyCompare( gPerformanceBrushSizeIndicatorAlpha, 0.0f ) )
        {
            
            // do we have any active touches that apply to the brush size control?
            
            MTouchData * curData = MTouchTracker::Tracker().getFirstData();
            while( curData )
            {
                if ( curData->performanceBrushSizeTouch_ )
                {
                    // reset the clock for hiding the brush size indicator
                    performanceModeBrushSizeUpdateTime_ = curTime_;
                }
                curData = MTouchTracker::Tracker().getNextData();
            }
            
            
            if ( curTime_ - performanceModeBrushSizeUpdateTime_ > TIME_SINCE_UPDATE_FADE_CONTROL )
            {
                if ( curTime_ - performanceModeBrushSizeUpdateTime_ > TIME_SINCE_UPDATE_HIDE_CONTROL )
                {
                    gPerformanceBrushSizeIndicatorAlpha = 0.0f;
                    gDrawPerformanceBrushSizeIndicator = false;
                }
                else
                {
                    float timeIntoFade = ((curTime_ - performanceModeBrushSizeUpdateTime_) - TIME_SINCE_UPDATE_FADE_CONTROL);
                    float totalFadeTime = TIME_SINCE_UPDATE_HIDE_CONTROL - TIME_SINCE_UPDATE_FADE_CONTROL;
                    gPerformanceBrushSizeIndicatorAlpha = 1.0f - timeIntoFade / totalFadeTime;
                    gPerformanceBrushSizeIndicatorAlpha = MIN( gPerformanceBrushSizeIndicatorAlpha, 1.0f );
                    gPerformanceBrushSizeIndicatorAlpha = MAX( gPerformanceBrushSizeIndicatorAlpha, 0.0f );
                }
            }
            
        }            
        
    }
        
    
    
}




@end
