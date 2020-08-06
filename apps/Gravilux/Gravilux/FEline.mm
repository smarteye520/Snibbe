//
//  FEline.cpp
//  Gravilux
//
//  Created by Colin Roache on 10/24/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#include "FEline.h"

FEline::FEline(ForceState * fs) : ForceEmitter(fs)
{
	CGRect screenRect = [UIScreen mainScreen].bounds;
	
	bottomLeft = new Force();
	bottomLeft->setPosition(screenRect.origin.x, screenRect.origin.y + screenRect.size.height);
	bottomLeft->setStrength(-5.);
	bottomLeft->setVelocity(0., 0.);
	bottomLeft->setAcceleration(0., 0.);
	bottomLeft->setBoundaryMode(ForceBoundaryModeClamp);
	state_->addForce(bottomLeft);
	
	bottomRight = new Force();
	bottomRight->setPosition(screenRect.origin.x + screenRect.size.width, screenRect.origin.y + screenRect.size.height);
	bottomRight->setStrength(-5.);
	bottomRight->setVelocity(0., 0.);
	bottomRight->setAcceleration(0., 0.);
	bottomRight->setBoundaryMode(ForceBoundaryModeClamp);
	state_->addForce(bottomRight);
}

FEline::~FEline()
{
	delete bottomLeft;
	delete bottomRight;
}

void
FEline::simulate(float dt, float lows, float mids, float highs)
{
	float strength = -((mids+lows)*20.);
	bottomLeft->setStrength(strength);
	bottomRight->setStrength(strength);
}