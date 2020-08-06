//
//  MShapeTexture.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/7/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#ifndef MotionPhone_MShapeTexture_h
#define MotionPhone_MShapeTexture_h

#include "MShape.h"
#include "defs.h"

@class CCTexture2D;


class MShapeTexture : public MShape
{
    
    friend class MShapeInstanceTexture;
    
public: 
    
    MShapeTexture();
    virtual ~MShapeTexture();    

    virtual MShapeInstance * createInstance();
    virtual void clear();
    virtual CCTexture2D * getTextureUsed() { return texture_; }
    
    void addTexturePoint( CGPoint pt, CGPoint texCoord );
    int  getNumTexturePoints() const { return numShapeTexPoints_; }
    
    void setTextureName( const char * name );    
    void loadTexture();
    
    
protected:
    
    // texture ids for filled version and outline version?
    // does fill/outline distinction make sense for texture shape?  maybe disallow if it's a texture shape
    
    CGPoint stripPoints_[MAX_POLYGON_POINTS];   
    CGPoint texCoords_[MAX_POLYGON_POINTS];        
    int numShapeTexPoints_;

    char textureName_[MAX_TEXTURE_LENGTH_NAME];

    CCTexture2D * texture_;
    
};



#endif
