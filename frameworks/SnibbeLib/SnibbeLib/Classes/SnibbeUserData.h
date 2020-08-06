//
//  SnibbeUserData.h
//  SnibbeLib
//
//  Created by Graham McDermott on 8/5/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//
//  class SnibbeUserData
//  ---------------------
//  empty parent class to be used to derive simple user data classes from.
//  Allows a way to give userdata a common parent class with a virtual
//  DTOR so objects that own them can easily destroy them without
//  needing to know their actual static type.


#ifndef __SNIBBE_USER_DATA_H__
#define __SNIBBE_USER_DATA_H__


class SnibbeUserData
{
  
public:
    
    SnibbeUserData();
    SnibbeUserData( void * pData );
    virtual ~SnibbeUserData();
    
    void setData( void * pData ) { pData_ = pData; }
    void * getData() { return pData_; }
    
protected:
    
    void * pData_; // objects pointed to by this aren't owned by this class - don't delete
    
    
};

#endif // __SNIBBE_USER_DATA_H__