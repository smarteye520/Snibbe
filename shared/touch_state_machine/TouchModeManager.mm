/*
 *  TouchModeManager.mm
 *  Tesla
 *
 *  Created by Graham McDermott on 2/18/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */

#import "TouchModeManager.h"
//#import "TeslaMode.h"
//#import "TeslaModeNoTouch.h"
//#import "TeslaModeTap.h"
//#import "TeslaMode1Touch.h"
//#import "TeslaMode2Touch.h"
//#import "TeslaMode3Touch.h"
//#import "TeslaMode4Touch.h"
//#import "TeslaMode5Touch.h"
#include "CGPointExtension.h"


// the min length of time that changes in number of touches are queued up before processing
// so that we don't run through unnecessary intermediate states
#define TOUCH_BUFFER_MIN_SECONDS 0.08f

#define TAP_DISTANCE_THRESHOLD 10.0f

//#include "TeslaSceneDefs.h"

// statics
TouchModeManager TouchModeManager::msModeManager;


///////////////////////////////////////////////////////////////////////////////
// c callbacks
///////////////////////////////////////////////////////////////////////////////

// these just translate c callbacks from the state machine implementation into
// calls to the static mode manager

void OnTouchEnterExitGeneral( bool enterOrExit, TouchModeT mode )
{
	if ( !enterOrExit )
	{
		TouchModeManager::Manager().onEndCurMode();
	}
	else 
	{
		TouchModeManager::Manager().onBeginMode(mode);
	}
	
}


void On0TouchEnterExit( bool enterOrExit )
{
	OnTouchEnterExitGeneral( enterOrExit, eModeNoTouch );	
}

void On1TouchTapEnterExit( bool enterOrExit )
{
	OnTouchEnterExitGeneral( enterOrExit, eModeTap );	
}

void On1TouchDrawEnterExit( bool enterOrExit )
{
	OnTouchEnterExitGeneral( enterOrExit, eMode1Touch );	
}

void On2TouchEnterExit( bool enterOrExit )
{
	OnTouchEnterExitGeneral( enterOrExit, eMode2Touch );	
}

void On3TouchEnterExit( bool enterOrExit )
{
	OnTouchEnterExitGeneral( enterOrExit, eMode3Touch );	
}

void On4TouchEnterExit( bool enterOrExit )
{
	OnTouchEnterExitGeneral( enterOrExit, eMode4Touch );	
}

void On5TouchEnterExit( bool enterOrExit )
{
	OnTouchEnterExitGeneral( enterOrExit, eMode5Touch );	
}

///////////////////////////////////////////////////////////////////////////////
// TouchModeManager
///////////////////////////////////////////////////////////////////////////////

//
//
TouchModeManager::TouchModeManager()
{
	//touchMode = eModeNoTouch;
	
	
	//curMode = NULL;
	
	touchMode = prevTouchMode = eModeNoTouch;

	// set up the callbacks so the state machine can let us know about important events
	stateMachine.Set0TouchCB( &On0TouchEnterExit );
	stateMachine.Set1TouchTapCB( &On1TouchTapEnterExit );
	stateMachine.Set1TouchDrawCB( &On1TouchDrawEnterExit );
	stateMachine.Set2TouchCB( &On2TouchEnterExit );
	stateMachine.Set3TouchCB( &On3TouchEnterExit );
	stateMachine.Set4TouchCB( &On4TouchEnterExit );
	stateMachine.Set5TouchCB( &On5TouchEnterExit );
}

//
//
TouchModeManager::~TouchModeManager()
{
	
//	if ( curMode )
//	{
//		delete curMode;
//	}

	clearAllTrackedTouches();
}


//
//
void TouchModeManager::Update(float dt)
{
	// Here we check for whether certain time thresholds have passed that
	// signify interesting events.
	
	// The timing here isn't totally accurate since we begin counting somewhere in the middle of a frame, but
	// if it's crucial we can change it to be more accurate.
	
	
	// we're cancelling the specific handling of tap delay since it can be rolled into the general delay
	// handling with the help of the special-case code for 0->1 and 1->0 immediate handling
	
//	if ( trackingTapThreshold )
//	{
//		timeTapThreshold += dt;
//		
//		if ( timeTapThreshold >= TESLA_TAP_SECONDS_THRESHOLD )
//		{
//			//stateMachine.OnTapTimeThresholdPassed();
//
//			startTrackingTouchDelay();
//			stopTrackingTapThreshold();
//		}
//				
//	}
	
	
	if ( trackingNumTouchesDelay )
	{
		timeNumTouchesDelayed += dt;
		
		if ( timeNumTouchesDelayed >= TOUCH_BUFFER_MIN_SECONDS )
		{
			doNumTouchesChanged(); // should reflect whatever the current state is now rather than the intermediate states we've passed through
			
			stopTrackingTouchDelay();
			
		}
	}
}

//
// A touch begins - this should either transition us to a new mode (1 touch -> 2 touch)
// or modify the state of the mode we're in (4 touch -> 5 touch).
// We might want to factor in some sort of delay so that we don't 
// create weird artifacts by creating intermediate modes (e.g. going from
// zero touch -> 1 touch mode -> 2 touch mode instead of directly to 2 touch 
void TouchModeManager::touchBegan( UITouch *touch, UIEvent *event )
{

	
	if ( touch )
	{
	
		
		
		if ( !getTrackedTouchInfo(touch) )
		{
			trackTouch(touch);
			
			//NSLog(@"Mode manager: touch began");
		}
	
		
	
	}
	
	

	
}

//
// An existing touch has moved.  This should modify the state of the current mode we're in.
void TouchModeManager::touchMoved( UITouch *touch, UIEvent *event )
{
	
	
	if ( trackingNumTouchesDelay )
	{
		// here we're actually not wanting to process this
		return;
	}
	
	// we're testing for the tap distance threshold here 
	touchInfoT *touchInfo = getTrackedTouchInfo(touch);
	if ( touchInfo )
	{
		bool bPrevMovedPast = touchInfo->movedPastTapThreshold;
		
		updatePositionInTouchInfo( touch, touchInfo, true );
						
		if ( touchInfo->movedPastTapThreshold && !bPrevMovedPast )
		{
			stateMachine.OnMovedPastTapDistanceThreshold();
		}
		
	}
	
	
//	if ( curMode && touchInfo )
//	{											
//		curMode->touchMoved( touchInfo );					
//	}
	
}

//
// A touch has ended.  This should either modify the state of the mode we're in (5 touch -> 4 touch)
// or cause a shift of modes altogether (2 touch -> 1 touch)  
void TouchModeManager::touchEnded( UITouch *touch, UIEvent *event )
{
	
	if ( touch )
	{
				
		if ( getTrackedTouchInfo(touch) )
		{
			stopTrackingTouch(touch);
		}
		
	}
	
	//NSLog(@"Mode manager: touch ended");
	
	
}



// The current input mode has ended.  We need to ditch our mode
// object.  Depending on the more comprehensive plan for the app, the effects
// of the mode may live on (lightning and audio continuing for example)
void TouchModeManager::onEndCurMode()
{
//	if ( curMode )
//	{
//		curMode->onModeEnd();
//		
//		delete curMode;
//		curMode = 0;
//	}
	
	
}

void TouchModeManager::onBeginMode( TouchModeT theMode )
{
	
//	if ( curMode )
//	{
//		onEndCurMode();
//	}
	
	prevTouchMode = touchMode;
	
	switch (theMode) 
	{
		case eModeNoTouch:
		{
			
			//curMode = new TeslaModeNoTouch();
			break;
		}
		case eModeTap:
		{
			
			// special case for tap - since touch is no longer active, use the cached version
			//curMode = new TeslaModeTap( &cachedEndedTrackedTouch );							
			break;
		}
		case eMode1Touch:
		{
			
			if ( trackedTouches.size() > 0 )
			{	
				if ( prevTouchMode != eModeNoTouch )
				{
					// special case so that we use the original touch point only when drawing from
					// scratch
					trackedTouches[0]->originalPointInView = trackedTouches[0]->pointInView;
				}
				
				//curMode = new TeslaMode1Touch( trackedTouches[0] );
			}		
			break;					
		}
			
		case eMode2Touch:
		{
			if (trackedTouches.size() > 1 )
			{
				//curMode = new TeslaMode2Touch( trackedTouches[0], trackedTouches[1] );

			}
			break;
		}
			
		case eMode3Touch:
		{
			if (trackedTouches.size() > 2 )
			{
				//curMode = new TeslaMode3Touch( trackedTouches[0], trackedTouches[1], trackedTouches[2] );				
			}
			break;
		}
		case eMode4Touch:
		{
			if (trackedTouches.size() > 3 )
			{
				//curMode = new TeslaMode4Touch( trackedTouches[0], trackedTouches[1], trackedTouches[2], trackedTouches[3] );				
			}
			break;
		}
		case eMode5Touch:
		{
			if (trackedTouches.size() > 4 )
			{
				//curMode = new TeslaMode5Touch( trackedTouches[0], trackedTouches[1], trackedTouches[2], trackedTouches[3], trackedTouches[4] );				
			}
			break;
		}
	

			
		default:
			break;
	}
	
	touchMode = theMode;
}


//
//
void TouchModeManager::getTouchesAvgPoint( CGPoint& outAvg, NSTimeInterval& outMostRecentTouchTimestamp ) const
{

	outAvg = CGPointZero;
	outMostRecentTouchTimestamp = 0;
	
	unsigned int iSize = trackedTouches.size();
	if ( iSize > 0 )
	{
		
		for( unsigned int i = 0; i < iSize; ++i )
		{
			outAvg.x += trackedTouches[i]->pointInView.x;
			outAvg.y += trackedTouches[i]->pointInView.y;
			
			if ( trackedTouches[i]->timeStamp > outMostRecentTouchTimestamp )
			{
				outMostRecentTouchTimestamp = trackedTouches[i]->timeStamp;
			}
		}

		outAvg.x /= iSize;
		outAvg.y /= iSize;

	}
	
}

//
//
touchInfoT *  TouchModeManager::trackTouch( UITouch *t )
{
	if ( !getTrackedTouchInfo(t) )
	{
		int iPrevNumTouches = trackedTouches.size();
		
		
		touchInfoT *newTI = new touchInfoT;
		newTI->key = t;
		newTI->timeStamp = t.timestamp;
		
        
        
		updatePositionInTouchInfo( t, newTI, false );		
		newTI->originalPointInView = newTI->pointInView;
				
        //NSLog( @"touch x: %f\ty: %f\n", newTI->pointInView.x, newTI->pointInView.y );
        
		trackedTouches.push_back( newTI );		
		numTouchesChanged( iPrevNumTouches, trackedTouches.size() );		
		
		newTI->movedPastTapThreshold = false;
		
		return newTI;
	}
	
	return NULL;
}

//
//
void TouchModeManager::stopTrackingTouch( UITouch *t )
{
	
	
	int iPrevNumTouches = trackedTouches.size();

	std::vector<touchInfoT *>::iterator itFound;
	if ( getTrackedTouchInfo(t, &itFound) )
	{
		// cache off the values - these are helpful for tap events (touch no longer active by the time
		// we detect it
		cachedEndedTrackedTouch = **itFound;
		
		delete *itFound;
		trackedTouches.erase( itFound );
		
		numTouchesChanged( iPrevNumTouches, trackedTouches.size() );
	}
	
		
	
}

//
//
void TouchModeManager::clearAllTrackedTouches()
{
	std::vector<touchInfoT *>::iterator it;
	for (it = trackedTouches.begin(); it != trackedTouches.end(); ++it )
	{
		if ( (*it) )
		{
			delete (*it);
		}
	}
	
	trackedTouches.clear();
}

touchInfoT * TouchModeManager::getTrackedTouchInfo( UITouch * touch, std::vector<touchInfoT *>::iterator * outIter )
{
	if ( !touch )
	{
		return NULL;
	}
	
	for ( std::vector<touchInfoT *>::iterator it = trackedTouches.begin(); it != trackedTouches.end(); ++it )
	{
		if ( (*it)->key == touch )
		{
			if ( outIter )
			{
				*outIter = it;
			}
			
			return (*it);						
		}
	}	
	
	return NULL;
}

//
//
void TouchModeManager::startTrackingTouchDelay()
{
	if ( !trackingNumTouchesDelay )
	{
		trackingNumTouchesDelay = true;
		timeNumTouchesDelayed = 0.0f;
	}
}

//
//
void TouchModeManager::stopTrackingTouchDelay()
{
	trackingNumTouchesDelay = false;
	timeNumTouchesDelayed = 0.0f;
}

//
//
//void TouchModeManager::startTrackingTapThreshold()
//{
//	timeTapThreshold = 0.0f;
//	trackingTapThreshold = true;
//}
//
//
//
//void TouchModeManager::stopTrackingTapThreshold()
//{
//	trackingTapThreshold = false;
//	timeTapThreshold = 0.0f;
//
//}

//
//
void TouchModeManager::numTouchesChanged( int iPrevTouches, int iCurTouches )
{
	
	// little special case logic to handle taps and intermediate
	// transitions in an expected way
	
	if ( iPrevTouches == 0 && iCurTouches == 1 || 
		 iPrevTouches == 1 && iCurTouches == 0 )
	{
		// process this right away - it could be a tap
		doNumTouchesChanged();
		
		if ( iPrevTouches == 0 && iCurTouches == 1 )
		{
			// in this case we also begin the normal touch delay as well... the first
			// touches changed should ˆave put us into the unresolved 1 touch category, 
			// and this will take us to the appropriate place after a short delay
			startTrackingTouchDelay();
		}
	}
	else
	{
		// otherwise we're going to wait so we can skip intermediate steps
		startTrackingTouchDelay();
	}
	
}

//
// actually inform the state machine about the current number of touches
void TouchModeManager::doNumTouchesChanged()
{
	int iNumCurTouches = trackedTouches.size();
	stateMachine.OnNumTouchesChanged( iNumCurTouches );
	
	//startTrackingTapThreshold();
	
}

//
//
CGPoint TouchModeManager::getTouchPos( UITouch *touch )
{
	if ( touch )
	{
		CGPoint touchPoint = [touch locationInView:[touch view]];
		touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
		return touchPoint;
	}
	
	return CGPointZero;
}

//
//
bool TouchModeManager::distanceIsPastTapThreshold( CGPoint pt1, CGPoint pt2 )
{
	return ( ccpDistance(pt1, pt2) > TAP_DISTANCE_THRESHOLD );
	
}

//
//
void TouchModeManager::updatePositionInTouchInfo( UITouch *touch, touchInfoT *touchInfo, bool bTestTapDist )
{
	if ( touch && touchInfo )
	{				
		touchInfo->pointInView = getTouchPos( touch );		
		
		if ( bTestTapDist )
		{
			touchInfo->movedPastTapThreshold = distanceIsPastTapThreshold(touchInfo->originalPointInView, touchInfo->pointInView);					
		}
	}
}

