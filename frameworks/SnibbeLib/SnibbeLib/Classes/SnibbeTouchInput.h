//
//  SnibbeTouchInput.h
//  SnibbeLib
//
//  Created by Colin Roache on 4/27/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#pragma once
#include "SnibbeInputTreeNode.h"
#include "SnibbeTouchTracker.h"
#import <UIKit/UIKit.h>



class SnibbeTouchInput : public SnibbeInputTreeNode {
public:
	SnibbeTouchInput();
	~SnibbeTouchInput();
	
	bool simulate(float dt);
	
	void touchesBegan(NSSet *touches);
	void touchesMoved(NSSet *touches);
	void touchesEnded(NSSet *touches);

    bool touchIsTracked( UITouch * t ) const; 
    FPoint NDC(UITouch* touch);
    
protected:
	SnibbeTouchTracker<SnibbeTouchInput*>* trackedTouches_;
private:
	
	
	FPoint lastPos_, lastVel_;
};