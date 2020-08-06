//
//  MPActionBrush.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//



#include "MPActionBrush.h"
#include "SnibbeUtils.h"
#include "MPNetworkManager.h"
#include "mcanvas.h"
//
//
MPActionBrush::MPActionBrush()
{
    actionType_ = eActionBrush;      
    
    frameDir_ = 1;
    constantWidth_ = DEFAULT_CONSTANT_OUTLINE_WIDTH;

    
    
    //populateHeader( actionData_ );
    
}

//
// virtual
MPActionBrush::~MPActionBrush()
{
    
}

//
// virtual
void MPActionBrush::reset()
{
    frameDir_ = 1;
    constantWidth_ = DEFAULT_CONSTANT_OUTLINE_WIDTH;
}


//
// virtual 
unsigned int MPActionBrush::actionNumBytes() const    
{
    return ACTION_BRUSH_BYTES;
}

//
// virtual
void MPActionBrush::toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining )
{
            
    if ( ACTION_BRUSH_BYTES <= outDataSpaceRemaining )
    {
        memcpy( *outData, actionData_, ACTION_BRUSH_BYTES );   
        outDataSpaceRemaining -= ACTION_BRUSH_BYTES;
        *outData += ACTION_BRUSH_BYTES;
    } 
     
}


// virtual
// In a sequence of brush stroke actions, write out the data that's common to the sequence
void MPActionBrush::toCommonData( unsigned char ** outData, unsigned int& outDataSpaceRemaining )
{
    
    // shape id
    writeTypedBytes<unsigned int>( outData, shapeID_, ACTION_SHAPE_ID_BYTES, outDataSpaceRemaining );
    
    // width
    writeTypedBytes<float>( outData, width_, ACTION_FLOAT_BYTES, outDataSpaceRemaining );    
    
    // filled
    writeTypedBytes<unsigned char>( outData, filled_, ACTION_CHAR_BYTES, outDataSpaceRemaining );
    
    // color   
    // represent color as bytes/channel intead of floats/channel
    writeTypedBytes<unsigned int>( outData, color_, ACTION_COLOR_BYTES, outDataSpaceRemaining );
    
    // frame dir
    writeTypedBytes<unsigned char>( outData, frameDir_, ACTION_CHAR_BYTES, outDataSpaceRemaining );  
    
    // constant width
    writeTypedBytes<unsigned char>( outData, constantWidth_, ACTION_CHAR_BYTES, outDataSpaceRemaining );  
}

//
// virtual
void MPActionBrush::fromData(  const unsigned char * dataCommon, const unsigned char * dataInstance, int iNetworkDataVersion  )
{
    
    if ( dataInstance && dataCommon )
    {
        
        // first common data
        
        shapeID_ = *(int *) (dataCommon + ACTION_BRUSH_OFFSET_SHAPE_ID);
        width_ = *(float *) (dataCommon + ACTION_BRUSH_OFFSET_WIDTH);
        filled_ = *(char *) (dataCommon + ACTION_BRUSH_OFFSET_FILLED);                
        color_ =  (*(unsigned int *) (dataCommon + ACTION_BRUSH_OFFSET_COLOR));
        frameDir_ = *(char *) (dataCommon + ACTION_BRUSH_OFFSET_FRAME_DIR);                
        constantWidth_ = *(char *) (dataCommon + ACTION_BRUSH_OFFSET_CONSTANT_WIDTH);                
        
        // now the instance data
        
        
        // here... remember to set any default instance values that aren't a part of earlier
        // versions of the app and only memcpy the number of bytes appropriate for the
        // version number of the incoming data.  Important to remember if we ever add more instance
        // values in later versions.  Otherwise we'll have garbage in the new value memory when
        // interpreting data coming from the older versions
        
        // newer versions must also always add to the existing format at the end to maintain backwards
        // compatibility
        
        
        // NETWORKING_DATA_VERSION == 1
        memcpy(actionData_, dataInstance, ACTION_BRUSH_BYTES);
                        
        
        
        //SSLog( @"from data: framenum: %d\n", *(int *) &(actionData_[ACTION_BRUSH_OFFSET_FRAME_NUM]) );
                
    }
     
}

//
//
void MPActionBrush::setData( ShapeID theID, CGPoint p1, CGPoint p2, float width, float theta, bool bFilled, MColor col, int frameNum, unsigned int brushIndex, unsigned int z, bool constantWidth )
{
    
    // common data
    
    shapeID_ = theID;
    width_ = width;
    filled_ = bFilled;
    frameDir_ = gParams->frameDir();
    constantWidth_ = constantWidth;
    
    // store color as int32
    MCOLOR_TO_INT32(col, color_)
    
    
    // all other data - stored in buffer for quick copy for network packaging

    *(CGPoint *) &(actionData_[ACTION_BRUSH_OFFSET_PT_1]) = p1;
    *(CGPoint *) &(actionData_[ACTION_BRUSH_OFFSET_PT_2]) = p2;
    *(float *) &(actionData_[ACTION_BRUSH_OFFSET_THETA]) = theta;    
    *(int *) &(actionData_[ACTION_BRUSH_OFFSET_FRAME_NUM]) = frameNum;    
    *(unsigned int *) &(actionData_[ACTION_BRUSH_OFFSET_BRUSH_INDEX]) = brushIndex;
    *(unsigned int *) &(actionData_[ACTION_BRUSH_OFFSET_Z_ORDER]) = z;    
    
    //SSLog( @"setting data: framenum: %d\n", frameNum );
    
}


//
//
void MPActionBrush::setZOrder( unsigned int z )
{
    *(unsigned int *) &(actionData_[ ACTION_BRUSH_OFFSET_Z_ORDER]) = z;
}

//
// virtual 
void MPActionBrush::debugOut()
{
    //debugOutCommon( actionData_ );
}


// virtual 
//
// This is a brushstroke action received from the server.  It can take one of a 2 forms:
//
// 1. We originally initiated the brushstroke, sent it to the server for processing and
//    are now receiving it back.  We need to update the original stroke with any changes the server made.
//
// 2. Another client initiated the brushstroke, and we must add it to that client's canvas 
//    in the appropriate frame

void MPActionBrush::perform()
{

    
    // extract some of the non-common data
            
    int frameNum =  *(int *) &(actionData_[ACTION_BRUSH_OFFSET_FRAME_NUM]);    
    unsigned int frameBrushIndex = *(unsigned int *) &(actionData_[ACTION_BRUSH_OFFSET_BRUSH_INDEX]);
    unsigned int zOrder = *(unsigned int *) &(actionData_[ACTION_BRUSH_OFFSET_Z_ORDER]);    
    
    
    if ( playerIDHash_ == [MPNetworkManager man].localPlayerIDHash_ )
    {
        // our brush stroke is coming back to us from the server... update zOrder if needed                                
        gMCanvas->updateBrushZ( playerIDHash_, frameNum, frameBrushIndex, zOrder );        
        
    }
    else
    {
        
        // another player's brush stroke is being reported.  Add to their canvas
        
        // extract rest of non-common data        
        CGPoint p1 = *(CGPoint *) &(actionData_[ACTION_BRUSH_OFFSET_PT_1]);    
        CGPoint p2 = *(CGPoint *) &(actionData_[ACTION_BRUSH_OFFSET_PT_2]);    
        float theta = *(float *) &(actionData_[ACTION_BRUSH_OFFSET_THETA]);                
        
        MColor colFloats;
        MCOLOR_FROM_INT32( colFloats, color_ );
        
        gMCanvas->addBrushData( playerIDHash_, shapeID_, p1, p2, width_, colFloats, theta, filled_, frameNum, zOrder, constantWidth_ );
        
    }
    
    
}

//
// virtual
bool MPActionBrush::canPerform() const
{
    
    // temp.. this isn't working, so cancelling for now
    //return true;
    
    
    if ( playerIDHash_ != [MPNetworkManager man].localPlayerIDHash_ )
    {
        // another player's brush stroke.  we need to wait until we're at the frame before it would be displayed
        // so avoid horrible flickering artifacts because of the frame loop and the network updates being out of phase
        
        int brushFrameNum =  *(int *) &(actionData_[ACTION_BRUSH_OFFSET_FRAME_NUM]);    

        int curFrame = gMCanvas->inq_cframe();
        int numFrames = gMCanvas->numFrames();
        
        // need to update this logic if we ever allow tempo to skip frames!
        // we don't want this to miss because we aren't incrementing frames 1 by 1
        
        // we use this method so that strokes appear smoothly on the peer devices.
        // if the frame progression is in reverse though we need to abandon the technique
        // b/c it would take forever to process a stroke!
        
        bool movingSameDir = gParams->frameDir() == frameDir_;
                
        bool bCanPerform = ( !movingSameDir || 
                            
                            ( frameDir_ > 0 && 
                              ((curFrame == brushFrameNum - 1) ||
                               (curFrame == numFrames - 1 && brushFrameNum == 0 ))) ||
                                 
                            ( frameDir_ < 0 && 
                            ( (curFrame == brushFrameNum + 1) ||                            
                              (brushFrameNum == numFrames - 1 && curFrame == 0 ) ) ) );
        

        if ( !bCanPerform )
        {
            //SSLog( @"can't perform...\n" );
        }
        
        

        
        
        return bCanPerform;        
        
        
    }
    
    return true;
    
}

// virtual 
// can this action be grouped with the action pointed to by other
// in a sequence of actions that share common aspects to their data?
// This is a network optimization that helps us group related actions together
// and factor out the shared attributes to save space.
bool MPActionBrush::sharesCommonDataWith( MPAction * other )
{
    if ( other && other->actionType() == eActionBrush )
    {
        MPActionBrush * pB = static_cast<MPActionBrush *>(other);
                
        return ( constantWidth_ == pB->constantWidth_ &&
                 shapeID_ == pB->shapeID_ &&
                 filled_ == pB->filled_ &&
                 color_ == pB->color_ &&
                 frameDir_ == pB->frameDir_ &&
                 fuzzyCompare( width_, pB->width_ ) );
        
    }
    
    return false; 
}







