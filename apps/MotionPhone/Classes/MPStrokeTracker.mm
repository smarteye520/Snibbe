//
//  MPStrokeTracker.mm
//  MotionPhone
//
//  Created by Graham McDermott on 11/1/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//


#include "MPStrokeTracker.h"
#include "SnibbeUtils.h"



//
//
MPStrokeBrushData::MPStrokeBrushData()
{    
    brush_ = 0;
    frameNum_ = 0;    
}

//
//
MPStrokeBrushData::MPStrokeBrushData( MBrush * pBrush, int frameNum ) :
    brush_( pBrush ),
    frameNum_( frameNum )
{
    
}



// static
MPStrokeTracker MPStrokeTracker::msStrokeTracker;


// static
// return the singleton
MPStrokeTracker& MPStrokeTracker::Tracker()
{
    return msStrokeTracker;
}

//
//
MPStrokeTracker::MPStrokeTracker()
{
    
}

//
//
MPStrokeTracker::~MPStrokeTracker()
{
    
}




//
//
bool MPStrokeTracker::isStrokeTracked( MTouchKeyT key ) const
{
    return strokeData_.find( key ) != strokeData_.end();
}


//
//
int MPStrokeTracker::numBrushesForStroke( MTouchKeyT key ) const
{
    StrokeTrackerData::const_iterator it = strokeData_.find( key );
    if ( it != strokeData_.end() )
    {    
        return it->second.size();
    }
    
    return 0;        
    
}

//
//
MPStrokeBrushData * MPStrokeTracker::brushAtIndex( MTouchKeyT key, int iIndex )
{
    StrokeTrackerData::iterator it = strokeData_.find( key );
    if ( it != strokeData_.end() )
    {    
        
        if ( iIndex >= 0 && iIndex < it->second.size() )
        {        
            return &((it->second)[iIndex]);
        }
        
    }
    
    return 0; 
    
}

//
//
void MPStrokeTracker::addBrushForStroke( MTouchKeyT key, MBrush * brush, int frameNum )
{
    
    StrokeTrackerData::iterator it = strokeData_.find( key );
    std::vector<MPStrokeBrushData> * pBrushes = 0;
    
    if ( it == strokeData_.end() )
    {    
        std::vector<MPStrokeBrushData> vecEmpty;
        strokeData_[key] = vecEmpty; 
        it = strokeData_.find( key );
    }
    
    pBrushes = &it->second;       
    (*pBrushes).push_back( MPStrokeBrushData(brush, frameNum) );
       
    //SSLog( @"added brush stroke for key: %d\n", (int) key );
    
}


//
//
void MPStrokeTracker::removeStroke( MTouchKeyT key )
{
    //SSLog( @"   removing stroke for key: %d\n", (int) key );
    strokeData_.erase( key );
}

//
//
void MPStrokeTracker::removeAllStrokes()
{
    strokeData_.clear();
}


