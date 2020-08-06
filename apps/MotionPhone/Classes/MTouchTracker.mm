//
//  MTouchTracker.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/6/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//


#include "MTouchTracker.h"


//
//
MTouchData::MTouchData()
{
    posOriginal_ = CGPointZero;
    prevPos_ = CGPointZero;
    pos_ = CGPointZero;
    posLastOrient_ = CGPointZero;
    orientation_ = 0.0f;
    drawnThisFrame_ = false;
    everDrawn_ = false;
    numFrames_ = 0;
    orientationValid_ = false;
    
    performanceTouch_ = false;
    performanceFGColorTouch_ = false;
    performanceBGColorTouch_ = false;
    performanceBrushSizeTouch_ = false;
    performanceControlTouchBeginTime_ = -1.0f;
}

//
//
float MTouchData::calculateTouchAlpha() const
{
    float alpha = 1.0f;
    if ( numFrames_ <= NUM_TOUCH_FADE_FRAMES )
    {
        alpha = numFrames_ / (float) (NUM_TOUCH_FADE_FRAMES + 1);
    }
    
    return alpha;
}


// static
MTouchTracker MTouchTracker::msTouchTracker;


// static
// return the singleton
MTouchTracker& MTouchTracker::Tracker()
{
    return msTouchTracker;
}

//
//
MTouchTracker::MTouchTracker()
{
    
}

//
//
MTouchTracker::~MTouchTracker()
{
    
}



//
//
int MTouchTracker::numTouchesTracked() const
{
    return touchData_.size();
}

//
//
bool MTouchTracker::isTouchTracked( MTouchKeyT key ) const
{
    return touchData_.find( key ) != touchData_.end();
}


//
//
void MTouchTracker::setDataForTouch( MTouchKeyT key, MTouchData& data )
{
    assert( key );
    touchData_[key] = data;
}

//
//
bool MTouchTracker::getDataForTouch( MTouchKeyT key, MTouchData& outData )
{   
    bool bFound = FALSE;
 
    std::map< MTouchKeyT, MTouchData >::const_iterator it = touchData_.find( key );
    if ( it != touchData_.end() )
    {
        outData = it->second;                        
        bFound = true;
    }
    
    
    return bFound;
}


//
//
MTouchData * MTouchTracker::getDataForTouch( MTouchKeyT key )
{
    std::map< MTouchKeyT, MTouchData >::iterator it = touchData_.find( key );
    if ( it != touchData_.end() )
    {
        return &it->second;
    }
    
    return 0;
}


//
//
void MTouchTracker::removeTouch( MTouchKeyT key )
{
    touchData_.erase( key );
}

//
//
void MTouchTracker::removeAllTouches()
{
    touchData_.clear();
}

//
//
MTouchData * MTouchTracker::getFirstData()
{ 
    itFirstNext_ = touchData_.begin();
    return ( itFirstNext_ == touchData_.end() ? 0 : &itFirstNext_->second );
}

//
//
MTouchData * MTouchTracker::getNextData()
{
 
    if ( itFirstNext_ == touchData_.end() )
    {
        return 0;
    }
    
    itFirstNext_++;
    return ( itFirstNext_ == touchData_.end() ? 0 : &itFirstNext_->second );
}


