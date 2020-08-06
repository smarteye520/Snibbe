//
//  UIDGenerator.cpp
//  SnibbeLib
//
//  Created by Graham McDermott on 8/3/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "UIDGenerator.h"

// statics
UIDGenerator UIDGenerator::genDefault;

UIDGenerator& UIDGenerator::defaultGenerator()
{
    return genDefault;
}





//
//
UIDGenerator::UIDGenerator()
{    
    reset();
}

//
//
UIDGenerator::~UIDGenerator()
{
    
}

//
//
void UIDGenerator::reset()
{
    nextUID_ = UNINIT_UID + 1;
}

//
//
UniqueIDT UIDGenerator::nextUniqueID()
{
    UniqueIDT rv = nextUID_++;
    if ( nextUID_ == UNINIT_UID )
    {
        // test for wrap around and avoid uninit value
        nextUID_++;
    }
    
    return rv;
}
