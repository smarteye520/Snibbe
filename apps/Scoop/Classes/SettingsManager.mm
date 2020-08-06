//
//  SettingsManager.m
//  Scoop
//
//  Created by Graham McDermott on 3/21/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import "SettingsManager.h"
#import "ScoopDefs.h"
#import "Scoop.h"
#import "ScoopUtils.h"

static SettingsManager *manager_ = nil;

// user default keys for settings
NSString *keyScoops = @"key_scoops";
NSString *keyPurchasedBeatSet1 = @"key_purchased_beat_set_1";



// private interface
@interface SettingsManager()

- (int) getNextUID;
- (bool) idIsUsed: (int) theID;
- (int) createNewScoopStateWithUID: (int) theID;

@end




@implementation SettingsManager


///////////////////////////////////////////////////////////////////////
// public implementation
///////////////////////////////////////////////////////////////////////


//
//
+ (void) init
{
    if ( !manager_ )
    {
        manager_ = [[SettingsManager alloc] init];
        [manager_ registerDefaults];
    }
}

//
//
+ (void) shutdown
{
    if ( manager_ )
    {
        [manager_ release];
        manager_ = nil;
    }
}

//
// returns the singleton
+ (SettingsManager *) manager
{    
    assert(manager_);
    return manager_;
}

//
//
- (id) init
{
    if ( (self = [super init] ) )
    {
        purchasedBeatSet1_ = false;
    }
    
    [self load];
    
    return self;
}

//
//
- (void) dealloc
{
    [self clear];
    [super dealloc];
}

//
//
- (void) clear
{
    
    for ( unsigned int i = 0; i < savedScoops_.size(); ++i )
    {
        delete savedScoops_[i];
    }
    
    savedScoops_.clear();
    purchasedBeatSet1_ = false;
}



// Register application defaults (values for settings if
// the user has not specified any yet
- (void) registerDefaults
{
    
    
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    

    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
        
    NSMutableArray *scoopArray = [[NSMutableArray alloc] init];        
    [appDefaults setObject: scoopArray forKey: keyScoops];
    
    [appDefaults setObject: [NSNumber numberWithBool:false] forKey:keyPurchasedBeatSet1];      
    
    [defs registerDefaults:appDefaults];
}

// 
// Save cached app settings data to the user defaults
- (void) save
{
            
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
            
    
    // scoops    
    NSMutableArray *scoopArray = [[NSMutableArray alloc] init];
    
    
    // populate the defaults-friendly obj-c array with data from our
    // c++ scoop objects after transforming it into objective-c objects.    
    for ( unsigned int i = 0; i < savedScoops_.size(); ++i )
    {        
        ObjCScoopState *objCSS = [ObjCScoopState objCScoopStateFromScoopState: savedScoops_[i] ];
        
        NSData *dataScoopState = [ObjCScoopState toData: objCSS]; // archive to data
        assert(dataScoopState);
        
        [scoopArray addObject: dataScoopState];
    }
        
    [defs setObject:scoopArray forKey:keyScoops];    
    
    
    // purchased beat set 1    
    [defs setBool:purchasedBeatSet1_ forKey:keyPurchasedBeatSet1];
    
    
    [[NSUserDefaults standardUserDefaults] synchronize];

    
    [scoopArray release];
    
}

//
// load user defaults into cached app settings data 
- (void) load
{
    [self clear];
    
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

    
    // scoops
    NSArray *scoopArray = [defs arrayForKey:keyScoops];
    
    if ( scoopArray )
    {
        for ( NSData *objcSSData in scoopArray )
        {
            
            
            ObjCScoopState *objcSS = [ObjCScoopState fromData: objcSSData]; // unarchive from data
            
            int iSSID = [self createNewScoopStateWithUID: [objcSS.uniqueID_ intValue] ];
            ScoopState *ss = [self scoopStateWithID: iSSID ];
            if ( ss )
            {
                
                // we've created a new c++ scoop state with the unique id we got
                // from the saved defaults.  populate it with the other data
                
                [objcSS populateScoopState:ss];                
                
            }
        }                
    }    
    
    // purchased beat set 1    
    purchasedBeatSet1_ = [defs boolForKey:keyPurchasedBeatSet1];
}


// accessors

@dynamic numSavedScoopStates;

- (int) numSavedScoopStates
{
    return savedScoops_.size();
}

@dynamic purchasedBeatSet1_;

//
//
- (bool) purchasedBeatSet1_
{


    return purchasedBeatSet1_;
}

//
// 
- (void) setPurchasedBeatSet1_: (bool) bPurchased
{
    purchasedBeatSet1_ = bPurchased;
    [self save];
}



//
//
- (int)  createNewScoopState
{
    int iNewID = [self createNewScoopStateWithUID:[self getNextUID] ];
    return iNewID;    
}

//
//
- (void) removeScoopStateWithID: (int) idScoop
{
    for ( unsigned int i = 0; i < savedScoops_.size(); ++i )
    {
        if ( savedScoops_[i]->getUniqueID() == idScoop )
        {
            delete savedScoops_[i];
            savedScoops_.erase( savedScoops_.begin() + i  );
            [self save];
            break;
        }
    }
    

}

//
//
- (ScoopState *) scoopStateWithID: (int) idScoop
{
    for ( unsigned int i = 0; i < savedScoops_.size(); ++i )
    {
        if ( savedScoops_[i]->getUniqueID() == idScoop )
        {
            return savedScoops_[i];
        }
    }
    
    return 0;
}

//
//
- (ScoopState *) scoopStateAtIndex: (int) iIndex
{
    
    if ( iIndex >= 0 && iIndex < (int) savedScoops_.size() )
    {
        return savedScoops_[iIndex];
    }
    
    return 0;
    
}

//
//
- (int) indexForScoopStateID: (int) idScoop
{
    for ( unsigned int i = 0; i < savedScoops_.size(); ++i )
    {
        if ( savedScoops_[i]->getUniqueID() == idScoop )
        {
            return i;
        }
    }
    
    return -1;
}

///////////////////////////////////////////////////////////////////////
// private implementation
///////////////////////////////////////////////////////////////////////


// This should cycle through 1..MAX_SAVED_SCOOPS, returning
// the first unused one.  Starts looking at the one after the previous
// save
- (int) getNextUID
{
    if ( savedScoops_.size() == 0 )
    {
        return 1;
    }
    
    int startingID = savedScoops_[savedScoops_.size()-1]->getUniqueID() + 1;
    
    for ( int i = 0; i < maxSaves(); ++i )
    {
        int idToTry = ( startingID + i );
        
        if ( idToTry > maxSaves() )
        {
            idToTry %= maxSaves();
        }
        
        if ( ![self idIsUsed: idToTry] )
        {
            return idToTry;
        }
        
    }
    
    
    return -1;
}

//
//
- (bool) idIsUsed: (int) theID
{
    for ( unsigned int i = 0; i < savedScoops_.size(); ++i )
    {
        if ( theID == savedScoops_[i]->getUniqueID() )
        {
            return true;
        }
    }
    
    return false;
}

//
//
-(int) createNewScoopStateWithUID: (int) theID
{
    assert( ![self scoopStateWithID:theID] );
           
    if ( savedScoops_.size() < maxSaves() )
    {        
        ScoopState *newScoop = new ScoopState();     
        newScoop->setUniqueID( theID );
        
        savedScoops_.push_back(newScoop);   
        return theID;
    }
    
    return -1;

}


@end
