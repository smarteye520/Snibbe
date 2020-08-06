/* MBrush.H
 *
 * Motion Brush Stroke
 * (c) 1989-2010 Scott Snibbe
 *
 * class MBrush
 * ------------
 * MBrush represents a brush stroke and encapsulates the notions
 * of location, rotation, scale and brush shape.
 *
 *
 */



#pragma once

class MBrush;
class MShape;
class MShapeInstance;
@class MPArchiveBrush;
class MPActionBrush;

#include "defs.H"
#include "ofxMSAShape3D.h"

#define CACHE_SIZE 10

//enum MBrushType { NONE=-1, LINE=0, RECT=1, TRIANGLE=2, CIRCLE=3, CLOVER=4};

class MBrush {
 public:
    MBrush();
    ~MBrush();

    void        set_pts(float *pt1, float *pt2, float w, float theta);
    
    
	void		drawGL(ofxMSAShape3D *shape3D);
	void		drawGLLines(ofxMSAShape3D *shape3D);	// debug draw - just outlines
    void        drawOntoCanvas(CGContextRef ctx, bool drawAlpha=true);
    
    void        acquireUniqueID();
    
    //void        draw(/* overriding type, width */);
    //void        rotate_pts(float *center, float theta);
    //void        scale_pts(float *center, float sx, float sy);
    //void        print(FILE *f);
    //void        setBrushType( MBrushType t );
        
    //unsigned long       time;       // timestamp = frame # since start
    
    void        clear( bool clearUserData = false );

    void         retransform();
    
    float        getAlpha() const { return color[3]; }
    void         setAlpha( float a ) { color [3] = a; }
    
    void         setZOrder( unsigned int z ) { zOrder_ = z; }
    unsigned int getZOrder() const { return zOrder_; }
    
    bool         getConstantOutlineWidth() const { return constantOutlineWidth_; }
    void         setConstantOutlineWidth( bool bConstant ) { constantOutlineWidth_ = bConstant; }
    
    //unsigned int getUniqueID() const { return uniqueID_; }
    
    unsigned int getUserData() const { return userData_; }
    void         setUserData( unsigned int iUD ) { userData_ = iUD; }
    
    void setShape( MShape * pShape );    
    bool hasShape() const { return shapeInstance_; }
    
    void setOwnsShapeInstance( bool bOwns ) { ownsShapeInstance_ = bOwns; }
    
    
    MColor      color;
    bool        fill;
    
    // archiving
    
    MPArchiveBrush * toArchiveBrush();
    void             fromArchiveBrush( MPArchiveBrush * src );
    void             copyFrom( MBrush * src );
    
    // networking helpers
    
    void             populateBrushAction( MPActionBrush * pAB, int frame );
    
private:
    
    //static unsigned int nextUID;
    //static unsigned int nextUniqueID();

    

    bool        constantOutlineWidth_;
    bool        ownsShapeInstance_;

    
    unsigned int userData_;
    
    CGPoint    centerPt_;
    float      scaleX_;
    float      scaleY_;
    float      rot_;
 
    unsigned   int zOrder_;
    unsigned   int uniqueID_;
    
    float      p1[2], p2[2];
    float      width;          // in vp coordinates
    
    // cached geometry, a list of 4 points
    //float      cache[CACHE_SIZE][2];
 
    MShapeInstance *   shapeInstance_;
    
    //void        drawSmoothLineVO(CGPoint pos1, CGPoint pos2, float width, float *color, ofxMSAShape3D *vertexObject);
};


//
//inline void 
//MBrush::drawSmoothLineVO(CGPoint pos1, CGPoint pos2, float width, float *color, ofxMSAShape3D *vertexObject)
//{
//    GLfloat lineVertices[12];
//    CGPoint dir, tan, microExtension;
//    
//    dir.x = pos2.x - pos1.x;
//    dir.y = pos2.y - pos1.y;
//    float len = sqrtf(dir.x*dir.x+dir.y*dir.y);
//    if(len<0.00001)
//        return;
//    dir.x = dir.x/len;
//    dir.y = dir.y/len;
//    tan.x = -width*dir.y;
//    tan.y = width*dir.x;
//	
//	// to account for gaps on but-ends of lines when drawn end-to-end
//	microExtension.x = dir.x * width;
//	microExtension.y = dir.y * width;
//	
//	pos1.x -= microExtension.x;
//	pos1.y -= microExtension.y;
//	pos2.x += microExtension.x;
//	pos2.y += microExtension.y;
//    
//    lineVertices[0] = pos1.x + tan.x;
//    lineVertices[1] = pos1.y + tan.y;
//    lineVertices[2] = pos2.x + tan.x;
//    lineVertices[3] = pos2.y + tan.y;
//    lineVertices[4] = pos1.x;
//    lineVertices[5] = pos1.y;
//    lineVertices[6] = pos2.x;
//    lineVertices[7] = pos2.y;
//    lineVertices[8] = pos1.x - tan.x;
//    lineVertices[9] = pos1.y - tan.y;
//    lineVertices[10] = pos2.x - tan.x;
//    lineVertices[11] = pos2.y - tan.y;
//	
//	vertexObject->setColor(color[0],color[1],color[2], 0);
//    
//    // double up on first vertex
//	vertexObject->addVertex2v(&lineVertices[0]);
//    
//	vertexObject->addVertex2v(&lineVertices[0]);
//	vertexObject->addVertex2v(&lineVertices[2]);
//	vertexObject->setColor(color[0],color[1],color[2], color[3]);
//	vertexObject->addVertex2v(&lineVertices[4]);
//	vertexObject->addVertex2v(&lineVertices[6]);
//	vertexObject->setColor(color[0],color[1],color[2], 0);
//	vertexObject->addVertex2v(&lineVertices[8]);
//	vertexObject->addVertex2v(&lineVertices[10]);
//    
//    // double up on last vertex
//    vertexObject->addVertex2v(&lineVertices[10]);
//
//}

