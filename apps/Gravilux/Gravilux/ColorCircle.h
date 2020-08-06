//
//  ColorCircle.h
//  Gravilux
//
//  Created by Colin Roache on 10/10/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ColorCircle : UIButton {
	CGPathRef	circlePath;
	UIColor *	color;
}
@property (readwrite, retain, getter = getColor, setter = setColor:) UIColor *	color; //getter = getColor, setter = setColor:, 
@end
