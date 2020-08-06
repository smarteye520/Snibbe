//  SnibbeInputTreeNode.mm
//  SnibbeLib
//
//  Created by Colin Roache on 10/13/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//


#include "SnibbeInputTreeNode.h"

static unsigned int nextUniqueID = 1;

SnibbeInputTreeNode::SnibbeInputTreeNode()
{
    uniqueID_ = 0;
	active_ = true;
	ignored_ = true;
	inputState_ = eSSInputStateNone;
    
	strength_ = 0.f;
	
	pos_ = FPoint();
	vel_ = FPoint();
	acc_ = FPoint();
	
	strengthRelationship_ = SNIBBE_RELATIONSHIP_MULT;
	posRelationship_ = SNIBBE_RELATIONSHIP_ADD;
	velRelationship_ = SNIBBE_RELATIONSHIP_ADD;
	accRelationship_ = SNIBBE_RELATIONSHIP_ADD;
	
	parent_ = NULL;
    
    acquireUniqueID();
    
    //NSLog( @"new tree node with ID: %u\n", (unsigned int) uniqueID_ );
}

SnibbeInputTreeNode::~SnibbeInputTreeNode()
{
//	children_.clear();
//	if(parent_) {
//		int numErased = parent_->children_.erase(this);
//        NSLog( @"erased %d from parent SnibbeInputTreeNode\n", numErased );
//		parent_ = NULL;
//	}
    
     //NSLog( @"DESTRUCT tree node with ID: %u\n", (unsigned int) uniqueID_ );
}

bool
SnibbeInputTreeNode::simulate(float dt)
{
    
    vector<SnibbeInputTreeNode *> toDelete;
    
	for (set<SnibbeInputTreeNode*>::iterator it = children_.begin(); it != children_.end(); ++it) {
		if ((*it)->active()) {
			bool alive = (*it)->simulate(dt);
			if (!alive) {
                toDelete.push_back( *it );
			}
		}
		
	}
    
    for ( int i = 0; i < toDelete.size(); ++i )
    {
        children_.erase( toDelete[i] );
    }
    
	return true;
}


//set<SnibbeInputTreeNode*>
//SnibbeInputTreeNode::allNodes()
//{
//    set<SnibbeInputTreeNode*> output;
//		if (children_.begin() != children_.end()) {
//			for (set<SnibbeInputTreeNode*>::iterator it = children_.begin(); it != children_.end(); ++it) {
//				set<SnibbeInputTreeNode*> subset = (*it)->allNodes();
//				output.insert(subset.begin(), subset.end());
//				if (!(*it)->ignored()) {
//					output.insert(*it);
//				}
//			}
//		}
//    return output;
//}

//set<SnibbeInputTreeNode*>
//SnibbeInputTreeNode::allLeafNodes()
//{
//    set<SnibbeInputTreeNode*> output;
//	if ( active_ ) { //  active() inherits from parents
//		if (children_.begin() != children_.end()) {
//			for (set<SnibbeInputTreeNode*>::iterator it = children_.begin(); it != children_.end(); ++it) {
//				set<SnibbeInputTreeNode*> subset = (*it)->allLeafNodes();
//				output.insert(subset.begin(), subset.end());
//			}
//		} else if ( !ignored_ ) {
//			output.insert(this);
//		}
//	}
//    return output;
//}


//
//
void SnibbeInputTreeNode::collectAllNodes( set<SnibbeInputTreeNode*>& outNodes, bool respectIgnoredFlag )
{
    for ( set<SnibbeInputTreeNode*>::iterator it = children_.begin(); it != children_.end(); ++it )
    {
        (*it)->collectAllNodes( outNodes, respectIgnoredFlag );        
    }
    
    if ( !ignored() || !respectIgnoredFlag )
    {
        outNodes.insert( this );
    }
    
}

//
//
void SnibbeInputTreeNode::collectAllLeafNodes( set<SnibbeInputTreeNode*>& outNodes, bool respectIgnoredFlag )
{
    if ( active_ )  //  active() inherits from parents
    {
        for ( set<SnibbeInputTreeNode*>::iterator it = children_.begin(); it != children_.end(); ++it )
        {
            (*it)->collectAllLeafNodes( outNodes );        
        }
        
        if ( children_.size() == 0 && ( !ignored() || !respectIgnoredFlag) )
        {
            outNodes.insert( this );
        }
    }
}

//
// find node recursively by unique id
SnibbeInputTreeNode * SnibbeInputTreeNode::findNode( unsigned int uid )
{
    if ( uniqueID_ == uid )
    {
        return this;
    }
    
    for ( set<SnibbeInputTreeNode*>::iterator it = children_.begin(); it != children_.end(); ++it )
    {
        SnibbeInputTreeNode * pChild = (*it)->findNode( uid );
        if ( pChild )
        {
            return pChild;
        }
    }

    
    return 0;
}

NSArray*
SnibbeInputTreeNode::getPositions()
{
	NSArray* ret = [NSArray array];
	if (children_.begin() != children_.end()) {
		for (set<SnibbeInputTreeNode*>::iterator it = children_.begin(); it != children_.end(); ++it) {
			ret = [ret arrayByAddingObjectsFromArray:(*it)->getPositions()];
			if (!(*it)->ignored()) {
				FPoint pos = (*it)->position();
				CGPoint point = CGPointMake(pos.x, pos.y);
				ret = [ret arrayByAddingObject:[NSValue valueWithCGPoint:point]];
			}
		}
	}
	return ret;	
}

NSArray*
SnibbeInputTreeNode::getVelocities()
{
	NSArray* ret = [NSArray array];
	if (children_.begin() != children_.end()) {
		for (set<SnibbeInputTreeNode*>::iterator it = children_.begin(); it != children_.end(); ++it) {
			ret = [ret arrayByAddingObjectsFromArray:(*it)->getVelocities()];
			if (!(*it)->ignored()) {
				FPoint vel = (*it)->velocity();
				CGPoint point = CGPointMake(vel.x, vel.y);
				ret = [ret arrayByAddingObject:[NSValue valueWithCGPoint:point]];
			}
		}
	}
	return ret;	
}

NSArray*
SnibbeInputTreeNode::getAccelerations()
{
	NSArray* ret = [NSArray array];
	if (children_.begin() != children_.end()) {
		for (set<SnibbeInputTreeNode*>::iterator it = children_.begin(); it != children_.end(); ++it) {
			ret = [ret arrayByAddingObjectsFromArray:(*it)->getAccelerations()];
			if (!(*it)->ignored()) {
				FPoint acc = (*it)->position();
				CGPoint point = CGPointMake(acc.x, acc.y);
				ret = [ret arrayByAddingObject:[NSValue valueWithCGPoint:point]];
			}
		}
	}
	return ret;	
}

bool
SnibbeInputTreeNode::active()
{
	bool output = active_;
	if (parent_) {
		output = output && parent_->active();
	}
	return output;
}

FPoint
SnibbeInputTreeNode::position()
{
	FPoint output = pos_;
	if (parent_) {
		switch (posRelationship_) {
			case SNIBBE_RELATIONSHIP_MULT:
				output *= parent_->position();
				break;
			case SNIBBE_RELATIONSHIP_ADD:
				output += parent_->position();
				break;
			case SNIBBE_RELATIONSHIP_POW:
				FPoint parentPosition = parent_->position();
				output = FPoint(powf(parentPosition.x, output.x), powf(parentPosition.y, output.y));
				break;
		}
	}
	return output;
}


FPoint
SnibbeInputTreeNode::velocity()
{
	FPoint output = vel_;
	if (parent_) {
		switch (posRelationship_) {
			case SNIBBE_RELATIONSHIP_MULT:
				output *= parent_->velocity();
				break;
			case SNIBBE_RELATIONSHIP_ADD:
				output += parent_->velocity();
				break;
			case SNIBBE_RELATIONSHIP_POW:
				FPoint parentVelocity = parent_->velocity();
				output = FPoint(powf(parentVelocity.x, output.x), powf(parentVelocity.y, output.y));
				break;
		}
	}
	return output;
}


FPoint
SnibbeInputTreeNode::acceleration()
{
	FPoint output = acc_;
	if (parent_) {
		switch (posRelationship_) {
			case SNIBBE_RELATIONSHIP_MULT:
				output *= parent_->acceleration();
				break;
			case SNIBBE_RELATIONSHIP_ADD:
				output += parent_->acceleration();
				break;
			case SNIBBE_RELATIONSHIP_POW:
				FPoint parentAcceleration = parent_->acceleration();
				output = FPoint(powf(parentAcceleration.x, output.x), powf(parentAcceleration.y, output.y));
				break;
		}
	}
	return output;
}

float
SnibbeInputTreeNode::strength()
{
	
	float output = strength_;
	if (parent_) {
		switch (strengthRelationship_) {
			case SNIBBE_RELATIONSHIP_MULT:
				output = output * parent_->strength();
				break;
			case SNIBBE_RELATIONSHIP_ADD:
				output = output + parent_->strength();
				break;
			case SNIBBE_RELATIONSHIP_POW:
				output = powf(output, parent_->strength());
				break;
			default:
				break;
		}
	}
	return output;
}

//
//
void
SnibbeInputTreeNode::add(SnibbeInputTreeNode* n)
{
	children_.insert(n);
	n->parent_ = this;
}

//
//
bool SnibbeInputTreeNode::remove(SnibbeInputTreeNode * n)
{
    int iNumRemoved = children_.erase( n );
    if ( iNumRemoved > 0 )
    {
        n->parent_ = nil;
    }
    
    return iNumRemoved == 1;
        
}

//
//
void SnibbeInputTreeNode::removeAll()
{
    for ( set<SnibbeInputTreeNode*>::iterator it = children_.begin(); it != children_.end(); ++it )
    {
        (*it)->parent_ = nil;
    }
    
    children_.clear();
}

//
//
void SnibbeInputTreeNode::acquireUniqueID()
{
    uniqueID_ = nextUniqueID++;
    
    if ( nextUniqueID == 0 )
    {
        nextUniqueID = 1; // 0 is uninit
    }        
        
}