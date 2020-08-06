//
//  MPActionUndo.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#ifndef MotionPhone_MPActionUndo_h
#define MotionPhone_MPActionUndo_h


#include "MPAction.h"
#include "MPCanvasState.h"


class MPActionUndo : public MPAction
{
public:
    
    MPActionUndo();
    virtual ~MPActionUndo();
    
    virtual unsigned int actionNumBytes() const;        
    
    virtual void toData( unsigned char ** outData, unsigned int& outDataSpaceRemaining );
    virtual void fromData(  const unsigned char * dataCommon, const unsigned char * dataInstance, int iNetworkDataVersion  );
    virtual void debugOut();
    virtual const char *actionDescription() { return "Undo"; }
    virtual void perform();
    
    void setData( MPCanvasState& s ) { canvasState_ = s; }
    
protected:
        
    MPCanvasState canvasState_;
};


#endif
