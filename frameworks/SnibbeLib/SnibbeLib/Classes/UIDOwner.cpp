//
//  UIDOwner.cpp
//  SnibbeLib
//
//  Created by Graham McDermott on 8/3/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "UIDOwner.h"

//
//
UIDOwner::UIDOwner() :
    uid_(UNINIT_UID)
{
    
}


UIDOwner::~UIDOwner()
{
    
}


void UIDOwner::acquireUID( UIDGenerator * pGen )
{
    if ( !pGen )
    {
        pGen = &UIDGenerator::defaultGenerator();
    }
    
    uid_ = pGen->nextUniqueID();
    
}
