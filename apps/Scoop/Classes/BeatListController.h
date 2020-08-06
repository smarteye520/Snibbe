//
//  BeatListController.h
//  Scoop
//
//  Created by Graham McDermott on 4/12/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ScoopBeatSetIDTarget

-(void) onBeatSetIDSelected: (int) beatSetID;
-(void) onTempoChanged: (float) normalizedTempo;
-(float) getNormalizedTempo;

@end


@protocol BeatSetNavDelegate

- (void) navigateToBeatSetViewAtIndex: (int) iIndex;

@end

@interface BeatListController : UITableViewController {
    
    id<ScoopBeatSetIDTarget> beatSetIDDelegate_;
    id<BeatSetNavDelegate> beatSetNavDelegate_;
    
    int selectedSetIndex_;
    
}

@property (nonatomic, assign) id<ScoopBeatSetIDTarget> beatSetIDDelegate_;
@property (nonatomic, assign) id<BeatSetNavDelegate> beatSetNavDelegate_;

@property (nonatomic) int selectedSetIndex_;


@end
