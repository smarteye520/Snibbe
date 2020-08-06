//
//  MShapeTexture.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/7/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#include "MShapeTexture.h"
#include "MShapeInstanceTexture.h"
#include "CCTextureCache.h"

//
//
MShapeTexture::MShapeTexture()
{
    numShapeTexPoints_ = 0;
    textureName_[0] = '\0';
    texture_ = 0;
}

//
// virtual
MShapeTexture::~MShapeTexture()
{
    
}



//
// virtual
MShapeInstance * MShapeTexture::createInstance()
{
    MShapeInstanceTexture * pInst = new MShapeInstanceTexture();
    populateInstanceCommon( pInst );
    return pInst;
}

//
// virtual 
void MShapeTexture::clear()
{

    textureName_[0] = '\0';
    texture_ = 0; // shouldn't need to release
    numShapeTexPoints_ = 0;
}

//
//
void MShapeTexture::addTexturePoint( CGPoint pt, CGPoint texCoord )
{
    stripPoints_[numShapeTexPoints_] = pt;
    texCoords_[numShapeTexPoints_++] = texCoord;    
}

//
//
void MShapeTexture::setTextureName( const char * name )
{
    if ( name && strlen(name) < MAX_TEXTURE_LENGTH_NAME -1 )
    {
        strcpy( textureName_, name );
    }
}

//
//
void MShapeTexture::loadTexture()
{
    if ( textureName_[0] != '\0' )
    {
        texture_ = [[CCTextureCache sharedTextureCache] addImage: [NSString stringWithCString: textureName_ encoding: NSASCIIStringEncoding] ];
    }
}