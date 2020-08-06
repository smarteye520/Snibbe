//
//  ForceState.h
//  Gravilux
//
//  Created by Colin Roache on 10/13/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//
#pragma once
#include "defs.h"
#include "SnibbeInterpolator.h"
#include "time.h"
#include <set>

using namespace std;

enum ForceBoundaryMode {
	ForceBoundaryModeNone	= 0,
	ForceBoundaryModeWrap	= 1,
	ForceBoundaryModeClamp	= 2,
	ForceBoundaryModeBounce	= 3
};

class ForceState; // header below
class ForceEmitter;

class Force {
public:
	friend class ForceState;
	Force() { init(); };
	Force(UITouch * touch) {
		init();
		touch_ = [touch retain];
		trackTouch_ = true;
	};
	~Force() {
		if (touch_ != nil) {
			[touch_ release];
			touch_ = nil;
		}
	};
	
	bool			simulate(float dt); // returns false if this object has died and should be dealloced
	
	bool			active();
	void			setActive(bool a) { active_ = a; };
	
	FPoint			position();
	void			setPosition(float x, float y) { pos_.x = x; pos_.y = y; };
	
	void			enableVelocity(bool sim) { simVel_ = sim; };
	void			setVelocity(float x, float y) { vel_.x = x; vel_.y = y; simVel_ = true; };
	
	void			enableAcceleration(bool sim) { simAcc_ = sim; };
	void			setAcceleration(float x, float y) { acc_.x = x; acc_.y = y; simAcc_ = true; simVel_ = true; };
	
	float			strength();
	void			enableStrength(bool sim) { simStrength_ = sim; };
	void			setStrength(float strength, float strengthDelta)
					{
						strength_ = strength;
						strengthDelta_ = strengthDelta;
						simStrength_ = true;
					};
	void			setStrength(float strength) { setStrength(strength, 0.f); simStrength_ = false; };
	void			setBoundaryMode(ForceBoundaryMode boundaryMode) { boundaryMode_ = boundaryMode; };
	
	void			toggleGravity() { strength_ = -strength_; };
	
	bool			isTouch() { return trackTouch_; };
	
	ForceState *	state() { return state_; }
protected:
	bool								active_;
	bool								simVel_;
	bool								simAcc_;
	bool								simStrength_;
	bool								trackTouch_;
	FPoint								vel_;
	FPoint								acc_;
	float								damp_;
	float								strength_;
	float								strengthDelta_;
	ForceBoundaryMode					boundaryMode_;
	UITouch								*touch_;
private:
	void								init();
	ForceState							*state_;
	FPoint								pos_;
	FPoint								offsetPos_;
	CGSize								screenSize_;
};

class ForceState {
public:
	friend class			Force;
	friend class			ForceEmitter;
	ForceState();
	~ForceState();
	
	void					addForce(Force* force);
	void					clear();
	set<Force*>::iterator	begin();
	set<Force*>::iterator	end();
	
	ForceState *			superstate() { return superstate(); };
	set<ForceState *>		substates() { return substates_; };
	void					insertSubstate(ForceState* fs);
	
	void					simulate(float dt);
	
	void					setGravity(float gravity); // sets the gravity of all current forces
													   // idea: only modify touch forces? $$$
	
	float					strength();
	void					setStrength(float strength);
	
	bool					active() { return active_; };
	void					setActive(bool active) { active_ = active; };
	
	void					setOffset(ForceEmitter* offset);
	FPoint					getOffset();
	FPoint					sumForce(CGPoint p, float sizeScale);
	
protected:
	bool					active_;
	set<Force*>				forces_;
private:
	SnibbeInterpolator<float, double>	*interpolator;
	set<ForceState*>		substates_;
	ForceState*				superstate_;
	ForceEmitter *			offset_;

};