//
//  MShapeInstancePolygon.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/10/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#ifndef MotionPhone_MShapeInstancePolygon_h
#define MotionPhone_MShapeInstancePolygon_h

#include "MShapeInstance.h"

class MShapeInstancePolygon : public MShapeInstance
{
    
public:
    
    MShapeInstancePolygon();
    virtual ~MShapeInstancePolygon();
    
    virtual	void drawGL( ofxMSAShape3D *shape3D, MColor col, bool fill, float lineWidth );
    virtual void drawOntoCanvas( CGContextRef ctx, bool drawAlpha );
    
    virtual void transform( CGPoint pos, CGPoint movementVector, float stretch, float shapeScale, float rot, bool fill );        
    
    
protected:

          
};



#endif
