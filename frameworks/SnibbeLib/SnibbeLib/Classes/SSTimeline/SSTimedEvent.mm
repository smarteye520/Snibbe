//
//  SSTimedEvent.m
//  PassionPit
//
//  Created by Colin Roache on 6/8/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#import "SSTimedEvent.h"


//
//
SSTimedEvent::SSTimedEvent() :
timeBegin_(0.0),
timeEnd_(0.0)
{
    
}


//
//
SSTimedEvent::SSTimedEvent( float timeBegin, float timeEnd ) :
timeBegin_( timeBegin ),
timeEnd_( timeEnd )
{
    assert( timeBegin = timeEnd );
}


//
// virtual 
SSTimedEvent::~SSTimedEvent()
{
    
}


