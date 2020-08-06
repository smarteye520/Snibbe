//
//  MShape.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/7/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//
//  class MShape
//  ------------
//  class representing a shape.  Shapes are used by brushes to paint onto
//  a canvas.  A brush uses a single shape.  MShape is an abstract base class 
//  that can be realized as various concrete subclasses, for example
//  a polygon or a texture.
//



#ifndef MotionPhone_MShape_h
#define MotionPhone_MShape_h

#include "defs.h"

#define ICON_OFF_POSTFIX "_off.png"
#define ICON_ON_POSTFIX "_on.png"

#define MAX_SHAPE_NAME_LEN 128

// forward declarations
class MShapeInstance;
@class CCTexture2D;



class MShape
{
    
    friend class MShapeInstance;
    friend class MShapeInstanceTexture;
    
public:
    
    MShape();
    virtual ~MShape() = 0;

    virtual void             clear() {}
    virtual MShapeInstance * createInstance() = 0;    
    virtual CCTexture2D *    getTextureUsed() { return 0; }
    
    
    ShapeID getShapeID() const { return shapeID_; }
    void    setShapeID( ShapeID theID ) { shapeID_ = theID; }

    void    setName( const char * name );
    const char * getName() const { return shapeName_; }
    
    void    setIconRootName( const char * name );
    const char * getIconRootName() const { return shapeIconRootName_; }
    
    bool    getAllowShear() const { return allowShear_; }
    void    setAllowShear( bool bAllow ) { allowShear_ = bAllow; }
        
    bool    getConstrainShearXDir() const { return constrainShearXDir_; }
    void    setConstrainShearXDir( bool bAllow ) { constrainShearXDir_ = bAllow; }
    
    GLuint    getSolidDrawMode() const { return solidDrawMode_; }
    void    setSolidDrawMode( GLuint theMode ) { solidDrawMode_ = theMode; }
    
        

protected:

    void populateInstanceCommon( MShapeInstance * pInst );
    
    
    ShapeID shapeID_;      // shape type unique id 
    char    shapeName_[MAX_SHAPE_NAME_LEN];
    char    shapeIconRootName_[MAX_SHAPE_NAME_LEN];
    bool    allowShear_;   // does this shape shear at speed?
    bool    constrainShearXDir_; // special case
    GLuint  solidDrawMode_;
    

    
};



#endif
