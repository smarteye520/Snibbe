//
//  MPSaveLoad.h
//  MotionPhone
//
//  Created by Graham McDermott on 12/2/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPSaveLoad : NSObject
{
    NSArray * loadedFrames_;
    
    NSString * saveFilePath_;
    NSMutableData *saveData_;
    UIImage *saveImage_;
}

+ (MPSaveLoad *) getSL;
+ (void) startup;
+ (void) shutdown;

- (int)  numSaves;

- (bool) save;
- (bool) loadSaveAtIndex: (int) iIndex;
- (bool) deleteSaveAtIndex: (int) iIndex;

- (UIImage *) screenShotForSaveAtIndex: (int) iIndex;


@end
