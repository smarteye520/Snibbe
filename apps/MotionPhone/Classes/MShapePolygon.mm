//
//  MShapePolygon.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/7/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#include "MShapePolygon.h"
#include "MShapeInstancePolygon.h"

//
//
MShapePolygon::MShapePolygon()
{
    numPoints_ = 0;
}

//
// virtual
MShapePolygon::~MShapePolygon()
{
    
}

// Add a point and a corresponding tri strip index remap to the polygon.
// The trip strip index remap array is just a level of indirection so we
// can reorder the point array (which is set up for line drawing) to work
// with tri strips
void MShapePolygon::addPolyPoint( CGPoint pt, int triStripPointIndexRemap )
{
    points_[numPoints_] = pt;
    triStripPointIndices_[numPoints_] = triStripPointIndexRemap;
    
    numPoints_++;
    
}



//
// virtual
MShapeInstance * MShapePolygon::createInstance()
{
    MShapeInstancePolygon * pInst = new MShapeInstancePolygon();
    populateInstanceCommon( pInst );
    return pInst;
}


