/*
 *  TouchModeManager.h
 *  Tesla
 *
 *  Created by Graham McDermott on 2/18/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 *
 *
 *  class TouchModeManager
 *  ----------------------
 *  TouchModeManager is an input handler who is responsible for accepting input events
 *  and and translating those events into meaningful app state changes.
 *  
 *  There is a concept of a current touch mode which correlates to what is happening with
 *  input at any given moment.
 */

#include "TouchStateMachine.h"
//#include "TouchMode.h"
#include "CCDirector.h"
 
#include <vector>

class TouchMode;
struct Machine;

@class UITouch;
@class UIEvent;



// these are stored naked in STL containers so if we add anything that
// requires a deep copy need to adjust in the code


typedef struct 
{
	void *key;	                 // UID associated with this touch
	NSTimeInterval timeStamp;    // timestamp of the touch 
	CGPoint pointInView;	     // touch coordinates
	CGPoint originalPointInView; // touch coordinates at the original point of contact
	bool movedPastTapThreshold;  // has the touch moved far enough yet to not be considered a tap?
} touchInfoT;


typedef enum
{
	eModeNoTouch = 0,
	eModeTap,
	eMode1Touch,
	eMode2Touch,
	eMode3Touch,
	eMode4Touch,
	eMode5Touch,
	
} TouchModeT;


// c callbacks (until we incoporate proper method callbacks)
void On0TouchEnterExit( bool enterOrExit );	
void On1TouchTapEnterExit( bool enterOrExit );
void On1TouchDrawEnterExit( bool enterOrExit );
void On2TouchEnterExit( bool enterOrExit );
void On3TouchEnterExit( bool enterOrExit );
void On4TouchEnterExit( bool enterOrExit );
void On5TouchEnterExit( bool enterOrExit );


//
//
class TouchModeManager
{
	
public:
	
	TouchModeManager();
	~TouchModeManager();
	
	void Update(float dt);
	
	// touch events are passed on
	
	void touchBegan( UITouch *touch, UIEvent *event );
	void touchMoved( UITouch *touch, UIEvent *event );
	void touchEnded( UITouch *touch, UIEvent *event ); // note - cancelled grouped with ended
	
	void onEndCurMode();
	void onBeginMode( TouchModeT theMode );
	
	void getTouchesAvgPoint( CGPoint& outAvg, NSTimeInterval& outMostRecentTouchTimestamp ) const;
	
	TouchModeT getCurTouchMode() const { return touchMode; } 
	int        getCurNumTouches() const { return trackedTouches.size(); }
	
	// updates are passed on		
	// lightning is created based on touches 	
	// audio is modified based on touches
	
	
	// access the singleton	
	static TouchModeManager& Manager() { return msModeManager; }
	
private:
	
	static TouchModeManager msModeManager;
	
	//bool isTrackingTouch( UITouch * t );
	
	touchInfoT * trackTouch( UITouch *t );
	void stopTrackingTouch( UITouch *t );
	void clearAllTrackedTouches();
	touchInfoT * getTrackedTouchInfo( UITouch * touch, std::vector<touchInfoT *>::iterator * outIter = NULL );
	
	void startTrackingTouchDelay();
	void stopTrackingTouchDelay();

	//void startTrackingTapThreshold();
	//void stopTrackingTapThreshold();
	
	void numTouchesChanged( int iPrevTouches, int iCurTouches );
	void doNumTouchesChanged();	

	CGPoint getTouchPos( UITouch *touch );
	bool distanceIsPastTapThreshold( CGPoint pt1, CGPoint pt2 );
	void updatePositionInTouchInfo( UITouch *touch, touchInfoT *touchInfo, bool bTestTapDist = false );
	
	
	std::vector<touchInfoT *> trackedTouches;
	touchInfoT cachedEndedTrackedTouch;
	
	
	TouchModeT touchMode;
	TouchModeT prevTouchMode;
	
	//TeslaMode *curMode;
	
	
	TouchStateMachine stateMachine;

	bool trackingNumTouchesDelay;
	float timeNumTouchesDelayed;
	
	//bool trackingTapThreshold;
	//float timeTapThreshold;
	
	
		
};