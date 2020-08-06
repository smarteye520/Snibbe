//
//  SSClock.mm
//  SnibbeLib
//
//  Created by Colin Roache on 6/20/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//


#include "SSClock.h"
#import <QuartzCore/QuartzCore.h>

static SSClock *clock_ = 0;

//
// static
SSClock& SSClock::clock(void * key)
{
	if ( !clock_ )
	{
		clock_ = new SSClock();
	}
	return *clock_;
}

//
//
void SSClock::update(float t)
{
	time_ = t;
}

//
//
void SSClock::reset()
{
	paused_ = false;
	pauseTime_ = 0.f;
}

//
// pause the timer so that the time is continuous when resumed
void SSClock::pause()
{
	if (!paused_) {
		paused_ = true;
		pauseTime_ = systemTime();
	}
}

//
// resume timer and account for the time paused
void SSClock::resume()
{
	if (paused_) {
		paused_ = false;
		pauseOffset_ += systemTime() - pauseTime_;
	}
}

//
// return current time as a float
float SSClock::timef()
{
	return time_;
}

//
// protected method for getting the preferred time
float SSClock::systemTime()
{
	return (float)CACurrentMediaTime();
}

//
//
SSClock::~SSClock()
{
	
}

//
// private ctor for singleton
SSClock::SSClock()
{
	time_ = 0.f;
	pauseOffset_ = 0.f;
	paused_ = false;
}