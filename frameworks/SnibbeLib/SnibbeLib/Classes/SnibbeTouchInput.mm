//
//  SnibbeTouchInput.mm
//  SnibbeLib
//
//  Created by Colin Roache on 4/27/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include <SnibbeTouchInput.h>

using namespace std;

SnibbeTouchInput::SnibbeTouchInput() : SnibbeInputTreeNode()
{
	trackedTouches_ = new SnibbeTouchTracker<SnibbeTouchInput*>();
	lastPos_ = lastVel_ = FPoint();
    
    //NSLog( @"touch input: %ul\n", (unsigned int) this );
}

SnibbeTouchInput::~SnibbeTouchInput()
{
	delete trackedTouches_;
}

bool
SnibbeTouchInput::simulate(float dt)
{
	setVelocity(lastPos_ - pos_);
	setAcceleration(lastVel_ - vel_);
	
	pos_ = lastPos_;
	lastVel_ = vel_;
	
	SnibbeInputTreeNode::simulate(dt);
	
	return true;
}

void
SnibbeTouchInput::touchesBegan(NSSet *touches)
{
	for(UITouch *touch in touches) {
		SnibbeTouchInput *n = new SnibbeTouchInput();
        
		n->setIgnored(false);
		FPoint p = NDC(touch);
		n->setPosition(p);
		n->lastPos_ = p;
        n->inputState_ = eSSInputStateBegan;
        
        add(n);
		trackedTouches_->setDataForTouch(touch, n);
        		
	}
}

void
SnibbeTouchInput::touchesMoved(NSSet *touches)
{
	// Perhapse we should use rolling averaging
	for(UITouch *touch in touches) {
		SnibbeTouchInput *n = 0;
		trackedTouches_->getDataForTouch(touch, n);
        if ( n )
        {
            n->lastPos_ = NDC(touch);
            n->inputState_ = eSSInputStateMoved;
        }
	}
}

void
SnibbeTouchInput::touchesEnded(NSSet *touches)
{
    std::vector<SnibbeTouchInput *> toDelete;
    
	for(UITouch *touch in touches) {
		SnibbeTouchInput *n = 0;
        
		trackedTouches_->getDataForTouch(touch, n);
        
        if ( n )
        {
            trackedTouches_->removeTouch( touch );
            toDelete.push_back( n );
        }
	}
    
    for ( int i = 0; i < toDelete.size(); ++i )
    {
        SnibbeTouchInput * cur = toDelete[i];        
        bool bRemoved = remove( toDelete[i] ); 
        
        if ( !bRemoved )
        {
            //NSLog( @"huh\n" );            
        }
        
        delete cur;
        //NSLog( @"Deleting %d\n", (int) cur );
        
    }
}

//
//
bool SnibbeTouchInput::touchIsTracked( UITouch * t ) const
{
    SnibbeTouchInput *n = 0;
    trackedTouches_->getDataForTouch(t, n);
    return (bool)n;

}

FPoint
SnibbeTouchInput::NDC(UITouch *touch)
{
	CGPoint screenSpace = [touch locationInView:nil]; // window coordinates
	CGRect screenRect = [UIScreen mainScreen].applicationFrame;
	FPoint output = FPoint((screenSpace.x - screenRect.origin.x) / screenRect.size.width,
					  1.- (screenSpace.y - screenRect.origin.y) / screenRect.size.height);
    
    switch ([UIApplication sharedApplication].keyWindow.rootViewController.interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            output = FPoint(output.y, 1.-output.x);
            break;
        case UIInterfaceOrientationLandscapeRight:
            output = FPoint(1.-output.y, output.x);
            break;
        default:
            break;
    }
    return output;
}