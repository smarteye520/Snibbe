//
//  MPAction.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#include "MPAction.h"
#include "SnibbeUtils.h"

//
//
MPAction::MPAction()
{
    poolAction_ = false;
    poolIsFree_ = false;
}

//
// virtual
MPAction::~MPAction()
{
    
}


//
// virtual
void MPAction::reset()
{
    // nothing by default
}



//
// virtual
// convert to common data to be shared by a group of actions to save space for networking
// data transfer
void MPAction::toCommonData( unsigned char ** outData, unsigned int& outDataSpaceRemaining )
{
    // nothing by default
}

//
// virtual
// size of common data to be shared by a group of actions to save space for networking
// data transfer
unsigned int MPAction::commonDataNumBytes()
{
    return 0;
}

// virtual 
// can this action be grouped with the action pointed to by other
// in a sequence of actions that share common aspects to their data?
// This is a network optimization that helps us group related actions together
// and factor out the shared attributes to save space.
bool MPAction::sharesCommonDataWith( MPAction * other )
{
    return false; 
}



//
// populates the header of the data chunk used by concrete subclasses with
// data to common to all MPAction objects.
//void MPAction::populateHeader( unsigned char * data )
//{    
//    if ( data )
//    {
//                
//        // length of block
//        int actionBytes = actionNumBytes();
//        assert( actionBytes < 256 );        
//        data[ACTION_SIZE_OFFSET] = (unsigned char)actionBytes;
//        
//        // action type
//        data[ACTION_ID_OFFSET] = actionType();        
//                
//    }
//    
//}


//
//

void MPAction::setPoolIsFree( bool bFree )
{
  
    poolIsFree_ = bFree;
    
    if ( bFree )
    {
        
        //NSLog( @"returning to pool\n");
        
        reset();
    }
  
}
   
//
// virtual
void MPAction::debugOutCommon( const unsigned char * data )
{
//    unsigned char actionID = data[ACTION_ID_OFFSET];
//    unsigned char actionLen = data[ACTION_SIZE_OFFSET];
//    
//    SSLog( @"action %s (%d), bytes: %d", actionDescription(), actionID, actionLen );
}

