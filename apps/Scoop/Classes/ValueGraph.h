/*
 * ValueGraph.h
 * (c) 2010 Scott Snibbe 
 */

#pragma once

#include "dumb3d.h"
#include "ofxMSAShape3D.h"
#include "ScoopDefs.h"
#include "ScoopUtils.h"

#define VSCALE_FUDGE 0.92	// $$$$ don't ask



/////////////////////////////////////////////////////////////////////////
// class ValueGraphState
// ----------------------
// represents the state needed to save/restore a single value graph
/////////////////////////////////////////////////////////////////////////

class ValueGraphState
{
        
public:
    
    ValueGraphState();
    ~ValueGraphState();
    
    void clear();
    void setValues( float *vAud, float *vVis, int numValues );
    int  getNumValues() const { return numValues_; }
    float const * getValuesAudio() const { return valuesAudio_; }
    float const * getValuesVisual() const { return valuesVisual_; }

    
private:
    
    float *valuesAudio_;
    float *valuesVisual_;

int numValues_;
    
};


/////////////////////////////////////////////////////////////////////////
// class ValueGraph
// ---------------------
/////////////////////////////////////////////////////////////////////////


typedef enum
{
    eVGDataAudio = 0,
    eVGDataVisual,
    eVGDataBoth
    
} ValueGraphDataT;


class ValueGraph {
public:
	enum State {
		State_Cylinder,
		State_Unwrap,
		State_Wrap,
		State_Flat,
		State_FlatSpeedup
	};

	ValueGraph(int size, float duration, int maxVal,
			   CGColorRef frontColor, 
			   CGColorRef backColor, 
			   CGColorRef bgColor);
	~ValueGraph();
	
	//void	startWriting(float normVal);
	//void	stopWriting();	

    void saveState( ValueGraphState& state );
    void restoreState( ValueGraphState& state );

    int  getSize() const { return size_; }
    
//	int setValue(int index, int valueVis, int valueAud) 
//		{ if (index >= size_) return -1;
//		  int oldVal = values_[index]; values_[index] = value; 
//		  return oldVal; }

	// values for all setter methods should be normalized floats (0-1)
	
	void setValues(ValueGraphDataT dataType, float *values);
	void setConsecutiveValues( ValueGraphDataT dataType, int startIndex, int stopIndex, float val, bool bIncreasingIndex = true);
	void setInterpValues( ValueGraphDataT dataType, int startIndex, int stopIndex, float startval, float endVal, bool bIncreasingIndex = true);
	// automatically chooses to quantize based on graph state
	void setCurrentValues( ValueGraphDataT dataType, int startIndex, int stopIndex, float startval, float endVal, bool bIncreasingIndex = true);

    void values(float time, float& outA, float& outV ) { int iInd = indexForTime(time); outA = valuesAudio_[iInd]; outV = valuesVisual_[iInd]; }
    void valuesAtIndex( int iIndex, float& outA, float& outV ) const { assert( iIndex < size_ && iIndex >= 0 ); outA = valuesAudio_[iIndex]; outV = valuesVisual_[iIndex]; }
    
    

	void setDuration( double dur, double curTime );
	
	void unwrap(float duration) { state_ = State_Unwrap; 
								   wrapDuration_ = duration;
								   wrapTime_ = 0; }
	void wrap(float duration) { state_ = State_FlatSpeedup; 
								 wrapDuration_ = duration;
								 wrapTime_ = 0; }

    float getWrapProgress() const;
    
	State state() { return state_; }
	int	quantize() { return quantize_; }
	
    void setQuantize(int q) { quantize_ = q; }		
    void setQuantizeY( float *quantizeSteps, int numSteps );
    float testAndQuantizeYVal( float inVal );

	void scale(float hScale, float vScale) { hScale_ = hScale; vScale_ = vScale; }
	void translation(point_4 trans) { trans_ = trans; }

	void roll(float theta) { roll_ = theta; }
	void resetGraph(float val);
	void randomizeGraph();

    bool isScrolling() const { return scrolling_; }
    
	void	draw(CGContextRef ctx);
	void	drawGL();
	void	drawGL3D(ofxMSAShape3D *shape3D);
	void	drawGL3DAA(ofxMSAShape3D *shape3D, float rotation);
	void	drawBBoxGL(float cameraRotation);
	
	void	update(double time);	// update animation and any cached graphics

	int		maxVal() { return maxVal_; }
	
    void    setTempoAdjustedDuration( float t ) { tempoAdjustedDuration_ = t; }
	
	
	
	int     indexForTime(double time) const;
	int     updateGraphOffset( double time );		
	
	void	invertCachePointsY(float height);
	void	scalePoints(float s);
	
	bool	intersects(CGPoint p, float cameraRotation,  CGPoint *pOutNormalizedPtInGraph = 0, float scaleBoundingBox = -1.0f);	// true if point touches graph (for hit testing)
    CGPoint constrainAndNormalizePointInGraph( CGPoint p, float cameraRotation );	
    
	CGRect	boundingBox(float cameraRotation);
	
    
    float computeLatencyForDrawing() const; // audio latency relative to current length of loop
	
    void	sliderScreenYRange(float& bottom, float& top) {		
		bottom = trans_.GetY() + 0;
        
        float multiplier = 1.0f;
        if ( state_ == State_Cylinder )
        {
            multiplier = 0.96f;
        }
        else
        {
            multiplier = 1.09f;
        }
        
		top = trans_.GetY() - vScale_*maxVal_*VSCALE_FUDGE * multiplier; 
	}
		
private:
	//void updateWrite();
    
    float * valuesForDataType( ValueGraphDataT dataType );
	void setConsecutiveValuesImpl( float *vals, int startIndex, int stopIndex, float val, bool bIncreasingIndex = true);
    void setInterpValuesImpl( float *vals, int startIndex, int stopIndex, float startVal, float endVal, bool bIncreasingIndex = true);
	void setCurrentValuesImpl( float *vals, int startIndex, int stopIndex, float startVal, float endVal, bool bIncreasingIndex = true);

    
	void computeCircleGraph(float arcTheta, int graphOffset);
	void computeFlatGraph(int graphOffset);
	void transformPoly(matrix_4x4 const &xform, point_4* poly, point_4* xformPoly, int nVerts);
	void ptsTo2d(point_4 *pts3d, CGPoint *pts2d, int nPts);
	void createCache(float theta);
	
	void addVertSegmentAA(ofxMSAShape3D *shape3D, const CGFloat *color,
						  point_4& tl, point_4& bl, point_4& tr, point_4& br);
	void addVertSegmentAAFlat(ofxMSAShape3D *shape3D, const CGFloat *color,
							  point_4& tl, point_4& bl, point_4& tr, point_4& br);
	
	void setState( State s );
	void drawPlayhead( int graphOffset, ofxMSAShape3D *shape3D );
    
	State state_;
	
	int size_;
	double duration_;
	int maxVal_;
	int quantize_;
	
    float quantizeStepsY_[MAX_NUM_QUANTIZE_STEPS];
    int   numQuantizeStepsY_;
    
    int maskGraphInputIndexLow_;
    int maskGraphInputIndexHigh_;
    
	float radius_, height_, tilt_, arcTheta_;
	float hScale_, vScale_;
	point_4 trans_;
	float roll_;

	int graphOffset_;	// actual current offset from start
	int latency_;

	double lastTime_;
	double timeOffset_;  // this is an offset that allows us to stay in the same graph index when we adjust tempo (duration)
	float wrapTime_, wrapDuration_;
    float tempoAdjustedDuration_;
	int lastGraphOffset_, curOffset_;

	int leftTurnIndex_, rightTurnIndex_;
	int nLeftPts_, nRightPts_, nFrontPts_;

	bool scrolling_;
	
	//bool writing_;
	//int	 writingVal_;

	float *valuesVisual_;
	float *valuesAudio_;
    
    
	point_4 *graphPts_;
	point_4 *circlePts_;
	point_4 *xformGraphPts_;
	point_4 *xformTopCirclePts_;
	point_4 *xformBotCirclePts_;

	CGPoint *cacheGraphPOINTS_;
	CGPoint *frontPOINTS_;
	CGPoint *backLeftPOINTS_;
	CGPoint *backRightPOINTS_;
	
	CGColorRef	frontColor_;
	CGColorRef	backColor_;
	CGColorRef	bgColor_;
	
	CGPoint	lastHitPoint_;
    
	float originalGraphToSize_; // account for parts of code that rely on the original graph size constant
};

/*
 draw an antialiased segment using vertex opacity:
 http://stackoverflow.com/questions/1813035/opengl-es-iphone-drawing-anti-aliased-lines
 
 (top left - tl)	1 -- 2	(transparent)	(top right - tr)
                       /
                      /
					3 -- 4	(opaque)
					   /
					  /
					5 -- 6  (opaque)
					   /
					  /
 (bot left - tl)	7 -- 8	(transparent)	(bot right - br)
 */

inline void
ValueGraph::addVertSegmentAA(ofxMSAShape3D *shape3D, const CGFloat *color,
							 point_4& tl, point_4& bl, point_4& tr, point_4& br)
{
	// 1
	shape3D->setColor(color[0], color[1], color[2], 0.0);	// transparent
	
	shape3D->addVertex(tl.GetX(),tl.GetY(), tl.GetZ());
	// 2
	shape3D->addVertex(tr.GetX(),tr.GetY(), tr.GetZ());
	// 3
	shape3D->setColor(color[0], color[1], color[2], 1.0);	// opaque
	
	shape3D->addVertex(tl.GetX(),tl.GetY()+1, tl.GetZ());
	// 4
	shape3D->addVertex(tr.GetX(),tr.GetY()+1, tr.GetZ());
	// 5
	shape3D->addVertex(bl.GetX(),bl.GetY()-1, bl.GetZ());
	// 6
	shape3D->addVertex(br.GetX(),br.GetY()-1, br.GetZ());
	
	shape3D->setColor(color[0], color[1], color[2], 0.0);	// transparent
	// 7
	shape3D->addVertex(bl.GetX(),bl.GetY(), bl.GetZ());
	// 8
	shape3D->addVertex(br.GetX(),br.GetY(), br.GetZ());
}

inline void
ValueGraph::addVertSegmentAAFlat(ofxMSAShape3D *shape3D, const CGFloat *color,
								 point_4& tl, point_4& bl, point_4& tr, point_4& br)
{
	// 1
	shape3D->setColor(color[0], color[1], color[2], 0.0);	// transparent
	
	shape3D->addVertex(tl.GetX(),tl.GetY(), tl.GetZ());
	// 2
	shape3D->addVertex(tr.GetX(),tl.GetY(), tr.GetZ());
	// 3
	shape3D->setColor(color[0], color[1], color[2], 1.0);	// opaque
	
	shape3D->addVertex(tl.GetX(),tl.GetY()+1, tl.GetZ());
	// 4
	shape3D->addVertex(tr.GetX(),tl.GetY()+1, tr.GetZ());
	// 5
	shape3D->addVertex(bl.GetX(),bl.GetY()-1, bl.GetZ());
	// 6
	shape3D->addVertex(br.GetX(),br.GetY()-1, br.GetZ());
	
	shape3D->setColor(color[0], color[1], color[2], 0.0);	// transparent
	// 7
	shape3D->addVertex(bl.GetX(),bl.GetY(), bl.GetZ());
	// 8
	shape3D->addVertex(br.GetX(),br.GetY(), br.GetZ());
}


