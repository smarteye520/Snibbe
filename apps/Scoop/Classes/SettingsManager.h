//
//  SettingsManager.h
//  Scoop
//
//  Created by Graham McDermott on 3/21/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <vector>

class ScoopState;







@interface SettingsManager : NSObject {
    
    
    // cached values
    
    std::vector<ScoopState *> savedScoops_;
    bool purchasedBeatSet1_;
        
}

+ (void) init;
+ (void) shutdown;
+ (SettingsManager *) manager; // returns the singleton

- (id) init;
- (void) dealloc;
- (void) clear;

- (void) registerDefaults;

- (void) save;
- (void) load;

// accessors for each user setting used in this app


@property (nonatomic, readonly) int numSavedScoopStates;
@property (nonatomic) bool purchasedBeatSet1_;


- (int)  createNewScoopState;
- (void) removeScoopStateWithID: (int) idScoop;
- (ScoopState *) scoopStateWithID: (int) idScoop;
- (ScoopState *) scoopStateAtIndex: (int) iIndex;
- (int) indexForScoopStateID: (int) idScoop;




@end
