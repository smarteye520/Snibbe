//
//  SnibbeAudioConverter.h
//  SnibbeLib
//
//  Created by Graham McDermott on 4/19/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef VideoMashup_AudioRender_h
#define VideoMashup_AudioRender_h

@class AVAssetReader;
@class AVAssetReaderOutput;
@class AVAssetWriter;
@class AVAssetWriterInput;

typedef enum 
{
    eStateWaiting = 0,
    eStateConverting,
    eStateComplete,
} SSAudioConvertState;

// note - delegate functions are all called on main thread, while audio conversion is 
// done asynchronously

@protocol SnibbeAudioConverterDelegate <NSObject>

- (void) onProgressUpdate: (NSNumber *) percentDone;
- (void) onComplete: (NSString *) convertedFilePath; 

@end


@interface SnibbeAudioConverter : NSObject
{
    id<SnibbeAudioConverterDelegate> delegate_;
    
    AVAssetReader *assetReader_;
    AVAssetReaderOutput *assetReaderOutput_;
    AVAssetWriter * assetWriter_;
    AVAssetWriterInput * assetWriterInput_;
    NSString * exportPath_;
    
    SSAudioConvertState state_;
    
}

@property (nonatomic, assign) id<SnibbeAudioConverterDelegate> delegate_;

- (bool) convertMP3Named: (NSString *) mp3Name;

@end



#endif
