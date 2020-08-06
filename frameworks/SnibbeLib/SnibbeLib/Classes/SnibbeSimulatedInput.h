//
//  SnibbeSimulatedInput.h
//  SnibbeLib
//
//  Created by Colin Roache on 5/1/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#pragma once
#include "SnibbeInputTreeNode.h"

enum SnibbeWrapMode {
	SnibbeWrapModeNone = 0,
	SnibbeWrapModeClamp,
	SnibbeWrapModeRepeat,
	SnibbeWrapModeMirroredRepeat
};

class SnibbeSimulatedInput : public SnibbeInputTreeNode {
public:
	SnibbeSimulatedInput();
	~SnibbeSimulatedInput();
	bool simulate(float dt);
	void simulateVelocity(bool sim) { simVel_ = sim; };
	void simulateAcceleration(bool sim) { simAcc_ = sim; };
	void simulateStrength(bool sim) { simStrength_ = sim; };
	
	void setStrength(float strength, float strengthDelta)
	{
		strength_ = strength;
		strengthDelta_ = strengthDelta;
		simStrength_ = true;
	};
	void setWrapMode(SnibbeWrapMode w) { wrapMode_ = w; };

private:
	bool simVel_;
	bool simAcc_;
	bool simStrength_;
	float damp_;
	float strengthDelta_;
	SnibbeWrapMode wrapMode_;
};
