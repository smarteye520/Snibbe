//
//  ColorWalk.h
//  Gravilux
//
//  Created by Colin Roache on 11/21/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#ifndef Gravilux_ColorWalk_h
#define Gravilux_ColorWalk_h
#include "defs.h"
#include "SnibbePerlin.h"

class ColorWalk {
private:
	ColorSet color;
	SnibbePerlin *perlinGenerator_;
	float time;
	
	Color hsv2rgb(float hue, float saturation, float value);
	
public:
	ColorWalk();
	~ColorWalk();
	ColorSet simulate(float delta);
};

#endif
