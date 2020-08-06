//
//  SnibbeCocosHelpers.h
//  SnibbeLib
//
//  Created by Graham McDermott on 8/2/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//


#ifdef USING_COCOS_2D

@class CCNode;


@interface SnibbeCocosHelpers : NSObject 
{
}

+ (bool) node: (CCNode *) node hasParent: (CCNode *) parent;
+ (void) collectAllChildren: (CCNode *) parent array: (NSMutableArray *) kids;

@end

#endif
