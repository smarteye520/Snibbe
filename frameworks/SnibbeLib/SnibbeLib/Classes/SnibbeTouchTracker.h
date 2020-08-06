//
//  SnibbeTouchTracker.h
//  SnibbeLib
//
//  Created by Graham McDermott on 2/24/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//
//  class SnibbeTouchTracker
//  -------------------
//  Templated class used to track of the current set of touches and associated
//  application-specific data.
//
//  The templated data type (DataT) which is associated with the touches is
//  stored in standard STL containers and therefore must have the normal container
//  functionality (e.g. and not require deep copies, etc.)


#ifndef SnibbeLib_SnibbeTouchTracker_h
#define SnibbeLib_SnibbeTouchTracker_h


typedef void * SnibbeTouchKeyT;

#include <map>


template<class DataT>
class SnibbeTouchTracker
{
    
public:
    
    SnibbeTouchTracker();
    ~SnibbeTouchTracker();
    
    bool    isTouchTracked( SnibbeTouchKeyT key ) const;
    int     numTouchesTracked() const;
    
    void setDataForTouch( SnibbeTouchKeyT key, DataT& data );
    bool getDataForTouch( SnibbeTouchKeyT key, DataT& outData );
    DataT * getDataForTouch( SnibbeTouchKeyT key );
    
    
    void removeTouch( SnibbeTouchKeyT key );
    void removeAllTouches();
    
    static SnibbeTouchTracker& Tracker();
    
    DataT * getFirstData();
    DataT * getNextData();
    
private:
    
    std::map< SnibbeTouchKeyT, DataT > touchData_;    
    typename std::map< SnibbeTouchKeyT, DataT >::iterator itFirstNext_;
    
};

//
// template implementation




//
//
template<class DataT>
SnibbeTouchTracker<DataT>::SnibbeTouchTracker()
{
    
}

//
//
template<class DataT>
SnibbeTouchTracker<DataT>::~SnibbeTouchTracker()
{
    
}



//
//
template<class DataT>
int SnibbeTouchTracker<DataT>::numTouchesTracked() const
{
    return touchData_.size();
}

//
//
template<class DataT>
bool SnibbeTouchTracker<DataT>::isTouchTracked( SnibbeTouchKeyT key ) const
{
    return touchData_.find( key ) != touchData_.end();
}


//
//
template<class DataT>
void SnibbeTouchTracker<DataT>::setDataForTouch( SnibbeTouchKeyT key, DataT& data )
{
    assert( key );
    touchData_[key] = data;
}

//
//
template<class DataT>
bool SnibbeTouchTracker<DataT>::getDataForTouch( SnibbeTouchKeyT key, DataT& outData )
{   
    bool bFound = false;
    
    typename std::map< SnibbeTouchKeyT, DataT >::const_iterator it = touchData_.find( key );
    if ( it != touchData_.end() )
    {
        outData = it->second;                        
        bFound = true;
    }
    
    
    return bFound;
}


//
//
template<class DataT>
DataT * SnibbeTouchTracker<DataT>::getDataForTouch( SnibbeTouchKeyT key )
{
    typename std::map< SnibbeTouchKeyT, DataT >::iterator it = touchData_.find( key );
    if ( it != touchData_.end() )
    {
        return &it->second;
    }
    
    return 0;
}


//
//
template<class DataT>
void SnibbeTouchTracker<DataT>::removeTouch( SnibbeTouchKeyT key )
{
    touchData_.erase( key );
}

//
//
template<class DataT>
void SnibbeTouchTracker<DataT>::removeAllTouches()
{
    touchData_.clear();
}

//
//
template<class DataT>
DataT * SnibbeTouchTracker<DataT>::getFirstData()
{ 
    itFirstNext_ = touchData_.begin();
    return ( itFirstNext_ == touchData_.end() ? 0 : &itFirstNext_->second );
}

//
//
template<class DataT>
DataT * SnibbeTouchTracker<DataT>::getNextData()
{
    
    if ( itFirstNext_ == touchData_.end() )
    {
        return 0;
    }
    
    itFirstNext_++;
    return ( itFirstNext_ == touchData_.end() ? 0 : &itFirstNext_->second );
}




#endif
