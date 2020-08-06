//
//  SnibbeSimulatedInput.mm
//  SnibbeLib
//
//  Created by Colin Roache on 5/1/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//


#include "SnibbeSimulatedInput.h"

SnibbeSimulatedInput::SnibbeSimulatedInput()
{
	simVel_ = false;
	simAcc_ = false;
	simStrength_ = false;
	
	damp_ = .95f;
	strengthDelta_ = 0.f;
	
	wrapMode_ = SnibbeWrapModeNone;
}

SnibbeSimulatedInput::~SnibbeSimulatedInput()
{
	
}

bool
SnibbeSimulatedInput::simulate(float dt)
{
	if (wrapMode_ != SnibbeWrapModeNone) {
		switch (wrapMode_) {
			case SnibbeWrapModeClamp:
				if (pos_.x < 0.f)
					pos_.x = 0.f;
				if (pos_.y < 0.f)
					pos_.y = 0.f;
				if (pos_.x > 1.f)
					pos_.x = 1.f;
				if (pos_.y > 1.f)
					pos_.y = 1.f;
				break;
				
			case SnibbeWrapModeRepeat:
				if (pos_.x < 0.f)
					pos_.x += 1.f;
				if (pos_.y < 0.f)
					pos_.y += 1.f;
				if (pos_.x > 1.f)
					pos_.x -= 1.f;
				if (pos_.y > 1.f)
					pos_.y -= 1.f;
				break;
				
			case SnibbeWrapModeMirroredRepeat:
				if (pos_.x < 0.f || pos_.x > 1.f)
					vel_.x = -vel_.x;
				if (pos_.y < 0.f || pos_.y > 1.f)
					vel_.y = -vel_.y;
				break;
			default:
				break;
		}
	}
	
	// TODO: $$$ damping is per frame, not dt based
	if ( simAcc_ ) {
		vel_ = vel_ * damp_ + acceleration() * dt;
	}
	if ( simVel_) {
		pos_ += velocity() * dt;
	}
	if ( simStrength_ ) {
		strength_ = strength_ * strengthDelta_;
	}
	
    vector<SnibbeInputTreeNode *> toDelete;
    
	for (set<SnibbeInputTreeNode*>::iterator it = children_.begin(); it != children_.end(); ++it) {
		if ((*it)->active()) {
			bool alive = (*it)->simulate(dt);
			if (!alive) 
            {
                toDelete.push_back( *it );
			}
		}
		
	}
    
    for ( int i = 0; i < toDelete.size(); ++i )
    {
        int iNumErased = children_.erase(toDelete[i]);
        //NSLog( @"num erased: %d\n", iNumErased );
    }
    
    
	
	return true; // Subclasses may return false to die
}