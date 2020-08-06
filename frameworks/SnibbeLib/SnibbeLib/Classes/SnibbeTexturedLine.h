//
//  SnibbeTexturedLine.h
//  SnibbeLib
//
//  Created by Graham McDermott on 8/19/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//

#ifndef __TEXTURED_LINE_H__
#define __TEXTURED_LINE_H__

#include <vector>
#import <UIKit/UIKit.h>
#include "ofxMSAShape3D.h"

#ifdef USING_COCOS_2D

class SnibbeTexturedLine
{
    
public:

    typedef enum
    {
        eStartSegment = 0,
        eMidSegment,
        eEndSegment,
        eStartEndSegment // special case for 2-point line
    } SegmentT;
    
    SnibbeTexturedLine( std::vector<CGPoint>& points, unsigned int textureID, float width, float alpha, ofxMSAShape3D *shape3D, std::vector<float> *pPointAlphas = 0 );

    void setSharpEnds( bool bSharpEnds ) { sharpEnds_ = bSharpEnds; }    
    void draw();
    
    static void init( int maxPathVerts );
    static void shutdown();
    
private:
    
    static int msMaxPathVerts;
    static int msMaxPointsInStrip;
    
    static CGPoint * secondStripVerts;
    static CGPoint * secondStripTexCoords;
    static float * secondStripAlpha;
    
    
    std::vector<CGPoint>& points_;
    unsigned int textureID_;
    float width_;
    float alpha_;    
    std::vector<float> * ptAlphaVals_;
    
    ofxMSAShape3D *shape3D_;
    
    bool sharpEnds_; 
    
};



#endif // #ifdef USING_COCOS_2D
#endif // __TEXTURED_LINE_H__