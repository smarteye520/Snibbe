//
//  MPProtocols.h
//  MotionPhone
//
//  Created by Graham McDermott on 11/2/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#ifndef MotionPhone_MPProtocols_h
#define MotionPhone_MPProtocols_h

@class GKMatch;
@class GKSession;

@protocol MPMatchMakerUIDelegate <NSObject>

@required

#if USE_GAMECENTER
- (void) mpDidFindMatch: (GKMatch *)match;  // gamecenter
#else
- (void) mpDidFindSession: (GKSession *)session withPeers: (NSArray *) peerArray; // gamekit peer to peer
#endif

@end



@protocol MPOrientingUIKitParent <NSObject>

@required
- (void) onViewControllerRequestDismissal: (UIViewController *) vc;

@end

@protocol MPStatusDelegate <NSObject>

@optional
- (void) onStatusCancel;

@end



#endif
