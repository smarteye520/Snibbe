//
//  MShapeInstance.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/10/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#include "MShapeInstance.h"
#include "MShape.h"
#include "MPArchiveShapeInstance.h"
#include "MShapeLibrary.h"
#include "defs.h"


// static
CCTexture2D *MShapeInstance::curTexture = 0;

//
//
MShapeInstance::MShapeInstance()
{
    curPos_ = CGPointZero;
    curStretch_ = 0.0f;
    curShapeScale_ = 0.0f;
    curRot_ = 0.0f;
    curFill_ = false;
    numCachedPoints_ = 0;
    forceNeedsTransform_ = false;
    constantOutlineWidth_ = DEFAULT_CONSTANT_OUTLINE_WIDTH;
}

//
//
MShapeInstance::~MShapeInstance()
{
    
}


//
//
bool MShapeInstance::needResetDraw( ofxMSAShape3D *shape3D )
{

    // always using tri strips.. no no need to compare draw modes
    
    return ( curTexture != pShape_->getTextureUsed() );
    
    // may need to expand this to include whether tex coords match up or not, etc...
        
    
}


//
// assumes point has already been corrected to be relative to (0,0)
void MShapeInstance::rotatePoint( CGPoint& pt, float theta)
{
    
    CGPoint temp = pt;
    float cosTheta = cosf( theta );
    float sinTheta = sinf( theta );
    
    pt.x = temp.x * cosTheta - temp.y * sinTheta;
    pt.y = temp.x * sinTheta + temp.y * cosTheta;
    
}




#pragma mark archiving

//
//
MPArchiveShapeInstance * MShapeInstance::toArchiveShapeInstance()
{
    MPArchiveShapeInstance * asi = [[MPArchiveShapeInstance alloc] init];
        

    asi.curPos_ = curPos_;
    asi.curRot_ = curRot_;
    asi.curShapeScale_ = curShapeScale_;
    asi.curStretch_ = curStretch_;
    asi.curFill_ = curFill_;
    asi.constantOutlineWidth_ = constantOutlineWidth_;
    
    for ( int iPt = 0; iPt < numCachedPoints_; ++iPt )
    {     
        [asi addCachedPt: cachedPoints_[iPt]];
    }
    
    if ( pShape_ )
    {
        asi.shapeID_ = pShape_->getShapeID();
    }
    
    
    return [asi autorelease];
}


//
// static
MShapeInstance * MShapeInstance::fromArchiveShapeInstance( MPArchiveShapeInstance * src )
{
    
    
    MShapeInstance * si = 0;
    
    if ( src )
    {
        MShape * pShape = [[MShapeLibrary lib] shapeForID: src.shapeID_];
        if ( pShape )
        {
            si = pShape->createInstance();
            
            si->setPos( src.curPos_ );
            si->setRot( src.curRot_ );
            si->setStretch( src.curStretch_ );
            si->setShapeScale( src.curShapeScale_ );
            si->setFill( src.curFill_ );
            si->setConstantOutlineWidth( src.constantOutlineWidth_ );
            
            si->numCachedPoints_ = [src numCachedPts];
            for ( int i = 0; i < si->numCachedPoints_; ++i )
            {
                si->cachedPoints_[i] = [src cachedPtAtIndex: i];                
            }
            
        }
        
        
    }
    
    return si;
}





