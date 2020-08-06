//
//  FEspinning.cpp
//  Gravilux
//
//  Created by Colin Roache on 10/24/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#include "FEspinning.h"

FEspinning::FEspinning(ForceState * fs) : ForceEmitter(fs)
{
	CGSize screenSize = [UIScreen mainScreen].bounds.size;
	
	spinningForce = new Force();
	spinningForce->setPosition((screenSize.width / 2.),
							   (screenSize.height / 2.));
	spinningForce->setStrength(5.);
	spinningForce->setVelocity(0., 0.);
	spinningForce->setAcceleration(0., 0.);
	spinningForce->setBoundaryMode(ForceBoundaryModeClamp);
	state_->addForce(spinningForce);
	
	
	theta = x = y = 0.;
}

FEspinning::~FEspinning()
{
	delete spinningForce;
}

void
FEspinning::simulate(float dt, float lows, float mids, float highs)
{
	theta += exp2f((lows+mids+highs)/3.)-1.;
	CGSize screenSize = [UIScreen mainScreen].bounds.size;
	x = (.25*x)+(.75*(sin(theta)*500*(lows+(.25*mids))));
	y = (.25*y)+(.75*(cos(theta)*500*(highs+(.25*mids))));
	
	spinningForce->setPosition((screenSize.width / 2.) + sin(theta)*100,
							   (screenSize.height / 2.) + cos(theta)*100);
	
	spinningForce->setStrength(MIN(5.*(lows+mids+highs), 5.));
}