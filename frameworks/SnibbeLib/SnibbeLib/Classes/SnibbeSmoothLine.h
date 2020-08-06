//
//  SnibbeSmoothLine.h
//  SnibbeLib
//
//  Created by Graham McDermott on 10/7/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#ifndef SnibbeLib_SnibbeSmoothLine_h
#define SnibbeLib_SnibbeSmoothLine_h


#include "ofxMSAShape3D.h"


inline void drawSmoothLineVO(CGPoint pos1, CGPoint pos2, float width, float *color, ofxMSAShape3D *vertexObject)
{
    GLfloat lineVertices[12];
    CGPoint dir, tan, microExtension;
    
    dir.x = pos2.x - pos1.x;
    dir.y = pos2.y - pos1.y;
    float len = sqrtf(dir.x*dir.x+dir.y*dir.y);
    if(len<0.00001)
        return;
    dir.x = dir.x/len;
    dir.y = dir.y/len;
    tan.x = -width*dir.y;
    tan.y = width*dir.x;
	
	// to account for gaps on but-ends of lines when drawn end-to-end
	microExtension.x = dir.x * width;
	microExtension.y = dir.y * width;
	
	pos1.x -= microExtension.x;
	pos1.y -= microExtension.y;
	pos2.x += microExtension.x;
	pos2.y += microExtension.y;
    
    lineVertices[0] = pos1.x + tan.x;
    lineVertices[1] = pos1.y + tan.y;
    lineVertices[2] = pos2.x + tan.x;
    lineVertices[3] = pos2.y + tan.y;
    lineVertices[4] = pos1.x;
    lineVertices[5] = pos1.y;
    lineVertices[6] = pos2.x;
    lineVertices[7] = pos2.y;
    lineVertices[8] = pos1.x - tan.x;
    lineVertices[9] = pos1.y - tan.y;
    lineVertices[10] = pos2.x - tan.x;
    lineVertices[11] = pos2.y - tan.y;
	
	vertexObject->setColor(color[0],color[1],color[2], 0);
    
    // double up on first vertex
	vertexObject->addVertex2v(&lineVertices[0]);
    
	vertexObject->addVertex2v(&lineVertices[0]);
	vertexObject->addVertex2v(&lineVertices[2]);
	vertexObject->setColor(color[0],color[1],color[2], color[3]);
	vertexObject->addVertex2v(&lineVertices[4]);
	vertexObject->addVertex2v(&lineVertices[6]);
	vertexObject->setColor(color[0],color[1],color[2], 0);
	vertexObject->addVertex2v(&lineVertices[8]);
	vertexObject->addVertex2v(&lineVertices[10]);
    
    // double up on last vertex
    vertexObject->addVertex2v(&lineVertices[10]);
    
}



#endif
