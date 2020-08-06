//
//  SnibbeTextureCache.h
//  SnibbeLib
//
//  Created by Graham McDermott on 6/18/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//
//
//  SnibbeTextureCache
//  -------------------
//  Simple cache for SnibbeTexture objects.  .png textures are loaded by filename
//  either synchronously or asynchronously.  Repeated requests for a texture of the
//  same name will return the same SnibbeTexture instance.


#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <UIKit/UIKit.h>

@class SnibbeTexture;








@protocol SnibbeTextureCacheDelegate <NSObject>

@optional

- (void) asyncTextureAddComplete: (SnibbeTexture *) tex;
- (void) asyncTextureAddFailedForPath: ( NSString * ) path;


@end




@interface SnibbeTextureCache : NSObject
{
    id<SnibbeTextureCacheDelegate> delegate_;

    NSMutableDictionary * cacheDict_;
    NSLock * asyncLockQueue_;
    NSLock * asyncLockLoad_;    
    NSLock * asyncLockCacheDict_;
    
    NSOperationQueue* opQueue_;
    
    EAGLContext * textureLoadingContext_;
    
    NSString * pathPreferredPostfix_;
}

@property (nonatomic, assign) id<SnibbeTextureCacheDelegate> delegate_;

@property (nonatomic, retain) NSString * pathPreferredPostfix_;

+ (SnibbeTextureCache *) cache;

- (SnibbeTexture *) textureWithID: (GLuint) texID;

- (SnibbeTexture *) textureNamed: (NSString *) name extension: (NSString *) ext;
- (SnibbeTexture *) textureNamed: (NSString *) nameWithExtension;
 
- (bool) textureIsLoadedNamed: (NSString *) name extension: (NSString *) ext;
- (bool) textureIsLoadedNamed: (NSString *) nameWithExtension;

- (void) addTextureAsyncNamed: (NSString *) name extension: (NSString *) ext;
- (void) addTextureAsyncNamed: (NSString *) nameWithExtension1;

- (void) removeTexture: (SnibbeTexture *) tex;
- (void) removeAllTextures;

- (void) setTextureLoadingContext: (EAGLContext *) pContext;




@end
