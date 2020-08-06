//
//  SnibbeTexture.h
//  SnibbeLib
//
//  Created by Graham McDermott on 10/12/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#ifndef SnibbeLib_SnibbeTexture_h
#define SnibbeLib_SnibbeTexture_h



#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>

//
// shouldn't mix load/cache concepts with the resource data itself but the texture
// cache / object combo is special case anyway so it's fine.

typedef enum
{
    eStatusNotLoaded = 0,
    eStatusLoaded
} loadStatusT;



@interface SnibbeTexture : NSObject
{

    GLuint textureID_;
    NSString * filename_;         // originally requested filename
    NSString * filenameRemapped_; // can potentially differ from actual filename (e.g. swap out for different res textures)
    
    unsigned int width_;
    unsigned int height_;  
    
    loadStatusT loadStatus_;
}

@property (nonatomic) GLuint textureID_;
@property (nonatomic, retain) NSString * filename_;
@property (nonatomic, retain) NSString * filenameRemapped_;
@property (nonatomic) loadStatusT loadStatus_;
@property (nonatomic) unsigned int width_;
@property (nonatomic) unsigned int height_;

@end



#endif
