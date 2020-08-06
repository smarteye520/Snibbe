//
//  SSTimedEvent.h
//  PassionPit
//
//  Created by Colin Roache on 6/8/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef PassionPit_SSTimedEvent_h
#define PassionPit_SSTimedEvent_h

    

class SSTimedEvent
{
  
public:
    
    SSTimedEvent();
    SSTimedEvent( float timeBegin, float timeEnd );
    
    virtual ~SSTimedEvent();
    
    float beginTime() const { return timeBegin_; }
    float endTime() const { return timeEnd_; }
    bool  activeAtTime( float atTime ) { return atTime >= timeBegin_ && atTime <= timeEnd_; }
    
protected:
    
    float timeBegin_;
    float timeEnd_;        
    
};



#endif // PassionPit_SSTimedEvent_h

