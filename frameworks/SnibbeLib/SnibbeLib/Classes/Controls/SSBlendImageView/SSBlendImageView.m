//
//  SSBlendImageView.m
//  SnibbeLib
//
//  Created by Graham McDermott on 6/26/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#import "SSBlendImageView.h"

@implementation SSBlendImageView

@dynamic blendMode_;
@dynamic image_;

- (CGBlendMode) blendMode_
{
    return blendMode_;
}

- (void) setBlendMode_:(CGBlendMode)b
{
    blendMode_ = b;
    [self setNeedsDisplay];
}

- (UIImage *) image_
{
    return image_;
}

- (void) setImage_:(UIImage *)i
{
    if ( image_ )
    {
        [image_ release];
        image_ = nil;
    }
    
    //self.backgroundColor = [UIColor clearColor];
    image_ = [i retain];
    [self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        blendMode_ = kCGBlendModeScreen;
        image_ = nil;
    }
    return self;
}

//
//
- (void) dealloc
{
    [super dealloc];
    if ( image_ )
    {
        [image_ release];
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // not exactly working yet
    [self.image_ drawInRect:rect blendMode:blendMode_ alpha:self.alpha];
}


@end
