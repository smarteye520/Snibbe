//
//  ForceEmitter.h
//  Gravilux
//
//  Created by Colin Roache on 10/14/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#pragma once
#include "ForceState.h"
#import "MicrophoneListener.h"
class ForceEmitter {
protected:
	ForceState			*state_;
	
	
public:
	ForceEmitter(ForceState * fs)
	{
		state_ = new ForceState();
		if (fs) {
			fs->insertSubstate(state_);
		}
	};
	~ForceEmitter()
	{
		delete state_;
	};
	
	virtual void			simulate(float dt, float lows, float mids, float highs) =0;
	void					start() { state_->setActive(true); };
	void					stop() { state_->setActive(false); };
	
	ForceState *			state() { return state_; };
};