 /*
 * ValueGraph.cpp
 * (c) 2010 Scott Snibbe
 */

#import "cocos2d.h"
#include "Scoop.h"
#include "ValueGraph.h"
#include "ofxMSAShape3D.h"
#include "ScoopDefs.h"
#import "ScoopUtils.h"

#define TWOPI 2*M_PI
#define TODEGREES 57.2957795


/////////////////////////////////////////////////////////////////////////
// class ValueGraphState
//////////////////////////////////////////////////////////////////////////


ValueGraphState::ValueGraphState()
{
    valuesAudio_ = 0;
    valuesVisual_ = 0;
    numValues_ = 0;
}

//
//
ValueGraphState::~ValueGraphState()
{
    clear();
}

void ValueGraphState::clear()
{
    if ( valuesAudio_ )
    {
        delete[] valuesAudio_;
        valuesAudio_ = 0;
    }
    
    if ( valuesVisual_ )
    {
        delete[] valuesVisual_;
        valuesVisual_ = 0;
    }    
    
    numValues_ = 0;
    
}

void ValueGraphState::setValues( float *vAud, float *vVis, int numValues )
{
    if ( (numValues == numValues_) && valuesAudio_ && valuesVisual_ )
    {
        // we already have memory allocated
    }
    else
    {
        clear();
        valuesAudio_ = new float[numValues];
        valuesVisual_ = new float[numValues];
    }
    
    memcpy(valuesAudio_, vAud, numValues * sizeof(float));
    memcpy(valuesVisual_, vVis, numValues * sizeof(float));
    
    numValues_ = numValues;
    
}

/////////////////////////////////////////////////////////////////////////
// class ValueGraph
/////////////////////////////////////////////////////////////////////////



// some of the original drawing computation was based on this number so we
// need to account for it now that the numbers can change
const int kOrinalGraphSize = 16*20;

extern ofxMSAShape3D	*gShape3D;

ValueGraph::ValueGraph(int size, float duration, int maxVal, 
					   CGColorRef frontColor, CGColorRef backColor, CGColorRef bgColor) :
	size_(size),	// size means # of samples
	duration_(duration),
	maxVal_(maxVal)
{
	
	originalGraphToSize_ = kOrinalGraphSize / (float) size_;
	
	valuesAudio_ = new float [size_];
	valuesVisual_ = new float [size_];

	
	graphPts_ = new point_4 [size_];
	circlePts_ = new point_4 [size_];
	//xformGraphPts_ = new point_4 [size_];
	//xformTopCirclePts_ = new point_4 [size_];
	//xformBotCirclePts_ = new point_4 [size_];
	//cacheGraphPOINTS_ = new CGPoint [size_];
	//frontPOINTS_ = new CGPoint [size_*2];
	//backLeftPOINTS_ = new CGPoint [size_*2];
	//backRightPOINTS_ = new CGPoint [size_*2];
	
	nLeftPts_ = nRightPts_ = nFrontPts_ = 0;

	//radius_ = 200;
	//height_ = 100;
	tilt_ = M_PI / 8.0;
	roll_ = 0;
	//trans_.SetPos(320, 240, 0);
	trans_.SetPos(0, 0, 0);
	arcTheta_ = TWOPI;
	hScale_ = 1.0;
	vScale_ = 1.0;

	//graphPen_ = GetStockObject(NULL_PEN);
	//graphFrontBr_ = CreateSolidBrush(frontColor);
	//graphBackBr_ = CreateSolidBrush(backColor);
	//graphBgBr_ = CreateSolidBrush(bgColor);
	
	frontColor_ = frontColor;
	backColor_ = backColor;
	bgColor_ = bgColor;

	state_ = State_Cylinder;
	scrolling_ = true;
	quantize_ = 0;
    numQuantizeStepsY_ = 0;
    
	timeOffset_ = 0.0f;

	// $$$$ should compute..
	latency_ = 0;
	//latency_ = ROUNDINT((float) size_ / duration_*40);
    
    // test latency
    //latency_ = 1;
    
    
    maskGraphInputIndexLow_ = -1;
    maskGraphInputIndexHigh_ = -1;
    
	resetGraph(0);
}

ValueGraph::~ValueGraph()
{
	delete [] valuesAudio_;
    delete [] valuesVisual_;
	delete [] graphPts_;
	delete [] xformGraphPts_;
	delete [] xformTopCirclePts_;
	delete [] xformBotCirclePts_;
	//delete [] cacheGraphPOINTS_;
	delete [] frontPOINTS_;
	delete [] backLeftPOINTS_;
	delete [] backRightPOINTS_;

	CGColorRelease(frontColor_);
	CGColorRelease(backColor_);
	CGColorRelease(bgColor_);
}


//
//
void ValueGraph::saveState( ValueGraphState& state )
{
    state.setValues(valuesAudio_, valuesVisual_, size_);
}

//
//
void ValueGraph::restoreState( ValueGraphState& state )
{
    
    
    int iNumNewVals = state.getNumValues();
    if ( iNumNewVals != size_ )
    {
        delete [] valuesAudio_;
        delete [] valuesVisual_;
        valuesAudio_ = new float [state.getNumValues()];
        valuesVisual_ = new float [state.getNumValues()];
    }
    
    memcpy(valuesAudio_, state.getValuesAudio(), iNumNewVals * sizeof( float ) );
    memcpy(valuesVisual_, state.getValuesVisual(), iNumNewVals * sizeof( float ) );

    size_ = iNumNewVals;
}


//
//
void ValueGraph::setQuantizeY( float *quantizeSteps, int numSteps )
{
    assert( numSteps <= MAX_NUM_QUANTIZE_STEPS );
    
    numQuantizeStepsY_ = numSteps;
    if ( numSteps > 0 )
    {
        memcpy(quantizeStepsY_, quantizeSteps, sizeof( float ) * numSteps );
    }
}

// If y quantization is enabled, quantize according to
// the desired number of steps.  Otherwise just return the value.
float ValueGraph::testAndQuantizeYVal( float inVal )
{
	if (numQuantizeStepsY_ <= 0 )
	{
		return inVal;
	}
	
    
    // now we need to walk through the quantize values array and find
    // the value we're closest to.
    // It's assumed to be in ascending order.
    // Just do simple linear search since our size will be small.
    
    if ( inVal <= quantizeStepsY_[0] )
    {
        return quantizeStepsY_[0];
    }
    else if ( inVal >= quantizeStepsY_[numQuantizeStepsY_-1] )
    {
        return quantizeStepsY_[numQuantizeStepsY_ - 1];
    }
    else
    {
        // test each interval
        for ( int i = 0; i < numQuantizeStepsY_ - 1; ++i )
        {
            // testing the interval of i -> i+1
            if ( inVal >= quantizeStepsY_[i] &&
                inVal < quantizeStepsY_[i+1] )
            {
                // which is it closer to?
                float deltaFromLow = inVal - quantizeStepsY_[i];
                float halfRange = ( quantizeStepsY_[i+1] - quantizeStepsY_[i] ) / 2.0f;
                if ( deltaFromLow <= halfRange )
                {
                    return quantizeStepsY_[i];                
                }
                else
                {
                    return quantizeStepsY_[i+1];
                }
            }
        }
    }
    
    
    return inVal;
    
    
	
}



void
ValueGraph::resetGraph(float val)
{
	for (int i = 0; i < size_; i++) {
		valuesAudio_[i] = valuesVisual_[i] = val;
	}
    
	//computeCircleGraph(arcTheta_);
}

void
ValueGraph::randomizeGraph()
{
	int i;
	float val = 0.0f;

	for (i = 0; i < size_; i++) {
		if (i % 10 == 0) {
			val = arc4random() % maxVal_ + 1;
		}
		valuesAudio_[i] = valuesVisual_[i] = val;
	}
}

//
// 
void ValueGraph::setConsecutiveValuesImpl( float *vals, int startIndex, int stopIndex, float val, bool bIncreasingIndex )
{

    
    
    if ( bIncreasingIndex )
    {
        if (stopIndex < startIndex) stopIndex += size_;
    }
    else
    {
        if ( stopIndex > startIndex ) startIndex += size_;
    }
    
	float adjustedVal = testAndQuantizeYVal( val );
    
	
    //NSLog( @"start index: %d\tstop index: %d, val: %f, adjusted: %f\n", startIndex, stopIndex, val, adjustedVal );
    
    
    if ( bIncreasingIndex )
    {
        for (int i = startIndex; i <= stopIndex; i++) 
        {                                
            vals[i%size_] = adjustedVal;
        }
    }
    else
    {
        for (int i = startIndex; i >= stopIndex; i--) 
        {
            vals[i%size_] = adjustedVal;
        }
    }
    

    
   }


//
// 
void ValueGraph::setConsecutiveValues(ValueGraphDataT dataType, int startIndex, int stopIndex, float val, bool bIncreasingIndex)
{
    

    if ( dataType == eVGDataAudio || dataType == eVGDataBoth )
    {
        setConsecutiveValuesImpl( valuesAudio_, startIndex, stopIndex, val, bIncreasingIndex );
    }
    
    if ( dataType == eVGDataVisual || dataType == eVGDataBoth )
    {
        setConsecutiveValuesImpl( valuesVisual_, startIndex, stopIndex, val, bIncreasingIndex );        
    }

    
} 

//
// Implementation of setInterpValues to be called with the desired data set (audio or visual)
void ValueGraph::setInterpValuesImpl( float *vals, int startIndex, int stopIndex, float startVal, float endVal, bool bIncreasingIndex )
{
    
    
    if ( bIncreasingIndex )
    {       
        // the default state... our editing is going from low index to high (round crown)
        // can't tell from the indices since they can wrap around
        if (stopIndex < startIndex) stopIndex += size_;
    }
    else
    {
        if (stopIndex > startIndex) startIndex += size_;            
    }
    
	float interp;
	float dv = stopIndex - startIndex + 1;
    if ( !bIncreasingIndex )
    {
        dv = startIndex - stopIndex + 1;
    }
    
	float dval;
    
    
    if ( bIncreasingIndex )
    {
        for (int i = startIndex; i <= stopIndex; i++) 
        {
            interp = (float) (i-startIndex) / dv;
            
            dval = (1-interp) * (float) startVal + interp * (float) endVal;				
            vals[i%size_] = testAndQuantizeYVal( dval );
            
        }
    }
    else
    {
        for (int i = startIndex; i >= stopIndex; i--) 
        {
            interp = (float) (startIndex-i) / dv;
            
            dval = (1-interp) * (float) startVal + interp * (float) endVal;			
            vals[i%size_] = testAndQuantizeYVal( dval );		
            
        }
        
    }
    
	
	// try a little smoothing from the previous chunk	
	// only do this if our sample is large enough
	// may need to revisit when we adjust tempo
	
	int *pSmoothIndices = 0;
	int smoothIndicesInc[] = {startIndex - 2, startIndex - 1, startIndex, startIndex + 1, startIndex + 2 };		
	int smoothIndicesDec[] = {startIndex + 2, startIndex + 1, startIndex, startIndex - 1, startIndex - 2 };
    
    int *smoothIndices = bIncreasingIndex ? smoothIndicesInc : smoothIndicesDec;
    
    
	int iNumSmoothing = 0;
    //	if ( startIndex + 2 <= stopIndex )
    //	{
    //		// use 5 values for smoothing if available
    //		iNumSmoothing = 5;
    //		pSmoothIndices = smoothIndices;
    //	}
    //	else 
    //      
    if ( bIncreasingIndex )
    {                
        
        if ( startIndex + 1 <= stopIndex )
        {
            // use three as a fallback
            iNumSmoothing = 3;
            pSmoothIndices = smoothIndices + 1;
        }
    }
    else
    {
        if ( startIndex - 1 >= stopIndex )
        {
            // use three as a fallback
            iNumSmoothing = 3;
            pSmoothIndices = smoothIndices + 1;
        }        
        
    }
    
	
	
	if ( iNumSmoothing > 0 )
	{		
        
		// we're just interpolating values across the previous boundary
		
		for (int i = 0; i < iNumSmoothing; ++i )		
		{
			if ( pSmoothIndices[i] < 0 )
			{
				pSmoothIndices[i] += size_;				
			}
			
			pSmoothIndices[i] = pSmoothIndices[i] % size_;
		}	
		
		float smoothValStart = vals[ pSmoothIndices[0] ];
		float smoothValEnd = vals[ pSmoothIndices[iNumSmoothing-1] ];
		
		float delta = ( smoothValEnd - smoothValStart ) / (iNumSmoothing - 1);
		
		for (int i = 0; i < iNumSmoothing; ++i )		
		{
			vals[pSmoothIndices[i]] = smoothValStart + i * delta;	
		}	
        
	}
}

//
//
void
ValueGraph::setInterpValues(ValueGraphDataT dataType, int startIndex, int stopIndex, float startVal, float endVal, bool bIncreasingIndex)
{	
    //NSLog( @"start index: %d, stop index: %d\n", startIndex, stopIndex );
    
    
    if ( dataType == eVGDataAudio || dataType == eVGDataBoth )
    {
        setInterpValuesImpl( valuesAudio_, startIndex, stopIndex, startVal, endVal, bIncreasingIndex );
    }
        
    if ( dataType == eVGDataVisual || dataType == eVGDataBoth )
    {
        setInterpValuesImpl( valuesVisual_, startIndex, stopIndex, startVal, endVal, bIncreasingIndex );        
    }
    
    
}

//
//
void ValueGraph::setCurrentValuesImpl( float *vals, int startIndex, int stopIndex, float startVal, float endVal, bool bIncreasingIndex )
{
    bool bAllowWrite = true;
    
    
    bool bTestForMaskedIndices = (state_ == State_Cylinder);
    
    if ( bTestForMaskedIndices )
    {
        
        
        
        
        
        
        
        if ( maskGraphInputIndexLow_ != -1 && maskGraphInputIndexHigh_ != -1 )
        {
            
            // this is really only set up for a simple test assuming increasing indices.
            // if we wanted to do it better actually exclude the masked region from the region and
            // see what's left - but not needed right now.  We'll allow a write  if any part of
            // the region is outside the masked area
            
            int iStartForTesting = startIndex;
            int iStopForTesting = stopIndex;
            int iLowMaskForTesting = maskGraphInputIndexLow_;
            int iHighMaskForTesting = maskGraphInputIndexHigh_;
            
            // first "unwrap" the numbers
            if ( iStopForTesting < iStartForTesting )
            {
                iStopForTesting += size_;
            }
            
            if ( iHighMaskForTesting < iLowMaskForTesting )
            {
                iHighMaskForTesting += size_;
            }
            
            bAllowWrite = ( (iStartForTesting < iLowMaskForTesting) || 
                           (iStopForTesting > iHighMaskForTesting ) );
            
            
            if ( bAllowWrite )
            {
                
                if ( iStartForTesting < iLowMaskForTesting )
                {
                    iStopForTesting = MIN( iStopForTesting, iLowMaskForTesting-1 );
                }
                else if ( iStopForTesting > iHighMaskForTesting )
                {
                    iStartForTesting = MAX( iStartForTesting, iHighMaskForTesting+1 );
                }
                
                
                startIndex = iStartForTesting % size_;
                stopIndex = iStopForTesting % size_;
                
                
            }
            
        }
    }
    
    if ( bAllowWrite )
    {
        //NSLog(@"allow\n" ); 
        
        maskGraphInputIndexLow_ = -1; maskGraphInputIndexHigh_ = -1;
        
        if (quantize_ != 0) {
            int remainder = startIndex % quantize_;
            int firstIndex = startIndex - remainder;
            int lastIndex = firstIndex + quantize_ - 1;
            
            // this prevents us from re-writing into the same quantized section twice
            // during the quantized period of input    
            maskGraphInputIndexLow_ = firstIndex;
            maskGraphInputIndexHigh_ = lastIndex;
            
            if ( bIncreasingIndex )
            {
                setConsecutiveValuesImpl( vals, firstIndex, lastIndex, endVal, bIncreasingIndex);
            }
            else
            {
                setConsecutiveValuesImpl( vals, lastIndex, firstIndex, endVal, bIncreasingIndex);
            }
            
        } else {
            setInterpValuesImpl( vals, startIndex, stopIndex, startVal, endVal, bIncreasingIndex);
        }
    }
    else
    {
        //NSLog(@"not ALLOWED - hi: %d, lo: %d, start: %d, stop: %d\n", maskGraphInputIndexHigh_, maskGraphInputIndexLow_, startIndex, stopIndex ); 
        
    }
}

//
// 
void ValueGraph::setCurrentValues(ValueGraphDataT dataType, int startIndex, int stopIndex, float startVal, float endVal, bool bIncreasingIndex )
{
         
    if ( dataType == eVGDataAudio || dataType == eVGDataBoth )
    {
        setCurrentValuesImpl( valuesAudio_, startIndex, stopIndex, startVal, endVal, bIncreasingIndex );
    }
    
    if ( dataType == eVGDataVisual || dataType == eVGDataBoth )
    {
        setCurrentValuesImpl( valuesVisual_, startIndex, stopIndex, startVal, endVal, bIncreasingIndex );        
    }
    
}

void	
ValueGraph::setValues(ValueGraphDataT dataType, float *values)
{
    if ( dataType == eVGDataAudio || dataType == eVGDataBoth )
    {
        for (int i = 0; i < size_; i++) {
            valuesAudio_[i] = testAndQuantizeYVal( values[i] );
        }
    }
    
    if ( dataType == eVGDataVisual || dataType == eVGDataBoth )
    {
        for (int i = 0; i < size_; i++) {
            valuesVisual_[i] = testAndQuantizeYVal( values[i] );
        }
    }
    
	
	//computeCircleGraph(arcTheta_);
}

//
// duration should have already been set in the constructor
void ValueGraph::setDuration( double dur, double curTime ) 
{ 

	
	double offsetPrev = fmod(curTime, duration_) / duration_;
	double offsetNew = fmod(curTime, dur) / dur;

	timeOffset_ += (offsetPrev - offsetNew) * dur;

		
	// we want the current time to produce the same graph offset set it
	// with the previous duration value
	
	duration_ = dur; 
} 

//
// how far is the graph through the wrapping or unwrapping process?
float ValueGraph::getWrapProgress() const
{
    if ( state_ == State_Wrap || state_ == State_Unwrap || state_ == State_FlatSpeedup )
    {
        if ( wrapDuration_ > 0 )
        {
            return MIN( 1.0f, wrapTime_ / wrapDuration_ );
        }
    }
    
    return 1.0f;
}

void	
ValueGraph::draw(CGContextRef ctx)
{
	CGContextSetFillColorWithColor(ctx, backColor_);
	
	CGContextBeginPath(ctx);
	CGContextAddLines (ctx, backLeftPOINTS_, nLeftPts_);
	CGContextClosePath(ctx);
	
	CGContextFillPath(ctx);

	CGContextBeginPath(ctx);
	CGContextAddLines (ctx, backRightPOINTS_, nRightPts_);
	CGContextClosePath(ctx);
	
	CGContextFillPath(ctx);

	CGContextSetFillColorWithColor(ctx, frontColor_);
	
	CGContextBeginPath(ctx);
	CGContextAddLines (ctx, frontPOINTS_, nFrontPts_);
	CGContextClosePath(ctx);
	
	CGContextFillPath(ctx);
	
	/*
	SelectObject(hdc, graphPen_);
	SelectObject(hdc, graphBackBr_);
	Polygon(hdc, backLeftPOINTS_, nLeftPts_);
	Polygon(hdc, backRightPOINTS_, nRightPts_);

	SelectObject(hdc, graphFrontBr_);
	Polygon(hdc, frontPOINTS_, nFrontPts_);
	*/
}

void	
ValueGraph::drawGL()
{
	const CGFloat *color;
	
	color = CGColorGetComponents (backColor_);
	glColor4f(color[0], color[1], color[2], color[3]);

	
	if (nLeftPts_ > 0) {
		glVertexPointer(2, GL_FLOAT, 0, backLeftPOINTS_);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, nLeftPts_);
	}
	
	if (nRightPts_ > 0) {
		glVertexPointer(2, GL_FLOAT, 0, backRightPOINTS_);	
		glDrawArrays(GL_TRIANGLE_STRIP, 0, nRightPts_);
	}
	
	if (nFrontPts_ > 0) {
		
		color = CGColorGetComponents (frontColor_);
		glColor4f(color[0], color[1], color[2], color[3]);
		
		glVertexPointer(2, GL_FLOAT, 0, frontPOINTS_);	
		glDrawArrays(GL_TRIANGLE_STRIP, 0, nFrontPts_);
	}
}

void
ValueGraph::drawBBoxGL(float cameraRotation)
{
    
        
	CGRect bbox = boundingBox(cameraRotation);    
    
	glDisableClientState(GL_COLOR_ARRAY);

	glLineWidth(1);
	CGPoint rectPts[4];
	rectPts[0].x = bbox.origin.x; rectPts[0].y = bbox.origin.y;
	rectPts[1].x = bbox.origin.x+bbox.size.width; rectPts[1].y = bbox.origin.y;
	rectPts[2].x = bbox.origin.x+bbox.size.width; rectPts[2].y = bbox.origin.y+bbox.size.height;
	rectPts[3].x = bbox.origin.x; rectPts[3].y = bbox.origin.y+bbox.size.height;
	
	glColor4f(0,0,0,1);
	glVertexPointer(2, GL_FLOAT, 0, rectPts);	
	glDrawArrays(GL_LINE_LOOP, 0, 4);
	
	rectPts[0].x = lastHitPoint_.x; rectPts[0].y = lastHitPoint_.y;

	glPointSize(4);
	glVertexPointer(2, GL_FLOAT, 0, rectPts);	
	glDrawArrays(GL_POINTS, 0, 1);

	glEnableClientState(GL_COLOR_ARRAY);
}

void	
ValueGraph::drawGL3D(ofxMSAShape3D *shape3D)
{
	
	int i;
	const CGFloat *color;
	
	if (nFrontPts_ == 0) return;	// not yet updated for first time
	
	if (leftTurnIndex_ == 0) 
		nLeftPts_ = 0;
	else
		nLeftPts_ = leftTurnIndex_+1;
	
	nRightPts_ = (size_ - rightTurnIndex_);
	nFrontPts_ = (rightTurnIndex_ - leftTurnIndex_);
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glTranslatef(trans_.GetX(), trans_.GetY(), trans_.GetZ());
	
	// draw left rear face
	color = CGColorGetComponents (backColor_);
	
	shape3D->begin(GL_TRIANGLE_STRIP);
	
	shape3D->setColor(color[0], color[1], color[2], color[3]);
	
	for (i=0; i < nLeftPts_; i++) {
		
		shape3D->addVertex(graphPts_[i].GetX(),
						   graphPts_[i].GetY(),
						   graphPts_[i].GetZ());
		
		shape3D->addVertex(circlePts_[(leftTurnIndex_-(nLeftPts_-1))+i].GetX(),
						   circlePts_[(leftTurnIndex_-(nLeftPts_-1))+i].GetY(),
						   circlePts_[(leftTurnIndex_-(nLeftPts_-1))+i].GetZ());
	}
	
	shape3D->end();
	
	// draw right rear face

	shape3D->begin(GL_TRIANGLE_STRIP);
	
	shape3D->setColor(color[0], color[1], color[2], color[3]);
	
	for (i=0; i < nRightPts_; i++) {
		
		shape3D->addVertex(graphPts_[rightTurnIndex_+i].GetX(),
						   graphPts_[rightTurnIndex_+i].GetY(),
						   graphPts_[rightTurnIndex_+i].GetZ());
		
		shape3D->addVertex(circlePts_[(size_-nRightPts_)+i].GetX(),
						   circlePts_[(size_-nRightPts_)+i].GetY(),
						   circlePts_[(size_-nRightPts_)+i].GetZ());
	}
	
	shape3D->end();
	
	// draw front face
	color = CGColorGetComponents (frontColor_);

	shape3D->begin(GL_TRIANGLE_STRIP);

	shape3D->setColor(color[0], color[1], color[2], color[3]);

	for (i=0; i < nFrontPts_; i++) {
		
		shape3D->addVertex(graphPts_[leftTurnIndex_+i].GetX(),
						   graphPts_[leftTurnIndex_+i].GetY(),
						   graphPts_[leftTurnIndex_+i].GetZ());
		
		shape3D->addVertex(circlePts_[(rightTurnIndex_-nFrontPts_)+i].GetX(),
						   circlePts_[(rightTurnIndex_-nFrontPts_)+i].GetY(),
						   circlePts_[(rightTurnIndex_-nFrontPts_)+i].GetZ());
	}
	
	shape3D->end();
	
	glPopMatrix();
}


void	
ValueGraph::drawGL3DAA(ofxMSAShape3D *shape3D, float rotation)
{
	int i;
	const CGFloat *color;

    
	if (nFrontPts_ == 0) return;	// not yet updated for first time
	
	if (leftTurnIndex_ == 0) 
		nLeftPts_ = 0;
	else
		nLeftPts_ = leftTurnIndex_+1;
	
	nRightPts_ = (size_ - rightTurnIndex_);
	nFrontPts_ = (rightTurnIndex_ - leftTurnIndex_);

    
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	    
    glTranslatef(trans_.GetX(), trans_.GetY(), trans_.GetZ());
	glRotatef(rotation, 1, 0, 0);
    
		
	// draw left rear face
	color = CGColorGetComponents (backColor_);
	
	shape3D->begin(GL_TRIANGLE_STRIP);	
	shape3D->setColor(color[0], color[1], color[2], color[3]);
	
	for (i=0; i < nLeftPts_-1; i++) {		

        addVertSegmentAA(shape3D, color,
                         graphPts_[i], circlePts_[(leftTurnIndex_-(nLeftPts_-1))+i],
                         graphPts_[i+1], circlePts_[(leftTurnIndex_-(nLeftPts_-1))+i+1]);
                
	}
	
	shape3D->end();
	
	// draw right rear face
	
	shape3D->begin(GL_TRIANGLE_STRIP);
	
	shape3D->setColor(color[0], color[1], color[2], color[3]);
	
	for (i=0; i < nRightPts_-1; i++) {
		

        addVertSegmentAA(shape3D, color,
                         graphPts_[rightTurnIndex_+i], circlePts_[(size_-nRightPts_)+i],
                         graphPts_[rightTurnIndex_+i+1], circlePts_[(size_-nRightPts_)+i+1]);
		
	}
	
	shape3D->end();
	
	// draw front face
	color = CGColorGetComponents (frontColor_);
	
	shape3D->begin(GL_TRIANGLE_STRIP);
	
	shape3D->setColor(color[0], color[1], color[2], color[3]);
	
	for (i=0; i < nFrontPts_-1; i++) {
		
    
        addVertSegmentAA(shape3D, color,
                         graphPts_[leftTurnIndex_+i], circlePts_[(rightTurnIndex_-nFrontPts_)+i],
                         graphPts_[leftTurnIndex_+i+1], circlePts_[(rightTurnIndex_-nFrontPts_)+i+1]);
        
        
	}
	        
	shape3D->end();
	
    
    if ( state_ == State_Flat )
    {
        // how much to adjust for?  Otherwise the cursor is behind.
        // Doesn't matter as much in the portrait view b/c of no
        // exact cursor
        int offset = size_ * computeLatencyForDrawing();
        
        drawPlayhead( (graphOffset_ + size_ / 2 - offset) % size_, shape3D );
    }
    
	glPopMatrix();
}

void
ValueGraph::transformPoly(matrix_4x4 const &xform, point_4* poly, point_4* xformPoly, int nVerts)
{
	for (int i = 0; i < nVerts; ++i) {
		xformPoly[i] = xform * poly[i];	
	}
}

void
ValueGraph::ptsTo2d(point_4 *pts3d, CGPoint *pts2d, int nPts)
{
	for (int i = 0; i < nPts; i++) {
		pts2d[i].x = pts3d[i].GetX();
		pts2d[i].y = pts3d[i].GetY();
	}
}

void
ValueGraph::createCache(float theta)
{
	int i,j;
	//int startIndex, index, backIndex, i;

	if (leftTurnIndex_ == 0) 
		nLeftPts_ = 0;
	else
		nLeftPts_ = leftTurnIndex_+1;

	nRightPts_ = (size_ - rightTurnIndex_);
	nFrontPts_ = (rightTurnIndex_ - leftTurnIndex_);

	// left rear face
	for (i=0,j=0; i < nLeftPts_; i++) {
		backLeftPOINTS_[j].x = xformGraphPts_[i].GetX();
		backLeftPOINTS_[j].y = xformGraphPts_[i].GetY();
		j++;
		backLeftPOINTS_[j].x = xformBotCirclePts_[(leftTurnIndex_-(nLeftPts_-1))+i].GetX();
		backLeftPOINTS_[j].y = xformBotCirclePts_[(leftTurnIndex_-(nLeftPts_-1))+i].GetY();
		j++;
	}

	// right rear face
	for (i=0,j=0; i < nRightPts_; i++) {
		backRightPOINTS_[j].x = xformGraphPts_[rightTurnIndex_+i].GetX();
		backRightPOINTS_[j].y = xformGraphPts_[rightTurnIndex_+i].GetY();
		j++;
		backRightPOINTS_[j].x = xformBotCirclePts_[(size_-nRightPts_)+i].GetX();
		backRightPOINTS_[j].y = xformBotCirclePts_[(size_-nRightPts_)+i].GetY();
		j++;
	}
	
	// front face

	for (i=0,j=0; i < nFrontPts_; i++) {
		frontPOINTS_[j].x = xformGraphPts_[leftTurnIndex_+i].GetX();
		frontPOINTS_[j].y = xformGraphPts_[leftTurnIndex_+i].GetY();
		j++;
		frontPOINTS_[j].x = xformBotCirclePts_[(rightTurnIndex_-nFrontPts_)+i].GetX();
		frontPOINTS_[j].y = xformBotCirclePts_[(rightTurnIndex_-nFrontPts_)+i].GetY();
		j++;
	}
	
	nLeftPts_  *= 2;
	nRightPts_ *= 2;
	nFrontPts_ *= 2;

	//startIndex = ROUNDINT(theta / TWOPI * (float)size_);
}




//
//
void ValueGraph::drawPlayhead( int graphOffset, ofxMSAShape3D *shape3D )
{
    if ( shape3D )
    {
        shape3D->begin( GL_TRIANGLE_STRIP );
                       
        shape3D->setColor( 255, 255, 255, 255 );
        CGFloat color[4] = { 255.0, 255.0, 255.0, 255.0 };
        
        
        point_4 topLeft = graphPts_[graphOffset];
        point_4 bottomLeft = circlePts_[graphOffset];
        point_4 topRight = topLeft;
        point_4 bottomRight = bottomLeft;
        
        topRight.SetX( topRight.GetX() + 1);
        bottomRight.SetX( bottomRight.GetX() + 1);
        
        addVertSegmentAA(shape3D, color,
                         topLeft, bottomLeft,
                         topRight, bottomRight );
        
                
        shape3D->end();
                            
    }
    
}

void
ValueGraph::invertCachePointsY(float height)
{
	int i;
	for (i=0; i<nLeftPts_; i++) {
		backLeftPOINTS_[i].y = height - backLeftPOINTS_[i].y;
	}
	for (i=0; i<nRightPts_; i++) {
		backRightPOINTS_[i].y = height - backRightPOINTS_[i].y;
	}
	for (i=0; i<nFrontPts_; i++) {
		frontPOINTS_[i].y = height - frontPOINTS_[i].y;
	}
}

void
ValueGraph::scalePoints(float s)
{
	int i;
	for (i=0; i<nLeftPts_; i++) {
		backLeftPOINTS_[i].x *= s;
		backLeftPOINTS_[i].y *= s;
	}
	for (i=0; i<nRightPts_; i++) {
		backRightPOINTS_[i].x *= s;
		backRightPOINTS_[i].y *= s;
	}
	for (i=0; i<nFrontPts_; i++) {
		frontPOINTS_[i].x *= s;
		frontPOINTS_[i].y *= s;
	}
}
/*
void	
ValueGraph::startWriting(float normVal)
{
	writingVal_ = roundf(normVal_*(float)maxVal_);
	writing_ = true;
}

void	
ValueGraph::stopWriting()
{
	writing_ = false;
}

void
ValueGraph::updateWrite()
{
	
}
*/
// update animation and any cached graphics
void	
ValueGraph::update(double time)
{
        
    
	float arcTheta;
	matrix_4x4 xform;//, scale;

	//time = 0;
	//tilt_ = sin(time)/4;

	(void) updateGraphOffset(time);	// computes proper graph offset
	
	switch (state_) {
	case State_Cylinder:
		scrolling_ = true;
		computeCircleGraph(TWOPI, graphOffset_);
		break;
	case State_Unwrap:
		if (graphOffset_ - lastGraphOffset_ < 0) 
		{
			scrolling_ = false;
		}
			
		wrapTime_ += (time - lastTime_);
		if (wrapTime_ >= wrapDuration_) {
			state_ = State_Flat;
			computeFlatGraph(graphOffset_);
		} else {
			arcTheta = TWOPI * (1 - wrapTime_ / wrapDuration_);
			computeCircleGraph(arcTheta, graphOffset_);
		}
		break;
	case State_Wrap:
		scrolling_ = true;
		wrapTime_ += (time - lastTime_);
		if (wrapTime_ >= wrapDuration_) {
			state_ = State_Cylinder;
			computeCircleGraph(TWOPI, graphOffset_);
		} else {
			arcTheta = TWOPI * (wrapTime_ / wrapDuration_);
			computeCircleGraph(arcTheta, graphOffset_);
		}
		break;
	case State_FlatSpeedup:
		scrolling_ = true;
		if (ABS(curOffset_ - graphOffset_) < 30) {
			state_ = State_Wrap;
		} else {
			curOffset_ = (curOffset_+10)%size_;
			computeFlatGraph(curOffset_);
		}
		break;
	case State_Flat:
		if (graphOffset_ - lastGraphOffset_ < 0) {
			scrolling_ = false;
		}
		curOffset_ = 0;
		computeFlatGraph(graphOffset_);
		break;
	}
	lastGraphOffset_ = graphOffset_;
	
	if (leftTurnIndex_ == 0) 
		nLeftPts_ = 0;
	else
		nLeftPts_ = leftTurnIndex_+1;
	
	nRightPts_ = (size_ - rightTurnIndex_);
	nFrontPts_ = (rightTurnIndex_ - leftTurnIndex_);
	
#if 0
	//float theta = TWOPI * fmod(time, duration_) / duration_;
	float theta = 0;

	// compute scale/rotate xformation matrix
	xform.setIdentity();
/*
	scale.SetElement(0,0, 0.5);
	scale.SetElement(1,1, 0.5);
	scale.SetElement(2,2, 0.5);
*/
	xform.ConcatenateXTranslation(trans_.GetX());
	xform.ConcatenateYTranslation(trans_.GetY());

	xform.ConcatenateZRotation(roll_*TODEGREES);
	xform.ConcatenateXRotation(tilt_*TODEGREES);
	//xform.ConcatenateYRotation(theta*TODEGREES);

	//xform = xform * scale;

	transformPoly(xform, graphPts_, xformGraphPts_, size_ );
	transformPoly(xform, circlePts_, xformBotCirclePts_, size_ );

	xform.setIdentity();

	xform.ConcatenateXTranslation(trans_.GetX());
	xform.ConcatenateYTranslation(trans_.GetY() + (float) maxVal_);

	xform.ConcatenateZRotation(roll_*TODEGREES);
	xform.ConcatenateXRotation(tilt_*TODEGREES);
	//xform.ConcatenateYRotation(theta*TODEGREES);

	xform = xform;// * scale;

	transformPoly(xform, circlePts_, xformTopCirclePts_, size_ );

	createCache(theta);
#endif

	lastTime_ = time;
}



//
//
int ValueGraph::indexForTime(double time) const
{
    float latency = 0; // this is used for drawing as well as audio so we don't want latency here
	return ROUNDINT(graphOffset_ - latency + size_/2) % size_;	
}

//
//
int ValueGraph::updateGraphOffset( double time )
{   
    
    const float latency = 0.00f;
    
    double modVal = fmod(time + timeOffset_ - latency, duration_);
    
    
	graphOffset_ = ROUNDINT((float) size_ * (modVal / duration_));
    return graphOffset_;
}



void
ValueGraph::computeFlatGraph(int graphOffset_)
{
	leftTurnIndex_ = 0;
	rightTurnIndex_ = size_;
	float x, y, z, halfWidth;
	
	halfWidth = (float)size_ / 2.0;
	z = -1;

	if (!scrolling_) 
	{
		graphOffset_ = 0;
	}

    
	for (int i = 0; i < size_; i++) {
		x = hScale_ * (-halfWidth + (float) i);

		y = (float) valuesVisual_[(graphOffset_+i)%size_] * vScale_;
		
		// our y values are normalized.  give them height here
		y *= maxVal_;
        
        if (y < MIN_CROWN_PIXEL_HEIGHT) y = MIN_CROWN_PIXEL_HEIGHT;	// leave hairline
        
		graphPts_[i].SetPos(-x, -y, z);
		circlePts_[i].SetPos(-x, 0, z);
	}
}

//
// helper so that our drawing functions can adjust to be in sync with the music...
// otherwise they're always a little ahead
float ValueGraph::computeLatencyForDrawing() const
{
    return (ESTIMATED_AUDIO_LATENCY / tempoAdjustedDuration_);
}

void 
ValueGraph::computeCircleGraph(float arcTheta, int graphOffset )
{
	
	//arcTheta = M_PI *1.8f;
	
    // this wasn't working out
    //float estimatedLatency = computeLatencyForDrawing();    
    
//    graphOffset -= estimatedLatency * size_;
//    if ( graphOffset < 0 )
//    {
//        graphOffset += size_;
//    }
    
	float theta;
	// Compute radius to make arc-length of circle arc constant (= size_)
	
	// here we're account for the fact we can now vary graph size so mult by 
	// originalGraphToSize_ to keep all original calculations intact

	//radius_ = hScale_ * (float) size_ / arcTheta * originalGraphToSize_; 	
	radius_ = hScale_ * (float) size_ / arcTheta;
	
	
	float dTheta = arcTheta / (float) (size_-1);
	float thetaStart = M_PI_2 - (TWOPI - arcTheta) / 2.0;
		
	float x, y, z, lastZ = 1; // arbitrary positive value

	leftTurnIndex_ = 0;
	rightTurnIndex_ = size_-1;

	if (!scrolling_) 
	{
		graphOffset = 0;
	}
	
	//NSLog( @"theta start: %f, arc theta: %f\n", thetaStart, arcTheta );
	
	// proceed around circle starting at back (pi/2)
	for (int i = 0; i < size_; i++) {
		theta = thetaStart - (float) i * dTheta;
		x = radius_ * cosf(theta);
		z = radius_ * sinf(theta);

		y = (float) valuesVisual_[(graphOffset+i)%size_] * vScale_;
		
		// our y values are normalized.  give them height here
		y *= maxVal_;
		
		if (y < MIN_CROWN_PIXEL_HEIGHT) y = MIN_CROWN_PIXEL_HEIGHT;	// leave hairline
		// set actual points so frontmost lie in z=0 plane
		graphPts_[i].SetPos(x, -y, z+radius_);
		circlePts_[i].SetPos(x, 0, z+radius_);

		// mark crossing indices
		if (z <= 0 && lastZ > 0) {
			leftTurnIndex_ = i-1;
			if (i == 0) leftTurnIndex_ = 0;
		} else if (z > 0 && lastZ < 0) {
			rightTurnIndex_ = i;
		}
		lastZ = z;
		


	}
}


//
//
float * ValueGraph::valuesForDataType( ValueGraphDataT dataType )
{
    return (dataType == eVGDataAudio) ? valuesAudio_ : valuesVisual_;    
}


CGRect 
ValueGraph::boundingBox(float cameraRotation)
{
	CGRect bbox;
	
	float left, right, top, bottom;
	
	//cameraRotation = 0;
	
	if (nFrontPts_ == 0) return CGRectMake(0, 0, 0, 0);	// not yet updated for first time

	

	// orthographic projection, so just find top/bottom by rotating around x-axis 

	bottom = trans_.GetY() + 0;
	// hacked!! $$$$
	
	//NSLog( @"ty: %f, vscale: %f, max: %f\n", trans_.GetY(), vScale_, maxVal_ );
	
	if ( state_ == State_Flat ||
		 state_ == State_FlatSpeedup )
	{
		// flat state
		top = trans_.GetY() + vScale_*maxVal_*VSCALE_FUDGE * 1.09; 
		left = graphPts_[0].GetX() + trans_.GetX();
		right = graphPts_[size_-1].GetX() + trans_.GetX();
	}
	else 
	{
		// cylinder or transition
		right = circlePts_[leftTurnIndex_].GetX() + trans_.GetX();
		left = circlePts_[rightTurnIndex_].GetX() + trans_.GetX();
        
        float sidePart = vScale_*maxVal_*VSCALE_FUDGE;        
        float topPart = 2*radius_ * sinf( ( cameraRotation / 360.0f ) * 2.0 * M_PI );
		top = trans_.GetY() + sidePart + topPart * .95; 
    }
    
	bbox = CGRectMake(left, bottom, right-left, bottom-top);
    
	return bbox;
}

bool 
ValueGraph::intersects(CGPoint p, float cameraRotation, CGPoint *pOutNormalizedPtInGraph, float scaleBoundingBox )
{
	CGRect bbox = boundingBox(cameraRotation);
	// compute bounding box
		

    // we give the option to inflate the bounding box (should pull into own function)
    if ( scaleBoundingBox >= 0 )
    {
        float newWidth = bbox.size.width * scaleBoundingBox;
        float newHeight = bbox.size.height * scaleBoundingBox;
        
        float origXAdjust = -(newWidth - bbox.size.width) / 2.0f;
        float origYAdjust = -(newHeight - bbox.size.height) / 2.0f;
                
        bbox = CGRectMake(bbox.origin.x + origXAdjust, bbox.origin.y + origYAdjust, newWidth, newHeight );        

    }
    
    
    
	lastHitPoint_ = p;
	
	if (CGRectContainsPoint(bbox, p))
    {
        if ( pOutNormalizedPtInGraph )
        {
            *pOutNormalizedPtInGraph = CGPointMake( (p.x - bbox.origin.x) / bbox.size.width, (p.y - bbox.origin.y) / bbox.size.height );
        }
        
		return true;
    }
	else 
    {
        if ( pOutNormalizedPtInGraph )
        {
            *pOutNormalizedPtInGraph = CGPointMake(0.0f, 0.0f);
        }
		return false;
    }
}

//
// constrain the point to the bounding box of the graph and return the
// resulting normalized value
CGPoint ValueGraph::constrainAndNormalizePointInGraph( CGPoint p, float cameraRotation )
{
    CGRect bbox = boundingBox(cameraRotation);
    
    
    // the bounding box code is totally messed up but don't have time
    // to fix right now :(
    // so going to just adjust this code to work with the bad values.
    // this code is only used in landscape mode right now and the bbox
    // is messed up in different ways in the two modes (!) 
    // this will just be adjusted to work in landscape mode. 
    // this will be a task to straighten out if we ever have the time or cause
    // to do so... yuck
    
    
    
    float x = 0.0f;
    float y = 0.0f;
    
    CGSize winSize = [[CCDirector sharedDirector] winSizeInPixels];
    
    // this modification is a HACK for landcape mode.. sorry!
    bbox = CGRectMake( winSize.width - bbox.origin.x, winSize.height - bbox.origin.y, -bbox.size.width, -bbox.size.height );
    
    
    if ( p.x < bbox.origin.x )
    {
        x = 0.0f;
    }
    else if ( p.x > bbox.origin.x + bbox.size.width )
    {
        x = 1.0f;
    }
    else 
    {
        x = (p.x - bbox.origin.x) / bbox.size.width;
    }

    if ( p.y < bbox.origin.y )
    {
        y = 0.0f;
    }
    else if ( p.y > bbox.origin.y + bbox.size.height )
    {
        y = 1.0f;
    }
    else 
    {
        y = (p.y - bbox.origin.y) / bbox.size.height;
    }

    return CGPointMake( x, y );
    
   
}

