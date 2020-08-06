//
//  MShapeInstanceTexture.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/10/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#include "MShapeInstanceTexture.h"
#include "MShapeTexture.h"
#include "CCTexture2D.h"

//
//
MShapeInstanceTexture::MShapeInstanceTexture()
{
    
}

//
// virtual
MShapeInstanceTexture::~MShapeInstanceTexture()
{
    
}




//
// virtual
void MShapeInstanceTexture::drawGL( ofxMSAShape3D *shape3D, MColor col, bool fill, float lineWidth )
{
    
    
    GLuint mode =  GL_TRIANGLE_STRIP;            
    bool needsBegin = false;
    
    MShapeTexture *shapeTex = (MShapeTexture *) pShape_;
    
    if ( !shape3D->hasBegun() )
    {
        needsBegin = true;
    }        
    else if ( needResetDraw( shape3D ) )
    {
        shape3D->end();
        shape3D->restoreClientStates();
        needsBegin = true;
    }
    
    if ( needsBegin )
    {        
        
        curTexture = ((MShapeTexture *) pShape_)->getTextureUsed();    
        	
        glEnable(GL_TEXTURE_2D);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);        
        glBindTexture( GL_TEXTURE_2D, curTexture ? curTexture.name : 0  );  
                 
        shape3D->enableColor(true);
        shape3D->enableNormal(false);
        shape3D->enableTexCoord(true);

        shape3D->begin(mode);  
                 
    }
        
    
    // transparent to move from line-to-line if batched
    shape3D->setColor(1, 1, 1, 0);
    
    
    CGPoint texCoord = shapeTex->texCoords_[0];        
    shape3D->setTexCoord( texCoord.x, texCoord.y );
    shape3D->addVertex(cachedPoints_[0].x, cachedPoints_[0].y);    

    texCoord = shapeTex->texCoords_[0];        
    shape3D->setTexCoord( texCoord.x, texCoord.y );
    shape3D->addVertex( cachedPoints_[0].x, cachedPoints_[0].y );                             
    
    
    shape3D->setColor4v(col);	
    
    for( int iPt = 0; iPt < numCachedPoints_; ++iPt )
    {     
        CGPoint texCoord = shapeTex->texCoords_[ iPt ];        
        shape3D->setTexCoord( texCoord.x, texCoord.y );
        shape3D->addVertex( cachedPoints_[iPt].x, cachedPoints_[iPt].y );                        
    }
    
 
    // close it out to transition to next
    shape3D->setColor(1, 1, 1, 0);
    
    texCoord = shapeTex->texCoords_[ numCachedPoints_-1 ];        
    shape3D->setTexCoord( texCoord.x, texCoord.y );
    shape3D->addVertex(cachedPoints_[numCachedPoints_-1].x, cachedPoints_[numCachedPoints_-1].y);        
    
    texCoord = shapeTex->texCoords_[ numCachedPoints_-1 ];        
    shape3D->setTexCoord( texCoord.x, texCoord.y );    
    shape3D->addVertex( cachedPoints_[numCachedPoints_-1].x, cachedPoints_[ numCachedPoints_-1].y );                                    
    

    
    
    
}

//
// virtual 
void MShapeInstanceTexture::drawOntoCanvas( CGContextRef ctx, bool drawAlpha )
{
}


// virtual
//
// the texture transform is simpler, as it always a straightforward tri strip
//
void MShapeInstanceTexture::transform( CGPoint pos, CGPoint movementVector, float stretch, float shapeScale, float rot, bool fill )
{
    
    MShapeTexture *pShapeTex = (MShapeTexture *)pShape_;    
    int numPts = pShapeTex->getNumTexturePoints();
    
    if ( needsTransform( pos, stretch, shapeScale, rot, fill ) )
    {
                        
        //NSLog( @"rot: %f\n", rot );
        
        float cosRot = cosf( rot );
        float sinRot = sinf( rot );
        bool allowShear = pShape_->getAllowShear();
        bool constrainShearX = pShape_->getConstrainShearXDir();        
                
        // transform the points to the cached points array based on the params        
        for( int iPt = 0; iPt < numPts; ++iPt )
        {
            
            CGPoint curPt;
            
            if ( constrainShearX && allowShear )
            {
                // special case 
                
                curPt.x = ( pShapeTex->stripPoints_[iPt].x * stretch * cosRot - pShapeTex->stripPoints_[iPt].y * sinRot ) * shapeScale;
                curPt.y = ( pShapeTex->stripPoints_[iPt].x * sinRot + pShapeTex->stripPoints_[iPt].y * cosRot ) * shapeScale; 
                
            }
            else
            {
                
                // rotation + general scale                                
                curPt.x = ( pShapeTex->stripPoints_[iPt].x * cosRot - pShapeTex->stripPoints_[iPt].y * sinRot ) * shapeScale;
                curPt.y = ( pShapeTex->stripPoints_[iPt].x * sinRot + pShapeTex->stripPoints_[iPt].y * cosRot ) * shapeScale;            
                
                
                // shearing calculation                                
                if ( allowShear )
                {
                    float th = -atan2( movementVector.y, movementVector.x );
                    
                    rotatePoint( curPt, th );
                    curPt.x *= stretch;
                    rotatePoint( curPt, -th );                    
                }
                
            }
            
            
            curPt.x += pos.x;
            curPt.y += pos.y;
            
                                                    
            cachedPoints_[ iPt ] = curPt;    
            numCachedPoints_++;

        }
        
        
        curStretch_ = stretch;
        curShapeScale_ = shapeScale;
        curRot_ = rot;
        curFill_ = fill;
        curPos_ = pos;
    }
}


