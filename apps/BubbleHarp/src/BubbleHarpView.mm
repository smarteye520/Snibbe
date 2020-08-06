//
//  BubbleHarpView.m
//  Bubble Harp
//
//  Created by Colin Roache on 9/15/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "BubbleHarpView.h"

@implementation BubbleHarpView

- (void)setFramebuffer
{
	[super setFramebuffer];
	
	CGSize winSize = ((UIScreen *)[[UIScreen screens] objectAtIndex:0]).bounds.size;
    float w = winSize.width;
    float h = winSize.height;
	
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	glOrthof (0, w, h, 0, 1, 0);
	
    glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}
@end
