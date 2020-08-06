//
//  MPCanvasState.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/27/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//
//
//  MPCanvasState
//  --------------
//  snapshot of canvas state.
//  very simple - just enough to implement brush stroke undo
//  at the moment

#ifndef MotionPhone_MPCanvasState_h
#define MotionPhone_MPCanvasState_h

#include "defs.h"

class MFrame;


class MPCanvasState
{
    
public:
    
    MPCanvasState();
    ~MPCanvasState();
  
    void snapshot( MFrame * frames );    
    int numBrushesForFrame( int iFrameIndex ) const;
    
    void clear();
    unsigned int sizeofData() const { return sizeof( numFrameBrushes_ ); }
    
    void toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining );
    void fromData(  const unsigned char * data );

    
private:
    
    int numFrameBrushes_[N_FRAMES];
};



#endif
