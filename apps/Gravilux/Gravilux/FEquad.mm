//
//  FEquad.cpp
//  Gravilux
//
//  Created by Colin Roache on 11/01/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#include "FEquad.h"

FEquad::FEquad(ForceState * fs) : ForceEmitter(fs)
{
	middleStrength = 0.;
	CGRect screenRect = [UIScreen mainScreen].bounds;
	
	topLeft = new Force();
	topRight = new Force();
	bottomLeft = new Force();
	bottomRight = new Force();
	middleLeft = new Force();
	middleRight = new Force();
	middleTop = new Force();
	middleBottom = new Force();
	
	
	middleLeft->setPosition(screenRect.origin.x,
							screenRect.origin.y + screenRect.size.height / 2);
	middleRight->setPosition(screenRect.origin.x + screenRect.size.width,
							 screenRect.origin.y + screenRect.size.height / 2);
	middleTop->setPosition(screenRect.origin.x + screenRect.size.width / 2,
						   screenRect.origin.y);
	middleBottom->setPosition(screenRect.origin.x + screenRect.size.width / 2,
							  screenRect.origin.y + screenRect.size.height);
	
	state_->addForce(topLeft);
	state_->addForce(topRight);
	state_->addForce(bottomLeft);
	state_->addForce(bottomRight);
	state_->addForce(middleLeft);
	state_->addForce(middleRight);
	state_->addForce(middleTop);
	state_->addForce(middleBottom);
}

FEquad::~FEquad()
{
	delete topLeft;
	delete topRight;
	delete bottomLeft;
	delete bottomRight;
	delete middleTop;
	delete middleBottom;
	delete middleLeft;
	delete middleRight;
}

void
FEquad::simulate(float dt, float lows, float mids, float highs)
{
	
	float strength = powf(lows*3., 3)*-10.;
	middleStrength = .25*(mids+highs) + .75*middleStrength;
	
	topLeft->setStrength(strength);
	topRight->setStrength(strength);
	bottomLeft->setStrength(strength);
	bottomRight->setStrength(strength);
	middleLeft->setStrength(middleStrength);
	middleRight->setStrength(middleStrength);
	middleTop->setStrength(middleStrength);
	middleBottom->setStrength(middleStrength/2);
	
	
	CGRect screenRect = [UIScreen mainScreen].bounds;
	float xOffset = 0;//mids*(screenRect.size.width / 3);
	float yOffset = highs*(screenRect.size.height / 6);
	
	topLeft->setPosition(xOffset + screenRect.origin.x,
						 -yOffset + screenRect.origin.y + screenRect.size.height / 3);
	topRight->setPosition(-xOffset + screenRect.origin.x + screenRect.size.width,
						  -yOffset + screenRect.origin.y + screenRect.size.height / 3);
	bottomLeft->setPosition(xOffset + screenRect.origin.x,
							yOffset + screenRect.origin.y + screenRect.size.height * 2 / 3);
	bottomRight->setPosition(-xOffset + screenRect.origin.x + screenRect.size.width,
							 yOffset + screenRect.origin.y + screenRect.size.height * 2 / 3);
}