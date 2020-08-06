//
//  MPNetworkManager.mm
//  MotionPhone
//
//  Created by Graham McDermott on 10/19/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//


#include "MPNetworkManager.h"
#include "MPActionQueue.h"
#include "SnibbeUtils.h"
#include "MPAction.h"
#include "MPActionBrush.h"
#include "mcanvas.h"
#include "MPUIKitViewController.h"
#include "FlurryAnalytics.h"
#include "MPActionMessage.h"
//#import  "Reachability.h"
#import  "MTouchTracker.h"

static MPNetworkManager * theMan = 0;


// max queue data representation
#define MAX_QUEUE_DATA_SIZE 1000000
static unsigned char networkDataBuffer[MAX_QUEUE_DATA_SIZE];




#pragma mark MPNetworkManager private interface

@interface MPNetworkManager()


- (bool) validMatchOrSession;
- (int) playerCount;

- (void) reset: (bool) bResetAuthentication;
- (void) endSession;
- (void) updateMultiplayer: (double) curTime;
- (void) authenticateLocalPlayer;
- (void) beginMatch;
- (void) endMatch;
- (void) retrievePlayerData;
- (void) determinePlayerRoles: (NSUInteger) forcedServerHash;
- (void) updateConnectionSpeed;


// all peers

//- (void) initiateRoleResolution;
- (void) sendLocalActionsToServer;
- (void) processResolvedServerActions;
- (bool) timeToSendLocalActions;

- (void) onOtherPlayerDisconnectedFromSession: (NSString *) playerID propagateChange: (bool) propagateToOthers;
- (void) onSelfDisconnectedFromSession: (bool) propagateToOthers;

//- (void) recomputeServerIdentity;

#if USE_GAMECENTER

- (GKPlayer *) playerForID: (NSString *) playerID;
- (void) removePlayerForID: (NSString *) playerID;

#else

- (bool) peerExists: (NSString *) peerID;
- (void) removePeer: (NSString *) peerID;

#endif

// server only

- (void) sendResolvedActionsToClients;
- (void) sendZOrderUpdateToClients;


// MPMatchMakerUIDelegate delegate methods

- (void) mpDidFindMatch: (GKMatch *)match;


// GKMatchDelegate methods

#if USE_GAMECENTER

// The match received data sent from the player.
- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID;
- (void)match:(GKMatch *)match player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state;
- (void)match:(GKMatch *)match connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error;
- (void)match:(GKMatch *)match didFailWithError:(NSError *)error;
//- (BOOL)match:(GKMatch *)match shouldReinvitePlayer:(NSString *)playerID;

#else

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state; 
- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error; 
- (void) session:(GKSession *)session didFailWithError:(NSError *)error;

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context;

#endif



@end


#pragma mark public implementation


@implementation  MPNetworkManager

@synthesize localPlayerIDHash_;
@synthesize playerRole_;
@synthesize appAuthenticationStatus_;
//@synthesize appNetworkingStatus_;

#if USE_GAMECENTER
@synthesize match_;
#else
@synthesize session_;
#endif

@synthesize appMatchStatus_;

//
//
+ (void) startup
{
    if ( !theMan )
    {
        theMan = [[MPNetworkManager alloc] init];
        
    }
}

//
//
+ (void) shutdown
{
    if ( theMan )
    {
        [theMan release];
        theMan = nil;
    }
}

//
//
+ (MPNetworkManager *) man
{ 
    return theMan;
}

//
// is the gamekit API available on this device?
+ (bool) gameKitAvailable
{
    
    
    
    // Check for presence of GKLocalPlayer class.
    BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
    
    // The device must be running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    
    return (localPlayerClassAvailable && osVersionSupported);
}


//
//
- (id) init
{
    
    if ( ( self = [super init] ) )
    {
        // these don't get called by reset by default - so init them here
        self.appAuthenticationStatus_ = eStatusPlayerNotAuthenticated;
        localPlayerID_ = nil;
        localPlayerIDHash_ = 0;   
        roleStatus_ = eMPRoleUndefined;
        connectionSpeed_ = eMPHighSpeed;
        lastNetworkSpeedUpdateTime_ = 0.0f;
        [self updateConnectionSpeed];
        
#if USE_GAMECENTER
        match_ = nil;
#else     
        session_ = nil;
#endif
        
        allClients_ = [[NSMutableArray alloc] init];
        serverArray_ = [[NSMutableArray alloc] init];        
        
        arrayPendingData_ = [[NSMutableArray alloc] init];
        arrayPendingPlayerIDs_ = [[NSMutableArray alloc] init];
        
        clientsRecognizingNewServer_ = [[NSMutableSet alloc] init];
        
#if USE_GAMECENTER
        allPlayers_ = nil;
#else
        allPeers_ = nil;
#endif
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackground) name:gNotificationAppDidEnterBG object:nil];
                
        
        [self reset];
    }
    
    return self;
}





//
//
- (void) dealloc
{
    [arrayPendingData_ release];
    [arrayPendingPlayerIDs_ release];

    
#if USE_GAMECENTER
    
    if ( self.match_ )
    {
        self.match_ = 0;
    }
    
#else
    
    if ( self.session_ )
    {
        self.session_ = 0;
    }
    
#endif
    
    
    if ( clientsRecognizingNewServer_ )
    {    
        [clientsRecognizingNewServer_ release];
        clientsRecognizingNewServer_ = nil;
    }    
    
    if ( allClients_ )
    {
        [allClients_ release];
        allClients_ = nil;
    }
    
    if ( serverArray_ )
    {
        [serverArray_ release];
        serverArray_ = nil; 
    }
    
    
#if USE_GAMECENTER
    
    if ( allPlayers_ )
    {
        [allPlayers_ release];
        allPlayers_ = nil;
    }
    
    allPlayers_ = nil;
    
#else
    
    if ( allPeers_ )
    {
        [allPeers_ release];
        allPeers_ = nil;
    }
    
    
#endif
    

    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(matchmakerTimeout) object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
     
    [super dealloc];
}


//
//
- (void) reset
{

    // reset everything but authentication
    [self reset: false];
}

//
//
- (void) update: (double) curTime
{
    
    
    switch ( appMatchStatus_ ) {
        case eMatchNotStarted:
        case eMatchStartPending:
        {
            // nothing
            break;
        }
        case eMatchStarted:
        {
            [self updateMultiplayer: curTime];
            break;
        }
        
        /*
        case eStatusPlayerAuthenticating:
        {
            [self updatePlayerAuthenticating: curTime];
            break;
        }
        case eStatusPlayerAuthenticated:
        {
            [self updatePlayerAuthenticated: curTime];
            break;
        }
         */
            
        default:
            break;
    }
    
    
    lastUpdateTime_ = curTime;

    
}


//
// entry point into multiplayer experience.
- (void) onMultiplayerInit
{
    
#ifdef PERFORMANCE_MODE
    return;
#endif
    
    // currently assumes we get here through user touching multiplayer button in-app.
    // may need to update for other ways of entering into gamekit (app launch/return from
    // background, initiated through notification or GameCenter app)
    
    if ( gameKitAvailable_ )
    {
        
    
#if USE_GAMECENTER
        
        if ( appAuthenticationStatus_ == eStatusPlayerNotAuthenticated )
        {            
            [self authenticateLocalPlayer];            
        }
        
#endif
        
        
    }
    else
    {
        

#if USE_GAMECENTER
        
        UIAlertView * notAvail = [[[UIAlertView alloc] initWithTitle:@"Multiplayer not supported" message:@"Please update to the latest version of iOS to enable multiplayer support" delegate:self cancelButtonTitle: @"OK" otherButtonTitles:nil] autorelease];
        
        [notAvail show];
        
#endif
        
    }
    
}

//
//
- (void) disconnectFromMatch: (bool) propagateToOthers
{
        
    if ( appMatchStatus_ == eMatchStarted )
    {                          
        [self onSelfDisconnectedFromSession: propagateToOthers];
    }
    
}


// Called when the app has been informed (likely through a received message) that another 
// player has disconnected from the shared session.  Go through the same processing as would be done
// if the message came from the GameKit framework.  Sometimes the GameKit framework is quite delated in 
// sending this message to all participants, so this is a way of speeding things up - when the first
// participant gets the message it sends it out to everyone.
- (void) onPlayerDisconnected: (unsigned int) playerIDHash
{
    
    
#if USE_GAMECENTER
    for ( GKPlayer * curPlayer in allPlayers_ )
#else
    for ( NSString * curPlayer in allPeers_ )    
#endif
        
    {
        
        NSString * pID = 0;
        
#if USE_GAMECENTER
        pID = [curPlayer playerID];
#else
        pID = curPlayer;
#endif
        
        if ( ![pID isEqualToString: localPlayerID_] )
        {
            if ( [pID hash] == playerIDHash )
            {
                [self onOtherPlayerDisconnectedFromSession: pID propagateChange:false];
                break;
            }
        }
    }
    
}


//
//
- (int)  numPlayersInMatch
{
    if ( [self multiplayerSessionActive] )
    { 

#if USE_GAMECENTER
        return allPlayers_ ? [allPlayers_ count] : 0;
#else
        return allPeers_ ? [allPeers_ count] : 0;
#endif
        
    }
    
    return 0;
}

//
//
- (NSString *) playerAlias: (int) iIndex
{
    if ( [self multiplayerSessionActive] )
    {     
        
        
#if USE_GAMECENTER
        
        if ( allPlayers_ && iIndex >= 0 && iIndex < [allPlayers_ count] )
        {
            GKPlayer * player = [allPlayers_ objectAtIndex: iIndex];
            if ( player )
            {
                return player.alias;
            }
        }
#else
        
        if ( session_ && allPeers_ && iIndex >= 0 && iIndex < [allPeers_ count] )
        {
            NSString * playerID = [allPeers_ objectAtIndex: iIndex];
            if ( playerID )
            {
                [session_ displayNameForPeer: playerID];
            }
        }

        
#endif
        
    }
    
    return 0;
}

//
//
- (bool) multiplayerSessionActive
{
    return (appMatchStatus_ == eMatchStarted);
}

//
//
- (bool) multiplayerSessionPending
{
    return ( appMatchStatus_ == eMatchStartPending );
}

//
//
- (void) onAppDidEnterBackground
{    
    appAuthenticationStatus_ = eStatusPlayerNotAuthenticated;
    
    // GameKit will re-authenticate when the app returns to the foreground.
    // See GKAuthentication example project for further explanation.
    

    
}

//
// Collect the hash values for all player IDs besides self (all peers)
- (void) collectPeerIDHashValues: (std::vector<unsigned int> *) outIDs
{
#if USE_GAMECENTER
    
    if ( match_ && outIDs )
    {
        for ( NSString *pID in match_.playerIDs )
        {
            if ( ![pID isEqualToString: localPlayerID_] )
            {
                outIDs->push_back( [pID hash] );
            }
        }
    }
    
#else
    
    if ( session_ && outIDs )
    {
        for ( NSString *pID in allPeers_ )
        {
            if ( ![pID isEqualToString: localPlayerID_] )
            {
                outIDs->push_back( [pID hash] );
            }
        }
    }

    
#endif
    
}



//
//
- (void) onBrushActionSequenceBegin
{
 
    // When a brush sequence begins, 
    lastClientToServerUpdateTime_ = lastUpdateTime_;
}

//
//
- (void) flushLocalActions
{

    flushLocalActions_ = true;
}

#pragma mark messages from other players

// helper
// Have all clients sent a message (which has been received) signifying that
// they recognize the new server identity
- (bool) allClientsRecognizeNewServer
{
    
    for ( NSString * clientID in allClients_ )
    {
        NSUInteger clientIDHash = [clientID hash];
        bool bFound = false;
        for ( NSNumber * curNumber in clientsRecognizingNewServer_ )
        {
            if ( [curNumber unsignedIntegerValue] == clientIDHash )
            {
                // already here
                bFound = true;
                break;
            }
        }
        
        if ( !bFound )
        {
            return false;
        }
    }
    
    return true;

}

/*
//
//
- (void) testIfNewServerReady
{
    if ( [localPlayerID_ isEqualToString: serverPlayerID_]  && [self allClientsRecognizeNewServer] )
    {
        roleStatus_ = eMPRoleDefined;
        
        // we're ready to go!
        // let the server know we're ready to go
        NSLog( @"all are ready!\n" );
        

        NSLog( @"server sending new server ready message...\n" );
        MPActionMessage * actionMsg = (MPActionMessage *) MPActionQueue::getLocalWorkingQueue().queueAction( self.localPlayerIDHash_, eActionMessage );
        actionMsg->setMessageType( eActionMsgNewServerIsReady );
        [[MPNetworkManager man] flushLocalActions];
        
        // process the new server ready message for the server locally too (clients will do this when they receive the message above)
        [self onNewServerReady: localPlayerIDHash_];
        

        [clientsRecognizingNewServer_ removeAllObjects];                
    }
}
 */


/*
//
//
- (void) onNewServerIdentified: (NSUInteger) playerIDHash
{
  
    // ah... 
    MPActionQueue::clearAll();

    roleStatus_ = eMPRolePendingRedefinition;
    [self determinePlayerRoles: playerIDHash];    
    
    // let the server know we're ready to go
    NSLog( @"I am a client... telling the new server I recognize it...\n" );
    

    MPActionMessage * actionMsg = (MPActionMessage *) MPActionQueue::getLocalWorkingQueue().queueAction( self.localPlayerIDHash_, eActionMessage );
    actionMsg->setMessageType( eActionMsgClientRecognizeNewServer );


    [[MPNetworkManager man] flushLocalActions];

}
*/

//
// The client with the given player ID hash has recognized us as the 
// new server.  Make a note of it, and when all remaining clients have done so
// let them know that it's time to reboot the process and resend their entire canvas.
// Likely the server has changed identity due to a disconnection, initiating this process
/*
- (void) onClientRecognizesNewServer: (NSUInteger) playerIDHash
{
    
    for ( NSNumber * curNumber in clientsRecognizingNewServer_ )
    {
       if ( [curNumber unsignedIntegerValue] == playerIDHash )
       {
           // already here
           return;
       }
    }
        
    [clientsRecognizingNewServer_ addObject:[NSNumber numberWithUnsignedInteger: playerIDHash]];
    

    [self testIfNewServerReady];
}
*/
/*
// The word has arrived that the new server is open for business.
// Likely the server has changed identity due to a disconnection.
// now we are ready to send the canvas over again.  It's a way of rebooting
// after the server disconnects and > 1 player is still remaining.
- (void) onNewServerReady: (NSUInteger) playerIDHash
{
    
    
    if ( [self multiplayerSessionActive] )
    {   
        NSLog( @"new server ready... sending clear and canvas" );
        roleStatus_ = eMPRoleDefined;
        
        // send network request


        MPActionQueue::getLocalWorkingQueue().queueAction( self.localPlayerIDHash_, eActionClear );                
        gMCanvas->sendCanvasToPeers();
        
    }
    
    [clientsRecognizingNewServer_ removeAllObjects];
    
}
*/


#pragma mark private implementation


//
//
- (bool) validMatchOrSession
{
#if USE_GAMECENTER
    return match_;
#else
    return session_;
#endif
     
}

//
//
- (int) playerCount
{

#if USE_GAMECENTER
    [match_.playerIDs count];
#else
    return [allPeers_ count];
#endif
}

//
//
- (void) reset: (bool) bResetAuthentication
{
        
    self.playerRole_ = eMPUnresolved;        
    delaySendingData_ = false;
    
    //self.appNetworkingStatus_ = eStatusDisconnected;
    self.appMatchStatus_ = eMatchNotStarted;
    
    serverPlayerID_ = nil;
    flushLocalActions_ = false;
    roleStatus_ = eMPRoleUndefined;
    
#if USE_GAMECENTER
    
    if ( match_ )
    {
        self.match_ = nil;
    }

    if ( allPlayers_ )
    {
        [allPlayers_ release];
        allPlayers_ = nil;
    }
    
#else
    
    if ( session_ )
    {
        self.session_ = nil;
    }
    
    if ( allPeers_ )
    {
        [allPeers_ release];
        allPeers_ = nil;
    }
    
#endif
    
    [allClients_ removeAllObjects];
    [serverArray_ removeAllObjects];
    


    [arrayPendingData_ removeAllObjects];
    [arrayPendingPlayerIDs_ removeAllObjects];
    
    lastClientToServerUpdateTime_ = 0.0f;
    lastServerToClientsUpdateTime_ = 0.0f;
    lastServerZOrderUpdateTime_ = 0.0f;
    lastServerZOrderUpdateSent_ = 0;
    lastUpdateTime_ = 0.0f;
    
    
    if ( bResetAuthentication )
    {
        
#if USE_GAMECENTER
        
        self.appAuthenticationStatus_ = eStatusPlayerNotAuthenticated;
        localPlayerID_ = nil;
        localPlayerIDHash_ = 0;
        
        [self authenticateLocalPlayer];
#endif
        
    }
    
    gameKitAvailable_ = [[self class] gameKitAvailable];
}




//
//
- (void) endSession
{
    [self reset];
}


//
//
//- (void) updatePlayerAuthenticating: (double) curTime
//{
//    // anything?
//}


//
//
- (void) updateMultiplayer: (double) curTime
{


    
#if NETWORK_DEBUG_OUTPUT
    
    /*
    int numLocalWorkingActions = MPActionQueue::getLocalWorkingQueue().numActions();
    int numServerWorkingActions = MPActionQueue::getServerWorkingQueue().numActions();
    int numServerTransferActions = MPActionQueue::getServerTransferQueue().numActions();
    int numResolvedActions = MPActionQueue::getResolvedQueue().numActions();
    
    int iTotal = numLocalWorkingActions + numServerWorkingActions + numServerTransferActions + numResolvedActions;
    if ( iTotal > 0 )
    {        
        NSLog( @"local working: %d\nserver working: %d\nserver transfer: %d\nresolved: %d\n\n", numLocalWorkingActions, numServerWorkingActions, numServerTransferActions, numResolvedActions );
    }
     */
    
#endif
    
        //MPActionQueue::getLocalWorkingQueue().debugOut();
        
    
    
        if ( curTime - lastNetworkSpeedUpdateTime_ >= NETWORK_SPEED_UPDATE_INTERVAL )
        {
            [self updateConnectionSpeed];
            lastNetworkSpeedUpdateTime_ = curTime;
        }
    
    
        

        // for low-speed (non-wifi) connections, hold off on sending data
        // while touches are active.  it prevents hitches while drawing
        //delaySendingData_ = ( connectionSpeed_ == eMPLowSpeed && 
        //                      MTouchTracker::Tracker().numTouchesTracked() > 0  );

    
#ifdef MOTION_PHONE_MOBILE
    
        // noticing on the phone that even on wifi it's better to delay strokes until 
        // touches are complete to avoid any hitches and keep the lines smooth
    
        delaySendingData_ = MTouchTracker::Tracker().numTouchesTracked() > 0;
    
#endif    
    
    
        switch ( playerRole_ )
        {
 

            case eMPClient:
            {

                

                
                if ( [self timeToSendLocalActions] )
                {                   
                    [self sendLocalActionsToServer];
                    flushLocalActions_ = false;
                    lastClientToServerUpdateTime_ = curTime;
                }

                
                break;
            }
            case eMPServer:
            {
             
                // send our local queue to ourself    
                if ( [self timeToSendLocalActions] )
                {
                    MPActionQueue::getLocalWorkingQueue().transferActionsToQueue( MPActionQueue::getServerWorkingQueue() );
                    flushLocalActions_ = false;
                }
                
                // don't need to update z order for the server-initiated strokes b/c they originally took their z-value from
                // the server's z queue.  So they should already be handled.
                
                
                // reflect resolved data back to clients                
                if ( curTime - lastServerToClientsUpdateTime_ >= SERVER_DATA_SEND_INTERVAL &&
                     MPActionQueue::getServerWorkingQueue().numActions() > 0 && 
                     !delaySendingData_ )
                {
                    [self sendResolvedActionsToClients];                    
                    lastServerToClientsUpdateTime_ = curTime;
                }
                
                
                unsigned int nextZ = gMCanvas->nextBrushZVal( false );
                if ( curTime - lastServerZOrderUpdateTime_ >= SERVER_DATA_Z_ORDER_UPDATE_INTERVAL &&
                     nextZ > lastServerZOrderUpdateSent_ && 
                     !delaySendingData_ )
                {
                    [self sendZOrderUpdateToClients];
                    lastServerZOrderUpdateTime_ = curTime;
                    lastServerZOrderUpdateSent_ = nextZ;
                }
                
                break;
            }
            case eMPUnresolved:
            {
                // need to figure out roles!
                //[self initiateRoleResolution];
                
                
                
                break;
            }
            default:
            {
                break;
            }
        
        }
                
        
        // now, has do we have any resolved actions from the server that we must process?
        // do so immediately...
        [self processResolvedServerActions];
            

        
    
    
}



//
// This block is retained by GameKit and reauthenticates every time the
// app returns to the foreground.
//
// See GKAuthentication example project for further explanation.

- (void) authenticateLocalPlayer
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    appAuthenticationStatus_ = eStatusPlayerAuthenticating;
    
    
    [localPlayer authenticateWithCompletionHandler:^(NSError *error) 
    {
        if (localPlayer.isAuthenticated)
        {
            appAuthenticationStatus_ = eStatusPlayerAuthenticated;
            localPlayerID_ = localPlayer.playerID;
            self.localPlayerIDHash_ = [localPlayerID_ hash];            
            
            // Perform additional tasks for the authenticated player.
            
        }
        else
        {
            // unable to autenticate
            appAuthenticationStatus_ = eStatusPlayerNotAuthenticated;
        }
    } ];
}
    



// 
//
- (void) beginMatch
{
    
    // figure out who is the server!
    // Use a simple method of the player with the lowest hash value
    
    gMCanvas->setAllowDrawPeers( true );
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(matchmakerTimeout) object:nil];

    serverPlayerID_ = nil;
    roleStatus_ = eMPRoleUndefined;
    
    [allClients_ removeAllObjects];
    [serverArray_ removeAllObjects];
    [clientsRecognizingNewServer_ removeAllObjects];
    

    if ( [self validMatchOrSession] )
    {
        
        
        //NSLog( @"num player ids in match: %d\n", [match_.playerIDs count] );
        
  
        
        [self determinePlayerRoles: 0];
              
        roleStatus_ = eMPRoleDefined;
        
        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationBeginMatch object: nil];
        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationMatchPlayersChanged object:nil];
        
        
      
#if USE_GAMECENTER
        int iNumTotalPlayers = [match_.playerIDs count] + 1;
#else
        int iNumTotalPlayers = [allPeers_ count]; // include self
#endif
        
        NSDictionary * dictParams = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:iNumTotalPlayers] forKey:@"player count"];
        [FlurryAnalytics logEvent:gEventStartedMultiplayer withParameters: dictParams];
        
        /*
        // temp
        NSString * msgMatchBegin = [NSString stringWithFormat: @"you: %@\n", [self playerForID: localPlayerID_].alias];
        //UIAlertView * alertMatchBegin = [[UIAlertView alloc] initWithTitle:@"session starting" message:msg_labels_t delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
         */
        self.appMatchStatus_ = eMatchStarted;   
        flushLocalActions_ = false;
                                    
        
        // process any pending data that was received before this player received the begin match 
        // notification
        
        int iNumPendingData = [arrayPendingData_ count];
        int iNumPendingIDs = [arrayPendingPlayerIDs_ count];
        
#if NETWORK_DEBUG_OUTPUT        
        SSLog( @"processing %d queued data chunks\n", iNumPendingData ); 
#endif
        
        for ( int iPend = 0; iPend < iNumPendingData; ++iPend )            
        {
            // sanity check
            if ( iPend >= iNumPendingData ||
                 iPend >= iNumPendingIDs )
            {
                break;
            }
            
#if USE_GAMECENTER
            [self match: match_ didReceiveData:[arrayPendingData_ objectAtIndex: iPend] fromPlayer:[arrayPendingPlayerIDs_ objectAtIndex: iPend]];
#else
            [self receiveData: [arrayPendingData_ objectAtIndex: iPend] fromPeer:[arrayPendingPlayerIDs_ objectAtIndex: iPend] inSession:session_ context:nil];
#endif
        }
        
        [arrayPendingData_ removeAllObjects];
        [arrayPendingPlayerIDs_ removeAllObjects];
        
    }
    
}

//
//
- (void) endMatch
{

    if ( [self validMatchOrSession] )
    {       
        
#if USE_GAMECENTER        
        [match_ disconnect];        
#else
        
        

    if( session_ ) 
    {
        [session_ disconnectFromAllPeers]; 
        session_.available = NO; 
        [session_ setDataReceiveHandler: nil withContext: NULL]; 
        session_.delegate = nil; 
    }


#endif
        
        [self reset];        
        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationEndMatch object: nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationMatchPlayersChanged object:nil];
    }
    
    MPActionQueue::clearAll();
    
}





//
//
- (void) doShowPlayerDataFail
{
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationUnableToBeginMatch object:nil];
    
    NSString * msg = @"Sorry, MotionPhone is unable to connect to the shared canvas";    
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Unable to connect" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
    [av release];
    
}

- (void) matchmakerTimeout
{
    [self endMatch];
    [self doShowPlayerDataFail];
}

//
//
- (void) retrievePlayerData
{
    
#if USE_GAMECENTER
    
    // add self to match players array and query player objects for everyone
    NSMutableArray *arrayAllPlayers = [NSMutableArray arrayWithArray: match_.playerIDs];
    [arrayAllPlayers addObject: localPlayerID_];
    
    
    [GKPlayer loadPlayersForIdentifiers:arrayAllPlayers withCompletionHandler:^(NSArray *players, NSError *error) {
        if (error != nil)
        {
            // Handle the error.            
            [self performSelectorOnMainThread: @selector(doShowPlayerDataFail) withObject:nil waitUntilDone:FALSE];                        
            
        }
        if (players != nil)
        {
            // Process the array of GKPlayer objects.
            
            if ( allPlayers_ )
            {
                [allPlayers_ release];
                allPlayers_ = nil;
            }
            
            allPlayers_ = [[NSMutableArray alloc] initWithArray: players copyItems: false];
                        
#if NETWORK_DEBUG_OUTPUT
            SSLog( @"\nmatch beginning with players:\n" );
            for ( GKPlayer * p in players )
            {
                SSLog( @"%@\n", p.alias );
            }
            SSLog( @"\n" );
#endif
            
            
            // all players are connected... and player data is retrieved.
            // we can begin the match
            [self beginMatch];        
                    
        }
    }];
    
#endif
    
}

   
//
//
- (void) determinePlayerRoles: (NSUInteger) forcedServerHash
{
    
    if ( [self validMatchOrSession] )
    {
     
#if USE_GAMECENTER
        NSMutableArray * allPlayers = [NSMutableArray arrayWithArray: match_.playerIDs];
        [allPlayers addObject: localPlayerID_];      
#else
        NSMutableArray * allPlayers = [NSMutableArray arrayWithArray: allPeers_];
#endif
        
        NSUInteger lowestHash = 0;
        bool bFirst = true;
        
        for ( NSString * curPlayerID in allPlayers )
        {
            NSUInteger iPlayerHash = curPlayerID.hash;
            
            if ( iPlayerHash == forcedServerHash )
            {
                serverPlayerID_ = curPlayerID;
                break;
            }
            
            if ( bFirst || iPlayerHash < lowestHash )
            {
                // assume the role of the server
                serverPlayerID_ = curPlayerID;
                lowestHash = iPlayerHash;
            }
            
            bFirst = false;
            
            
        }
        
        [allClients_ removeAllObjects];
        [serverArray_ removeAllObjects];
        
        
        if ( serverPlayerID_ == localPlayerID_ )
        {
            playerRole_ = eMPServer;
            
            // if we're the server, create an array of ids of all other clients
            
        
#if USE_GAMECENTER
            
            for ( NSString * curPlayerID in match_.playerIDs )
            {        
                if ( ![curPlayerID isEqualToString: localPlayerID_] )
                {
                    [allClients_ addObject: [NSString stringWithString: curPlayerID]];
                }
            }
#else
            
            for ( NSString * curPlayerID in allPeers_ )
            {        
                if ( ![curPlayerID isEqualToString: localPlayerID_] )
                {
                    [allClients_ addObject: [NSString stringWithString: curPlayerID]];
                }
            }

#endif
            
            
    #if NETWORK_DEBUG_OUTPUT
            SSLog( @"player role is server, player id hash is %d\n", [localPlayerID_ hash] );
    #endif
        }
        else
        {
            playerRole_ = eMPClient;
            [serverArray_ addObject: serverPlayerID_];
    #if NETWORK_DEBUG_OUTPUT
            SSLog( @"player role is client, player id hash is %d\n", [localPlayerID_ hash] );
    #endif
        }
    }
    
}
        
//
//
- (void) updateConnectionSpeed
{
    
    // for now, we don't need this
    return;
    
    /*
    Reachability *r = [Reachability reachabilityWithHostName:@"www.apple.com"];
    
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    
    if ( internetStatus == ReachableViaWiFi )
    {
        NSLog( @"high speed\n" );
        connectionSpeed_ = eMPHighSpeed;
    }
    else
    {
        NSLog( @"low speed\n" );
        connectionSpeed_ = eMPLowSpeed;
    }
     */
    
    
}
         
#pragma mark all-peer helper methods



//
// send local actions that have been queued up over the last networking period to the
//
// bytes        val
// --------------------
// 4            packet id
// ...          queue action data
//
- (void) sendLocalActionsToServer
{
 
    

    if ( [self validMatchOrSession]  && [self multiplayerSessionActive] && playerRole_ == eMPClient && MPActionQueue::getLocalWorkingQueue().numActions() > 0 )
    {       
        
        
        unsigned int totalSpaceRemaining = MAX_QUEUE_DATA_SIZE;
        unsigned char *pBufPtr = networkDataBuffer;
        
        
        // the data version            
        *((int *) pBufPtr) = NETWORKING_DATA_VERSION;
        pBufPtr += ACTION_INT_BYTES;
        totalSpaceRemaining -= ACTION_INT_BYTES;
        
        
        // mark the packet type
        *((int *) pBufPtr) = ePacketClientToServerActions;        
        pBufPtr += ACTION_INT_BYTES;
        totalSpaceRemaining -= ACTION_INT_BYTES;
                
        int iNumToData = MPActionQueue::getLocalWorkingQueue().toData(pBufPtr, totalSpaceRemaining, MAX_ACTIONS_SENT_PER_FRAME);

        unsigned int totalDataLen = MAX_QUEUE_DATA_SIZE - totalSpaceRemaining;
        NSData * dataToSend = [NSData dataWithBytes: networkDataBuffer length:totalDataLen];
        

        
        NSError *outError = nil;
        
#if USE_GAMECENTER        
        [match_ sendData:dataToSend toPlayers:serverArray_ withDataMode:GKMatchSendDataReliable error: &outError];        
        
#else        
        [session_ sendData:dataToSend toPeers:serverArray_ withDataMode:GKSendDataReliable error:&outError];
#endif
        
        
#if NETWORK_DEBUG_OUTPUT
        SSLog( @"sending local actions to server... %d actions, total data bytes: %d\n", iNumToData, totalDataLen );
#endif
        
        MPActionQueue::getLocalWorkingQueue().clearNumActions( iNumToData );  
    }
        
    
}



// Any actions we have received back from the server can now be acted upon here
// locally, in the order they were received.
- (void) processResolvedServerActions
{
    
    MPActionQueue& resolved = MPActionQueue::getResolvedQueue();
    
#if NETWORK_DEBUG_OUTPUT

    int iNumServerActions = resolved.numActions();
    if ( iNumServerActions > 0 )
    {
        //SSLog( @"processing resolved server actions: %d actions\n", iNumServerActions );
    }
    
#endif
    
    
    
    resolved.performActions( true, true );
    
    
    //resolved.clear();
    
}

//
//
- (bool) timeToSendLocalActions
{
 

    
    int numLocalWorkingActions = MPActionQueue::getLocalWorkingQueue().numActions();
                    
    return (  ( numLocalWorkingActions > 0 ) &&                                         
              ( flushLocalActions_ ||
              ( numLocalWorkingActions >= NUM_LOCAL_ACTIONS_FORCE_UPDATE && !delaySendingData_ ) ) );
         
         
         //curTime - lastClientToServerUpdateTime_ >= CLIENT_DATA_SEND_INTERVAL ||
         //numLocalWorkingActions >= NUM_LOCAL_ACTIONS_FORCE_UPDATE ) )
}



//
//
- (void) doGeneralConnectFailureAlert
{
    NSString * msg = @"Unable to connect to the shared canvas";    
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Connection Status" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
    [av release];
    
}


//
//
- (void) doShowCanvasDisconnectAlert
{
    NSString * msg = @"All other players have disconnected from the shared canvas";    
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Connection Status" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
    [av release];

}


//
//
- (void) onOtherPlayerDisconnectedFromSession: (NSString *) playerID propagateChange: (bool) propagateToOthers
{
        
#if USE_GAMECENTER
    GKPlayer * disconnectedPlayer = [self playerForID: playerID];        
    if ( disconnectedPlayer )
    {
#else
    if ( playerID )
    {
#endif
    
        bool serverDisconnected = [playerID isEqualToString:serverPlayerID_];
     
#if USE_GAMECENTER
    #if NETWORK_DEBUG_OUTPUT
        SSLog( @"player %@ disconnected from session.  %d players remain in match.\n", disconnectedPlayer.alias, [match_.playerIDs count] );
    #endif
#else
        //SSLog( @"player %@ disconnected from session.  %d players remain in match.\n", disconnectedPlayer.alias, [ .playerIDs count] );
#endif
        
        // remove the player from our list of players
        
#if USE_GAMECENTER        
        [self removePlayerForID: playerID];   
#else                
        [self removePeer: playerID];
#endif
        

#if USE_GAMECENTER        
        if (  [self validMatchOrSession] && ([match_.playerIDs count] == 0 || serverDisconnected) )
#else
        if (  [self validMatchOrSession] && ([self playerCount] <= 1 || serverDisconnected) )    
#endif
        {
            // end the match if all players have disconnected or if the server has disconnected
            [self disconnectFromMatch: false];      
            [self performSelector: @selector(doShowCanvasDisconnectAlert) withObject:nil afterDelay: 0.5f];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationMatchPlayersChanged object:nil]; 
        
        if ( propagateToOthers )
        {
            MPActionMessage * actionMsg = (MPActionMessage *) MPActionQueue::getLocalWorkingQueue().queueAction( self.localPlayerIDHash_, eActionMessage );
            actionMsg->setMessageType( eActionMsgPlayerDisconnected );
            actionMsg->setMessageParam1( [playerID hash] );        
            [self flushLocalActions];
        }
    }

}

//
//
- (void) onSelfDisconnectedFromSession: (bool) propagateToOthers
{
    // for now, debug alert
    //UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"connection status" message:@"MotionPhone: you disconnected" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    //[av show];
    //[av release];
 
    if ( propagateToOthers )
    {
        MPActionMessage * actionMsg = (MPActionMessage *) MPActionQueue::getLocalWorkingQueue().queueAction( self.localPlayerIDHash_, eActionMessage );
        actionMsg->setMessageType( eActionMsgPlayerDisconnected );
        actionMsg->setMessageParam1( [localPlayerID_ hash] );        
        [self flushLocalActions];
    }
    
    [self performSelectorOnMainThread:@selector(endMatch) withObject:nil waitUntilDone:false];
    
}


//
// Called when the server has disconnected - now we need to figure out the new server and
// begin the process that allow things to re sync up.
//
// New server realizes it's the server
// Clients realize the identity of the new server
// Once server has heard from all clients that they recognize it, send message to all
// that we're ready to roll.
// All players (clients and server) send erase message then entire canvas
/*
- (void) recomputeServerIdentity
{
    // am I the new server?
    
    NSLog( @"recomputing server identity..." );
        
    roleStatus_ = eMPRolePendingRedefinition;
    
    [self determinePlayerRoles: 0];
    
    // whatever used to be in the queue... get rid of it
    //MPActionQueue::clearAll();
    
    if ( [serverPlayerID_ isEqualToString: localPlayerID_] )
    {
        // wait for all clients to recognize my server-ness
        NSLog( @"I am the server... waiting...\n" );
        
        MPActionQueue::clearAll();
        

        MPActionMessage * actionMsg = (MPActionMessage *) MPActionQueue::getLocalWorkingQueue().queueAction( self.localPlayerIDHash_, eActionMessage );
        actionMsg->setMessageType( eActionMsgNewServerIdentified );

        
    }
    else
    {
//        // let the server know we're ready to go
//        NSLog( @"I am a client... telling the server I recognize it...\n" );
//        
//        MPActionMessage * actionMsg = (MPActionMessage *) MPActionQueue::getLocalWorkingQueue().queueAction( self.localPlayerIDHash_, eActionMessage );
//        actionMsg->setMessageType( eActionMsgClientRecognizeNewServer );

        
        
    }
    
    [[MPNetworkManager man] flushLocalActions];
    
    
    
}
*/
 
#if USE_GAMECENTER

//
// given a player's game center ID, return the player object
- (GKPlayer *) playerForID: (NSString *) playerID
{
    if ( allPlayers_ )
    {
        for ( GKPlayer * curPlayer in allPlayers_ )
        {
            if ( [curPlayer.playerID isEqualToString: playerID] )
            {
                return curPlayer;
            }
        }
    }
    
    return nil;
}


//
//
- (void) removePlayerForID: (NSString *) playerID
{
    int iIndex = 0;
    if ( allPlayers_ )
    {
        for ( GKPlayer * curPlayer in allPlayers_ )
        {
            if ( [curPlayer.playerID isEqualToString: playerID] )
            {
                [allPlayers_ removeObjectAtIndex: iIndex];
                break;
            }
            
            ++iIndex;
        }
    }
}

#else

// given a player's game center ID, return the player object
- (bool) peerExists: (NSString *) peerID
{
    if ( allPeers_ )
    {
        for ( NSString * curPlayer in allPeers_ )
        {
            if ( [curPlayer isEqualToString: peerID] )
            {
                return true;
            }
        }
    }
    
    return false;
}


//
//
- (void) removePeer: (NSString *) peerID
{
    int iIndex = 0;
    if ( allPeers_ )
    {
        for ( NSString * curPlayer in allPeers_ )
        {
            if ( [curPlayer isEqualToString: peerID] )
            {
                [allPeers_ removeObjectAtIndex: iIndex];
                break;
            }
            
            ++iIndex;
        }
    }
}

#endif


#pragma mark server-only helper methods


//
// send pending resolved server actions back to all clients to be process
//
// bytes        val
// --------------------
// 4            packet id
// ...          queue action data
//
- (void) sendResolvedActionsToClients
{
        

    
    
    if ( [self validMatchOrSession]  && [self multiplayerSessionActive] && playerRole_ == eMPServer )
    {        
                
        
        unsigned int totalSpaceRemaining = MAX_QUEUE_DATA_SIZE;
        unsigned char *pBufPtr = networkDataBuffer;
        
        // the data version            
        *((int *) pBufPtr) = NETWORKING_DATA_VERSION;
        pBufPtr += ACTION_INT_BYTES;
        totalSpaceRemaining -= ACTION_INT_BYTES;
                
        // mark the packet type
        *((int *) pBufPtr) = ePacketServerToClientResolvedActions;        
        pBufPtr += ACTION_INT_BYTES;
        totalSpaceRemaining -= ACTION_INT_BYTES;
                
        int iNumToData = MPActionQueue::getServerWorkingQueue().toData(pBufPtr, totalSpaceRemaining, MAX_ACTIONS_SENT_PER_FRAME);
        
        unsigned int totalDataLen = MAX_QUEUE_DATA_SIZE - totalSpaceRemaining;
        NSData * dataToSend = [NSData dataWithBytes: networkDataBuffer length:totalDataLen];
        
        NSError *outError = nil;   
        
        
#if USE_GAMECENTER 
        
        [match_ sendData:dataToSend toPlayers:allClients_ withDataMode:GKMatchSendDataReliable error: &outError];        
#else
      
        [session_ sendData:dataToSend toPeers:allClients_ withDataMode:GKSendDataReliable error: &outError];
#endif
        
#if NETWORK_DEBUG_OUTPUT
        SSLog( @"sending resolved actions to clients... %d actions, total data bytes: %d\n", iNumToData, totalDataLen );
#endif
                
        // we are the server, so we must also perform these actions locally in addition to sending them to clients
        MPActionQueue& resolvedQueue = MPActionQueue::getResolvedQueue(); 
        MPActionQueue::getServerWorkingQueue().transferActionsToQueue( resolvedQueue, iNumToData );
        
        //MPActionQueue::getServerWorkingQueue().performActions();        
        //MPActionQueue::getServerWorkingQueue().clear();
    }

       
}



// send current next z order val to all clients so they can update
// their own next z to be in sync (reduces sorting corrections that must be made later)
//
// bytes        val
// --------------------
// 4            packet id
// 4            z val
- (void) sendZOrderUpdateToClients
{
    unsigned int theData[3];        
    
    theData[0] = NETWORKING_DATA_VERSION;    
    theData[1] = ePacketServerToClientUpdateZOrder;
    theData[2] = gMCanvas->nextBrushZVal( false );
    
    NSData * dataZ = [NSData dataWithBytes: theData length:sizeof( theData )];
    NSError * outError = nil;
    
    
#if USE_GAMECENTER 
    
    [match_ sendData:dataZ toPlayers:allClients_ withDataMode:GKMatchSendDataReliable error: &outError];        
#else
    [session_ sendData:dataZ toPeers:allClients_ withDataMode:GKSendDataReliable error: &outError];
#endif
    
    
#if NETWORK_DEBUG_OUTPUT
    SSLog( @"server sending next z update: %d\n", gMCanvas->nextBrushZVal( false ) );
#endif
    
}




#if USE_GAMECENTER

// MPMatchMakerUIDelegate delegate methods


//
//
- (void) mpDidFindMatch: (GKMatch *)match
{
  
    self.match_ = match; // retain the match      
    self.appMatchStatus_ = eMatchStartPending;
    match_.delegate = self;
    

    // our timeout condition
    [self performSelector:@selector(matchmakerTimeout) withObject:nil afterDelay: MP_MATCHMAKING_TIMEOUT_SECONDS];
   
    
#if NETWORK_DEBUG_OUTPUT    
    SSLog(@"Did find match.  Expected player count: %d\n", match.expectedPlayerCount );
#endif
    
    if (self.appMatchStatus_ != eMatchStarted && match.expectedPlayerCount == 0)
    {
        // retrieve all player data before beginning match
        [self retrievePlayerData];
    }
}

#else

//
// gamekit peer to peer
- (void) mpDidFindSession: (GKSession *)session withPeers: (NSArray *) peerArray
{
    self.session_ = session;
    self.appMatchStatus_ = eMatchStartPending;
    session_.delegate = self;
                
    [session setDataReceiveHandler: self withContext:nil];
    
    // todo - timeout calc?
    
    // are we all set up at this point or is there more matchmaking to do?
    
#if NETWORK_DEBUG_OUTPUT    
    SSLog(@"Did find multiplayer session.\n" );
#endif
        
    if (self.appMatchStatus_ != eMatchStarted )
    {        
        
        if ( allPeers_ )
        {
            [allPeers_ release];
            allPeers_ = nil;
        }
        
        allPeers_ = [[NSMutableArray alloc] initWithArray: peerArray copyItems: false];
                
        localPlayerID_ = session_.peerID;
        self.localPlayerIDHash_ = [localPlayerID_ hash];          
        
        [self beginMatch];        
        
        
    }
    
}

#endif




#pragma mark data handling common helpers

//
//
- (void) appDidReceiveData: (NSData *) data fromPlayer: (NSString *) playerID
{
    // todo - continue here
    // ensure that if this isn't on main thread, perform selector on main thread
    
    // need to deal with either server or client data coming in
    
    
    bool bSaveInPending = false;
    
    if ( [self multiplayerSessionActive ] )
    {
        
        
        const unsigned char * pData = static_cast<const unsigned char *>([data bytes]);
        unsigned int dataLen = [data length];
        
        if ( dataLen > ACTION_INT_BYTES )
        {
            
            // the data version                        
            int networkDataVersion = *((int *) pData);
            pData += ACTION_INT_BYTES;
            
            //NSLog( @"data version: %d\n", networkDataVersion );
            
            int packetType = *((int *) pData);
            pData += ACTION_INT_BYTES;
            
            if ( packetType == ePacketServerToClientResolvedActions && 
                playerRole_ == eMPClient )
            {
                
                
                
                // as the client, we just received resolved actions from the server.
                // need to convert the data chunk to action objects and add them to our
                // resolved queue for processing
                
                MPActionQueue& resolvedQueue = MPActionQueue::getResolvedQueue();                                                
                resolvedQueue.fromData( const_cast<unsigned char *>(pData), networkDataVersion );
                
                
#if NETWORK_DEBUG_OUTPUT
                int iPreDataResolved = resolvedQueue.numActions();
                int iPostDataResolved = resolvedQueue.numActions();
                SSLog( @"client receiving resolved data from server.  pre data num actions: %d, post: %d, delta: %d\n", iPreDataResolved, iPostDataResolved, iPostDataResolved-iPreDataResolved );
#endif  
                
                // that's it!
                
            }
            else if ( packetType == ePacketClientToServerActions && 
                     playerRole_ == eMPServer )
            {
                // as the server we're receiving actions from the client.  We need to translate the data
                // into actions, update any values as needed and insert it into the server's working queue
                
                
                
                MPActionQueue& transferQueue = MPActionQueue::getServerTransferQueue();
                
                transferQueue.clear();                
                transferQueue.fromData( const_cast<unsigned char *>(pData), networkDataVersion );
                
                // now update the z-values of all brush actions in the queue to correspond to the order 
                int iNumActions = transferQueue.numActions();
                
#if NETWORK_DEBUG_OUTPUT
                SSLog( @"server receiving action data from client: %d actions\n", iNumActions );
#endif
                
                
                for ( int i = 0; i < iNumActions; ++i )
                {
                    MPAction *curAction = transferQueue.actionAtIndex( i );
                    if ( curAction->actionType() == eActionBrush )
                    {
                        MPActionBrush * actionBrush = static_cast<MPActionBrush *>(curAction);
                        actionBrush->setZOrder( gMCanvas->nextBrushZVal() );
                    }
                }                          
                
                transferQueue.transferActionsToQueue( MPActionQueue::getServerWorkingQueue() );    
                
                
                
            }
            else if ( packetType == ePacketServerToClientUpdateZOrder &&
                     playerRole_ == eMPClient )
            {
                // server has instructed us to update our next z order val
                unsigned int newNextZVal = *((unsigned int *) pData);
                gMCanvas->setNextBrushZVal( newNextZVal );
                
#if NETWORK_DEBUG_OUTPUT
                SSLog( @"client setting next z to: %d\n", newNextZVal );
#endif
            }
            else
            {
                bSaveInPending = true;
            }
        }
        
    }
    else
    {
        bSaveInPending = true;
    }
    
    if ( bSaveInPending )
    {
#if NETWORK_DEBUG_OUTPUT
        SSLog( @"player receiving data, but multiplayer session is not active - saving data\n" );                
#endif
        
        // save this data!
        [arrayPendingData_ addObject:data];
        [arrayPendingPlayerIDs_ addObject: playerID];
    }
}


#pragma mark GKMatchDelegate


#if USE_GAMECENTER

// The match received data sent from the player.
- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
        
    [self appDidReceiveData:data fromPlayer:playerID];
    
}


- (void) doPlayerChangedState
{
    
}

// The player state changed (eg. connected or disconnected)
- (void)match:(GKMatch *)match player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state
{
    
    //NSAssert([NSThread isMainThread], @"Method called using a thread other than main!");
    
    switch (state)
    {
        case GKPlayerStateConnected:
            
            // handle a new player connection.     
            // todo - anything?
            
            break;
        case GKPlayerStateDisconnected:
            
            // a player just disconnected.       
            
            if ( playerID == localPlayerID_ )
            {
                [self onSelfDisconnectedFromSession: true]; 
            }
            else
            {
                [self onOtherPlayerDisconnectedFromSession: playerID propagateChange:true];
            }            
            
            break;
    }
    
    if ( match_ && self.appMatchStatus_ != eMatchStarted && match_.expectedPlayerCount == 0)
    {    
        // retrieve all player data before beginning match
        [self retrievePlayerData];
        
    }
    
}

// The match was unable to connect with the player due to an error.
- (void)match:(GKMatch *)match connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error
{
    [self endSession];
}


// The match was unable to be established with any players due to an error.
- (void)match:(GKMatch *)match didFailWithError:(NSError *)error
{
    [self endSession];
    
}


//// This method is called when the match is interrupted; if it returns YES, a new invite will be sent to attempt reconnection. This is supported only for 1v1 games
//- (BOOL)match:(GKMatch *)match shouldReinvitePlayer:(NSString *)playerID
//{
//    
//}


#else


- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    
    if ( self.appMatchStatus_ == eMatchStarted )
    {
    
        if ( state == GKPeerStateUnavailable ||
             state == GKPeerStateDisconnected )        
        {
            
            [self onPlayerDisconnected: [peerID hash]];                        
            [self endMatch]; // currently with p2p bluetooth any player disconnecting ends the session.  This may be redundant but 
        }
            
    }
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
    [self performSelector: @selector(doGeneralConnectFailureAlert) withObject:nil afterDelay: 0.5f];

    if ( self.appMatchStatus_ == eMatchStarted )
    {
        [self endMatch];
    }
}


- (void) session:(GKSession *)session didFailWithError:(NSError *)error
{
    [self performSelector: @selector(doGeneralConnectFailureAlert) withObject:nil afterDelay: 0.5f];
    
    if ( self.appMatchStatus_ == eMatchStarted )
    {
        [self endMatch];
    }
}

//
// GKSession (p2p) data receive handler
- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{
    [self appDidReceiveData:data fromPlayer:peer];
}

#endif



@end







