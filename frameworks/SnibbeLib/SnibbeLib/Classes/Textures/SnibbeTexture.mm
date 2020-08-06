//
//  SnibbeTexture.mm
//  SnibbeLib
//
//  Created by Graham McDermott on 10/12/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#include "SnibbeTexture.h"

#pragma mark private interface

@interface SnibbeTexture()

- (void) clear;

@end


@implementation SnibbeTexture


@synthesize textureID_;
@synthesize filename_;
@synthesize filenameRemapped_;
@synthesize loadStatus_;
@synthesize width_;
@synthesize height_;


//
//
- (id) init
{
    self = [super init];
    if ( self )
    {
        [self clear];
    }
    
    return self;
}

//
//
- (void) dealloc
{
    [super dealloc];
    
    [self clear];
    
    // todo release texture resource
}

#pragma mark private implementation

//
//
- (void) clear
{
    height_ = 0.0f;
    width_ = 0.0f;
    self.textureID_ = 0;
    self.filename_ = nil;
    self.filenameRemapped_ = nil;
    self.loadStatus_ = eStatusNotLoaded;
}

@end