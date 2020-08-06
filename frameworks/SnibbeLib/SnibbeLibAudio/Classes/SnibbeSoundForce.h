//
//  SnibbeSoundForce.h
//  SnibbeLib
//
//  Created by Colin Roache on 5/28/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef SnibbeLib_SnibbeSoundForce_h
#define SnibbeLib_SnibbeSoundForce_h

#include "SnibbeInputTreeNode.h"
#include "SnibbeSoundAnalyzer.h"

class SnibbeSoundForce : public SnibbeInputTreeNode, public SnibbeSoundAnalyzer {
public:
	SnibbeSoundForce();
	~SnibbeSoundForce();
	
	virtual bool simulate(float dt);
};

#endif
