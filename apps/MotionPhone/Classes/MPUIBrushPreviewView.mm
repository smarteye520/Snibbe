//
//  MPUIBrushPreviewView.m
//  MotionPhone
//
//  Created by Graham McDermott on 11/21/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPUIBrushPreviewView.h"
#import "Parameters.h"
#import "MShape.h"
#import "MShapeInstance.h"
#import "defs.h"
#import "mcanvas.h"
#import "MPUtils.h"

// private interface
@interface MPUIBrushPreviewView () 

- (void) createShapeInst;
- (void) onBrushChanged;

@end


@implementation MPUIBrushPreviewView
@synthesize dirty_;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        shapeInst_ = 0;
        dirty_ = true;
        
        
        self.backgroundColor = [UIColor clearColor];

        
        // set up notifications

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrushChanged) name:gNotificationBrushFillChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrushChanged) name:gNotificationBrushOrientChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrushChanged) name:gNotificationBrushShapeChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrushChanged) name:gNotificationBrushWidthChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrushChanged) name:gNotificationBGColorChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrushChanged) name:gNotificationFGColorChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrushChanged) name:gNotificationGlobalOrientationChanged object:nil];
        
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    if ( shapeInst_ )
    {
        delete shapeInst_;
    }
    
    [super dealloc];
    
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    if ( dirty_ )
    {
        [self createShapeInst];
    }
            
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState( ctx );
    
    MColor bgCol;    
    gParams->getBGColor( bgCol );

    CGContextSetRGBFillColor(ctx, bgCol[0], bgCol[1], bgCol[2], 1.0);    

    // rounded rect bg
            
    CGFloat minx = CGRectGetMinX(rect);
    CGFloat midx = CGRectGetMidX(rect);
    CGFloat maxx = CGRectGetMaxX(rect);
    CGFloat miny = CGRectGetMinY(rect);
    CGFloat midy = CGRectGetMidY(rect);
    CGFloat maxy = CGRectGetMaxY(rect);
    
    CGContextMoveToPoint(ctx, minx, midy);
    CGContextAddArcToPoint(ctx, minx, miny, midx, miny, UI_CORNER_RADIUS);
    CGContextAddArcToPoint(ctx, maxx, miny, maxx, midy, UI_CORNER_RADIUS);
    CGContextAddArcToPoint(ctx, maxx, maxy, midx, maxy, UI_CORNER_RADIUS);
    CGContextAddArcToPoint(ctx, minx, maxy, minx, midy, UI_CORNER_RADIUS);
    
    CGContextClosePath(ctx);        
    CGContextFillPath(ctx);

    
    if ( shapeInst_ )
    {
        shapeInst_->drawOntoCanvas( ctx, true );
    }
    

    CGContextRestoreGState( ctx );    
    
}


#pragma mark private implementation

//
//
- (void) createShapeInst
{

    if ( shapeInst_ )
    {
        delete shapeInst_;
        shapeInst_ = nil;
    }
    
    MShape * shape = gParams->brushShape();
    if ( shape )
    {
        // to account for the rotated subview
        const float rotToAugment = ((180.0f/360.0f) *  M_PI * 2.0);        
        const float rotOrientToAugment = gParams->brushOrient() ? ((45.0f/360.0f) *  M_PI * 2.0) : 0.0f;
        
        shapeInst_ = shape->createInstance();
        CGPoint centerPt = CGPointMake( self.frame.size.width * 0.5f, self.frame.size.height * 0.5f );
        float rot = [MPUtils thetaAugForBrushStroke];
        rot += rotToAugment;
        rot += rotOrientToAugment;
        rot = -rot;
        
        shapeInst_->transform( centerPt, CGPointZero, 1.0f, gParams->brushWidth() * gMCanvas->scale(), rot, false );        
    }
    
    
    self.dirty_ = false;
    
    
}

//
//
- (void) onBrushChanged
{
    self.dirty_ = true;
    [self createShapeInst];
    
    [self setNeedsDisplay];
}

@end
