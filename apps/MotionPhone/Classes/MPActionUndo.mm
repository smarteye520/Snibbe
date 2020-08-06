//
//  MPActionUndo.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#include "MPActionUndo.h"
#include "MPNetworkManager.h"
#include "mcanvas.h"

//
//
MPActionUndo::MPActionUndo()
{
    actionType_ = eActionUndo;
}

//
// virtual
MPActionUndo::~MPActionUndo()
{
    
}

//
// virtual 
unsigned int MPActionUndo::actionNumBytes() const    
{
    return canvasState_.sizeofData();
}

//
// virtual
void MPActionUndo::toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining )
{
    
    canvasState_.toData( outData, outDataSpaceRemaining );
    
}

//
// virtual
void MPActionUndo::fromData(  const unsigned char * dataCommon, const unsigned char * dataInstance, int iNetworkDataVersion  )
{
    
    if ( dataInstance )
    {
        canvasState_.fromData( dataInstance );               
    }
        
}

//
// virtual 
void MPActionUndo::debugOut()
{
    //debugOutCommon( actionData_ );
}

//
// virtual 
void MPActionUndo::perform()
{

    
    // performing a undo action is always undoing a peer;'s canvas, since we
    // perform ours locally before sending out the message.
    
    if ( [[MPNetworkManager man] multiplayerSessionActive] &&  
         [[MPNetworkManager man] localPlayerIDHash_] != playerIDHash_ )
    {        
        gMCanvas->revertPeerBrushesToState( playerIDHash_, &canvasState_ );
    }
    
    
}






