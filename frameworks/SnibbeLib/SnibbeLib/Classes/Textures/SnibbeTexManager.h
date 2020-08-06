//
//  SnibbeTexManager.h
//  VirusApp
//
//  Created by Graham McDermott on 4/28/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//
//  class SnibbeTexManager
//  --------------------
//  Manages loading textures into memory by name, associating them
//  with app-relevant integer ids, and ensuring that they stay in
//  memory as needed
//
//  note: requires cocos2d

#ifdef USING_COCOS_2D

@class CCTexture2D;




@interface SnibbeTexManager : NSObject 
{
    NSMutableDictionary * texturesByID_;
    NSMutableDictionary * texFilenameToID_;
    int iNumRequests_;    // for tracking async texture requests
    int iNumCompleted_;   // for tracking async texture requests
    
    NSLock * asyncLock_;
    
}

+ (void) startup;
+ (void) shutdown;

+ (SnibbeTexManager *) man;

- (void) addTextureWithName: (NSString *) name textureID: (int) theID;

- (CCTexture2D *) textureForID: (int) theID;
- (void) setID: (int) theID forTexture: (CCTexture2D *) texture;
- (void) releaseTextureForID: (int) theID;

- (void) asyncImageAdded: (CCTexture2D *) tex;

- (bool) allRequestsCompleted;

@end


#endif

