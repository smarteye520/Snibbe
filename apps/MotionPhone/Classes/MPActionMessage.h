//
//  MPActionMessage.h
//  MotionPhone
//
//  Created by Graham McDermott on 1/3/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//
//  A generic message action

#ifndef MotionPhone_MPActionMessage_h
#define MotionPhone_MPActionMessage_h

#include "MPAction.h"


#define ACTION_MESSAGE_OFFSET_MSG 0
#define ACTION_MESSAGE_OFFSET_PARAM_1 (ACTION_MESSAGE_OFFSET_MSG + ACTION_INT_BYTES)
#define ACTION_MESSAGE_OFFSET_PARAM_2 (ACTION_MESSAGE_OFFSET_PARAM_1 + ACTION_INT_BYTES)
#define ACTION_MESSAGE_BYTES (ACTION_MESSAGE_OFFSET_PARAM_2 + ACTION_INT_BYTES)

// enums for the message

enum 
{

    eActionMsgNewServerIdentified = 1,
    eActionMsgClientRecognizeNewServer,
    eActionMsgNewServerIsReady,
    eActionMsgPlayerDisconnected,
    eActionMsgDontDrawPeers,
    eActionMsgDrawPeers,
};


class MPActionMessage : public MPAction
{
public:
    
    MPActionMessage();
    virtual ~MPActionMessage();
    
    virtual unsigned int actionNumBytes() const;
    
    virtual void toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining );
    virtual void fromData(  const unsigned char * dataCommon, const unsigned char * dataInstance, int iNetworkDataVersion  );
    virtual void debugOut();
    virtual const char *actionDescription();
    virtual void perform();
    
    void setMessageType( int iType ) { messageFlag_ = iType; }
    
    void setMessageParam1( unsigned int iParam ) { messageParam1_ = iParam; }
    void setMessageParam2( unsigned int iParam ) { messageParam2_ = iParam; }
    
protected:

    int messageFlag_;
    unsigned int messageParam1_;
    unsigned int messageParam2_;
    
};

#endif
