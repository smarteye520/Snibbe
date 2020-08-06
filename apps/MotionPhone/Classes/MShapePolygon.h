//
//  MShapePolygon.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/7/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#ifndef MotionPhone_MShapePolygon_h
#define MotionPhone_MShapePolygon_h


#include "MShape.h"
#include "defs.h"

class MShapePolygon : public MShape
{
    
    friend class MShapeInstancePolygon;
    
public:
    
    MShapePolygon();
    virtual ~MShapePolygon();  
    
    virtual MShapeInstance * createInstance();
    
    void addPolyPoint( CGPoint pt, int triStripPointIndexRemap );
    int getNumPolyPoints() const { return numPoints_; } 

    
protected:

    CGPoint points_[MAX_POLYGON_POINTS];    
    int     triStripPointIndices_[MAX_POLYGON_POINTS];     
    
    int     numPoints_;
    
};


#endif
