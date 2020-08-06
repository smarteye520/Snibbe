//
//  MPShapeSetViewController.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/22/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPShapeSetViewController.h"
#import "MShapeSet.h"
#import "MShape.h"
#import "MPUIOrientButton.h"
#import "Parameters.h"
#import "defs.h"

// private interface
@interface MPShapeSetViewController() 

- (void) createShapeButtons;
- (void) onShapeButtonSelected: (id) sender;

// notification handlers
- (void) onActiveShapeChanged;

@end


@implementation MPShapeSetViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        shapeSet_ = nil;
        shapeButtons_ = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onActiveShapeChanged) name:gNotificationBrushShapeChanged object:nil];
    }
    return self;
}

- (void) dealloc
{
    
    [shapeButtons_ release];
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createShapeButtons];
    [self onActiveShapeChanged];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark private implementation

//
//
- (void) createShapeButtons
{
    [shapeButtons_ removeAllObjects];
    
    
    // on iPad they increase in y-dir, on iPhone in x-dir
    
    
    float curY = 18.0f;
    float curX = 0.0f;
    const float buttonSpacing = 18.0f;
    const float buttonWidth = 36.0f;
    
#ifdef MOTION_PHONE_MOBILE

    curY = 18.0f;
    curX = 18.0f;
    
#endif
    
    if ( shapeSet_ )
    {
        int iNumShapes = [shapeSet_ numShapes];
        for ( int iS = iNumShapes-1; iS >= 0; --iS )
        {
            MShape *s = [shapeSet_ shapeAtIndex: iS];
            if ( s )
            {
                
                CGRect buttonFrame = CGRectMake( curX, curY, buttonWidth, buttonWidth );
                
#ifdef MOTION_PHONE_MOBILE
                curX += buttonWidth;
                curX += buttonSpacing;
#else
                curY += buttonWidth;
                curY += buttonSpacing;
#endif
                MPUIOrientButton *newButton = [[MPUIOrientButton alloc] initWithFrame: buttonFrame];                
                
                NSString * stringIconOff = [NSString stringWithFormat: @"%s%s", s->getIconRootName(), ICON_OFF_POSTFIX];
                NSString * stringIconOn = [NSString stringWithFormat: @"%s%s", s->getIconRootName(), ICON_ON_POSTFIX];
                
                [newButton setImageNamesOn: stringIconOn off: stringIconOff ];
                newButton.tag = (int) s->getShapeID(); // stuff the shape id into the button's tag for later retrieval
                [scrollView_ addSubview: newButton];                
                
                [newButton addTarget:self action:@selector(onShapeButtonSelected:) forControlEvents:UIControlEventTouchUpInside];                
                
                [shapeButtons_ addObject: newButton];
                [newButton release];
                
            }
        }
        
        CGSize contentS;
        
     
#ifdef MOTION_PHONE_MOBILE
        contentS.width = curX - buttonSpacing;
        contentS.height = self.view.frame.size.height;
#else
        contentS.width = self.view.frame.size.width;
        contentS.height = curY - buttonSpacing;
#endif        
        
        scrollView_.contentSize = contentS;
    }
    
    
    
}

//
//
- (void) onShapeButtonSelected: (id) sender
{

    MPUIOrientButton * button = (MPUIOrientButton *) sender;
    if ( button )
    {
        int iShapeID = button.tag;
        gParams->setBrushShape( iShapeID ); 
    }
}

//
//
#pragma mark notification handlers

//
//
- (void) onActiveShapeChanged
{
    // the current shape has changed globally.  Change the highlighted button!

    if ( gParams->brushShape() )
    {
        int iActiveShapeID = gParams->brushShape()->getShapeID();
        for ( MPUIOrientButton * curButton in shapeButtons_ )
        {
            [curButton setOn: (iActiveShapeID == curButton.tag) ];
        }
    }
}

#pragma mark public implementation

//
//
- (void) setShapeSet: (MShapeSet *) s
{
    shapeSet_ = s;
    
}

@end
