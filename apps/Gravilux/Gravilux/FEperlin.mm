//
//  FEperlin.cpp
//  Gravilux
//
//  Created by Colin Roache on 01/22/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "FEperlin.h"

FEperlin::FEperlin(ForceState * fs) : ForceEmitter(fs)
{
	myForce = new Force();
	myForce->enableVelocity(true);
	myForce->setBoundaryMode(ForceBoundaryModeWrap);
	state_->addForce(myForce);
	
	perlinGenerator = new SnibbePerlin();
	time=0.;
}

FEperlin::~FEperlin()
{
	delete myForce;
	delete perlinGenerator;
}

void
FEperlin::simulate(float dt, float lows, float mids, float highs)
{
	time+=dt;
	myForce->setVelocity((.5-perlinGenerator->f(SnibbePerlin::NOISE1, time))*NOISE_COEFFICIENT,
						 (.5-perlinGenerator->f(SnibbePerlin::NOISE2, time))*NOISE_COEFFICIENT);
}