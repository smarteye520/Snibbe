//
//  MPNetworkManager.h
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//
//
//  class MPNetworkManager
//  ----------------------------------------
//  This class is a singleton that currently serves dual roles
//  
//  1. handling network setup and communication of data
//  2. implementing multiplayer roles based on the network data
//
//  The multiplayer aspect of the game is so simple that it's just handled
//  here with the networking code.  If it ever becomes more complex it can
//  be broken out into its own class.
//
//  The UI aspects of multiplayer are primarily handled by GameKit but there is 
//  a small amount of UIKit integration involved.  Rather than 
//
//
// data flow:
// ----------
// - 1 player is server, all others are clients
// - actions are performed by all parties (brush strokes, clear, undo, etc)
// - server's job is to function as central entity that coordinates action
//   order among all players
// - when clients perform actions:
//   - they report them to the server
//   - the server places them in a queue with all other players actions (other
//     coordination such as brush stroke z-order coordination is also performed)
//   - periodically the queue is send back from the server to all players so they can reflect
//     each players actions in their local representation
//   -
///////////////////////////////////////////////////////////



#ifndef MotionPhone_MPNetworkManager_h
#define MotionPhone_MPNetworkManager_h


#define UNINIT_PLAYER_ID 0
//#define CLIENT_DATA_SEND_INTERVAL 222.5f
#define SERVER_DATA_SEND_INTERVAL 0.01f
#define SERVER_DATA_Z_ORDER_UPDATE_INTERVAL 1.0f
#define NUM_LOCAL_ACTIONS_FORCE_UPDATE 60

#define NETWORKING_DATA_VERSION 1

#import <GameKit/GameKit.h>
#import "MPProtocols.h"
#import "defs.h"
#import <vector>

// networking packet IDs
enum
{
    ePacketClientToServerActions = 1,       // client reporting new actions to server
    ePacketServerToClientResolvedActions,   // server sending "blessed" actions to all clients
    ePacketServerToClientUpdateZOrder,      // server instructing all clients to update their baseline brush z order
};

typedef enum 
{
    eMPUnresolved = 0,
    eMPClient,
    eMPServer
} MPNetworkRoleT;

typedef enum
{
    eMPRoleUndefined = 0,
    eMPRoleDefined,
    eMPRolePendingRedefinition,
} MPRoleStatusT;

//typedef enum
//{
//    eStatusDisconnected = 0,
//    eStatusConnected
//    
//} MPNetworkingStatusT;

typedef enum
{
    eMatchNotStarted = 0,
    eMatchStartPending,
    eMatchStarted
} MPMatchStatusT;

typedef enum
{
    eStatusPlayerNotAuthenticated = 0,
    eStatusPlayerAuthenticating,
    eStatusPlayerAuthenticated,
    
} MPAuthenticationStatusT;

typedef enum
{
    eMPLowSpeed = 0,
    eMPHighSpeed,
} MPConnectionSpeedT;


#if USE_GAMECENTER
@interface MPNetworkManager : NSObject< GKMatchDelegate, MPMatchMakerUIDelegate >
#else
@interface MPNetworkManager : NSObject< GKSessionDelegate, MPMatchMakerUIDelegate >
#endif

{
    
    MPNetworkRoleT          playerRole_;
    MPAuthenticationStatusT appAuthenticationStatus_;
    //MPNetworkingStatusT     appNetworkingStatus_;
    MPMatchStatusT          appMatchStatus_;
    
    bool           gameKitAvailable_;

    
    
    NSString *      serverPlayerID_; // the player id of the current server
    NSString *      localPlayerID_;
    NSUInteger      localPlayerIDHash_;   // integer representation of the local player's player ID
    

#if USE_GAMECENTER
    GKMatch *       match_;
#else
    GKSession *     session_;
#endif
    
    
    NSMutableArray  *allClients_;    // array of client player ids (all players minus server)
    NSMutableArray  *serverArray_;   // array containing only the server id

#if USE_GAMECENTER
    NSMutableArray  *allPlayers_;    // array of GKPlayer objects for the current match (if using GameCenter)
#else
    NSMutableArray *allPeers_;       // array of NSString * player ids for the current session (if using GameKit p2p) including local player
#endif
    
    NSMutableSet    *clientsRecognizingNewServer_; // tracks 
    
    NSMutableArray  *arrayPendingData_;      // network data received before we've started our session officially
    NSMutableArray  *arrayPendingPlayerIDs_; // player ids for network data received before we've started our session officially
    
    
    double         lastNetworkSpeedUpdateTime_;
    double         lastClientToServerUpdateTime_;
    double         lastServerToClientsUpdateTime_;

    double         lastServerZOrderUpdateTime_;
    unsigned int   lastServerZOrderUpdateSent_;
    
    double         lastUpdateTime_;
    bool           flushLocalActions_;
    
    MPRoleStatusT  roleStatus_;
                
    MPConnectionSpeedT connectionSpeed_;
    bool               delaySendingData_;
    
}

+ (void) startup;
+ (void) shutdown;

+ (MPNetworkManager *) man;
+ (bool) gameKitAvailable;


@property (nonatomic) NSUInteger localPlayerIDHash_;
@property (nonatomic) MPNetworkRoleT playerRole_;
@property (nonatomic) MPAuthenticationStatusT appAuthenticationStatus_;
//@property (nonatomic) MPNetworkingStatusT appNetworkingStatus_;
@property (nonatomic) MPMatchStatusT appMatchStatus_;

#if USE_GAMECENTER
@property (retain) GKMatch *match_;
#else
@property (retain) GKSession *session_;
#endif



- (void) reset;
- (void) update: (double) curTime;
- (void) onMultiplayerInit;
- (void) disconnectFromMatch: (bool) propagateToOthers;
- (void) onPlayerDisconnected: (unsigned int) playerIDHash;

- (int)  numPlayersInMatch;
- (NSString *) playerAlias: (int) iIndex;

- (bool) multiplayerSessionActive;
- (bool) multiplayerSessionPending;

- (void) onAppDidEnterBackground;
- (void) collectPeerIDHashValues: (std::vector<unsigned int> *) outIDs;
- (void) onBrushActionSequenceBegin;

- (void) flushLocalActions;

// messages sent from other players
//- (void) onNewServerIdentified: (NSUInteger) playerIDHash;
//- (void) onClientRecognizesNewServer: (NSUInteger) playerIDHash;
//- (void) onNewServerReady: (NSUInteger) playerIDHash;


// todo - add gamekit code here w/ delegate functionality?

@end




#endif
