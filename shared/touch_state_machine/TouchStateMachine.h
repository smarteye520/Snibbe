/*
 *  TouchStateMachine.h
 *  Tesla
 *
 *  Created by Graham McDermott on 2/20/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 *  class TouchStateMachine
 *  -----------------------
 *  Wrapper API for input state machine
 */

#include <boost/function.hpp>

#define CB_STATE_ENTER 1
#define CB_STATE_EXIT 0


typedef void (*StateMachCallbackT) (bool);


struct StateMachineImpl;

class TouchStateMachine
{
	
public:
	
	TouchStateMachine();
	~TouchStateMachine();
	
	void OnNumTouchesChanged( int iCurTouches );
	void OnMovedPastTapDistanceThreshold();
	
	//void OnTapTimeThresholdPassed();	
	
	void Set0TouchCB( StateMachCallbackT cb ) { cbEnterExit0Touches = cb; }
	void Set1TouchTapCB( StateMachCallbackT cb ) { cbEnterExit1TouchTap = cb; }
	void Set1TouchDrawCB( StateMachCallbackT cb ) { cbEnterExit1TouchDraw = cb; }
	void Set2TouchCB( StateMachCallbackT cb ) { cbEnterExit2Touch = cb; }
	void Set3TouchCB( StateMachCallbackT cb ) { cbEnterExit3Touch = cb; }
	void Set4TouchCB( StateMachCallbackT cb ) { cbEnterExit4Touch = cb; }
	void Set5TouchCB( StateMachCallbackT cb ) { cbEnterExit5Touch = cb; }
	
	void On0TouchCB( bool enterOrExit ) { if ( cbEnterExit0Touches ) cbEnterExit0Touches(enterOrExit); }	
	void On1TouchTapCB( bool enterOrExit ) { if ( cbEnterExit1TouchTap ) cbEnterExit1TouchTap(enterOrExit); }
	void On1TouchDrawCB( bool enterOrExit ) { if ( cbEnterExit1TouchDraw ) cbEnterExit1TouchDraw(enterOrExit); }
	void On2TouchCB( bool enterOrExit ) { if ( cbEnterExit2Touch ) cbEnterExit2Touch(enterOrExit); }
	void On3TouchCB( bool enterOrExit ) { if ( cbEnterExit3Touch ) cbEnterExit3Touch(enterOrExit); }
	void On4TouchCB( bool enterOrExit ) { if ( cbEnterExit4Touch ) cbEnterExit4Touch(enterOrExit); }
	void On5TouchCB( bool enterOrExit ) { if ( cbEnterExit5Touch) cbEnterExit5Touch(enterOrExit); }
	
	
private:
	
	StateMachCallbackT cbEnterExit0Touches;
	StateMachCallbackT cbEnterExit1TouchTap;
	StateMachCallbackT cbEnterExit1TouchDraw;	
	StateMachCallbackT cbEnterExit2Touch;
	StateMachCallbackT cbEnterExit3Touch;
	StateMachCallbackT cbEnterExit4Touch;
	StateMachCallbackT cbEnterExit5Touch;
	
	StateMachineImpl *machine;
	
	
};