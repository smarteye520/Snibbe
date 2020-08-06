//
//  MPActionPool.h
//  MotionPhone
//
//  Created by Graham McDermott on 2/15/12.
//  Copyright (c) 2012 Scott Snibbe. All rights reserved.
//

#ifndef MotionPhone_MPActionPool_h
#define MotionPhone_MPActionPool_h

#import "MPActionBrush.h"
#import "MPActionUpdateBrushVals.h"
#include <vector>

// small value unless we turn these back on
#define ACTION_POOL_SIZE 10

//
//
template <class poolType, int poolSize>
class MPActionPool
{

public:
    
    MPActionPool();
    ~MPActionPool();
    
    poolType * request();
        
private:
    
    
    int lastFreeElemIndex_;
    std::vector<poolType> poolElems_;
};



//
//
template <class poolType, int poolSize>
MPActionPool<poolType, poolSize>::MPActionPool()
{
    
    lastFreeElemIndex_ = 0;
    
    // allocate empty objects
    poolElems_.resize( poolSize );
    
    // init the actions to all be free pool actions
    for ( int i = 0; i < poolSize; ++i )
    {
        poolElems_[i].setPoolAction( true );
        poolElems_[i].setPoolIsFree( true );
    }
    
}

//
//
template <class poolType, int poolSize>
MPActionPool<poolType, poolSize>::~MPActionPool()
{
    lastFreeElemIndex_ = 0;
}

//
//
template <class poolType, int poolSize>
poolType * MPActionPool<poolType, poolSize>::request()
{
    
    for ( int i = lastFreeElemIndex_ + 1; i < poolSize; ++i )
    {
        if ( poolElems_[i].isFreePoolAction() )
        {
            lastFreeElemIndex_ = i;
            poolElems_[i].setPoolIsFree( false );
            //NSLog( @"pulling elem %d from pool\n", i );
            return &poolElems_[i];
        }
    }
    
    for ( int i = 0; i <= lastFreeElemIndex_; ++i )
    {
        lastFreeElemIndex_ = i;
        poolElems_[i].setPoolIsFree( false );

        //NSLog( @"pulling elem %d from pool\n", i );
        return &poolElems_[i];
    }
     
    
    return 0;
}


extern MPActionPool<MPActionBrush, ACTION_POOL_SIZE> gPoolBrush;
extern MPActionPool<MPActionUpdateBrushVals, ACTION_POOL_SIZE> gPoolUpdateBrushVals;

#endif
