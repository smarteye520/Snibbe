//
//  MShapeInstancePolygon.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/10/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#include "MShapeInstancePolygon.h"
#include "MShapePolygon.h"
#include "SnibbeSmoothLine.h"
#include "Parameters.h"
#include "mcanvas.h"


// these should produce comparable results on the canvas and in the
// preview window
#define CANVAS_SHAPE_OUTLINE_LINE_WIDTH 3.0f

// this is what actually affects the width of the generated polygon
// for stroked shapes

// used for constant width outlined polygon calculations
#define SHAPE_OUTLINE_LINE_WIDTH_COEF_CONSTANT_WIDTH_PAD 0.025f
#define SHAPE_OUTLINE_LINE_WIDTH_COEF_CONSTANT_WIDTH_PHONE 0.05f

// original value for varying width outlined polygon calculations
#define SHAPE_OUTLINE_LINE_WIDTH_COEF_VARYING_WIDTH 0.038f


//
//
MShapeInstancePolygon::MShapeInstancePolygon()
{
    
}

//
// virtual
MShapeInstancePolygon::~MShapeInstancePolygon()
{
    
}

//
// virtual
void MShapeInstancePolygon::drawGL( ofxMSAShape3D *shape3D, MColor col, bool fill, float lineWidth )
{

        
    GLuint mode =  GL_TRIANGLE_STRIP;            
    bool needsBegin = false;
    
    if ( !shape3D->hasBegun() )
    {
        needsBegin = true;
    }        
    else if ( needResetDraw( shape3D ) )
    {
        shape3D->end();
        needsBegin = true;
    }
    
    if ( needsBegin )
    {
        
        glDisable(GL_TEXTURE_2D);
                 
        shape3D->enableColor(true);
        shape3D->enableNormal(false);
        shape3D->enableTexCoord(false);
        
         shape3D->begin(mode);
    }
        
    // transparent to move from line-to-line if batched
    shape3D->setColor(0, 0, 0, 0);
    shape3D->addVertex(cachedPoints_[0].x, cachedPoints_[0].y);    
    shape3D->addVertex( cachedPoints_[1].x, cachedPoints_[1].y );                             

    
    shape3D->setColor4v(col);	
    
    for( int iPt = 0; iPt < numCachedPoints_; ++iPt )
    {           
        shape3D->addVertex( cachedPoints_[iPt].x, cachedPoints_[iPt].y );                        
    }
    
    

    if ( !fill )
    {
        // the outline tri strip requires completing the loop to the begining
        shape3D->addVertex( cachedPoints_[0].x, cachedPoints_[0].y );   
        shape3D->addVertex( cachedPoints_[1].x, cachedPoints_[1].y );   
        
        // close it out to transition to next
        shape3D->setColor(0, 0, 0, 0);
        shape3D->addVertex(cachedPoints_[0].x, cachedPoints_[0].y);        
        shape3D->addVertex( cachedPoints_[1].x, cachedPoints_[1].y );   
        
    }
    else
    {
        
        // close it out to transition to next
        shape3D->setColor(0, 0, 0, 0);
           
        shape3D->addVertex(cachedPoints_[numCachedPoints_-2].x, cachedPoints_[numCachedPoints_-2].y);        
        shape3D->addVertex( cachedPoints_[numCachedPoints_-1].x, cachedPoints_[ numCachedPoints_-1].y );                                    
                    
    }
        

    
}

//
// virtual 
void MShapeInstancePolygon::drawOntoCanvas( CGContextRef ctx, bool drawAlpha )
{
    
    
 
    if ( numCachedPoints_ <= 1 )
    {
        return;
    }
    
    MColor fgCol;    
    gParams->getFGColor( fgCol );
        
    bool fill = gParams->brushFill();
    float alpha;
    
    if (drawAlpha) 
    {
        alpha = fgCol[3];
    }
    else
    {            
        alpha = 1.0f;
    }    
    
    CGContextSetLineWidth(ctx, CANVAS_SHAPE_OUTLINE_LINE_WIDTH);
    CGContextSetRGBStrokeColor(ctx, fgCol[0], fgCol[1], fgCol[2], alpha);
    CGContextSetRGBFillColor(ctx, fgCol[0], fgCol[1], fgCol[2], alpha);
     
    CGContextBeginPath(ctx);
    
        
    CGContextMoveToPoint(ctx, cachedPoints_[0].x, cachedPoints_[0].y);
    
    
    if ( fill )
    {
    
        for( int iPt = 1; iPt < numCachedPoints_; iPt += 1 )
        {        
            CGContextAddLineToPoint( ctx, cachedPoints_[iPt].x, cachedPoints_[iPt].y );                 
        }
        
    }
    else
    {
        // for polygon outlines we create them using a tri strip, so use only every
        // other point since we're using a stroke method here
        for( int iPt = 2; iPt < numCachedPoints_; iPt += 2 )
        {        
            CGContextAddLineToPoint( ctx, cachedPoints_[iPt].x, cachedPoints_[iPt].y );             
        }        
    }
                    
    
    CGContextClosePath( ctx );


    
    if (fill) 
    {     
        CGContextFillPath(ctx);
    } 
    else 
    {    
        CGContextStrokePath(ctx);     
    }     
    
}



//
// virtual
void MShapeInstancePolygon::transform( CGPoint pos, CGPoint movementVector, float stretch, float shapeScale, float rot, bool fill )
{
    MShapePolygon * shapePoly = (MShapePolygon *) pShape_;
    
    int numPts = shapePoly->getNumPolyPoints();
    GLuint solidDrawMode = pShape_->getSolidDrawMode();
    
    if ( needsTransform( pos, stretch, shapeScale, rot, fill ) )
    {
                
        CGPoint cachedWorkingPoints[MAX_POLYGON_POINTS];        
        
        
        float cosRot = cosf( rot );
        float sinRot = sinf( rot );
        bool allowShear = pShape_->getAllowShear();
        bool constrainShearX = pShape_->getConstrainShearXDir();        
        bool bFanStrip = solidDrawMode == GL_TRIANGLE_FAN && fill;
        
        numCachedPoints_ = 0;        
        
        // transform the points to the cached points array based on the params
        
        for( int iPt = 0; iPt < numPts; ++iPt )
        {
            
            CGPoint curPt;
            
            if ( constrainShearX && allowShear )
            {
                // special case 
                
                curPt.x = ( shapePoly->points_[iPt].x * stretch * cosRot - shapePoly->points_[iPt].y * sinRot ) * shapeScale;
                curPt.y = ( shapePoly->points_[iPt].x * sinRot + shapePoly->points_[iPt].y * cosRot ) * shapeScale; 
                
            }
            else
            {
                
                // rotation + general scale
                
                
                curPt.x = ( shapePoly->points_[iPt].x * cosRot - shapePoly->points_[iPt].y * sinRot ) * shapeScale;
                curPt.y = ( shapePoly->points_[iPt].x * sinRot + shapePoly->points_[iPt].y * cosRot ) * shapeScale;            
                
                // shearing calculation
                
                //NSLog( @"move vec: %f, %f\n", movementVector.x, movementVector.y );
                
                if ( allowShear )
                {
                    float th = -atan2( movementVector.y, movementVector.x );
                    
                    rotatePoint( curPt, th );
                    curPt.x *= stretch;
                    rotatePoint( curPt, -th );
                    

                }
                
            }
            
            
            curPt.x += pos.x;
            curPt.y += pos.y;
            
            
            if ( fill )
            {
                if ( solidDrawMode == GL_TRIANGLE_STRIP )
                {
                    
                    // translate to tri strip ordering
                    
                    
                    cachedPoints_[ shapePoly->triStripPointIndices_[iPt] ] = curPt;    
                    numCachedPoints_++;
                }
                else if ( solidDrawMode == GL_TRIANGLE_FAN )
                {
                    // special case for solid draw triangle fans - we approximate them with a tri strip
                    
                    cachedPoints_[ numCachedPoints_++ ] = pos;   
                    cachedPoints_[ numCachedPoints_++ ] = curPt;   
                }
                else
                {
                    // nothing...
                }
                
            }
            else
            {
                
                cachedWorkingPoints[iPt] = curPt; 
            }
            
        }
                

        
        
        if ( !fill ) 
        {
            
            static float constantWidthCoef = IS_IPAD ? SHAPE_OUTLINE_LINE_WIDTH_COEF_CONSTANT_WIDTH_PAD : SHAPE_OUTLINE_LINE_WIDTH_COEF_CONSTANT_WIDTH_PHONE;            
            float shapeOutlineWidthCoef = ( constantOutlineWidth_ ? constantWidthCoef * gMCanvas->inverseScale() : constantWidthCoef );
                     
            // we use the points calculated as a first pass and compute a tri-strip
            // poly to achieve a smoother line than we can get with a line loop                        
            
            for ( int iSeg = 0; iSeg < numPts; ++iSeg )
            {
                CGPoint p0 = iSeg == 0 ? cachedWorkingPoints[numPts-1] : cachedWorkingPoints[iSeg-1];
                CGPoint p1 = cachedWorkingPoints[iSeg];
                CGPoint p2 = iSeg < numPts - 1 ? cachedWorkingPoints[iSeg+1] : cachedWorkingPoints[0];
                
                CGPoint toP0 = CGPointNorm( CGPointSub( p0, p1 ) );
                CGPoint toP2 = CGPointNorm( CGPointSub( p2, p1 ) );
                
                // recalculate p0 and p2 based on normalized length from p1
                p0 = CGPointAdd( p1, toP0 );
                p2 = CGPointAdd( p1, toP2 );
                
                CGPoint v = CGPointSub(p2, p0 );
                v = CGPointNorm( v );                
                CGPoint normalized = CGPointNorm( v );                                                
                
                CGPoint bisector = CGPointMake(-normalized.y, normalized.x);
                                               
                
                
                // how acute is the angle? Here we modify the strip bisector coefficient
                // to make the stroked line thicker or thinner depending on the acuteness
                // of the angle at this vertex.  It's an approximation tweaked for looking good
                // rather than actually calculating a line intersection or some other more
                // technically accurate way of maintaining a consistent stroke width.
                
                float radsBetween = CGPointAngle(toP0, toP2);
                
                const float maxCoef = 1.8f;
                const float minCoef = 0.7f;
                
                float angleCoef = 1.0f;                
                if ( radsBetween < M_PI_2 )
                {
                    // adjust the line width coefficient to be greater
                    // as the angle increases in acuteness
                    float acuteness = ( M_PI_2 - radsBetween );    
                    angleCoef = (maxCoef - 1.0f) * acuteness + 1.0f;
                }
                else
                {
                    // adjust the line width coefficient to be less
                    // as the angle decreases in acuteness
                    float acuteness = ( radsBetween - M_PI_2 );    
                    angleCoef = 1.0f - (1.0f - minCoef) * acuteness;
                }
                
                
                bisector = CGPointMult( bisector, shapeOutlineWidthCoef * angleCoef );
                
                cachedPoints_[numCachedPoints_++] = CGPointSub( p1, bisector );
                cachedPoints_[numCachedPoints_++] = CGPointAdd( p1, bisector );
                
                
                
            }
            
            
        }
         
        
        if ( bFanStrip )
        {
            
            // when we approximate a fan with a tri strip we need to finish it off
            cachedPoints_[ numCachedPoints_++ ] = cachedPoints_[0];   
            cachedPoints_[ numCachedPoints_++ ] = cachedPoints_[1];  
        }
        
        
        
        
        curStretch_ = stretch;
        curShapeScale_ = shapeScale;
        curRot_ = rot;
        curFill_ = fill;
        curPos_ = pos;
        forceNeedsTransform_ = false;
    }
}



