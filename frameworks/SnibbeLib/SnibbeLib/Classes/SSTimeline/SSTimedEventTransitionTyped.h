//
//  SSTimedEventTransitionTyped.h
//  PassionPit
//
//  Created by Graham McDermott on 6/14/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//
//  SSTimedEventTransitionTyped is a templated SSTimedEventTransition with a particular
//  interpolatable value type.  the template argument T must support the - and + operators (with const type
//  T as arg and * operator (with scalar float as arg)  for this method to function, 
// and also must be able to be copied by value.



#ifndef PassionPit_SSTimedEventTransitionTyped_h
#define PassionPit_SSTimedEventTransitionTyped_h

#include "SSTimedEventTransition.h"


template <class T>
class SSTimedEventTransitionTyped : public SSTimedEventTransition
{
    
public:
    
    SSTimedEventTransitionTyped();
    SSTimedEventTransitionTyped( float timeBegin, float timeEnd, const T& valBegin, const T& valEnd, TimedEventTransitionT transition = eTEEaseInOut );
    virtual ~SSTimedEventTransitionTyped();
    
    const T& valueBegin() const { return valBegin_; }
    const T& valueEnd() const { return valEnd_; }
    
    void setValueBegin( const T& val ) { valBegin_ = val; }
    void setValueEnd( const T& val ) { valEnd_ = val; }
    
    T valueAtTime( float t );  
    
protected:    
    
    T valBegin_;
    T valEnd_;
    
};


//
//
template <class T>
SSTimedEventTransitionTyped<T>::SSTimedEventTransitionTyped()
{
    // warning - val_'s values are undefined here
}


//
//
template <class T>
SSTimedEventTransitionTyped<T>::SSTimedEventTransitionTyped( float timeBegin, float timeEnd, const T& valBegin, const T& valEnd, TimedEventTransitionT transition ) :
SSTimedEventTransition( timeBegin, timeEnd, transition ),
valBegin_(valBegin),
valEnd_(valEnd)
{
    
}

//
//
template <class T>
SSTimedEventTransitionTyped<T>::~SSTimedEventTransitionTyped()
{
    
}

//
//
template <class T>
T SSTimedEventTransitionTyped<T>::valueAtTime( float t )
{
    T delta = valEnd_ - valBegin_;
    float progress = normalizedValueAtTime( t );
    return (delta * progress) + valBegin_;
}




#endif
