//
//  SnibbeTexManager.mm
//  VirusApp
//
//  Created by Graham McDermott on 4/28/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//

// Make sure this is defined, we should probably orgainize all library dependant classes this way -Colin 1/31/12
#ifdef USING_COCOS_2D


#import "SnibbeTexManager.h"
#import "CCTextureCache.h"

SnibbeTexManager *theManager = nil;

///////////////////////////////////////////
// SnibbeTexManager private interface
///////////////////////////////////////////


@interface SnibbeTexManager()

    -(void) releaseAllTextures;

@end

///////////////////////////////////////////
// SnibbeTexManager implementation
///////////////////////////////////////////

@implementation SnibbeTexManager


//
// called at app init
+ (void) startup
{
    theManager = [[SnibbeTexManager alloc] init];
}

//
// called at app shutdown
+ (void) shutdown
{
    [theManager release];
    theManager = nil;
}


//
// return the singleton
+ (SnibbeTexManager *) man
{
    return theManager;
}


//
//
- (id) init
{
    if ( (self = [super init] ) )
    {
        texturesByID_ = [[NSMutableDictionary alloc] init];        
        texFilenameToID_ = [[NSMutableDictionary alloc] init];
        
        asyncLock_ = [[NSLock alloc] init];
        
        iNumRequests_ = 0;
        iNumCompleted_ = 0;
    }
    
    return self;
}


//
//
-(void) dealloc
{
    [self releaseAllTextures];
    
    [texturesByID_ release];
    texturesByID_ = nil;
    
    [texFilenameToID_ release];
    texFilenameToID_ = nil;
    
	[super dealloc];
}



//
//
- (void) addTextureWithName: (NSString *) name textureID: (int) theID
{
    
    // new async technique    
    NSNumber * numID = [NSNumber numberWithInt: theID];
    
    
    [asyncLock_ lock];
    
    ++iNumRequests_;    
    [texFilenameToID_ setObject: numID forKey: name];
    
    [[CCTextureCache sharedTextureCache] addImageAsync:name target:self selector: @selector(asyncImageAdded:) ];
    
    [asyncLock_ unlock];
    
   }

//
//
- (CCTexture2D *) textureForID: (int) theID
{
    return [texturesByID_ objectForKey: [NSNumber numberWithInt: theID]];
}

//
//
- (void) setID: (int) theID forTexture: (CCTexture2D *) texture
{
    NSNumber * numID = [NSNumber numberWithInt: theID];
    [texturesByID_ setObject: texture forKey: numID];
}

//
//
- (void) releaseTextureForID: (int) theID
{
    
    
}

//
//
- (void) asyncImageAdded: (CCTexture2D *) tex
{
    
    
    [asyncLock_ lock];
    
    
    ++iNumCompleted_;
    
    NSString *texName = [[CCTextureCache sharedTextureCache] keyForTexture: tex];    
    NSNumber *numID = [texFilenameToID_ objectForKey: texName];
    
    if ( tex && texName && numID && ![texturesByID_ objectForKey: numID] )
    {
        
        if ( tex )
        {
            [texturesByID_ setObject: tex forKey: numID];
        }
        else
        {
            //NSLog( @"warning, attempted to add texture %@ to texture manager but add to texture cache failed\n", texName );
        }        
        
    }
    else
    {
        //NSLog( @"warning, attempted to add texture %@ to texture manager but texture already present\n", texName );
    }
    
    [asyncLock_ unlock];
    
}

//
//
- (bool) allRequestsCompleted
{
    
    [asyncLock_ lock];    
    bool bRet = iNumRequests_ == iNumCompleted_;
    [asyncLock_ unlock];
    
    return bRet;
}

///////////////////////////////////////////
// SnibbeTexManager private implementation
///////////////////////////////////////////

//
//
-(void) releaseAllTextures
{
    [texturesByID_ removeAllObjects];
}

@end

#endif