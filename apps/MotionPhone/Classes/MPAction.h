//
//  MPAction.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#ifndef MotionPhone_MPAction_h
#define MotionPhone_MPAction_h

#include "defs.h"

// values as the beginning of each action
// no longer used
//#define ACTION_SIZE_BYTES 1
//#define ACTION_ID_BYTES 1
//
//#define ACTION_SIZE_OFFSET 0
//#define ACTION_ID_OFFSET (ACTION_SIZE_OFFSET + ACTION_SIZE_BYTES)


// total memory for header bytes
//#define ACTION_HEADER_BYTES ( ACTION_ID_OFFSET + ACTION_ID_BYTES )


class MPAction
{
  
public:
    
    MPAction();
    virtual ~MPAction() = 0;

    virtual void reset();
    virtual unsigned int actionNumBytes() const = 0;
    
    
    virtual void toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining ) = 0;
    
    virtual void toCommonData( unsigned char ** outData, unsigned int& outDataSpaceRemaining );
    virtual unsigned int  commonDataNumBytes();
    
    virtual void fromData(  const unsigned char * dataCommon, const unsigned char * dataInstance, int iNetworkDataVersion ) = 0;
    virtual void debugOut() = 0;
    virtual const char *actionDescription() = 0;
    virtual void perform() = 0;
    
    virtual bool canPerform() const { return true; }
    virtual bool sharesCommonDataWith( MPAction * other );
    
    MPActionT actionType() const { return actionType_; }

    
    int playerIDHash() const { return playerIDHash_; }
    void setPlayerIDHash( int theHash ) { playerIDHash_ = theHash; }

    bool isPoolAction() const { return poolAction_; }
    void setPoolAction( bool bPoolAction ) { poolAction_ = bPoolAction; }
    
    bool isFreePoolAction() const { return poolIsFree_; }
    void setPoolIsFree( bool bFree );
    
protected:
    
    void debugOutCommon( const unsigned char * data );    
    //void populateHeader( unsigned char * data );

    MPActionT actionType_;      // 4 bytes
    NSUInteger playerIDHash_;   // 4 bytes

    // note - any members here have to maintain the class size as a multiple of 4 bytes
    
    
    // for collaboration with action pools
    bool poolAction_;  // is this action a member of an action pool
    bool poolIsFree_;  // is the action available for use in a pool?    
    bool dummy1_;  // dummy val to pad object to 4 byte multiple
    bool dummy2_;  // dummy val to pad object to 4 byte multiple     

    
};


// helper for writing to buffer and incrementing pointer
template<class t>
void writeTypedBytes( unsigned char ** pOutBuf, t val, unsigned int dataSize, unsigned int& outBufSpaceRemaining )
{
    
    //NSLog( @"writing typed bytes at: %d, datasize: %d, space remaining: %d\n", (unsigned int) *pOutBuf, dataSize, outBufSpaceRemaining );
    
    *(t *) *pOutBuf = val;    
    *pOutBuf += dataSize;
    outBufSpaceRemaining -= dataSize;
}

// helper for reading from buffer and incrementing pointer
template<class t>
void readTypedBytes( unsigned char ** pBuf, t& val, unsigned int dataSize, unsigned int& bytesRead )
{
    val = *(t *) *pBuf;        
    *pBuf += dataSize;
    bytesRead += dataSize;
}


#endif
