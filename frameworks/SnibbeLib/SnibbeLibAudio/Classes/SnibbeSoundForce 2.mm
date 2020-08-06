//
//  SnibbeSoundForce.mm
//  SnibbeLib
//
//  Created by Colin Roache on 5/28/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SnibbeSoundForce.h"

SnibbeSoundForce::SnibbeSoundForce() : SnibbeInputTreeNode(), SnibbeSoundAnalyzer()
{
	
}

SnibbeSoundForce::~SnibbeSoundForce()
{
	
}

bool
SnibbeSoundForce::simulate(float dt)
{
	SnibbeInputTreeNode::simulate(dt);
	return true;
}
