//
//  SnibbeInterpolator.h
//  SnibbeLib
//
//  Created by Graham McDermott on 8/2/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//
//  class SnibbeInterpolator
//  ------------------------
//  A generic interpolation class, templated by time type and value type


#ifndef __SNIBBE_INTERPOLATOR_H__
#define __SNIBBE_INTERPOLATOR_H__

#include "SnibbeUtils.h"
#include <assert.h>


typedef enum
{
    eLinear = 1,
    eSmooth
} SnibbeInterpolatorInterpT;


template<class valT, class timeT> class SnibbeInterpolator
{
  
public:
    
    SnibbeInterpolator();
    ~SnibbeInterpolator();
    
    void beginInterp( valT startVal, valT targetVal, timeT curTime, timeT interpLength, SnibbeInterpolatorInterpT interpT = eLinear );
    void setValue( valT val ) { curValue_ = val; isComplete_= true; }
    
    valT update( timeT curTime );
    void stop() { isComplete_ = true; }    
    
    valT curVal()     const { return curValue_; }
    bool isComplete() const { return isComplete_; }
    bool isInterpolating() const { return !isComplete_; }
    
private:
    
    valT curValue_;
              
    timeT          interpTimeBegin_;
    timeT          interpTimeEnd_;
    timeT          interpDur_;
    valT           interpStart_;
    valT           interpTarget_;
    valT           interpDelta_;
    
        
    bool           isComplete_;
    
    SnibbeInterpolatorInterpT interpType_;

};



//
//
template<class valT, class timeT>
SnibbeInterpolator<valT, timeT>::SnibbeInterpolator()
{
    isComplete_ = true;
    curValue_ = 0; // should be valid for valT types
}

//
//
template<class valT, class timeT>
SnibbeInterpolator<valT, timeT>::~SnibbeInterpolator()
{
    
}

//
// initiate an interpolation
template<class valT, class timeT>
void SnibbeInterpolator<valT, timeT>::beginInterp( valT startVal, valT targetVal, timeT curTime, timeT interpLength, SnibbeInterpolatorInterpT interpT )
{
    assert( interpLength >= 0 );
    if ( fuzzyCompare( interpLength, 0 ) )
    {
        curValue_ = targetVal;
        isComplete_ = true;
    }
    else
    {
        
        interpTimeBegin_ = curTime;
        interpTimeEnd_ = curTime + interpLength;
        interpDur_ = interpLength; 
        
        interpStart_ = startVal;
        interpTarget_ = targetVal;
        interpDelta_ = interpTarget_ - interpStart_;
        
        
        interpType_ = interpT;

        curValue_ = interpStart_;
        isComplete_ = false;
    }
}


//
//
template<class valT, class timeT>
valT SnibbeInterpolator<valT, timeT>::update( timeT curTime )
{
    
    if ( !isComplete_ )
    {
    

        if ( curTime >= interpTimeBegin_ && curTime <= interpTimeEnd_ )
        {
            float percentThere = ( curTime - interpTimeBegin_ ) / interpDur_;
            
            if ( interpType_ == eSmooth )
            {            
                percentThere = easeInOutMinMax( 0.0, 1.0, percentThere );
            }            
                
            curValue_ = interpStart_ + interpDelta_ * percentThere;
        }
        else
        {
            // set to target and reset
            curValue_ = interpTarget_;                        
            isComplete_ = true;
        }
            
    }
    
    
    return curValue_;
}


#endif // __SNIBBE_INTERPOLATOR_H__