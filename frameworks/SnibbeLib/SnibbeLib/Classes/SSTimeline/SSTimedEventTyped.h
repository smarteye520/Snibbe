//
//  SSTimedEventTyped.h
//  PassionPit
//
//  Created by Graham McDermott on 6/14/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef PassionPit_SSTimedEventTyped_h
#define PassionPit_SSTimedEventTyped_h

#include "SSTimedEvent.h"


template <class T>
class SSTimedEventTyped : public SSTimedEvent
{
    
public:
    
    SSTimedEventTyped();
    SSTimedEventTyped( float timeBegin, float timeEnd, const T& val, bool duration = false);
    virtual ~SSTimedEventTyped();
    
    const T& value() const { return val_; }
    void setValue( const T& val ) { val_ = val; }
    
protected:    
    
    T val_;
};


//
//
template <class T>
SSTimedEventTyped<T>::SSTimedEventTyped()
{
    // warning - val_'s value is undefined here
}


//
// if duration is passed as true, then timeEnd is treated as a duration after timeBegin
template <class T>
SSTimedEventTyped<T>::SSTimedEventTyped( float timeBegin, float timeEnd, const T& val, bool duration) :
SSTimedEvent(timeBegin, timeEnd),
val_(val)
{
    if (duration) {
		timeEnd_ += timeBegin;
	}
}

//
//
template <class T>
SSTimedEventTyped<T>::~SSTimedEventTyped()
{
    
}




#endif
