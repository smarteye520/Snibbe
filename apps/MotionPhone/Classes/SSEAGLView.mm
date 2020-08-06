//
//  SSEAGLView.m
//  MotionPhone
//
//  Created by Scott Snibbe on 11/12/10.
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "defs.h"
#import "SSEAGLView.h"

@interface SSEAGLView (PrivateMethods)
- (void)createFramebuffer;
- (void)deleteFramebuffer;
@end

@implementation SSEAGLView

@dynamic context;

// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


//The EAGL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:.
- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
	if (self)
    {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
    }
    
    return self;
}

- (void)dealloc
{
    [self deleteFramebuffer];    
    [context release];
    
    [super dealloc];
}

- (EAGLContext *)context
{
    return context;
}

- (void)setContext:(EAGLContext *)newContext
{
    if (context != newContext)
    {
        [self deleteFramebuffer];
        
        [context release];
        context = [newContext retain];
        
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)createFramebuffer
{
    if (context && ( !defaultFramebuffer || defaultFramebufferMS ) )
    {
        [EAGLContext setCurrentContext:context];
        
        // Create default framebuffer object.
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create color render buffer and allocate backing store.
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);            
        
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];            
        
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);            

        
        // optionally create the multi-sample render and frame buffers on this device
        
        if ( gUseMultiSample )
        {
            
            // Create default framebuffer object.
            glGenFramebuffers(1, &defaultFramebufferMS);
            glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebufferMS);
            
            // Create color render buffer and allocate backing store.
            glGenRenderbuffers(1, &colorRenderbufferMS);
            glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbufferMS);    
                        
            
            CGSize renderBufferSize =  ((CAEAGLLayer *)self.layer).frame.size;
            
            const GLenum samplesToUse = 4;
            glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, samplesToUse, GL_RGB5_A1_OES, renderBufferSize.width, renderBufferSize.height);
         
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbufferMS);

    
            
            
        }
        
        
       
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
            NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    
        

            
        
       
    }
} 

- (void)deleteFramebuffer
{
    if (context)
    {
        [EAGLContext setCurrentContext:context];
        
        if (defaultFramebuffer)
        {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer)
        {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }

        if (defaultFramebufferMS)
        {
            glDeleteFramebuffers(1, &defaultFramebufferMS);
            defaultFramebufferMS = 0;
        }
        
        if (colorRenderbufferMS)
        {
            glDeleteRenderbuffers(1, &colorRenderbufferMS);
            colorRenderbufferMS = 0;
        }
        
    } 
}

- (void)setFramebuffer
{
    if (context)
    {
        [EAGLContext setCurrentContext:context];
        
        if (!defaultFramebuffer)
            [self createFramebuffer];
        
        
        if ( gUseMultiSample )
        {         
            glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebufferMS);
        }
        else
        {
            glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        }
        
        glViewport(0, 0, framebufferWidth, framebufferHeight);
    }
}

- (BOOL)presentFramebuffer
{
    BOOL success = FALSE;
    
    if (context)
    {
        [EAGLContext setCurrentContext:context];
        
        
        if ( gUseMultiSample )
        {  
            //Bind both MSAA and View FrameBuffers. 
            glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, defaultFramebufferMS); 
            glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, defaultFramebuffer);
            glResolveMultisampleFramebufferAPPLE();
        }
        
        
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        
        success = [context presentRenderbuffer:GL_RENDERBUFFER];
    }
    
    return success;
}

- (void)layoutSubviews
{
    // The framebuffer will be re-created at the beginning of the next setFramebuffer method call.
    [self deleteFramebuffer];
}

@end
