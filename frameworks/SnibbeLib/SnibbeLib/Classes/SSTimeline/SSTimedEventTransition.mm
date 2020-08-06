//
//  SSTimedEventTransition.mm
//  PassionPit
//
//  Created by Graham McDermott on 6/14/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SSTimedEventTransition.h"
#include "SnibbeUtils.h"

//
//
SSTimedEventTransition::SSTimedEventTransition()
{
    inverseDuration_ = 0.0f;    
}


SSTimedEventTransition::SSTimedEventTransition( float timeBegin, float timeEnd,  TimedEventTransitionT transition ) :
SSTimedEvent( timeBegin, timeEnd ),
transitionType_( transition )
{
    assert( timeEnd > timeBegin );
    inverseDuration_ = 1.0f / (timeEnd - timeBegin);
   
}

//
//
//SSTimedEventTransition::SSTimedEventTransition( float timeBegin, float timeEnd, float transIn, float transInEndVal, float transOut, float transOutBeginVal, bool smoothTrans ) :
//SSTimedEvent( timeBegin, timeEnd ),
//transitionInLength_( transIn ),
//transitionOutLength_( transOut ),
//transitionInEndVal_( transInEndVal ),
//transitionOutBeginVal_( transOutBeginVal ),
//smoothTransition_( smoothTrans ),
//iNumControlPts_(0)
//{
//    
//    addControlPt(timeBegin_, 0.0);
//    if ( transIn > 0 )
//    {
//        addControlPt( timeBegin_ + transIn, transInEndVal );
//    }
//    if ( transOut > 0 )
//    {
//        addControlPt( timeEnd_ - transOut, transOutBeginVal );        
//    }    
//    addControlPt(timeEnd_, 1.0);
//    
//    assert( (transIn + transOut) <= (timeEnd - timeBegin) );
//    assert( timeEnd > timeBegin );
//    
//    
//    
//
//}

//
//
SSTimedEventTransition::~SSTimedEventTransition()
{
    
}

//
//
//float SSTimedEventTransition::addControlPt( float time, float val )
//{
//
//    if ( iNumControlPts_ < MAX_TE_CONTROL_POINTS )
//    {
//        controlPts_[iNumControlPts_].time_ = time;
//        controlPts_[iNumControlPts_].val_ = val;
//        
//        ++iNumControlPts_;
//    }
//    
//}


float SSTimedEventTransition::normalizedValueAtTime( float t )
{ 
    
    
    float secondsIntoEvent = t - timeBegin_;
    float linearProgress = secondsIntoEvent * inverseDuration_;
    
    if ( transitionType_ == eTELinear ) 
    {
        return linearProgress;
    }
    else if ( transitionType_ == eTEEaseInOut )
    {
        return easeInOutMinMax( 0.0, 1.0, linearProgress );
    }
    
    return 0.0f;
            
}

//
//    
//float SSTimedEventTransition::normalizedSmoothValueAtTime( float t )
//{
//    
//}

//
//
//float SSTimedEventTransition::normalizedLinearValueAtTime( float t )
//{
//    
//    
//    float secondsIntoEvent = t - timeBegin_;
//    float returnVal = 1.0f;
//    
//    if ( secondsIntoEvent < 0 )
//    {
//        return 0.0f;
//    }
//    
//    for ( int i = 1; i < iNumControlPts_; ++i )
//    {
//        if ( secondsIntoEvent <= controlPts_[i].time_ )
//        {
//            // interpolate!
//            
//        }
//    }
//
//      
//}