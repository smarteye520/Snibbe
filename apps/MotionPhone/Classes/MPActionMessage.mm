//
//  MPActionMessage.mm
//  MotionPhone
//
//  Created by Graham McDermott on 1/3/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#include "MPActionMessage.h"
#include "MPNetworkManager.h"
#include "mcanvas.h"

//
//
MPActionMessage::MPActionMessage()
{
    actionType_ = eActionMessage;
    messageFlag_ = 0;
    messageParam1_ = 0;
    messageParam2_ = 0;
}

//
// virtual
MPActionMessage::~MPActionMessage()
{
    
}

//
// virtual 
unsigned int MPActionMessage::actionNumBytes() const    
{
    return ACTION_MESSAGE_BYTES;
}

//
// virtual
void MPActionMessage::toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining )
{
        unsigned int numBytes = actionNumBytes();
        if ( numBytes < outDataSpaceRemaining )
        {                        

            writeTypedBytes<unsigned int>( outData, messageFlag_, ACTION_INT_BYTES, outDataSpaceRemaining );            
            writeTypedBytes<unsigned int>( outData, messageParam1_, ACTION_INT_BYTES, outDataSpaceRemaining );            
            writeTypedBytes<unsigned int>( outData, messageParam2_, ACTION_INT_BYTES, outDataSpaceRemaining );                
            
        }
}

//
// virtual
void MPActionMessage::fromData(  const unsigned char * dataCommon, const unsigned char * dataInstance, int iNetworkDataVersion  )
{
    
    if ( dataInstance )
    {        
        // no common data here... just instance data      
        
        messageFlag_ = *(unsigned int *) (dataInstance + ACTION_MESSAGE_OFFSET_MSG);
        messageParam1_ = *(unsigned int *) (dataInstance + ACTION_MESSAGE_OFFSET_PARAM_1);
        messageParam2_ = *(unsigned int *) (dataInstance + ACTION_MESSAGE_OFFSET_PARAM_2);          
        
        
    }
    
}

//
// virtual 
void MPActionMessage::debugOut()
{
    //debugOutCommon( actionData_ );
}

//
// virtual 
void MPActionMessage::perform()
{

    MPNetworkManager * pMan = [MPNetworkManager man];
    
    if ( [pMan multiplayerSessionActive] &&
         [pMan localPlayerIDHash_] != playerIDHash_ )
    {
                
    
        // no longer using these
        
        
        switch (messageFlag_)
        {
            case eActionMsgNewServerIdentified:
            {
                //[pMan onNewServerIdentified: playerIDHash_];
                break;
            }
            case eActionMsgNewServerIsReady:
            {                   
                //[pMan onNewServerReady: playerIDHash_];
                break;
            }
            case eActionMsgClientRecognizeNewServer:
            {                
                //[pMan onClientRecognizesNewServer: playerIDHash_];
                break;
            }     
            case eActionMsgPlayerDisconnected:
            {
                [pMan onPlayerDisconected: messageParam1_];
                break;
            }
            case eActionMsgDontDrawPeers:
            {
            
                gMCanvas->setAllowDrawPeers( false );
                break;
            }
            case eActionMsgDrawPeers:
            {
                gMCanvas->setAllowDrawPeers( true );
                break;
            }
            default:
            {
                
            }
        }
         
         
        
    }
    
    
    // performing a clear action is always erasing a peers canvas, since we
    // erase ours locally before sending out the message.
    
//    if ( [[MPNetworkManager man] multiplayerSessionActive] &&  
//        [[MPNetworkManager man] localPlayerIDHash_] != playerIDHash_ )
//    {
//        gMCanvas->erasePeerCanvas( playerIDHash_ );
//    }
}


//
// virtual 
const char *MPActionMessage::actionDescription()
{
    switch (messageFlag_)
    {
        case eActionMsgNewServerIsReady:
        {
            return "Message: New server is ready";        
        }
        case eActionMsgClientRecognizeNewServer:
        {
            return "Message: Client recognizes new server";
        }
        default:
        {
            return "";
        }
    }
}