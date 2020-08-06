//
//  ColorWalk.mm
//  Gravilux
//
//  Created by Colin Roache on 11/21/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "ColorWalk.h"

#define MAX_DELTA 1.
#define SCALE_DELTA 0.02 // Exponential?
#define POWER_DELTA 3.5
#define MIN_THETA_DELTA -.05
#define MAX_THETA_DELTA .05

#define M_PI_2_3 (M_PI * (2. / 3.))
#define M_2PI (M_PI * 2.f)

ColorWalk::ColorWalk()
{
	time = 0.;
	
	perlinGenerator_ = new SnibbePerlin();
}

ColorWalk::~ColorWalk()
{
	delete perlinGenerator_;
}

ColorSet
ColorWalk::simulate(float delta)
{
	time += delta;
	
	float hue = perlinGenerator_->f(SnibbePerlin::NOISE1, time/500.f)*M_2PI;
	
	color.slow = hsv2rgb(hue, 1., 1.);
	color.medium = hsv2rgb(fmod(hue+M_PI_2_3, M_2PI), 1., 1.);
	color.fast = hsv2rgb(fmod(hue+M_PI_2_3+M_PI_2_3, M_2PI), 1., 1.);
	return color;
}

Color
ColorWalk::hsv2rgb(float h, float s, float v)
{
	Color sampledColor;
	// From http://en.wikipedia.org/wiki/HSL_and_HSV#Converting_to_RGB
	float c = s * v;
	float hPrime = h / (M_PI / 3.);
	float x = c * (1. - ABS(fmod(hPrime, 2.) - 1.));
	if (0. <= hPrime && hPrime < 1.) {
		sampledColor.r = c;
		sampledColor.g = x;
		sampledColor.b = 0.;
	} else if (1. <= hPrime && hPrime < 2.) {
		sampledColor.r = x;
		sampledColor.g = c;
		sampledColor.b = 0.;
	} else if (2. <= hPrime && hPrime < 3.) {
		sampledColor.r = 0.;
		sampledColor.g = c;
		sampledColor.b = x;
	} else if (3. <= hPrime && hPrime < 4.) {
		sampledColor.r = 0.;
		sampledColor.g = x;
		sampledColor.b = c;
	} else if (4. <= hPrime && hPrime < 5.) {
		sampledColor.r = x;
		sampledColor.g = 0.;
		sampledColor.b = c;
	} else if (5. <= hPrime && hPrime < 6.) {
		sampledColor.r = c;
		sampledColor.g = 0.;
		sampledColor.b = x;
	} else {
		sampledColor.r = 0.;
		sampledColor.g = 0.;
		sampledColor.b = 0.;
	}
	
	float m = v - c;
	sampledColor.r += m;
	sampledColor.g += m;
	sampledColor.b += m;
	
	return sampledColor;
}