//
//  SSTimeline.h
//  PassionPit
//
//  Created by Colin Roache on 6/8/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//
//  SSTimeline is a collection of SSTimedEvent objects.  Each SSTimedEvent
//  represents a block of time and some progression of (or constant) data
//  values over that time block.
// 
//  If SSTimedEvent objects are allocated in module different from this one,
//  a callback function to free the memory must be provided.
// 
//  template argument  SSTimedEventT should be a subclass of SSTimedEvent

// Responsibilities:
// --------------------------
// 




#ifndef PassionPit_SSTimeline_h
#define PassionPit_SSTimeline_h



#include <vector>
class SSTimedEvent;

typedef void (*EventFreeFunc) (SSTimedEvent *);


//
//
template <class SSTimedEventT>
class SSTimeline
{
  
    
    
public:
    
    typedef SSTimedEventT * EventPtr;
    typedef std::vector<EventPtr> EventPtrVector;
    typedef typename EventPtrVector::iterator EventPtrVectorIter;
    
    SSTimeline();
    ~SSTimeline();
    
    int eventsAtTime( float t, EventPtrVector& outEvents );
    void addEvent( EventPtr pEvent );  // transfers ownership of object to the timeline object
    
    // if we allocated objects in another module, use this callback hook to provide a free function
    void setEventFreeFunc( EventFreeFunc func ) { eventFreeFunc_ = func; }
    
private:
    
    void clear();
    
    EventPtrVector events_;
    EventFreeFunc eventFreeFunc_; 
};


//
//
template <class SSTimedEventT>
SSTimeline<SSTimedEventT>::SSTimeline() :
eventFreeFunc_(0)
{
    
}

//
//
template <class SSTimedEventT>
SSTimeline<SSTimedEventT>::~SSTimeline()
{ 
    clear();
}

//
//
template <class SSTimedEventT>
int SSTimeline<SSTimedEventT>::eventsAtTime( float t, EventPtrVector& outEvents )
{
    int iEventCount = 0;
    
    EventPtrVectorIter it;
    for ( it = events_.begin(); it != events_.end(); ++it )
    {
        if ( (*it)->activeAtTime( t ) )
        {         
            outEvents.push_back( (*it) );
            ++iEventCount;
        }
    }
    
    return iEventCount;
}

//
//
template <class SSTimedEventT>
void SSTimeline<SSTimedEventT>::addEvent( EventPtr pEvent )
{
    events_.push_back( pEvent );
}

//
// remove all events and free their memory
template <class SSTimedEventT>
void SSTimeline<SSTimedEventT>::clear()
{
    EventPtrVectorIter it;
    for ( it = events_.begin(); it != events_.end(); ++it )
    {
        if ( eventFreeFunc_ )
        {
            // for objects allocated in another module
            eventFreeFunc_( *it );
        }
        else
        {
            delete (*it);                
        }
    }
    
    events_.clear();
    
}





#endif // PassionPit_SSTimeline_h
