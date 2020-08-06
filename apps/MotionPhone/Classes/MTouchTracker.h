//
//  MTouchTracker.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/6/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//
//
//  class MTouchTracker
//  -------------------
//  used to keep track of the current set of touches and associated
//  data.

#ifndef MotionPhone_MTouchTracker_h
#define MotionPhone_MTouchTracker_h

#include <map>
#include "defs.h"

struct MTouchData
{  
    MTouchData();    
    
    float calculateTouchAlpha() const;
    
    CGPoint posOriginal_;
    CGPoint prevPos_;
    CGPoint posLastOrient_; // last pos used for orient calculation
    CGPoint pos_;
    float orientation_;
    bool  orientationValid_;
    bool drawnThisFrame_;
    float numFrames_;
    bool everDrawn_;
    MTouchKeyT touchKey_;
    
    // performance mode keys - hacked in values to enable performance mode
    
    bool performanceTouch_;        // flag indicating used for general controls in performance mode
    bool performanceFGColorTouch_; // flag indicating used for fg color in performance mode
    bool performanceBGColorTouch_;
    bool performanceBrushSizeTouch_;
    double performanceControlTouchBeginTime_;
};



class MTouchTracker
{
  
public:
    
    ~MTouchTracker();
    
    bool    isTouchTracked( MTouchKeyT key ) const;
    int     numTouchesTracked() const;

    void setDataForTouch( MTouchKeyT key, MTouchData& data );
    bool getDataForTouch( MTouchKeyT key, MTouchData& outData );
    MTouchData * getDataForTouch( MTouchKeyT key );
    
    
    void removeTouch( MTouchKeyT key );
    void removeAllTouches();
    
    static MTouchTracker& Tracker();
    
    MTouchData * getFirstData();
    MTouchData * getNextData();
    
private:
    
    MTouchTracker(); // ensures singleton
    
    static MTouchTracker msTouchTracker;    
    std::map< MTouchKeyT, MTouchData > touchData_;
    
    std::map< MTouchKeyT, MTouchData >::iterator itFirstNext_;
    
};

#endif
