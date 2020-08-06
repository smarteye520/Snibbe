//
//  ForceState.mm
//  Gravilux
//
//  Created by Colin Roache on 10/13/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#include "ForceState.h"
#include "ForceEmitter.h"
#include "Gravilux.h"
#include "Parameters.h"

static FPoint zeroPoint;

void
Force::init()
{
	active_ = true;
	
	touch_ = nil;
	
	simVel_ = false;
	simAcc_ = false;
	simStrength_ = false;
	trackTouch_ = false;
	pos_ = FPoint();
	offsetPos_ = FPoint();
	vel_ = FPoint();
	acc_ = FPoint();
	
	damp_ = .95f;
	strength_ = 0.f;
	strengthDelta_ = 0.f;
	boundaryMode_ = ForceBoundaryModeNone;
	state_ = NULL;
	
	screenSize_ = [UIScreen mainScreen].bounds.size;
	
	zeroPoint = FPoint();
}

bool
Force::active()
{
	// Inherit our state's activity
	if (state_)
		return state_->active() && active_;
	else
		return active_;
}

FPoint
Force::position()
{
//	return pos_;
	FPoint position = pos_;
	if (state_) {
		FPoint offset = state()->getOffset();
		position = position + offset;
		
		if (position.x > screenSize_.width) {
			position.x -= screenSize_.width;
		} else if (position.x < 0) {
			position.x += screenSize_.width;
		}
		if (position.y > screenSize_.height) {
			position.y -= screenSize_.height;
		} else if (position.y < 0) {
			position.y += screenSize_.height;
		}
		
	};
	return position;
}

/*void
Force::setPosition(float x, float y)
{
	FPoint offset = state()->getOffset();

	pos_.x = x;
	pos_.y = y;

	if (state_) {
		offsetPos_ = pos_+state_->getOffset();
		
		if (offsetPos_.x > screenSize_.width) {
			offsetPos_.x -= screenSize_.width;
		} else if (offsetPos_.x < 0.) {
			offsetPos_.x += screenSize_.width;
		}
		if (offsetPos_.y > screenSize_.height) {
			offsetPos_.y -= screenSize_.height;
		} else if (offsetPos_.y < 0.) {
			offsetPos_.y += screenSize_.height;
		}
	}
}*/

float
Force::strength()
{
	float ret = strength_;
	if (state_) {
		ret *= state_->strength();
	}
	return ret;
}

bool
Force::simulate(float dt)
{
	// If the simulation takes touches into account
	if ( trackTouch_ ) {
		// If we have a touch object in memory
		if ( touch_ != nil ) {
			// If the touch is not active
			if(touch_.phase == UITouchPhaseCancelled
			   || touch_.phase == UITouchPhaseEnded) {
				// If we are not moving
				if (ABS(vel_.x) + ABS(vel_.y) < 5.) {
					return false; // tell the ForceState that we have died
				}
			}
			// If there is still a touch occuring
			else {
				UIView *renderingView = [[UIApplication sharedApplication].keyWindow.subviews objectAtIndex:0];
				// Find the pixel position
				CGPoint position = [touch_ locationInView:renderingView];
				
				if (simVel_) {
					// Find the previous touch to calculate the current touch velocity vector
					CGPoint previousPosition = [touch_ previousLocationInView:renderingView];
					CGPoint distanceFromPrevious = CGPointMake((position.x - previousPosition.x) / dt, (position.y - previousPosition.y) / dt);
					float lamba = .9f;
					vel_.x = (1.0f - lamba) * vel_.x + lamba * distanceFromPrevious.x;
					vel_.y = (1.0f - lamba) * vel_.y + lamba * distanceFromPrevious.y;
				}
				
				position = CGPointMake(position.x, position.y);
				
				pos_.x = position.x;
				pos_.y = position.y;
			}
		}
	}
	
	
	if (boundaryMode_ != ForceBoundaryModeNone) {
		CGRect screen = [UIScreen mainScreen].bounds;
		
		float xMin = screen.origin.x;
		float xMax = screen.origin.x + screen.size.width;
		float yMin = screen.origin.y;
		float yMax = screen.origin.y + screen.size.height;
		
		switch (boundaryMode_) {
			case ForceBoundaryModeClamp:
				if (pos_.x < xMin)
					pos_.x = xMin;
				if (pos_.y < yMin)
					pos_.y = yMin;
				if (pos_.x > xMax)
					pos_.x = xMax;
				if (pos_.y > yMax)
					pos_.y = yMax;
				break;
				
			case ForceBoundaryModeWrap:
				if (pos_.x < xMin)
					pos_.x += screen.size.width;
				if (pos_.y < yMin)
					pos_.y += screen.size.height;
				if (pos_.x > xMax)
					pos_.x -= screen.size.width;
				if (pos_.y > yMax)
					pos_.y -= screen.size.height;
				break;
				
			case ForceBoundaryModeBounce:
				if (pos_.x < xMin || pos_.x > xMax)
					vel_.x = -vel_.x;
				if (pos_.y < yMin || pos_.y > yMax)
					vel_.y = -vel_.y;
				break;
			case ForceBoundaryModeNone:
			default:
				break;
		}
	}
	
	
	if ( simAcc_ ) {
		vel_.x = vel_.x*damp_ + acc_.x*dt;
		vel_.y = vel_.y*damp_ + acc_.y*dt;
	}
	if ( simVel_) {
		pos_.x += vel_.x * dt;
		pos_.y += vel_.y * dt;
	}
	if ( simStrength_ ) {
		// Make sure we are not reacting to a touch so that we don't lose the touch's strength
		if (!trackTouch_ || (touch_ != nil
							 && (touch_.phase == UITouchPhaseEnded
								 || touch_.phase == UITouchPhaseCancelled))) {;
			 strength_ = strength_ * strengthDelta_;
		}
	}
	
	return true;
}

ForceState::ForceState()
{
	interpolator = new SnibbeInterpolator<float, double>();
	interpolator->setValue(1.f);
	superstate_ = 0;
	active_ = true;
	offset_ = NULL;
}

ForceState::~ForceState()
{
	clear();
	substates_.clear();
	if(superstate_) {
		superstate_->substates_.erase(this);
	}
	if (offset_) {
		delete offset_;
	}
	delete interpolator;
}

void
ForceState::addForce(Force *force)
{
	force->state_ = this;
	forces_.insert(force);
}

void
ForceState::clear()
{
	forces_.clear();
}

set<Force*>::iterator
ForceState::begin()
{
	return forces_.begin();
}

set<Force*>::iterator
ForceState::end()
{
	return forces_.end();
}

void
ForceState::insertSubstate(ForceState *fs)
{
	if (fs) {
		fs->superstate_ = this;
		fs->offset_ = offset_;
		substates_.insert(fs);
	}
}

void
ForceState::simulate(float dt)
{
	if (offset_) {
		offset_->simulate(dt, 0., 0., 0.);
		offset_->state()->simulate(dt);
	}
	set<Force*>::iterator force = begin();
	while (force != end()) {
		if ((*force)->active()) {
			bool alive = (*force)->simulate(dt);
			
			// Remove the force if it declares itself dead
			if( !alive ) {
				forces_.erase(force++);
			} else {
				++force;
			}
		} else { 
			++force;
		}
	}
	
	// Recursivly call simulate on substates
	set<ForceState*>::iterator substate;
	for (substate = substates_.begin(); substate != substates_.end(); substate++) {
		(*substate)->simulate(dt);
	}
}

// Called when updating gravity while touching
void
ForceState::setGravity(float gravity)
{ 
	for (set<Force*>::iterator force = forces_.begin(); force != forces_.end(); force++) {
		if ((*force)->isTouch()) {
			(*force)->setStrength(gravity);
		}
	}
	// Recursivly call on child states
//	set<ForceState*>::iterator substate;
//	for (substate = substates_.begin(); substate != substates_.end(); substate++) {
//		(*substate)->setGravity(gravity);
//	}
}

void
ForceState::setStrength(float strength)
{
	interpolator->setValue(strength);
	interpolator->beginInterp(interpolator->curVal(), strength, time(NULL), 100.);
}

float
ForceState::strength()
{
	return interpolator->curVal();
}

void
ForceState::setOffset(ForceEmitter *offset)
{
	offset_ = offset;
	set<ForceState*>::iterator substate;
	for (substate = substates_.begin(); substate != substates_.end(); substate++) {
		(*substate)->setOffset(offset);
	}
}

FPoint
ForceState::getOffset()
{
	if (offset_) {
		return (*(offset_->state()->begin()))->position();
	}
	
	// Commented out as we propogate the offset object to child states
	/*if (superstate_) {
		return superstate_->getOffset();
	}*/
	return zeroPoint;
};

FPoint
ForceState::sumForce(CGPoint p, float sizeScale)
{
	FPoint sum, temp;
	float g, factor, lengthSq;
	sum.x = 0.;
	sum.y = 0.;
	bool anti = gGravilux->params()->antigravity();
	for (set<Force*>::iterator force = forces_.begin(); force != forces_.end(); force++) {
		temp = (*force)->position();
		temp.x = temp.x - p.x;
		temp.y = temp.y - p.y;
		
		lengthSq = temp.x*temp.x + temp.y*temp.y;
		
		g = GRAVITY_CONSTANT * (*force)->strength() * sizeScale;
		factor = g/lengthSq;
		
		temp.x *= factor;
		temp.y *= factor;
		
		if (anti && (*force)->isTouch()) {
			temp.x = -temp.x;
			temp.y = -temp.y;
		}
		
		sum.x += temp.x;
		sum.y += temp.y;
	}
	
	// Recusivly sum active substates
	for (set<ForceState*>::iterator substate = substates_.begin(); substate != substates_.end(); substate++) {
		if ((*substate)->active()) {
			temp = (*substate)->sumForce(p, sizeScale);
			sum.x += temp.x;
			sum.y += temp.y;
		}
	}
	
	return sum;
}