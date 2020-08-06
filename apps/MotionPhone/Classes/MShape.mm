//
//  MShape.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/7/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//


#include "MShape.h"
#include "MShapeInstance.h"

//
//
MShape::MShape()
{
    shapeID_ = -1;
    allowShear_ = true;
    constrainShearXDir_ = false;
    solidDrawMode_ = GL_TRIANGLE_STRIP;
    
}


//
// virtual
MShape::~MShape()
{
    
}


//
//
void MShape::setName( const char * name )
{
    int iNameLen = strlen( name );
    if ( iNameLen < MAX_SHAPE_NAME_LEN )
    {
        strcpy( shapeName_, name );
    }
    else
    {
        strncpy(shapeName_, name, MAX_SHAPE_NAME_LEN);    
        shapeName_[MAX_SHAPE_NAME_LEN-1] = '\0';    
    }
}


//
//
void MShape::setIconRootName( const char * name )
{
    
    int iNameLen = strlen( name );
    if ( iNameLen < MAX_SHAPE_NAME_LEN )
    {
        strcpy( shapeIconRootName_, name );
    }
    else
    {
        strncpy(shapeIconRootName_, name, MAX_SHAPE_NAME_LEN);    
        shapeIconRootName_[MAX_SHAPE_NAME_LEN-1] = '\0';    
    }
       
}


//
//
void MShape::populateInstanceCommon( MShapeInstance * pInst )
{
    pInst->setShape( this );
}