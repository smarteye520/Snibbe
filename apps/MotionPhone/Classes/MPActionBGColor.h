//
//  MPActionBGColor.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#ifndef MotionPhone_MPActionBGColor_h
#define MotionPhone_MPActionBGColor_h

#include "MPAction.h"
#include "defs.h"



// data offsets for common bg color data

#define ACTION_BG_COLOR_BYTES_COMMON (0)

// data offsets for all other bg color data

#define ACTION_BG_COLOR_OFFSET_COLOR 0
#define ACTION_BG_COLOR_BYTES (ACTION_BG_COLOR_OFFSET_COLOR + ACTION_COLOR_BYTES)




class MPActionBGColor : public MPAction
{
public:
    
    MPActionBGColor();
    virtual ~MPActionBGColor();
    
    virtual unsigned int actionNumBytes() const;
    
    virtual void toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining );
    virtual void fromData(  const unsigned char * dataCommon, const unsigned char * dataInstance, int iNetworkDataVersion  );
    virtual void debugOut();
    virtual const char *actionDescription() { return "Change BG Color"; }
    virtual void perform();
    
    void setColor( MColor col );
    
protected:
    
    unsigned int color_; // int32 representation of color
    
};



#endif
