//
//  MPActionClear.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#ifndef MotionPhone_MPActionClear_h
#define MotionPhone_MPActionClear_h

#include "MPAction.h"

#define ACTION_CLEAR_BYTES 0


class MPActionClear : public MPAction
{
public:
    
    MPActionClear();
    virtual ~MPActionClear();
    
    virtual unsigned int actionNumBytes() const;
    
    virtual void toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining );
    virtual void fromData(  const unsigned char * dataCommon, const unsigned char * dataInstance, int iNetworkDataVersion  );
    virtual void debugOut();
    virtual const char *actionDescription() { return "Clear Canvas"; }
    virtual void perform();
    
protected:
    
    
};



#endif
