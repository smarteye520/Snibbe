//
//  UIDGenerator.h
//  SnibbeLib
//
//  Created by Graham McDermott on 8/3/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef __SnibbeLib__UIDGenerator__
#define __SnibbeLib__UIDGenerator__

#define UNINIT_UID 0

typedef unsigned int UniqueIDT;

class UIDGenerator
{
    
public:
    
    UIDGenerator();
    ~UIDGenerator();
    
    void reset();
    
    UniqueIDT nextUniqueID();
    
    static UIDGenerator& defaultGenerator();
    
private:
    
    static UIDGenerator genDefault;
    
    UniqueIDT nextUID_;
    
};


#endif /* defined(__SnibbeLib__UIDGenerator__) */
