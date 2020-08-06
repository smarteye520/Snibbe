//
//  SnibbeInputTreeNode.h
//  SnibbeLib
//
//  Created by Colin Roache on 10/13/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#ifndef SnibbeLib_SnibbeInputTreeNode_h
#define SnibbeLib_SnibbeInputTreeNode_h

#include <set>
#include <vector>
#include <algorithm>
#include "FPoint.h"
#import "UIKit/UIKit.h"

using namespace std;

enum SnibbeHierarchicalRelationship {
	SNIBBE_RELATIONSHIP_MULT = 0,
	SNIBBE_RELATIONSHIP_ADD,
	SNIBBE_RELATIONSHIP_POW
};

//
//
typedef enum
{
  
    eSSInputStateNone = 0,
    eSSInputStateBegan,
    eSSInputStateMoved,
    eSSInputStateEnded,
    
} SSInputTreeStateT;

class SnibbeInputTreeNode {
public:
	SnibbeInputTreeNode();
	virtual ~SnibbeInputTreeNode();
	
	virtual bool simulate(float dt); // returns false if this object has died and should be dealloced
	
    //set<SnibbeInputTreeNode*> allNodes();
    //set<SnibbeInputTreeNode*> allLeafNodes();
    
    void collectAllNodes( set<SnibbeInputTreeNode*>& outNodes, bool respectIgnoredFlag = true );
    void collectAllLeafNodes( set<SnibbeInputTreeNode*>& outNodes, bool respectIgnoredFlag = true );
    
    SnibbeInputTreeNode * findNode( unsigned int uid );
    
    
    
	NSArray* getPositions();
	NSArray* getVelocities();
	NSArray* getAccelerations();
	
	bool active();
	void setActive(bool a) { active_ = a; };
	
	bool ignored() { return ignored_; };
	void setIgnored(bool i) { ignored_ = i; };
	
    SSInputTreeStateT getInputState() const { return inputState_; }
    
	FPoint position();
	void setPosition(FPoint p) { pos_ = p; };
	void setPosition(float x, float y) { pos_.x = x; pos_.y = y; };
	
	// We should have ways to access both local and inherited velocities
	FPoint velocity();
	void setVelocity(FPoint v) { vel_ = v; };
	void setVelocity(float x, float y) { vel_.x = x; vel_.y = y; };
	
	FPoint acceleration();
	void setAcceleration(FPoint a) { acc_ = a; }
	void setAcceleration(float x, float y) { acc_.x = x; acc_.y = y; };
	
	float strength();
	void setStrength(float s) { strength_ = s; };
	
	void setStrengthRelationship(SnibbeHierarchicalRelationship r) { strengthRelationship_ = r; };
	void setPositionRelationship(SnibbeHierarchicalRelationship r) { posRelationship_ = r; };
	void setVelocityRelationship(SnibbeHierarchicalRelationship r) { velRelationship_ = r; };
	void setAccelerationRelationship(SnibbeHierarchicalRelationship r) { accRelationship_ = r; };
	
	void add(SnibbeInputTreeNode* n);
    bool remove(SnibbeInputTreeNode * n);
    void removeAll();
    
    void setUniqueID( unsigned int uid );
    unsigned int getUniqueID() const { return uniqueID_; }
    
    
protected:
    
    void acquireUniqueID();
    
	bool active_; // if false children nodes are not evaluated
	bool ignored_; // if true children are outputed but self is not
	float strength_;
	set<SnibbeInputTreeNode*> children_;
	SnibbeInputTreeNode *parent_;
	FPoint pos_, vel_, acc_;
	SnibbeHierarchicalRelationship strengthRelationship_, posRelationship_, velRelationship_, accRelationship_;
    SSInputTreeStateT inputState_;
    unsigned int uniqueID_;
};

#endif
