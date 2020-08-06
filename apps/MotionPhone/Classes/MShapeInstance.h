//
//  MShapeInstance.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/10/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#ifndef MotionPhone_MShapeInstance_h
#define MotionPhone_MShapeInstance_h

#include "defs.h"
#include "SnibbeUtils.h"

// forward declarations
class MShape;
@class CCTexture2D;
@class MPArchiveShapeInstance;



class MShapeInstance
{
  
public:
    
    MShapeInstance();
    virtual ~MShapeInstance() = 0;
    
    void setShape( MShape * pShape ) { pShape_ = pShape; }
    MShape * getShape() { return pShape_; }
    
    virtual	void drawGL( ofxMSAShape3D *shape3D, MColor col, bool fill, float lineWidth ) = 0;    
    virtual void drawOntoCanvas( CGContextRef ctx, bool drawAlpha ) = 0;
    
    virtual void transform( CGPoint pos, CGPoint movementVector, float stretch, float shapeScale, float rot, bool fill ) = 0;        

    // archiving
    
    MPArchiveShapeInstance * toArchiveShapeInstance();
    void setPos( CGPoint pos ) { curPos_ = pos; }
    void setRot( float rot ) { curRot_ = rot; }
    void setStretch( float stretch ) { curStretch_ = stretch; }
    void setShapeScale( float ss ) { curShapeScale_ = ss; }
    void setFill( bool fill ) { curFill_ = fill; }
    void forceNeedsTransform() { forceNeedsTransform_ = true; }
    
    bool getConstantOutlineWidth() const { return constantOutlineWidth_; }
    void setConstantOutlineWidth( bool bConstant ) { constantOutlineWidth_ = bConstant; }
    
    
    static MShapeInstance * fromArchiveShapeInstance( MPArchiveShapeInstance * src );
    
protected:

        
    static CCTexture2D * curTexture; 

    bool needResetDraw( ofxMSAShape3D *shape3D );
    
    inline bool needsTransform( CGPoint pos, float stretch, float shapeScale, float rot, bool fill  ) 
    {   return forceNeedsTransform_ ||
        curPos_.x != pos.x ||
        curPos_.y != pos.y ||
        curFill_ != fill || 
        !fuzzyCompare( stretch, curStretch_ ) || 
        !fuzzyCompare( shapeScale, curShapeScale_ ) || 
        !fuzzyCompare( rot, curRot_ ); }

    void rotatePoint( CGPoint& pt, float theta);
    
    
    MShape * pShape_; // shape this is an instance of
    CGPoint cachedPoints_[MAX_POLYGON_POINTS * 2]; // 2x b/c of tri strip for outline shapes
    
    int numCachedPoints_;
    
    // cached points transform
    
    CGPoint curPos_;
    float curShapeScale_;
    float curStretch_;
    float curRot_;
    bool  curFill_; 
    bool  forceNeedsTransform_;
    bool  constantOutlineWidth_;
    
    
};

#endif
