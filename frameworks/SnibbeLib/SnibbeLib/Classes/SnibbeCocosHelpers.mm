//
//  SnibbeCocosHelpers.mm
//  SnibbeLib
//
//  Created by Graham McDermott on 8/2/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//

#include "SnibbeCocosHelpers.h"
#import "cocos2d.h"

@implementation SnibbeCocosHelpers


//
// helper
+ (bool) node: (CCNode *) node hasParent: (CCNode *) parent
{
    if ( !node || !parent )
    {
        return false;
    }
    
    if ( node.parent == parent )
    {
        return true;
    }
    
    return [self node: node.parent hasParent: parent];
    
}

//
//
+ (void) collectAllChildren: (CCNode *) parent array: (NSMutableArray *) kids
{
    if ( !parent || !kids )
    {
        return;        
    }
    
    for ( CCNode * curChild in parent.children )
    {
        [kids addObject: curChild];
        [self collectAllChildren:curChild array:kids];
    }
                            
}


@end
