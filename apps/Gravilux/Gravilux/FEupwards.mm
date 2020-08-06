//
//  FEupwards.cpp
//  Gravilux
//
//  Created by Colin Roache on 10/24/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#include "FEupwards.h"

FEupwards::FEupwards(ForceState * fs) : ForceEmitter(fs)
{
	CGRect screenRect = [UIScreen mainScreen].bounds;
	
	topLeft = new Force();
	topLeft->setPosition(screenRect.origin.x, screenRect.origin.y);
	topLeft->setStrength(5.);
	topLeft->setVelocity(0., 0.);
	topLeft->setAcceleration(0., 0.);
	topLeft->setBoundaryMode(ForceBoundaryModeClamp);
	state_->addForce(topLeft);
	
	topRight = new Force();
	topRight->setPosition(screenRect.origin.x + screenRect.size.width, screenRect.origin.y);
	topRight->setStrength(5.);
	topRight->setVelocity(0., 0.);
	topRight->setAcceleration(0., 0.);
	topRight->setBoundaryMode(ForceBoundaryModeClamp);
	state_->addForce(topRight);
}

FEupwards::~FEupwards()
{
	delete topLeft;
	delete topRight;
}

void
FEupwards::simulate(float dt, float lows, float mids, float highs)
{
	float strength = powf(lows*3., 3)*5.;
	topLeft->setStrength(strength);
	topRight->setStrength(strength);
}