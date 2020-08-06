/* mbrush.C 
 * (c) 1989-2010 Scott Snibbe
 */

#include "mbrush.H"
#include "mcanvas.h"
#include "MPArchiveBrush.h"
#include "MPActionBrush.h"

// test
#include "MShapeLibrary.h"
#include "MShapeSet.h"
#include "MShapeInstance.h"
#include "MShape.h"



//// static
//unsigned int MBrush::nextUID = 0;
//
//// 
//// static
//unsigned int MBrush::nextUniqueID()
//{
//    return nextUID++;
//}



#define N_CHEVRON_POINTS 6

MBrush::MBrush()
{
    fill = FALSE;
    shapeInstance_ = 0;
    
    centerPt_ = CGPointZero;    
    scaleX_ = 1.0f;
    scaleY_ = 1.0f;
    rot_ = 0.0f;
    ownsShapeInstance_ = true;
    constantOutlineWidth_ = DEFAULT_CONSTANT_OUTLINE_WIDTH;
        
    // test
    //shapeInstance_ = [[[MShapeLibrary lib] shapeSetAtIndex: 0] shapeAtIndex: 0]->createInstance();
}

MBrush::~MBrush()
{
    clear();
}

/*
void
MBrush::rotate_pts(
    float      *center,
    float      theta)
{
    int i;
    float x, y;

    for (i = 0; i < CACHE_SIZE; i++) {

        cache[i][X] -= center[X];
        cache[i][Y] -= center[Y];

        x = cache[i][X];
        y = cache[i][Y];

        cache[i][X] = x * cosf(theta) - y * sinf(theta);
        cache[i][Y] = x * sinf(theta) + y * cosf(theta);

        cache[i][X] += center[X];
        cache[i][Y] += center[Y];        
    }
}

void
MBrush::scale_pts(
    float      *center,
    float      sx,
    float      sy)
{
    int i;

    for (i = 0; i < CACHE_SIZE; i++) {

        cache[i][X] -= center[X];
        cache[i][Y] -= center[Y];

        cache[i][X] *= sx;
        cache[i][Y] *= sy;

        cache[i][X] += center[X];
        cache[i][Y] += center[Y];        
    }
}
*/

void
MBrush::set_pts(
    float      *from,
    float      *to,
    float      w,
    float      theta)
{
    
    
    
    float      dx, dy, length; //, perp[2], v[2];
    //float      th;//, l, zero[2] = {0,0};
    //static      float last_dx = 0.0, last_dy = 0.0;  // dgm - statics are used here... is this correct?  need to check on this
    //int         i;

    dx = to[X] - from[X];
    dy = to[Y] - from[Y];

    /*
    if (dx == 0.0 && dy == 0.0) {
        from[X] -= last_dx;
        from[Y] -= last_dy;
        dx = last_dx; dy = last_dy;
    } else {
        last_dx = dx; last_dy = dy;
    }
     */
    
    // using this instead
    //last_dx = dx; last_dy = dy;

    centerPt_.x = from[X] + dx * 0.5;
    centerPt_.y = from[Y] + dy * 0.5;

    length = sqrtf(dx*dx + dy*dy);
    
    width = w;
    rot_ = theta;
    
    /*
    v[X] = dx / length;
    v[Y] = dy / length;

    perp[X] = - dy / length * w;
    perp[Y] = dx / length * w;
*/
    
    //////////////////////////////////////////////////////////////////////////////////////
    // dgm - this is the old hardcoded shape transform code, kept for reference in case we
    // need to tweak anything to match the original version
    //////////////////////////////////////////////////////////////////////////////////////    
    
//    
//    
//    if (type == LINE) {
//        cache[0][X] = centerPt_.x - length / 2;
//        cache[0][Y] = center[Y] - w / 2;
//
//        cache[1][X] = centerPt_.x + length / 2;
//        cache[1][Y] = center[Y] - w / 2;
//
//        cache[2][X] = centerPt_.x + length / 2;
//        cache[2][Y] = center[Y] + w / 2;
//
//        cache[3][X] = centerPt_.x - length / 2;
//        cache[3][Y] = center[Y] + w / 2;
//
//        shear = FALSE;
//
//    } else if (type == TRIANGLE) {
////        float x_length = MAX(length/2, w/2);
//        float x_length = w/2;
//        float y_length = w/2;
//
//        cache[0][X] = center[X];
//        cache[0][Y] = center[Y] + y_length;
//
//        cache[1][X] = center[X] + x_length;
//        cache[1][Y] = center[Y] - y_length;
//
//        cache[2][X] = center[X] - x_length;
//        cache[2][Y] = center[Y] - y_length;
//
//        shear = TRUE;
//
///*
//        th = -atan2(dy, dx);
//        l = MAX(length, w);
//        rotate_pts(center, th);
//        scale_pts(center, l / w, 1);
//        rotate_pts(center, -th);
//*/
//    } else if (type == CIRCLE) {
//        float x_r, y_r;
//        float th;
//
//        // x_r = MAX(length, dx);
//        x_r = w/2;
//        y_r = w/2;
//
//        for (i = 0; i < CACHE_SIZE; i++) {
//            th = TWOPI / CACHE_SIZE * (float) i + TWOPI / (CACHE_SIZE * 1.3);
//            cache[i][X] = center[X] + x_r * cosf(th);
//            cache[i][Y] = center[Y] + y_r * sinf(th);
//        }
//        shear = TRUE;
///*
//        th = -atan2(dy, dx);
//        l = MAX(length, w);
//        rotate_pts(center, th);
//        scale_pts(center, l / w, 1);
//        rotate_pts(center, -th);
//*/
//    } else if (type == CLOVER) {
////        from[X] = center[X] - length * 0.5; 
////        from[Y] = center[Y];
////        to[X] = center[X] + length * 0.5;
////        to[Y] = center[Y];
////
////        perp[X] = 0;
////        perp[Y] = w*0.5;
////
////        cache[0][X] = from[X]; 
////		cache[0][Y] = from[Y];
////
////        cache[1][X] = from[X] + (from[X] - to[X]) * 0.133975 + perp[X] * 0.5;
////        cache[1][Y] = from[Y] + (from[Y] - to[Y]) * 0.133975 + perp[Y] * 0.5;
////
////        cache[2][X] = from[X] + (from[X] - to[X]) * 0.5 + perp[X];
////        cache[2][Y] = from[Y] + (from[Y] - to[Y]) * 0.5 + perp[Y];
////
////        cache[3][X] = from[X] + (from[X] - to[X]) * 0.866025 + perp[X] * 0.5;
////        cache[3][Y] = from[Y] + (from[Y] - to[Y]) * 0.866025 + perp[Y] * 0.5;
////
////        cache[4][X] = to[X]; // point sticking through
////		cache[4][Y] = to[Y];
////		
//////        cache[4][X] = cache[3][X];
//////        cache[4][Y] = cache[3][Y];
////
////        cache[5][X] = from[X] + (from[X] - to[X]) * 0.866025 - perp[X] * 0.5;
////        cache[5][Y] = from[Y] + (from[Y] - to[Y]) * 0.866025 - perp[Y] * 0.5;
////
////        cache[6][X] = from[X] + (from[X] - to[X]) * 0.5 - perp[X];
////        cache[6][Y] = from[Y] + (from[Y] - to[Y]) * 0.5 - perp[Y];
////
////        cache[7][X] = from[X] + (from[X] - to[X]) * 0.133975 - perp[X] * 0.5;
////        cache[7][Y] = from[Y] + (from[Y] - to[Y]) * 0.133975 - perp[Y] * 0.5;
//
//        cache[0][X] = center[X]+ 0.04*length;
//        cache[0][Y] = center[Y];
//        
//        cache[1][X] = center[X]- 0.5*length;
//        cache[1][Y] = center[Y]+ 0.25*w;
//        
//        cache[2][X] = center[X]- 0.5*length;
//        cache[2][Y] = center[Y]+ 0.5*w;
//        
//        cache[3][X] = center[X]+ 0.5*length;
//        cache[3][Y] = center[Y];
//        
//        cache[4][X] = center[X]- 0.5*length;
//        cache[4][Y] = center[Y]- 0.5*w;
//        
//        cache[5][X] = center[X]- 0.5*length;
//        cache[5][Y] = center[Y]- 0.25*w;
//   
//        
//    } else if (type == RECT) {
//        float x_length = w/2;
//        float y_length = w/2;
//        cache[0][X] = center[X] - x_length;
//        cache[0][Y] = center[Y] - y_length;
//
//        cache[1][X] = center[X] - x_length;
//        cache[1][Y] = center[Y] + y_length;
//
//        cache[2][X] = center[X] + x_length;
//        cache[2][Y] = center[Y] + y_length;
//
//        cache[3][X] = center[X] + x_length;
//        cache[3][Y] = center[Y] - y_length;
//        
//        shear = TRUE;
//
//
//    }

    
    p1[X] = from[X];
    p1[Y] = from[Y];
    p2[X] = to[X];
    p2[Y] = to[Y];

    if ( shapeInstance_ )        
    {      
        shapeInstance_->setConstantOutlineWidth( constantOutlineWidth_ );
        
        
        // calculate how much stretch we want.... the smaller the brush width the
        // more we allow it to stretch, since more stretching is needed to create
        // comparable impact the smaller the brush.

        float stretch = (length / w) * 0.60f;
        bool bStetch = false;
        
        static const float invMinToMaxBrushWidth = 1.0f / (MAX_BRUSH_WIDTH - MIN_BRUSH_WIDTH);    
        static const float invScaleX = 1.0f / gWinScaleDefaultX;
        static const float invUpperStretchRegion = 1.0f / (1.0f - BRUSH_STRETCH_MIDPOINT);             
        static const float invLowerStretchRegion = 1.0f / BRUSH_STRETCH_MIDPOINT;
        
        if ( stretch > 1.0f )
        {   
            float widthWindowIndependent = w * invScaleX;       
            float relativeBrushSize = (widthWindowIndependent - MIN_BRUSH_WIDTH) * invMinToMaxBrushWidth;
            
            //float savedR = relativeBrushSize;
            
            float maxStretch = 1.0f;
            
            // the mapping has two slopes, separated by a midpoint
            if ( relativeBrushSize > BRUSH_STRETCH_MIDPOINT )
            {
            
                // normalize 0 to 1 for upper region
                relativeBrushSize = (relativeBrushSize - BRUSH_STRETCH_MIDPOINT) * invUpperStretchRegion;                
                maxStretch = (MAX_STRETCH_LARGEST_BRUSH - MAX_STRETCH_MID_BRUSH) * relativeBrushSize + MAX_STRETCH_MID_BRUSH;    
                //NSLog( @"upper: %f, remapped: %f, max stretch: %f\n", savedR, relativeBrushSize, maxStretch );
            }
            else
            {

                // normalize 0 to 1 for lower region
                relativeBrushSize = relativeBrushSize * invLowerStretchRegion;                
                maxStretch = (MAX_STRETCH_MID_BRUSH - MAX_STRETCH_SMALLEST_BRUSH) * relativeBrushSize + MAX_STRETCH_SMALLEST_BRUSH;            
                
                //NSLog( @"lower: %f, remapped: %f, max stretch: %f\n", savedR, relativeBrushSize, maxStretch );

            }
            
            
            stretch = MIN( stretch, maxStretch );
            bStetch = true;            
        }
                
        
        if ( bStetch )
        {                
            CGPoint moveVec = CGPointMake( to[X] - from[X], to[Y] - from[Y] );
            shapeInstance_->transform( centerPt_, moveVec, stretch, w, theta, fill);
        }
        else
        { 
            shapeInstance_->transform( centerPt_, CGPointZero, 1.0f, w, theta, fill);
        }
                
    }
    

    /*
    rotate_pts(center, theta);

    if (shear && length > w) {
        th = -atan2f(dy, dx);
        rotate_pts(center, th);
        scale_pts(center, length / w, 1);
        rotate_pts(center, -th);
    }
     */

}

//
// Debugging draw - wireframe
void
MBrush::drawGLLines(ofxMSAShape3D *shape3D)
{
    
    // $$$ dgm - come back to this if needed
    
    /*
     
    // switch on object type
	
	// $$$$ need to change to use vertex pointers
	// and antialiasing?
	
	glLineWidth(2);
	
	int nLines;
    switch (type) {
        case NONE:
            break;
		case LINE:
		case RECT:
			nLines = 4;
			break;
		case CIRCLE:
		case CLOVER:
			nLines = 8;
			break;
		case TRIANGLE:
			nLines = 3;
			break;
	}
	
	shape3D->begin(GL_LINE_LOOP);
	
	// transparent to move from line-to-line if batched
//	shape3D->setColor(0, 0, 0, 0);
//	shape3D->addVertex(cache[0][X], cache[0][Y]);
	
	shape3D->setColor4v(color);	
	for (int i=0; i<nLines; i++) {
		shape3D->addVertex(cache[i][X], cache[i][Y]);
	}	
	// close loop
	shape3D->addVertex(cache[nLines-1][X], cache[nLines-1][Y]);
	
	// transparent to move from line-to-line if batched
//	shape3D->setColor(0, 0, 0, 0);
//	shape3D->addVertex(cache[nLines-1][X], cache[nLines-1][Y]);
	
	shape3D->end();
     
     */
}

void		
MBrush::drawGL(ofxMSAShape3D *shape3D)
{
	//int v;	    	
    //	shape3D->begin(GL_TRIANGLE_STRIP);
	
    
    
    
    if ( shapeInstance_ )
    {
        shape3D->setColor4v(color);	    
        float lineWidth = gMCanvas->line_width();        
        shapeInstance_->drawGL( shape3D, color, fill, lineWidth );
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////
    // dgm - this is the old hardcoded shape drawing code, kept for reference in case we
    // need to tweak anything to match the original version
    //////////////////////////////////////////////////////////////////////////////////////    
    
    /*
    if (fill) {
        switch (type) {
            case NONE:
                break;
                
            case LINE:
            case RECT:
                // repeat vertex for non-contiguous polygon before
                shape3D->addVertex(cache[0][X], cache[0][Y]);
                
                shape3D->addVertex(cache[0][X], cache[0][Y]);
                shape3D->addVertex(cache[1][X], cache[1][Y]);
                shape3D->addVertex(cache[3][X], cache[3][Y]);
                shape3D->addVertex(cache[2][X], cache[2][Y]);
                
                // repeat vertex for non-contiguous polygon after
                shape3D->addVertex(cache[2][X], cache[2][Y]);
                break;
                
            case CIRCLE:
                // repeat vertex for non-contiguous polygon before
                shape3D->addVertex(cache[0][X], cache[0][Y]);

                // $$ might be a problem if CACHE_SIZE is odd #
                for (int i=0; i<CACHE_SIZE/2; i++) {
                    // zig zag across circle for triangle strips
                    shape3D->addVertex(cache[i][X], cache[i][Y]);
                    v = (CACHE_SIZE-1)-i;
                    shape3D->addVertex(cache[v][X], cache[v][Y]);
                }                       

                // repeat vertex for non-contiguous polygon after
                shape3D->addVertex(cache[v][X], cache[v][Y]);

                break;
                
            case CLOVER:
                // triangle strip order to fill chevron
                
                // repeat vertex for non-contiguous polygon before
                shape3D->addVertex(cache[2][X], cache[2][Y]);
 
                shape3D->addVertex(cache[2][X], cache[2][Y]);
                shape3D->addVertex(cache[1][X], cache[1][Y]);
                shape3D->addVertex(cache[3][X], cache[3][Y]);
                shape3D->addVertex(cache[0][X], cache[0][Y]);         
                shape3D->addVertex(cache[4][X], cache[4][Y]);
                shape3D->addVertex(cache[5][X], cache[5][Y]);
                
                // repeat vertex for non-contiguous polygon after
                shape3D->addVertex(cache[5][X], cache[5][Y]);
                
                break;
                
            case TRIANGLE:
                // repeat vertex for non-contiguous polygon before
                shape3D->addVertex(cache[0][X], cache[0][Y]);
                
                shape3D->addVertex(cache[0][X], cache[0][Y]);
                shape3D->addVertex(cache[1][X], cache[1][Y]);
                shape3D->addVertex(cache[2][X], cache[2][Y]);
                
                // repeat vertex for non-contiguous polygon after
                shape3D->addVertex(cache[2][X], cache[2][Y]);
                
                break;
        }
    } else {    // unfilled
        switch (type) {
            case NONE:
                break;
                
            case LINE:
            case RECT:
                
                for (int i=0; i<4; i++) {
                    drawSmoothLineVO(CGPointMake(cache[i][X], cache[i][Y]), 
                                     CGPointMake(cache[(i+1)%4][X], cache[(i+1)%4][Y]), 
                                     lineWidth, color, shape3D);    
                }
                break;
                
            case CIRCLE:
                for (int i=0; i<CACHE_SIZE; i++) {
                    drawSmoothLineVO(CGPointMake(cache[i][X], cache[i][Y]), 
                                     CGPointMake(cache[(i+1)%CACHE_SIZE][X], cache[(i+1)%CACHE_SIZE][Y]), 
                                     lineWidth, color, shape3D);    
                }	
                break;
                
            case CLOVER:
                for (int i=0; i<N_CHEVRON_POINTS; i++) {
                    drawSmoothLineVO(CGPointMake(cache[i][X], cache[i][Y]), 
                                     CGPointMake(cache[(i+1)%N_CHEVRON_POINTS][X], cache[(i+1)%N_CHEVRON_POINTS][Y]), 
                                     lineWidth, color, shape3D);    
                }	
              
                break;
                
            case TRIANGLE:
                for (int i=0; i<3; i++) {
                    drawSmoothLineVO(CGPointMake(cache[i][X], cache[i][Y]), 
                                     CGPointMake(cache[(i+1)%3][X], cache[(i+1)%3][Y]), 
                                     lineWidth, color, shape3D);    
                }                
                break;
        }
    }
     */
	
//	shape3D->end();
    
    
}

void        
MBrush::drawOntoCanvas(CGContextRef ctx, bool drawAlpha)
{    
    
    // come back to this - dgm
    
    /*
    float alpha;
    
    if (drawAlpha) 
        alpha = color[3];
    else
        alpha = 1.0f;
    
    CGContextSetRGBStrokeColor(ctx, color[0], color[1], color[2], alpha);
    CGContextSetRGBFillColor(ctx, color[0], color[1], color[2], alpha);
    
    CGContextBeginPath(ctx);
    
    CGContextMoveToPoint(ctx, cache[0][X], cache[0][Y]);
    
    
    switch (type) {
        case NONE:
            break;
            
        case LINE:
        case RECT:
            
            for (int i=1; i<4+1; i++) {
                CGContextAddLineToPoint(ctx, cache[i%4][X], cache[i%4][Y]);
            }
            break;
            
        case CIRCLE:
            for (int i=0; i<CACHE_SIZE+1; i++) {
                CGContextAddLineToPoint(ctx, cache[i%CACHE_SIZE][X], cache[i%CACHE_SIZE][Y]);
                
            }	
            break;
            
        case CLOVER:
            for (int i=0; i<N_CHEVRON_POINTS+1; i++) {
                CGContextAddLineToPoint(ctx, cache[i%N_CHEVRON_POINTS][X], cache[i%N_CHEVRON_POINTS][Y]);   
            }	
            
            break;
            
        case TRIANGLE:
            for (int i=0; i<3+1; i++) {
                CGContextAddLineToPoint(ctx, cache[i%3][X], cache[i%3][Y]);
            }                
            break;
    }
    if (fill) {
        CGContextFillPath(ctx);
    } else {
        CGContextStrokePath(ctx);
    }
     */
}

/*
void
MBrush::draw()
{
    // switch on object type
	
	// $$$$ need to change to use vertex pointers
	// and antialiasing?

    if (fill)
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    else {
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        glLineWidth(2);
    }

    switch (type) {
    case LINE:
        glBegin(GL_POLYGON);
        glVertex2f(cache[0][X], cache[0][Y]);
        glVertex2f(cache[1][X], cache[1][Y]);
        glVertex2f(cache[2][X], cache[2][Y]);
        glVertex2f(cache[3][X], cache[3][Y]);
        glEnd();
        break;
    case RECT:
        // glRectf(p1[0], p1[1], p2[0], p2[1]);
//        glRectf(cache[0][X], cache[0][Y],
//                cache[1][X], cache[1][Y]);
        glBegin(GL_POLYGON);
        glVertex2f(cache[0][X], cache[0][Y]);
        glVertex2f(cache[1][X], cache[1][Y]);
        glVertex2f(cache[2][X], cache[2][Y]);
        glVertex2f(cache[3][X], cache[3][Y]);
        glEnd();
        break;
    case CIRCLE:
    case CLOVER:
        glBegin(GL_POLYGON);
        glVertex2f(cache[0][X], cache[0][Y]);
        glVertex2f(cache[1][X], cache[1][Y]);
        glVertex2f(cache[2][X], cache[2][Y]);
        glVertex2f(cache[3][X], cache[3][Y]);
        glVertex2f(cache[4][X], cache[4][Y]);
        glVertex2f(cache[5][X], cache[5][Y]);
        glVertex2f(cache[6][X], cache[6][Y]);
        glVertex2f(cache[7][X], cache[7][Y]);
        glEnd();        
        break;
    case TRIANGLE:
        glBegin(GL_POLYGON);
        glVertex2f(cache[0][X], cache[0][Y]);
        glVertex2f(cache[1][X], cache[1][Y]);
        glVertex2f(cache[2][X], cache[2][Y]);
        glEnd();
        break;
    }
}
*/


////
////
//void MBrush::acquireUniqueID()
//{
//    uniqueID_ = nextUniqueID();
//}


void
MBrush::clear( bool clearUserData )
{

    //time = 0;
    //user_id = 0;
    fill = FALSE;

    //selected = FALSE;
    
    if ( clearUserData )
    {
        userData_ = 0;
    }
    
	MCOLOR_SET(color,0,0,0,0);
    p1[0] = p1[1] = p2[0] = p2[1] = 0.0;
    width = 0;
//    for (int i = 0; i < CACHE_SIZE; i++)
//        cache[i][0] = cache[i][1] = 0.0;
    
    if ( shapeInstance_ )
    {
        if ( ownsShapeInstance_ )
        {
            delete shapeInstance_;
        }
        
        shapeInstance_ = 0;
    }
}


//
//
void MBrush::retransform()
{  
    if ( shapeInstance_ )
    {
        shapeInstance_->forceNeedsTransform();
        shapeInstance_->setConstantOutlineWidth( constantOutlineWidth_ );
        set_pts(p1, p2, width, rot_);
    }
    
}


//
//
void MBrush::setShape( MShape * pShape )
{
    if ( shapeInstance_ && shapeInstance_->getShape() == pShape )
    {
        // do nothing
    }
    else
    {
        if ( shapeInstance_ )
        {
            delete shapeInstance_;
            shapeInstance_ = 0;
        }
        
        if ( pShape )
        {
            shapeInstance_ = pShape->createInstance();
        }
    }
}

#pragma mark archiving

//
//
MPArchiveBrush * MBrush::toArchiveBrush()
{

    MPArchiveBrush * ab = [[MPArchiveBrush alloc] init];
    
    ab.fill = fill;
    ab.userData_ = userData_;
    ab.centerPt_ = centerPt_;
    ab.scaleX_ = scaleX_;
    ab.scaleY_ = scaleY_;
    ab.rot_ = rot_;
    ab.zOrder_ = zOrder_;
    ab.uniqueID_ = uniqueID_;
    ab.width = width;
    ab.constantOutlineWidth_ = constantOutlineWidth_;
    
    [ab setColor: color];
    [ab setPointsP1: p1 P2: p2];
    
    if ( shapeInstance_ )
    {
        MPArchiveShapeInstance * si = shapeInstance_->toArchiveShapeInstance();
        [ab setShapeInstance: si];
    }
    
    return [ab autorelease];
}


//
//
void MBrush::fromArchiveBrush( MPArchiveBrush * src )
{
    fill = src.fill;
    userData_ = src.userData_;
    centerPt_ = src.centerPt_;
    scaleX_ = src.scaleX_;
    scaleY_ = src.scaleY_;
    rot_ = src.rot_;
    zOrder_ = src.zOrder_;
    uniqueID_ = src.uniqueID_;
    width = src.width;
    constantOutlineWidth_ = src.constantOutlineWidth_;
    
    [src getColor: color];
    [src getPointsP1: p1 P2:p2];
    
    // create a shape instance from the archive shape instance
    
    if ( shapeInstance_ )
    {
        delete shapeInstance_;
        shapeInstance_ = 0;
    }
    
    shapeInstance_ = MShapeInstance::fromArchiveShapeInstance( [src getShapeInstance] );
    
    
}



// this is a helper to create a duplicate copy of the brush.
// the copy currently doens't own the shape instance - just copies the pointer.
// mostly a helper for archiving.
void MBrush::copyFrom( MBrush * src )
{
    fill = src->fill;
    userData_ = src->userData_;
    centerPt_ = src->centerPt_;
    scaleX_ = src->scaleX_;
    scaleY_ = src->scaleY_;
    rot_ = src->rot_;
    zOrder_ = src->zOrder_;
    uniqueID_ = src->uniqueID_;
    width = src->width;
    constantOutlineWidth_ = src->constantOutlineWidth_;
    
    MCOLOR_COPY(color, src->color );
    p1[0] = src->p1[0];
    p1[1] = src->p1[1];

    p2[0] = src->p2[0];    
    p2[1] = src->p2[1];
    
    shapeInstance_ = src->shapeInstance_;
    ownsShapeInstance_ = false;
}

#pragma mark networking helpers

//
// fill out as much data as we can in the brush action
void MBrush::populateBrushAction( MPActionBrush * pAB, int frame )
{    
        
    pAB->setData( shapeInstance_->getShape()->getShapeID(), CGPointMake(p1[0], p1[1]), CGPointMake(p2[0], p2[1]), width, rot_, fill, color, frame, userData_, zOrder_, constantOutlineWidth_ );
}

