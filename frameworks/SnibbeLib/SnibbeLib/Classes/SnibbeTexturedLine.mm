//
//  SnibbeTexturedLine.mm
//  SnibbeLib
//
//  Created by Graham McDermott on 8/19/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//

#include "SnibbeTexturedLine.h"

#ifdef USING_COCOS_2D

#include "CGPointExtension.h"


#define EPSILON 0.00001f

// statics

int SnibbeTexturedLine::msMaxPathVerts = 0;
int SnibbeTexturedLine::msMaxPointsInStrip = 0;

CGPoint * SnibbeTexturedLine::secondStripVerts = 0;
CGPoint * SnibbeTexturedLine::secondStripTexCoords = 0;
float * SnibbeTexturedLine::secondStripAlpha = 0;

// if we're giving the line sharp ends, we interpolate from width of 0 to this value
// on the first segment and from this value to the full width on the next segment
static const float sharpEndWideEndWidthCoef = 0.5f; 


//////////////////////////////////////////////////////////////////////////
// inline helpers
//////////////////////////////////////////////////////////////////////////



inline CGPoint endcapPerp(CGPoint p0, CGPoint p1, float width)
{
	CGPoint dir = ccpSub(p1, p0);
	CGPoint perp = CGPointMake(-dir.y, dir.x);
	perp = ccpNormalize(perp);
	
	return ccpMult(perp, width);
}


inline CGPoint endcapNorm(CGPoint p0, CGPoint p1, CGPoint p2, CGPoint perp, float width)
{
	CGPoint v = ccpSub(p2, p0);
	v = ccpNormalize(v);
	CGPoint bisector = CGPointMake(-v.y, v.x);
	
	bisector = ccpMult(bisector, width);
    
	// project perp onto bisector (there are some wanky optimizations we could do, but probably not necessary)
	CGPoint norm = ccpProject(perp, bisector);
	
	return norm;
}

inline void drawSmoothLineSegmentVO(CGPoint p0, CGPoint p1, CGPoint p2, CGPoint p3,
									float startWidth, float endWidth,
									ccColor4F colorStart, ccColor4F colorEnd, ofxMSAShape3D *vertexObject)
{
    GLfloat lineVertices[12]; 
    CGPoint perp1, perp2, norm1, norm2;
	
	perp1 = endcapPerp(p1, p2, startWidth);
	perp2 = endcapPerp(p1, p2, endWidth);
	
	if (ccpFuzzyEqual(p0, p1, EPSILON)) {
		// if points equal then normal is perpendicular vec
		norm1 = perp1;
	} else {
		norm1 = endcapNorm(p0, p1, p2, perp1, startWidth);
	}
	
	if (ccpFuzzyEqual(p2, p3, EPSILON)) {
		// if points equal then normal is perpendicular vec
		norm2 = perp2;
	} else {
		norm2 = endcapNorm(p1, p2, p3, perp2, endWidth);
	}
	
    //	norm1 = norm2 = perp;
    
    lineVertices[0] = p1.x + norm1.x;
    lineVertices[1] = p1.y + norm1.y;
    
	lineVertices[2] = p2.x + norm2.x;
    lineVertices[3] = p2.y + norm2.y;
    
	lineVertices[4] = p1.x;
    lineVertices[5] = p1.y;
    
	lineVertices[6] = p2.x;
    lineVertices[7] = p2.y;
    
	lineVertices[8] = p1.x - norm1.x;
    lineVertices[9] = p1.y - norm1.y;
    
	lineVertices[10] = p2.x - norm2.x;
    lineVertices[11] = p2.y - norm2.y;
	
	vertexObject->setColor(colorStart.r, colorStart.g, colorStart.b, 0);
	vertexObject->addVertex2v(&lineVertices[0]);
	vertexObject->setColor(colorEnd.r, colorEnd.g, colorEnd.b, 0);
	vertexObject->addVertex2v(&lineVertices[2]);
	vertexObject->setColor(colorStart.r, colorStart.g, colorStart.b, colorStart.a);
	vertexObject->addVertex2v(&lineVertices[4]);
	vertexObject->setColor(colorEnd.r, colorEnd.g, colorEnd.b, colorEnd.a);    
	vertexObject->addVertex2v(&lineVertices[6]);
	vertexObject->setColor(colorStart.r, colorStart.g, colorStart.b, 0);
	vertexObject->addVertex2v(&lineVertices[8]);
  	vertexObject->setColor(colorEnd.r, colorEnd.g, colorEnd.b, 0);
	vertexObject->addVertex2v(&lineVertices[10]);
}


//////////////////////////////////////////////////////////////////////////
// SnibbeTexturedLine
//////////////////////////////////////////////////////////////////////////



//
//
SnibbeTexturedLine::SnibbeTexturedLine( std::vector<CGPoint>& points, unsigned int textureID, float width, float alpha, ofxMSAShape3D *shape3D, std::vector<float> *pPointAlphas ) :
    points_( points ),
    textureID_( textureID ),
    width_( width ),
    alpha_( alpha ),
    sharpEnds_( false ),
    ptAlphaVals_( pPointAlphas )
{

    shape3D_ = shape3D;
}




// monster function (sorry! didn't want to break up for efficiency...)
// draws the line along the vector of points given the desired width and texture id.
// uses two triangular line endcaps and a triangle strip for each side of the line
// (perpendicular to line direction) to minimize texture seams due to varying
// widths of each segment (from corners).
void SnibbeTexturedLine::draw()
{
    

    
    // endpoints - they can't be part of the triangle strips - do separately in a triangles call
    CGPoint startVerts [3];
    CGPoint startTexCoords [3];
    CGPoint endVerts [3];
    CGPoint endTexCoords [3];
    
        
    // cap vertex count;
    int vertexCount = points_.size();
    bool hasTriStrip = vertexCount > 2;
    
    if ( vertexCount > msMaxPathVerts )
    {
        vertexCount = msMaxPathVerts;
    }
    
    if ( vertexCount <= 1 )
    {
        return;
    }    
    
    float vertexIncrement = 1.0f / vertexCount - .0001; // fudge the numbers a bit to avoid edge cases
    float curVertexPercent = 0.0001f;
    
    SegmentT curSegmentType = eMidSegment;    

    shape3D_->setClientStates();
    shape3D_->enableColor( true );
    shape3D_->enableTexCoord( true );                              
    shape3D_->setColor( 1.0f, 1.0f, 1.0f, alpha_ );    
        
    
    if ( hasTriStrip )
    {
        // we have some mid segments that will use the triangle strip
        shape3D_->begin( GL_TRIANGLE_STRIP );            
    }
        
    glEnable(GL_TEXTURE_2D);    
    glBindTexture(GL_TEXTURE_2D, textureID_ );          
    
    int iSSIndex = 0;    
    shape3D_->setColor( 1.0f, 1.0f, 1.0f, alpha_ );
    CGPoint p2Cached;
    CGPoint p2PlusCached;
    CGPoint p2MinusCached;
    
    
    // we calculate the end width coefficient of each side of the line one
    // bend ahead of the current segment
    
    float prevPlusEndWidthCoef = 1.0f;
    float prevMinusEndWidthCoef = 1.0f;
    
    float curPlusEndWidthCoef = 1.0f;
    float curMinusEndWidthCoef = 1.0f;
    
    float nextPlusEndWidthCoef = 1.0f;
    float nextMinusEndWidthCoef = 1.0f;

    float radians23SegEnd = 0.0f;
    
    //    output all vertices
    //    NSLog(@"\n\nbegin\n\n" );
    //    for( int i=1;i<vertexCount;i++) 
    //    {
    //        NSLog( @"%@\n", NSStringFromCGPoint( points_[i] ) );
    //    }  
    //    NSLog(@"\n\nend\n\n" );
    
    float prevAlpha = 0.0f;
    
    for( int i=1;i<vertexCount;i++) {
        
        
        CGPoint p0 = points_[MAX(0,i-2)];	// p0 is p1 for first segment
        CGPoint p1 = points_[i-1];
        CGPoint p2 = points_[i];
        CGPoint p3 = points_[MIN(i+1,vertexCount-1)]; // p3 is p2 for last segment
        CGPoint p4 = points_[MIN(i+2,vertexCount-1)]; 
        
        float curAlpha = alpha_;
        if ( ptAlphaVals_ )
        {
            // each line segment can have an alpha val as well
            curAlpha *= (*ptAlphaVals_)[i];
        }
        
        
        
        float startWidth = width_, endWidth = width_;
        
        // following the path, plus is left, and minus is right
        
        float plusEndWidthCoef = 1.0f;
        float minusEndWidthCoef = 1.0f;                
        
        // if we have a particularly sharp angle at the end of the current segment
        // we calculate the segment normals in a different way b/c the standard method
        // breaks down
        
        bool bSharpPlusExterior = false;
        bool bSharpMinusExterior = false;
                        
        
        ///////////////////////////////////////////////////////////////////
        // here we do a little calculation to better handle acute angles 
        ///////////////////////////////////////////////////////////////////
        
        if ( i > 2 && i < vertexCount-2 )
        {
            
            prevPlusEndWidthCoef = curPlusEndWidthCoef;
            prevMinusEndWidthCoef = curMinusEndWidthCoef;
            
            curPlusEndWidthCoef = nextPlusEndWidthCoef;
            curMinusEndWidthCoef = nextMinusEndWidthCoef;
                        
            CGPoint seg23 = ccpSub( p3, p2 );
            CGPoint seg34 = ccpSub( p4, p3 );            
            
            float radians12AtSegEnd = radians23SegEnd; // previous 23 angle is now 12 angle                           
            
            if ( radians12AtSegEnd > M_PI_2 )
            {                     
                // plus side needs is "interior" sharp angle, minus side is exterior                
                bSharpMinusExterior = true;
            }
            else if ( radians12AtSegEnd < - M_PI_2 )
            {                
                // minus side is "interior" sharp angle, plus side is exterior                
                bSharpPlusExterior = true;
            }
                                    
            // angle one segment ahead of the current one            
            radians23SegEnd = ccpAngleSigned( seg23, seg34 );
                                    
            // we calculate coefficients for the width of each side of the line using the
            // acuteness of the angle of each segment.  It's calculated between segments 23 and 34
            // and passed down the line in subsequent loop interations
            
            if ( radians23SegEnd > 0 )
            {                
                nextPlusEndWidthCoef = 1.0f - radians23SegEnd * M_1_PI;  
                nextMinusEndWidthCoef = 1.0f;
                
            }
            else 
            {
                nextPlusEndWidthCoef = 1.0f;
                nextMinusEndWidthCoef = 1.0f + radians23SegEnd * M_1_PI;                
            }
             

            // the effective line width coefficients for each side are based on an average of the previous, current and
            // next segment coefficients.  We then multiply it by itself to increase the effect of low values
            
            plusEndWidthCoef = ( nextPlusEndWidthCoef + curPlusEndWidthCoef + prevPlusEndWidthCoef ) * 0.333f;
            minusEndWidthCoef = ( nextMinusEndWidthCoef + curMinusEndWidthCoef + prevMinusEndWidthCoef ) * 0.333f;
            
            // thin it a bit
            plusEndWidthCoef *= (plusEndWidthCoef );
            minusEndWidthCoef *= (minusEndWidthCoef );
            
             
        }
         
        
        
        ////////////////////////////////////////////////////////////////////////////////////
        // here we determine the class of the segment in this particular loop
        // iteration and set up some values about its width
        /////////////////////////////////////////////////////////////////////////////////////
        
        curSegmentType = eMidSegment;
        bool bNeedNorm1 = false;
        
        
        if ( vertexCount > 2 )
        {
            
            if ( i == 1 )
            {
                if ( sharpEnds_ )
                {
                    startWidth = 0.0001f;
                    endWidth = width_ * sharpEndWideEndWidthCoef;
                }
                
                curSegmentType = eStartSegment;                
            }
            else if ( i == vertexCount - 1 )
            {
                if ( sharpEnds_ )
                {
                    startWidth = width_ * sharpEndWideEndWidthCoef;
                    endWidth = 0.0001f;
                }
                
                curSegmentType = eEndSegment;
                bNeedNorm1 = true;
                
            } 
            else if ( i == vertexCount - 2 )
            {
                if ( sharpEnds_ )
                {
                    endWidth = width_ * sharpEndWideEndWidthCoef;
                }
            }
            else if ( i == 2 )
            {
                if ( sharpEnds_ )
                {
                    startWidth = width_ * sharpEndWideEndWidthCoef;
                }
                
                bNeedNorm1 = true;
            }



        }
        else if ( vertexCount == 2 )
        {
            curSegmentType = eStartEndSegment;
            startWidth = endWidth = width_ * sharpEndWideEndWidthCoef;
        }
        
        if ( vertexCount == 3 )
        {
            // special case for width in line with only one mid-segment
            startWidth = endWidth = width_ * sharpEndWideEndWidthCoef;
        }
        
        
        
        ////////////////////////////////////////////////////////////////////////////////////
        // calculate the perpendiculars of the segment
        /////////////////////////////////////////////////////////////////////////////////////
        
        
        
        CGPoint perp1, perp2, norm1, norm2;
        
        if ( bNeedNorm1 ) 
        {            
            perp1 = endcapPerp(p1, p2, startWidth);
        }
        
        perp2 = endcapPerp(p1, p2, endWidth);
        
            
        if ( bNeedNorm1 ) 
        {
            if ( ccpFuzzyEqual(p0, p1, EPSILON) ) {
                // if points equal then normal is perpendicular vec
                norm1 = perp1;
            } else {
                
                norm1 = endcapNorm(p0, p1, p2, perp1, startWidth);
            }
        }
        
        if ( ccpFuzzyEqual(p2, p3, EPSILON) ) {
            // if points equal then normal is perpendicular vec
            norm2 = perp2;
        } else {
            
            norm2 = endcapNorm(p1, p2, p3, perp2, endWidth);
        }
        
        CGPoint p2PlusCur = CGPointMake(p2.x + norm2.x * plusEndWidthCoef, p2.y + norm2.y * plusEndWidthCoef);
        CGPoint p2MinusCur = CGPointMake(p2.x - norm2.x * minusEndWidthCoef, p2.y - norm2.y * minusEndWidthCoef);
        
        
        const float extSharpCoef = 1.3f;
        const float intSharpCoef = 0.4f;
        
        if ( bSharpPlusExterior )
        {
            CGPoint perp23 = endcapPerp(p2, p3, endWidth);
            p2PlusCur = CGPointMake( p2.x + ( perp2.x + perp23.x ) * extSharpCoef, p2.y + ( perp2.y + perp23.y ) * extSharpCoef );
            p2MinusCur = CGPointMake( p2.x - ( perp2.x + perp23.x ) * intSharpCoef, p2.y - ( perp2.y + perp23.y ) * intSharpCoef );
        }
        else if ( bSharpMinusExterior )
        {
            CGPoint perp23 = endcapPerp(p2, p3, endWidth);            
            p2PlusCur = CGPointMake( p2.x + ( perp2.x + perp23.x ) * intSharpCoef, p2.y + ( perp2.y + perp23.y ) * intSharpCoef );
            p2MinusCur = CGPointMake( p2.x - ( perp2.x + perp23.x ) * extSharpCoef, p2.y - ( perp2.y + perp23.y ) * extSharpCoef );
        }


        switch (curSegmentType ) 
        {
            case eMidSegment:
            {
                
                ////////////////////////////////////////////////////////////////////////////////////
                // here we use the tri strips
                ////////////////////////////////////////////////////////////////////////////////////
                
                shape3D_->setColor( 1.0f, 1.0f, 1.0f, prevAlpha );  // here we use the previous alpha value to provide a smooth transition from the previous tri endpoint
                
                if ( i == 2 )
                {
                    // the first mid-segment - we need to prime with first two vertices
                    
                    // strip 1 - straight to ofxMSAShape3D                                                        
                                        
                    shape3D_->setTexCoord( 0.0f, 0.0f );
                    shape3D_->addVertex( startVerts[1].x, startVerts[1].y );
                    
                    shape3D_->setTexCoord( 0.5f, 0.0f );
                    shape3D_->addVertex( p1.x , p1.y );
                    
                    // strip 2 - cache off and do as second pass
                    
                    secondStripAlpha[iSSIndex] = prevAlpha;
                    secondStripVerts[iSSIndex] = p1;
                    secondStripTexCoords[iSSIndex++] = CGPointMake( 0.5f, 0.0f );
                    
                    secondStripAlpha[iSSIndex] = prevAlpha;                
                    secondStripVerts[iSSIndex] = CGPointMake( startVerts[2].x, startVerts[2].y );
                    secondStripTexCoords[iSSIndex++] = CGPointMake( 1.0f, 0.0f );
                    
                    
                }
                
                shape3D_->setColor( 1.0f, 1.0f, 1.0f, curAlpha );
                
                p2Cached = p2;
                p2PlusCached = p2PlusCur;            
                p2MinusCached = p2MinusCur;
                
                // strip 1 - straight to ofxMSAShape3D        
                
                shape3D_->setTexCoord( 0.0f, 1.0f );
                shape3D_->addVertex( p2PlusCur.x, p2PlusCur.y );
                
                shape3D_->setTexCoord( .50f, 1.0f );
                shape3D_->addVertex( p2.x, p2.y );
                
                // strip 2 - cache off and do as second pass
                
                secondStripAlpha[iSSIndex] = curAlpha;
                secondStripVerts[iSSIndex] = p2;
                secondStripTexCoords[iSSIndex++] = CGPointMake( 0.5f, 1.0f );
                
                secondStripAlpha[iSSIndex] = curAlpha;
                secondStripVerts[iSSIndex] = p2MinusCur;
                secondStripTexCoords[iSSIndex++] = CGPointMake( 1.0f, 1.0f );

            }
            break;
            

            case eStartSegment:
            {
                ////////////////////////////////////////////////////////////////////////////////////
                // cache off tris for start segment (not part of tri strip)
                ////////////////////////////////////////////////////////////////////////////////////
                
                
                startVerts[0] = p1;
                startVerts[1] = p2PlusCur;
                startVerts[2] = p2MinusCur;
                
                startTexCoords[0] = CGPointMake( 0.5f, 1.0f );
                startTexCoords[1] = CGPointMake( 0.0f, 0.0f );
                startTexCoords[2] = CGPointMake( 1.0f, 0.0f );
            }
            break;
            
            case eEndSegment:
            {
                ////////////////////////////////////////////////////////////////////////////////////
                // cache off tris for end segment (not part of tri strip)
                ////////////////////////////////////////////////////////////////////////////////////
                
                
                endVerts[0] = p2;
                endVerts[1] = CGPointMake( p1.x + norm1.x, p1.y + norm1.y );
                endVerts[2] = CGPointMake( p1.x - norm1.x, p1.y - norm1.y );
                
                endTexCoords[0] = CGPointMake( 0.5f, 1.0f );
                endTexCoords[1] = CGPointMake( 0.0f, 0.0f );
                endTexCoords[2] = CGPointMake( 1.0f, 0.0f );
                

            }
            break;
                
            case eStartEndSegment:
            {
                ////////////////////////////////////////////////////////////////////////////////////
                // we do the entire bit in one go with tris
                ////////////////////////////////////////////////////////////////////////////////////
                
                
                CGPoint halfWay = CGPointMake( (p1.x + p2.x) * 0.5f, (p1.y + p2.y) * 0.5f );                
                CGPoint halfwayPlus = CGPointMake(halfWay.x + norm2.x * plusEndWidthCoef, halfWay.y + norm2.y * plusEndWidthCoef);
                CGPoint halfwayMinus = CGPointMake(halfWay.x - norm2.x * minusEndWidthCoef, halfWay.y - norm2.y * minusEndWidthCoef);
                
                startVerts[0] = p1;
                startVerts[1] = halfwayPlus;
                startVerts[2] = halfwayMinus;
                                                
                startTexCoords[0] = CGPointMake( 0.5f, 1.0f );
                startTexCoords[1] = CGPointMake( 0.0f, 0.0f );
                startTexCoords[2] = CGPointMake( 1.0f, 0.0f );
                
                endVerts[0] = p2;
                endVerts[1] = halfwayPlus;
                endVerts[2] = halfwayMinus;
                
                endTexCoords[0] = CGPointMake( 0.5f, 1.0f );
                endTexCoords[1] = CGPointMake( 0.0f, 0.0f );
                endTexCoords[2] = CGPointMake( 1.0f, 0.0f );
                
            }
            break;
                                
            default:
                break;
        }
        
               

        prevAlpha = curAlpha;
        curVertexPercent += vertexIncrement;
    }	
    
    

    ////////////////////////////////////////////////////////////////////////////////////
    // finally, draw any cached values
    ////////////////////////////////////////////////////////////////////////////////////
    
    
    if ( hasTriStrip )
    {
        // we had some mid segments that will use the triangle strip
        shape3D_->end();
    
         
        // now the cached strip
        
        shape3D_->begin( GL_TRIANGLE_STRIP );   
        for ( int iCached = 0; iCached < iSSIndex; ++iCached )
        {   
            
            shape3D_->setColor( 1.0f, 1.0f, 1.0f, secondStripAlpha[iCached] );              
            shape3D_->setTexCoord( secondStripTexCoords[iCached].x, secondStripTexCoords[iCached].y );
            shape3D_->addVertex( secondStripVerts[iCached].x, secondStripVerts[iCached].y );
        }
        shape3D_->end();        
            
    }
    
    // now the ends
    
    shape3D_->begin( GL_TRIANGLES );   
    
    for ( int iTri = 0; iTri < 3; ++iTri )
    {        

        float alphaWideEnd = alpha_;
        if ( ptAlphaVals_ )
        {
            alphaWideEnd *= (*ptAlphaVals_)[1];
        }
        
        shape3D_->setColor( 1.0f, 1.0f, 1.0f, (iTri == 0 ? 0 : alphaWideEnd) );        
        shape3D_->setTexCoord( startTexCoords[iTri].x, startTexCoords[iTri].y );
        shape3D_->addVertex( startVerts[iTri].x, startVerts[iTri].y );
    } 


    for ( int iTri = 0; iTri < 3; ++iTri )
    {        
        float alphaWideEnd = alpha_;
        if ( ptAlphaVals_ )
        {
            alphaWideEnd *= (*ptAlphaVals_)[vertexCount-2];
        }
        
        shape3D_->setColor( 1.0f, 1.0f, 1.0f, (iTri == 0 ? 0 : alphaWideEnd) ); 
        shape3D_->setTexCoord( endTexCoords[iTri].x, endTexCoords[iTri].y );
        shape3D_->addVertex( endVerts[iTri].x, endVerts[iTri].y );
    }

     
 
    shape3D_->end();        
    shape3D_->restoreClientStates();

    
    ///////////////////////////////////////////////////////////////////
    // debug method one - uncomment to draw lines of alternating color 
    // along the segment path
    ///////////////////////////////////////////////////////////////////    
    
    
    /*
     
    //NSLog( @"vertex count: %d\n", vertexCount );
    glDisable(GL_TEXTURE_2D);  
    
    shape3D_->setClientStates();
    shape3D_->enableColor( true );
    shape3D_->begin( GL_LINES );       
    
    for( int i=1;i<vertexCount;i++) {
        
        CGPoint p1 = points_[i-1];
        CGPoint p2 = points_[i];
        
        if ( i % 2 == 0 )
        {
            shape3D_->setColor( 1.0f, 1.0f, 1.0f, 1 );
        }
        else
        {
            shape3D_->setColor( 1.0f, 0.0f, 0.0f, 1 );
        }
        
        shape3D_->addVertex( p1.x, p1.y );
        shape3D_->addVertex( p2.x, p2.y );        
        
        
    }
    shape3D_->end();
    shape3D_->restoreClientStates();
     
     */
    
    ///////////////////////////////////////////////////////////////////
    // debug method two - uncomment to draw lines that depict the
    // cached vertices
    ///////////////////////////////////////////////////////////////////        
    
    /*
    
    shape3D_->setClientStates();
    glDisable(GL_TEXTURE_2D);  
    shape3D_->enableColor( true );
    shape3D_->begin( GL_LINES ); 
    
    shape3D_->setColor( 0.0f, 1.0f, 0.0f, 1 );   
    
    
    for ( int iCached = 0; iCached < iSSIndex; iCached = iCached + 2 )
    {   
        
        shape3D_->setColor( 0.0f, 1.0f, 0.0f, 1 );   
        
        shape3D_->addVertex( secondStripVerts[iCached].x, secondStripVerts[iCached].y );
        shape3D_->addVertex( secondStripVerts[iCached+1].x, secondStripVerts[iCached+1].y ); 
        
    }
    
    shape3D_->end();
    shape3D_->restoreClientStates();

    */
}


///////////////////////////////////////////////////////////////////////////////
// static public methods
///////////////////////////////////////////////////////////////////////////////

//
// static
void SnibbeTexturedLine::init( int maxPathVerts )
{
    msMaxPathVerts = maxPathVerts;
    msMaxPointsInStrip = (maxPathVerts - 2) *2;
        
    secondStripVerts = new CGPoint[msMaxPointsInStrip];    
    secondStripTexCoords = new CGPoint [msMaxPointsInStrip];
    secondStripAlpha = new float [msMaxPointsInStrip];
    
    
}

//
// static
void SnibbeTexturedLine::shutdown()
{
    delete[] secondStripVerts;
    delete[] secondStripTexCoords;
    delete[] secondStripAlpha;
}


#endif // #ifdef USING_COCOS_2D