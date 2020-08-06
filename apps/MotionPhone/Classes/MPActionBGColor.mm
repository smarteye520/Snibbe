//
//  MPActionBGColor.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//



#include "MPActionBGColor.h"
#include "defs.h"
#include "Parameters.h"
#include "mcanvas.h"
#include "MPNetworkManager.h"


//
//
MPActionBGColor::MPActionBGColor()
{
    actionType_ = eActionBGColor;
    //populateHeader( actionData_ );
}

//
// virtual
MPActionBGColor::~MPActionBGColor()
{
    
}

//
// virtual 
unsigned int MPActionBGColor::actionNumBytes() const    
{
    return ACTION_BG_COLOR_BYTES;
}

//
// virtual
void MPActionBGColor::toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining )
{    
    writeTypedBytes<unsigned int>( outData, color_, ACTION_COLOR_BYTES, outDataSpaceRemaining );    
}

//
// virtual
void MPActionBGColor::fromData(  const unsigned char * dataCommon, const unsigned char * dataInstance, int iNetworkDataVersion  )
{
    
    if ( dataInstance )
    {    
        color_ =  (*(unsigned int *) (dataInstance + ACTION_BG_COLOR_OFFSET_COLOR));        
    }
    
}

//
// virtual 
void MPActionBGColor::debugOut()
{
    //debugOutCommon( actionData_ );
}

//
// virtual 
void MPActionBGColor::perform()
{
    
        
    // don't re-perform our own original color action coming back to us
    // from the server,
    
    // update - not using this technique b/c it introduces the possibility of
    // players getting their bg color out of sync in a multiplayer session
        
    //if ( [[MPNetworkManager man] multiplayerSessionActive] &&  
    //    [[MPNetworkManager man] localPlayerIDHash_] != playerIDHash_ )
    //{
                
        
        // we prevent a circular bgcolor change situation with this
        gMCanvas->allowBGColorChangedActions( false );
        
        MColor col;
        MCOLOR_FROM_INT32( col, color_ );    
        gParams->setBGColor( col );
        
        gMCanvas->allowBGColorChangedActions( true );
        
    //}
    //else
    //{
        //NSLog( @"skipping.. it's our own.\n" );
    //}
    
}


//
//
void MPActionBGColor::setColor( MColor col )
{
    MCOLOR_TO_INT32(col, color_);
}



