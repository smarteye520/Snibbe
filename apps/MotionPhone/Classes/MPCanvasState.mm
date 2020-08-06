//
//  MPCanvasState.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/27/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPCanvasState.h"
#import "mframe.h"

//
//
MPCanvasState::MPCanvasState()
{
    clear();
}

//
//
MPCanvasState::~MPCanvasState()
{
    
}

//
// record the number
void MPCanvasState::snapshot( MFrame * frames )
{
    for ( int i = 0; i < N_FRAMES; ++i )
    {
        numFrameBrushes_[i] = frames[i].numBrushes();
    }
}

//
//
int MPCanvasState::numBrushesForFrame( int iFrameIndex ) const
{
    if ( iFrameIndex >= 0 && iFrameIndex < N_FRAMES )
    {
        return numFrameBrushes_[iFrameIndex];
    }
    
    return 0;
}

//
//
void MPCanvasState::clear()
{
    for ( int i = 0; i < N_FRAMES; ++i )
    {
        numFrameBrushes_[i] = 0;
    }
}

//
//
void MPCanvasState::toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining )
{
    memcpy( *outData, numFrameBrushes_, sizeofData() );
    outDataSpaceRemaining -= sizeofData();
}

//
//
void MPCanvasState::fromData(  const unsigned char * data )
{
    memcpy( numFrameBrushes_, data, sizeofData() );
}