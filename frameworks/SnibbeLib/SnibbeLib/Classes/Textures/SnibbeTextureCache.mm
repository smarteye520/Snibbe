//
//  SnibbeTextureCache.m
//  SnibbeLib
//
//  Created by Graham McDermott on 6/18/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#import "SnibbeTextureCache.h"
#import "SnibbeTexture.h"
#import "../SnibbeUtilsiOS.h"

static SnibbeTextureCache * gCache = 0;


#pragma mark private interface

@interface SnibbeTextureCache()

- (SnibbeTexture *) loadTextureWithPath: (NSString *) fullPath;
- (void) loadTextureAsyncWithParams: (NSDictionary *) params;


@end




@implementation SnibbeTextureCache


@synthesize delegate_;
@synthesize pathPreferredPostfix_;

//
//
- (id) init
{
    self = [super init];
    if ( self )
    {
        textureLoadingContext_ = nil;
        cacheDict_ = [[NSMutableDictionary alloc] init];
        asyncLockCacheDict_ = [[NSLock alloc] init];
        asyncLockLoad_ = [[NSLock alloc] init]; 
        asyncLockQueue_ = [[NSLock alloc] init];  
        opQueue_ = [[NSOperationQueue alloc] init];
        pathPreferredPostfix_ = nil;
    }
    
    return self;
}

//
//
- (void) dealloc
{
    [super dealloc];
    [asyncLockCacheDict_ release];
    [opQueue_ release];
    [asyncLockQueue_ release];
    [asyncLockLoad_ release];
    [cacheDict_ release];
    
}

//
//
+ (SnibbeTextureCache *) cache
{
    if ( !gCache )
    {
        gCache = [[SnibbeTextureCache alloc] init];
    }
    
    return gCache;
}


//
// load a texture synchronously and return the texture object (or the previously loaded cached object)
- (SnibbeTexture *) textureNamed: (NSString *) name extension: (NSString *) ext
{
    NSString * texName = [NSString stringWithFormat: @"%@.%@", name, ext];
    //NSLog( @"looking for texture: %@", texName );
    
    NSString * preferredTexName = nil;
    NSString * preferredTexNameWithExt = nil;
    
    
    if ( pathPreferredPostfix_ )
    {
        preferredTexName = [NSString stringWithFormat: @"%@%@", name, pathPreferredPostfix_];                
        preferredTexNameWithExt = [NSString stringWithFormat: @"%@%@.%@", name, pathPreferredPostfix_, ext];                
    }

    
    
    [asyncLockCacheDict_ lock];
    id existing = [cacheDict_ objectForKey: texName];
    [asyncLockCacheDict_ unlock];
    
    if ( existing )
    {
        //NSLog( @"found\n" );
        return existing;
    }
    else 
    {
    
        // load it up
        
        
        NSString * fullPath = [[NSBundle mainBundle] pathForResource:name ofType:ext];
        NSString * fullPathPreferred = nil;
        
        if ( preferredTexName )
        {            
            fullPathPreferred = [[NSBundle mainBundle] pathForResource:preferredTexName ofType:ext];
        }
        
        
        NSString * pathToUse = nil;
        NSString * fileNameRemapped = nil;
        
        if ( fullPathPreferred )
        {
            pathToUse = fullPathPreferred;
            fileNameRemapped = preferredTexNameWithExt;
        }
        else 
        {        
            pathToUse = fullPath;
            fileNameRemapped = nil;
        }
                    
        
        if ( pathToUse )
        {
            
            // load it
            
            SnibbeTexture * newTexture = [self loadTextureWithPath: pathToUse];
            if ( newTexture )
            {
                [asyncLockCacheDict_ lock];
                [cacheDict_ setObject:newTexture forKey:texName];
                
                // ensure that the filenames are set up to reflect any remapping we did
                newTexture.filename_ = texName;
                newTexture.filenameRemapped_ = fileNameRemapped;                
                
                [asyncLockCacheDict_ unlock];
            }
            
            return newTexture;
             
        }
        
    }
    
    return nil;
}

//
//
- (SnibbeTexture *) textureNamed: (NSString *) nameWithExtension
{
    
    NSString * fileName = [nameWithExtension stringByDeletingPathExtension];
    NSString * ext = [nameWithExtension pathExtension];
    
    return [self textureNamed: fileName extension: ext];
    
}

//
//
- (bool) textureIsLoadedNamed: (NSString *) name extension: (NSString *) ext
{
    NSString * texName = [NSString stringWithFormat: @"%@.%@", name, ext];
    
    [asyncLockCacheDict_ lock];    
    id existing = [cacheDict_ objectForKey: texName];
    [asyncLockCacheDict_ unlock];
    
    if ( existing )
    {
        SnibbeTexture * foundTex = (SnibbeTexture *) existing;
        return foundTex.loadStatus_ == eStatusLoaded;
    }

    return false;
}


//
//
- (bool) textureIsLoadedNamed: (NSString *) nameWithExtension
{
 
    NSString * fileName = [nameWithExtension stringByDeletingPathExtension];
    NSString * ext = [nameWithExtension pathExtension];
    
    return [self textureIsLoadedNamed: fileName extension: ext];
}


//
//
- (SnibbeTexture *) textureWithID: (GLuint) texID
{

    [asyncLockCacheDict_ lock];
    
    for ( id key in cacheDict_ )
    {
        SnibbeTexture * st = [cacheDict_ objectForKey: key];
        if ( st.textureID_ == texID )
        {
            [asyncLockCacheDict_ unlock];
            return st;
        }
    }
    
    [asyncLockCacheDict_ unlock];
    return nil;
}

//
//
- (void) addTextureAsyncNamed: (NSString *) name extension: (NSString *) ext
{
    NSString * texName = [NSString stringWithFormat: @"%@.%@", name, ext];
    
    NSString * preferredTexName = nil;
    NSString * preferredTexNameWithExt = nil;
    
    
    if ( pathPreferredPostfix_ )
    {
        preferredTexName = [NSString stringWithFormat: @"%@%@", name, pathPreferredPostfix_];                
        preferredTexNameWithExt = [NSString stringWithFormat: @"%@%@.%@", name, pathPreferredPostfix_, ext];                
    }

    
    [asyncLockCacheDict_ lock];
    id existing = [cacheDict_ objectForKey: texName];
    [asyncLockCacheDict_ unlock];
    
    if ( existing )
    {
        SnibbeTexture * foundTex = (SnibbeTexture *) existing;
        if ( self.delegate_ && foundTex.loadStatus_ == eStatusLoaded )
        {
            [self.delegate_ asyncTextureAddComplete: foundTex];
        }
        
    }
    else 
    {                

        [asyncLockQueue_ lock];
        
        
        NSString * fullPath = [[NSBundle mainBundle] pathForResource:name ofType:ext];
        NSString * fullPathPreferred = nil;
        
        if ( preferredTexName )
        {
            fullPathPreferred = [[NSBundle mainBundle] pathForResource:preferredTexName ofType:ext];
        }
        
        NSString * pathToUse = nil;
        NSString * fileNameRemapped = @"";
        
        if ( fullPathPreferred )
        {
            pathToUse = fullPathPreferred;
            fileNameRemapped = preferredTexNameWithExt;
        }
        else 
        {        
            pathToUse = fullPath;
            fileNameRemapped = @"";
        }


        if ( pathToUse )
        {
            
            NSDictionary * dictParams = [NSDictionary dictionaryWithObjectsAndKeys: pathToUse, @"pathToUse", texName, @"texName", fileNameRemapped, @"fileNameRemapped", nil];
            
            NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                              selector:@selector(loadTextureAsyncWithParams:)
                                                                              object:dictParams];            
            [opQueue_ addOperation:operation];
            [operation release];                                    
            
        }
        
        [asyncLockQueue_ unlock];
                
    }
}

//
//
- (void) addTextureAsyncNamed: (NSString *) nameWithExtension
{
    NSString * fileName = [nameWithExtension stringByDeletingPathExtension];
    NSString * ext = [nameWithExtension pathExtension];
    
    return [self addTextureAsyncNamed: fileName extension: ext];
}

//
// removes texture object from our cache an unbinds from GL
- (void) removeTexture: (SnibbeTexture *) tex
{

    if ( tex )
    {
        [asyncLockCacheDict_ lock];
        
        assert( [cacheDict_ objectForKey: tex.filename_] );
        
        GLuint theID = tex.textureID_;
        

        EAGLContext * savedContext = [EAGLContext currentContext];
        [EAGLContext setCurrentContext: textureLoadingContext_];
        
        glDeleteTextures(1, &theID);
        tex.textureID_ = 0;

        [EAGLContext setCurrentContext: savedContext];
        
        [cacheDict_ removeObjectForKey: tex.filename_];        

        [asyncLockCacheDict_ unlock];
    
    }
    else 
    {   
        SSLog( @"SnibbeTextureCache::removeTexture: error - null pointer\n" );
    }
    
    
}

//
// removes all texture objects from our cache an unbinds from GL
- (void) removeAllTextures
{

    NSMutableArray * allTextures = [NSMutableArray array];
    
    [asyncLockCacheDict_ lock];
    for( id key in cacheDict_ )
    {
        SnibbeTexture * curTex = [cacheDict_ objectForKey: key];
        [allTextures addObject: curTex];
    }
    [asyncLockCacheDict_ unlock];
    
    for (SnibbeTexture * tex in allTextures)
    {
        [self removeTexture: tex];
    }
    
    
}

//
//
- (void) setTextureLoadingContext:(EAGLContext *)pContext
{
    textureLoadingContext_ = pContext;
}


#pragma mark private implementation

//
//
- (SnibbeTexture *) loadTextureWithPath: (NSString *) fullPath
{    
    
    // Load the image with UIKit

    NSData *texData = [[NSData alloc] initWithContentsOfFile:fullPath];
    UIImage *image = [[UIImage alloc] initWithData:texData];
    [texData release];
    if ( image )
    {                     
        
        EAGLContext * savedContext = [EAGLContext currentContext];
        [EAGLContext setCurrentContext: textureLoadingContext_];
        
        GLuint textureHandle = 0;        
        
        glGenTextures(1, &textureHandle);
        glBindTexture(GL_TEXTURE_2D, textureHandle);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        // Draw the image into a properly formatted binary data context with CoreGraphics
        
        SnibbeTexture * ssTexture = [[SnibbeTexture alloc] init];
        
        ssTexture.width_ = CGImageGetWidth(image.CGImage);
        ssTexture.height_ = CGImageGetHeight(image.CGImage);
        void *imageData = malloc( ssTexture.height_ * ssTexture.width_ * 4 );
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();                
        CGContextRef cgContext = CGBitmapContextCreate( imageData, ssTexture.width_, ssTexture.height_, 8, 4 * ssTexture.width_, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
        CGColorSpaceRelease( colorSpace );
        
        CGContextClearRect( cgContext, CGRectMake( 0, 0, ssTexture.width_, ssTexture.height_ ) );
        
        
        // flip the texture in the y direction so that texture coords are consistent with
        // core graphics (y increasing as you move towards the bottom of the screen)
        CGContextTranslateCTM (cgContext, 0, ssTexture.height_);
        CGContextScaleCTM (cgContext, 1.0, -1.0);
        
        CGContextDrawImage( cgContext, CGRectMake( 0, 0, ssTexture.width_, ssTexture.height_ ), image.CGImage );
        
        
        // feed the image data to GL        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image.size.width, image.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
        
        GLenum err = glGetError();
        assert( err == GL_NO_ERROR );        
        
        CGContextRelease(cgContext);        
        free(imageData);
        
        ssTexture.textureID_ = textureHandle;
        ssTexture.loadStatus_ = eStatusLoaded;
        ssTexture.filename_ = [fullPath lastPathComponent];
        
        [EAGLContext setCurrentContext: savedContext];
        
		[image release];
		
        return ssTexture;
        
    }
    
    return nil;
}

//
//
- (void) loadTextureAsyncWithParams: (NSDictionary *) params
{
    [asyncLockLoad_ lock];
    
    NSString * fullPath = [params objectForKey: @"pathToUse"];
    NSString * texName = [params objectForKey: @"texName"];
    NSString * texNameRemapped = [params objectForKey: @"fileNameRemapped"];    
    
    if ( texNameRemapped && [texNameRemapped isEqualToString: @""] )
    {
        texNameRemapped = nil;
    }
            
    SnibbeTexture * loadedTexture = [self loadTextureWithPath: fullPath];
    
    if ( loadedTexture )
    {
        
        
        [asyncLockCacheDict_ lock];    
        
        loadedTexture.filename_ = texName;
        loadedTexture.filenameRemapped_ = texNameRemapped;        
        [cacheDict_ setObject:loadedTexture forKey: texName ];
        
        [asyncLockCacheDict_ unlock];
        
        
        if ( delegate_ && [delegate_ respondsToSelector: @selector( asyncTextureAddComplete: ) ] )
        {            
            SSLog( @"added texture async complete. id: %d, name: %@, remapped: %@\n", loadedTexture.textureID_, loadedTexture.filename_, texNameRemapped ? texNameRemapped : @"nil" );
            [(NSObject *)delegate_ performSelectorOnMainThread: @selector( asyncTextureAddComplete: ) withObject: loadedTexture waitUntilDone: false];
        }
    }
    else
    {
        if ( delegate_ && [delegate_ respondsToSelector: @selector( asyncTextureAddFailedForPath: ) ] )
        {
            SSLog( @"added texture async failed. path: %@\n", fullPath  );
            [(NSObject *)delegate_ performSelectorOnMainThread: @selector( asyncTextureAddFailedForPath: ) withObject: fullPath waitUntilDone: false];
        }

    }    
    
    [asyncLockLoad_ unlock];

    
}



    
@end
