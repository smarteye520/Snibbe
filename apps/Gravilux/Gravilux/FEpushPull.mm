//
//  FEtemplate.cpp
//  Gravilux
//
//  Created by Colin Roache on 10/24/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#include "FEpushPull.h"

#define FEPUSHPULL_IMPULSE_WEIGHT .15
#define FEPUSHPULL_STRENGTH_COEFFICIENT 30.
#define FEPUSHPULL_STRENGTH_EXPO 3.
FEpushPull::FEpushPull(ForceState * fs) : ForceEmitter(fs)
{
	CGRect screenRect = [UIScreen mainScreen].bounds;
	lowsForce = new Force();
	lowsForce->setPosition(screenRect.origin.x + screenRect.size.width / 2., screenRect.origin.y + screenRect.size.height / 2. - screenRect.size.height /3.);
	lowsForce->setStrength(0);
	lowsForce->setVelocity(0., 0.);
	lowsForce->setAcceleration(0., 0.);
	lowsForce->setBoundaryMode(ForceBoundaryModeClamp);
	state_->addForce(lowsForce);
	
	
	midsForce = new Force();
	midsForce->setPosition(screenRect.origin.x + screenRect.size.width / 2., screenRect.origin.y + screenRect.size.height / 2.);
	midsForce->setStrength(0);
	midsForce->setVelocity(0., 0.);
	midsForce->setAcceleration(0., 0.);
	midsForce->setBoundaryMode(ForceBoundaryModeClamp);
	state_->addForce(midsForce);
	
	
	highsForce = new Force();
	highsForce->setPosition(screenRect.origin.x + screenRect.size.width / 2., screenRect.origin.y + screenRect.size.height / 2. + screenRect.size.height /3.);
	highsForce->setStrength(0);
	highsForce->setVelocity(0., 0.);
	highsForce->setAcceleration(0., 0.);
	highsForce->setBoundaryMode(ForceBoundaryModeClamp);
	state_->addForce(highsForce);
	
	rollingAverages[0] = 0.0;
	rollingAverages[1] = 0.0;
	rollingAverages[2] = 0.0;
}

FEpushPull::~FEpushPull()
{
	delete lowsForce;
	delete midsForce;
	delete highsForce;
}

void
FEpushPull::simulate(float dt, float lows, float mids, float highs)
{
	lowsForce->setStrength(windowingFunction(lows, &rollingAverages[0]));
	midsForce->setStrength(windowingFunction(mids, &rollingAverages[1]));
	highsForce->setStrength(windowingFunction(highs, &rollingAverages[2]));
}

float
FEpushPull::windowingFunction(float input, float* feedback)
{
	input = MIN(input, 1.);
	*feedback = ((1. - FEPUSHPULL_IMPULSE_WEIGHT) * (*feedback)) + (FEPUSHPULL_IMPULSE_WEIGHT * input);
	float delta = input - (*feedback);
	float strength = FEPUSHPULL_STRENGTH_COEFFICIENT * (powf(FEPUSHPULL_STRENGTH_EXPO, delta) - 1.);
	return strength;
}