//
//  FEtemplate.cpp
//  Gravilux
//
//  Created by Colin Roache on 10/24/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#include "FEspine.h"

#define FESPINE_STRENGTH_MAX 5.f
#define FESPINE_STRENGTH_DELTA .5f
#define FESPINE_STRENGTH_THRESHOLD .1f
#define FESPINE_SPEED_COEFFICIENT .25f
FEspine::FEspine(ForceState * fs) : ForceEmitter(fs)
{
	screenSize = [UIScreen mainScreen].bounds;
	
	spineForce = new Force();
	spineForce->setPosition(screenSize.origin.x + screenSize.size.width / 2., screenSize.origin.y + screenSize.size.height / 2.);
	spineForce->setStrength(0.);
	spineForce->setVelocity(0., 0.);
	spineForce->setAcceleration(0., 0.);
	spineForce->setBoundaryMode(ForceBoundaryModeClamp);
	state_->addForce(spineForce);
	
	integrator = 0.;
}

FEspine::~FEspine()
{
	delete spineForce;
}

void
FEspine::simulate(float dt, float lows, float mids, float highs)
{
	float current = .25*lows + .25*mids + .5*highs;
	integrator += current * FESPINE_SPEED_COEFFICIENT;
	spineForce->setPosition(screenSize.origin.x + screenSize.size.width / 2.,
							screenSize.origin.y + screenSize.size.height / 2. + sin(integrator)*(screenSize.size.height/4.));
	if (current > FESPINE_STRENGTH_THRESHOLD) {
		spineForce->setStrength(FESPINE_STRENGTH_MAX, .1);
	}
}