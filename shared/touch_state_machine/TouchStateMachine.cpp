/*
 *  TouchStateMachine.cpp
 *  Tesla
 *
 *  Created by Graham McDermott on 2/20/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */

#include "TouchStateMachine.h"


#include <boost/statechart/state_machine.hpp>
#include <boost/statechart/simple_state.hpp>
#include <boost/statechart/state.hpp>
#include <boost/mpl/list.hpp>
#include <boost/statechart/transition.hpp>


namespace sc = boost::statechart;
namespace mpl = boost::mpl;

#define DEBUG_PRINT_STATES 0


void debugPrint( const char *str )
{
#if DEBUG_PRINT_STATES
	printf( "%s", str);
#endif
}

///////////////////////////////////////////////////////////////////////////////
// StateMachineImpl
///////////////////////////////////////////////////////////////////////////////



// define boost state machine components

// forward declarations
struct Touch0;
struct Touch1Unresolved;
struct Touch1Draw;
struct Touch1Tap;
struct Touch2;
struct Touch3;
struct Touch4;
struct Touch5;

// the state machine
struct StateMachineImpl : 
sc::state_machine< StateMachineImpl, Touch0 > 
{
	StateMachineImpl( TouchStateMachine * sm) {touchStateMachine = sm;}
	~StateMachineImpl() {}
	
	TouchStateMachine *touchStateMachine;
};



// events
struct Ev0Touches : sc::event< Ev0Touches > {};
struct Ev1Touch : sc::event< Ev1Touch > {};
struct Ev2Touches : sc::event< Ev2Touches > {};
struct Ev3Touches : sc::event< Ev3Touches > {};
struct Ev4Touches : sc::event< Ev4Touches > {};
struct Ev5Touches : sc::event< Ev5Touches > {};
struct EvMovedPastTapDistThreshold : sc::event< EvMovedPastTapDistThreshold > {};

//struct EvTapTimeThresholdPassed : sc::event< EvTapTimeThresholdPassed > {};

// states

struct Touch0 : sc::state< Touch0, StateMachineImpl > 
{
	// rections (transitions)
	typedef mpl::list<
	sc::transition< Ev1Touch, Touch1Unresolved >,
	sc::transition< Ev2Touches, Touch2 >,
	sc::transition< Ev3Touches, Touch3 >,
	sc::transition< Ev4Touches, Touch4 >,
	sc::transition< Ev5Touches, Touch5> > reactions;
	
	Touch0( my_context ctx ) : my_base( ctx )
	{
		outermost_context().touchStateMachine->On0TouchCB( CB_STATE_ENTER );
		debugPrint( "touch 0 enter\n" );
	}
	
	~Touch0() 
	{
		outermost_context().touchStateMachine->On0TouchCB( CB_STATE_EXIT );
		debugPrint( "touch 0 exit\n" );
	}
};


struct Touch1Unresolved : sc::state< Touch1Unresolved, StateMachineImpl > 
{
	
	// rections (transitions)
	typedef mpl::list<
	//sc::transition< EvTapTimeThresholdPassed, Touch1Draw >,
	sc::transition< Ev0Touches, Touch1Tap >,
	sc::transition< EvMovedPastTapDistThreshold, Touch1Draw >,
	//sc::transition< Ev1Touch, Touch1Draw >,
	sc::transition< Ev2Touches, Touch2 >,
	sc::transition< Ev3Touches, Touch3 >,
	sc::transition< Ev4Touches, Touch4 >,
	sc::transition< Ev5Touches, Touch5> > reactions;
	
	Touch1Unresolved( my_context ctx ) : my_base( ctx )
	{		
		debugPrint( "touch 1 unresolved enter\n" );
	}
	
	~Touch1Unresolved() 
	{
		debugPrint( "touch 1 unresolved exit\n" );
	}
	
};


struct Touch1Tap : sc::state< Touch1Tap, StateMachineImpl > 
{
	// rections (transitions)
	typedef mpl::list<
	sc::transition< Ev0Touches, Touch0 >,
	sc::transition< Ev1Touch, Touch1Unresolved >,
	sc::transition< Ev2Touches, Touch2 >,
	sc::transition< Ev3Touches, Touch3 >,
	sc::transition< Ev4Touches, Touch4 >,
	sc::transition< Ev5Touches, Touch5> > reactions;
	
	
	Touch1Tap( my_context ctx ) : my_base( ctx )
	{
		outermost_context().touchStateMachine->On1TouchTapCB( CB_STATE_ENTER );
		debugPrint( "touch 1 tap enter\n" );
		
		post_event( Ev0Touches() );
	}
	
	~Touch1Tap() 
	{
		outermost_context().touchStateMachine->On1TouchTapCB( CB_STATE_EXIT );
		debugPrint( "touch 1 tap exit\n" );
	}
	
	
	// todo - need to transition this to Ev0Touches automatically
};


struct Touch1Draw : sc::state< Touch1Draw, StateMachineImpl > 
{
	// rections (transitions)
	typedef mpl::list<
	sc::transition< Ev0Touches, Touch0 >,
	sc::transition< Ev2Touches, Touch2 >,
	sc::transition< Ev3Touches, Touch3 >,
	sc::transition< Ev4Touches, Touch4 >,
	sc::transition< Ev5Touches, Touch5> > reactions;
	
	Touch1Draw( my_context ctx ) : my_base( ctx ) 
	{
		outermost_context().touchStateMachine->On1TouchDrawCB( CB_STATE_ENTER );
		debugPrint( "touch 1 draw enter\n" );
	}
	
	~Touch1Draw() 
	{
		outermost_context().touchStateMachine->On1TouchDrawCB( CB_STATE_EXIT );
		debugPrint( "touch 1 draw exit\n" );
	}
};

struct Touch2 : sc::state< Touch2, StateMachineImpl > 
{
	// rections (transitions)
	typedef mpl::list<
	sc::transition< Ev0Touches, Touch0 >,
	sc::transition< Ev1Touch, Touch1Draw >,
	sc::transition< Ev3Touches, Touch3 >,
	sc::transition< Ev4Touches, Touch4 >,
	sc::transition< Ev5Touches, Touch5> > reactions;
	
	Touch2( my_context ctx ) : my_base( ctx ) 
	{
		outermost_context().touchStateMachine->On2TouchCB( CB_STATE_ENTER );
		debugPrint( "touch 2 enter\n" );
	}
	
	~Touch2() 
	{
		outermost_context().touchStateMachine->On2TouchCB( CB_STATE_EXIT );
		debugPrint( "touch 2 exit\n" );
	}
};

struct Touch3 : sc::state< Touch3, StateMachineImpl > 
{
	// rections (transitions)
	typedef mpl::list<
	sc::transition< Ev0Touches, Touch0 >,
	sc::transition< Ev1Touch, Touch1Draw >,
	sc::transition< Ev2Touches, Touch2 >,
	sc::transition< Ev4Touches, Touch4 >,
	sc::transition< Ev5Touches, Touch5> > reactions;
	
	Touch3( my_context ctx ) : my_base( ctx ) 
	{
		outermost_context().touchStateMachine->On3TouchCB( CB_STATE_ENTER );
		debugPrint( "touch 3 enter\n" );
	}
	
	~Touch3() 
	{
		outermost_context().touchStateMachine->On3TouchCB( CB_STATE_EXIT );
		debugPrint( "touch 3 exit\n" );
	}
	
};


struct Touch4 : sc::state< Touch4, StateMachineImpl > 
{
	// rections (transitions)
	typedef mpl::list<
	sc::transition< Ev0Touches, Touch0 >,
	sc::transition< Ev1Touch, Touch1Draw >,
	sc::transition< Ev2Touches, Touch2 >,
	sc::transition< Ev3Touches, Touch3 >,
	sc::transition< Ev5Touches, Touch5> > reactions;
	
	Touch4( my_context ctx ) : my_base( ctx ) 
	{
		outermost_context().touchStateMachine->On4TouchCB( CB_STATE_ENTER );
		debugPrint( "touch 4 enter\n" );
	}
	
	~Touch4() 
	{
		outermost_context().touchStateMachine->On4TouchCB( CB_STATE_EXIT );
		debugPrint( "touch 4 exit\n" );
	}
	
};



struct Touch5 : sc::state< Touch5, StateMachineImpl > 
{
	// rections (transitions)
	typedef mpl::list<
	sc::transition< Ev0Touches, Touch0 >,
	sc::transition< Ev1Touch, Touch1Draw >,
	sc::transition< Ev2Touches, Touch2 >,
	sc::transition< Ev3Touches, Touch3 >,
	sc::transition< Ev4Touches, Touch4 > > reactions;
	
	Touch5( my_context ctx ) : my_base( ctx ) 
	{
		outermost_context().touchStateMachine->On5TouchCB( CB_STATE_ENTER );
		debugPrint( "touch 5 enter\n" );
	}
	
	~Touch5() 
	{
		outermost_context().touchStateMachine->On5TouchCB( CB_STATE_EXIT );
		debugPrint( "touch 5 exit\n" );
	}
	
};


// todo - define sub states for multi if needed
//struct Touch3 : sc::simple_state< Touch3, TouchMulti > {};
//struct Touch4 : sc::simple_state< Touch4, TouchMulti > {};
//struct Touch5 : sc::simple_state< Touch5, TouchMulti > {};



///////////////////////////////////////////////////////////////////////////////
// TouchStateMachine
///////////////////////////////////////////////////////////////////////////////

//
//
TouchStateMachine::TouchStateMachine()
{
	
	cbEnterExit0Touches = cbEnterExit1TouchTap = cbEnterExit1TouchDraw = cbEnterExit2Touch = cbEnterExit3Touch = cbEnterExit4Touch = cbEnterExit5Touch = 0;	
	
	machine = new StateMachineImpl( this );
	machine->initiate();
}


//
//
TouchStateMachine::~TouchStateMachine()
{
	if ( machine )
	{
		delete machine;
	}
}

//
// The number of touches currently active has changed
void TouchStateMachine::OnNumTouchesChanged( int iCurTouches )
{
	switch (iCurTouches) {
		case 1:
		{
			machine->process_event( Ev1Touch() );
			break;
		}
		case 2:
		{
			machine->process_event( Ev2Touches() );
			break;
		}
		case 3:
		{
			machine->process_event( Ev3Touches() );
			break;
		}
		case 4:
		{
			machine->process_event( Ev4Touches() );
			break;
		}
		case 5:
		{
			machine->process_event( Ev5Touches() );
			break;
		}
		case 0:
		default:
		{
			machine->process_event( Ev0Touches() );
			break;
		}
			
	}
	
	
	
}


//
// a single touch has moved beyond the distance thredhold that constitutes a tap
void TouchStateMachine::OnMovedPastTapDistanceThreshold()
{
	machine->process_event( EvMovedPastTapDistThreshold() );	
}


// The time since the last change in number of touches has exceeded the
// threshold to count it as a tap
//void TouchStateMachine::OnTapTimeThresholdPassed()
//{
//	machine->process_event( EvTapTimeThresholdPassed() );
//}
