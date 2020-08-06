//
//  RotatingColorButton.h
//  Gravilux
//
//  Created by Colin Roache on 11/18/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RotatingColorButton : UIControl {
	CGFloat color[4];
	NSDate	*startTime;
	UIImage	*imageOff;
	UIImage *imageOn;
	UIImage *mask;
}
@property (readwrite, atomic) BOOL render;

@end
