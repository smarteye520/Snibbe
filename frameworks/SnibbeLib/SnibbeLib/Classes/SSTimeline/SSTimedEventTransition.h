//
//  SSTimedEventTransition.h
//  PassionPit
//
//  Created by Graham McDermott on 6/14/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef PassionPit_SSTimedEventTransition_h
#define PassionPit_SSTimedEventTransition_h

#include "SSTimedEvent.h"

//#define MAX_TE_CONTROL_POINTS 4

//struct TEControlPoint
//{
//    float time_;
//    float val_;    
//};


typedef  enum
{

    eTELinear = 0,
    eTEEaseInOut,
    
} TimedEventTransitionT;


class SSTimedEventTransition : public SSTimedEvent
{
    
public:
    
    SSTimedEventTransition();
    SSTimedEventTransition( float timeBegin, float timeEnd,  TimedEventTransitionT transition = eTEEaseInOut );
    
    //SSTimedEventTransition( float timeBegin, float timeEnd, float transInSec = 0.0f, float transInEndVal = 0.1f, float transOutSec = 0.0f, float transOutBeginVal = 0.9f, bool smoothTrans = true );

    ~SSTimedEventTransition();
    
protected:
    
    

    float normalizedValueAtTime( float t );       
    
    //float addControlPt( float time, float val );
    

    TimedEventTransitionT transitionType_;
    float inverseDuration_;

    
    //float normalizedSmoothValueAtTime( float t );
    //float normalizedLinearValueAtTime( float t );    
    //TEControlPoint controlPts_[MAX_TE_CONTROL_POINTS];
    //int iNumControlPts_;
    
};



#endif
