//
//  SnibbeUserDataOwner.h
//  SnibbeLib
//
//  Created by Graham McDermott on 8/5/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//
//  class SnibbeUserDataOwner
//  ---------------------
//  Mixin class allowing attachment of SnibbeUserData-derived classes.
//  Once user data is dynamically allocated and attached to 
//  an object of a class derived from SnibbeUserDataOwner, it assumes
//  responsibility for the user data including deleting it.


#ifndef __SNIBBE_USER_DATA_OWNER_H__
#define __SNIBBE_USER_DATA_OWNER_H__

class SnibbeUserData;

class SnibbeUserDataOwner
{
    
public:
    
    SnibbeUserDataOwner();
    virtual ~SnibbeUserDataOwner();
    
    SnibbeUserData * getUserData();
    void setUserData( SnibbeUserData * data ); // caller relinquishes ownership of userdata
    
protected:
    
    SnibbeUserData * userData_;
    
    
};

#endif // __SNIBBE_USER_DATA_OWNER_H__