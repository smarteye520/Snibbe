//
//  MPActionQueue.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//
//  class MPActionQueue
//  -------------------
//  A queue of app actions encoded as concrete subclasses to MPAction.
//
//  Usage: primarily to represent data for network communications.
// 
//  - Each player has an send action queue that becomes filled during a window of time
//  - at regular intervals, the queue is converted to NSData and sent to the server player (could be self)
//  - the server player receives the actions and decodes the NSData back to MPAction objects, performing
//    any necessary processing to resolve issues of order or other conflicts among the actions
//  - the server reencodes the resolved action queue (which now may contain actions of multiple players) 
//    back to NSData and sends copies to each client
//  - the clients receive the resolved server queue, decode it back into a resolved MPActionQueue and process
//    each action in turn, updating the appropriate player's (or the global) state

#ifndef MotionPhone_MPActionQueue_h
#define MotionPhone_MPActionQueue_h

#include "defs.h" 
#include <vector>

class MPAction;

class MPActionQueue
{
    
public:
    
    MPActionQueue();
    ~MPActionQueue();
    
    MPAction * queueAction( int playerID, MPActionT actionType );
    
    int toData( unsigned char * outData, unsigned int& outDataSpaceRemaining, int maxActions = -1 );
    unsigned int fromData( unsigned char * pData, int iNetworkDataVersion ); 
    
    void clear();
    void clearNumActions( int iNumActions );
    int transferActionsToQueue( MPActionQueue& dest, int maxActions = -1 );
    
    void performActions( bool bCheckCanPerform, bool bClearPerformed );
    void debugOut();

    int  numActions() const { return actions_.size(); }
    MPAction * actionAtIndex( int iIndex );
    
    static void clearAll();
    
    static MPActionQueue& getLocalWorkingQueue();
    static MPActionQueue& getServerWorkingQueue();
    static MPActionQueue& getServerTransferQueue();
    static MPActionQueue& getResolvedQueue();
    
private:
    
    void performDeleteAtIndex( int i );
    
    static MPActionQueue localWorkingQueue;
    static MPActionQueue serverWorkingQueue;
    static MPActionQueue serverTransferQueue;
    static MPActionQueue resolvedQueue;  
    
    static MPAction * constructAction( MPActionT actionType, bool useLocalPlayerIDHash = true );
    
    // player identification
    
    
    // todo - optimize the storage / allocation of actions later.
    // we likely don't have to pop actions off the front like an actual
    // queue so we can use a vector here for simplicity
    std::vector<MPAction *> actions_;
};


#endif
