//
//  MPActionClear.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#include "MPActionClear.h"
#include "defs.h"
#include "mcanvas.h"
#include "MPNetworkManager.h"

//
//
MPActionClear::MPActionClear()
{
    actionType_ = eActionClear;
    //populateHeader( actionData_ );
}

//
// virtual
MPActionClear::~MPActionClear()
{
    
}

//
// virtual 
unsigned int MPActionClear::actionNumBytes() const    
{
    return ACTION_CLEAR_BYTES;
}

//
// virtual
void MPActionClear::toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining )
{
//    unsigned int numBytes = actionNumBytes();
//    if ( numBytes < outDataSpaceRemaining )
//    {
//        memcpy( *outData, actionData_, numBytes );   
//        outDataSpaceRemaining -= numBytes;
//    }
}

//
// virtual
void MPActionClear::fromData(  const unsigned char * dataCommon, const unsigned char * dataInstance, int iNetworkDataVersion  )
{
//    if ( data )
//    {
//        
//        // todo - not flexible if we modify in the future at the moment...
//        
//        char len = data[ACTION_SIZE_OFFSET];
//        char actionType = data[ACTION_ID_OFFSET];
//        
//        if ( len == actionNumBytes() &&
//            actionType == actionType_ )
//        {
//            // proceed!            
//            memcpy(actionData_, data + ACTION_HEADER_BYTES, len);                        
//        }
//        
//    }
}

//
// virtual 
void MPActionClear::debugOut()
{
    //debugOutCommon( actionData_ );
}

//
// virtual 
void MPActionClear::perform()
{
    
    // performing a clear action is always erasing a peers canvas, since we
    // erase ours locally before sending out the message.
    
    if ( [[MPNetworkManager man] multiplayerSessionActive] &&  
         [[MPNetworkManager man] localPlayerIDHash_] != playerIDHash_ )
    {
        gMCanvas->erasePeerCanvas( playerIDHash_ );
    }
}





