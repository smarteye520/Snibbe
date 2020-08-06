//
//  MPActionUpdateBrushVals.mm
//  MotionPhone
//
//  Created by Graham McDermott on 11/1/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#include "MPActionUpdateBrushVals.h"
#include "MPNetworkManager.h"
#include "mcanvas.h"


//
//
MPActionUpdateBrushVals::MPActionUpdateBrushVals()
{
    actionType_ = eActionUpdateBrushVals;
    numValues_ = 0;
    valueType_ = eBrushUpdateAlpha;
}

//
// virtual
MPActionUpdateBrushVals::~MPActionUpdateBrushVals()
{
    
}

//
// virtual
void MPActionUpdateBrushVals::reset()
{
    numValues_ = 0;
    valueType_ = eBrushUpdateAlpha;
}

//
// virtual 
unsigned int MPActionUpdateBrushVals::actionNumBytes() const    
{
    return ACTION_BRUSHVALS_BYTES;
}

//
// virtual
void MPActionUpdateBrushVals::toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining )
{
    
    writeTypedBytes<int>( outData, valueType_, ACTION_INT_BYTES, outDataSpaceRemaining );   
    writeTypedBytes<int>( outData, numValues_, ACTION_INT_BYTES, outDataSpaceRemaining );   
    
    memcpy( *outData, values_, ACTION_BRUSHVALS_VALUE_BYTES);
    *outData += ACTION_BRUSHVALS_VALUE_BYTES;
    outDataSpaceRemaining -= ACTION_BRUSHVALS_VALUE_BYTES;    
    
}

//
// virtual
void MPActionUpdateBrushVals::fromData(  const unsigned char * dataCommon, const unsigned char * dataInstance, int iNetworkDataVersion  )
{
    
    if ( dataInstance )
    {

        valueType_ = *((int *) (dataInstance + ACTION_BRUSHVALS_OFFSET_VALUE_TYPE));
        numValues_ = *((int *) (dataInstance + ACTION_BRUSHVALS_OFFSET_NUM_VALUES));
        
        memcpy( values_, dataInstance + ACTION_BRUSHVALS_OFFSET_VALUES, ACTION_BRUSHVALS_VALUE_BYTES);
                
    }
    
}

//
// virtual 
void MPActionUpdateBrushVals::debugOut()
{
    //debugOutCommon( actionData_ );
}

//
// virtual 
void MPActionUpdateBrushVals::perform()
{
    
    //NSLog( @"\nalpha sequence\n" );
    for ( int i = 0; i < numValues_; ++ i )
    {
        
        MPBrushVal& bVal = values_[i];
        
        MBrush * b = gMCanvas->getPlayerBrush( playerIDHash_, bVal.frameNum_, bVal.frameBrushIndex_ );
        if ( b )
        {
            switch (eBrushUpdateAlpha)
            {
                case eBrushUpdateAlpha:
                {
                    //NSLog(@"setting alpha: %f, framenum: %d, frame ind: %d\n", bVal.val_, bVal.frameNum_, bVal.frameBrushIndex_  );
                    b->setAlpha( bVal.val_ );
                    break;
                }
                    
                default:
                    break;
            }
        }   
        else
        { 
            //NSLog( @"brush not found, index %d of %d\n", i, numValues_ );
        }
    }    
    
        //NSLog( @"\nend alpha sequence\n\n" );
    
    
}

//
// virtual
bool MPActionUpdateBrushVals::canPerform() const
{
    
    return true;
        
}

//
//
void MPActionUpdateBrushVals::addValue( int frameNum, unsigned int brushIndex, float fVal )
{
    if ( numValues_ < MAX_NUM_VAL_UPDATES_IN_SEQUENCE - 1 )
    {                        
        values_[numValues_].frameNum_ = frameNum;
        values_[numValues_].frameBrushIndex_ = brushIndex;
        values_[numValues_].val_ = fVal;
        
        numValues_++;
    }
}
