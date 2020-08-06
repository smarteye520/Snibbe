
//
//  UIDOwner.h
//  SnibbeLib
//
//  Created by Graham McDermott on 8/3/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef __SnibbeLib__UIDOwner__
#define __SnibbeLib__UIDOwner__

#include "UIDGenerator.h"

class UIDOwner
{
    
public:
    
    UIDOwner();
    ~UIDOwner();
    
    void acquireUID( UIDGenerator * pGen = 0 );
    void assumeUID( const UIDOwner& src ) { uid_ = src.uid_; }
    
    UniqueIDT uniqueID() const { return uid_; }
    void setUniqueID( UniqueIDT theID ) { uid_ = theID; } // not commonly used
    
    bool hasValidUniqueID() const { return uid_ != UNINIT_UID; }
    
    
protected:

    UniqueIDT uid_;
    
};

#endif /* defined(__SnibbeLib__UIDOwner__) */
