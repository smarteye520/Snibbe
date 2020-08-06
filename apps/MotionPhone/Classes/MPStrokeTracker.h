//
//  MPStrokeTracker.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/1/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//
//  class MPStrokeTracker
//  -------------------
//  used to keep track of continuous brush strokes - associates unique ids with
//  an ordered array of brush objects for a single stroke


#ifndef MotionPhone_MPStrokeTracker_h
#define MotionPhone_MPStrokeTracker_h




#include <map>
#include <vector>
#include "defs.h"

struct MPStrokeBrushData
{  
    MPStrokeBrushData();    
    MPStrokeBrushData( MBrush * pBrush, int frameNum );    
    
    MBrush * brush_;
    int frameNum_;        
};


typedef std::map< MTouchKeyT, std::vector<MPStrokeBrushData> > StrokeTrackerData;




class MPStrokeTracker
{
    
public:
    
    ~MPStrokeTracker();
    
    
    bool                isStrokeTracked( MTouchKeyT key ) const;
    int                 numBrushesForStroke( MTouchKeyT key ) const;
    MPStrokeBrushData * brushAtIndex( MTouchKeyT key, int iIndex );
    
    void                addBrushForStroke( MTouchKeyT key, MBrush * brush, int frameNum );
                
    void                removeStroke( MTouchKeyT key );
    void                removeAllStrokes();
    
    static MPStrokeTracker& Tracker();
    
    
private:
    
    MPStrokeTracker(); // ensures singleton
            
    static MPStrokeTracker msStrokeTracker;        
    StrokeTrackerData strokeData_;
    
    
};

#endif
