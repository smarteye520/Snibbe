//
//  SnibbeUserDataOwner.mm
//  SnibbeLib
//
//  Created by Graham McDermott on 8/5/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//

#include "SnibbeUserDataOwner.h"
#include "SnibbeUserData.h"


//
//
SnibbeUserDataOwner::SnibbeUserDataOwner() :
   userData_(0)
{
    
}

//
// virtual
SnibbeUserDataOwner::~SnibbeUserDataOwner()
{
    if ( userData_ )
    {
        delete userData_;
    }
}

//
// 
SnibbeUserData * SnibbeUserDataOwner::getUserData()
{
    return userData_;
}

//
//
void SnibbeUserDataOwner::setUserData( SnibbeUserData * data )
{
    if ( userData_ )
    {
        delete userData_;
    }
    
    userData_ = data; // now we own it
}