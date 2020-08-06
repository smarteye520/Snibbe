//
//  SnibbeAudioConverter.mm
//  SnibbeLib
//
//  Created by Graham McDermott on 4/19/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SnibbeAudioConverter.h"
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetReader.h>
#import <AVFoundation/AVAssetWriter.h>
#import <AVFoundation/AVAssetReaderOutput.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVAssetWriterInput.h>
#import <AVFoundation/AVAudioSettings.h>
#import <AVFoundation/AVAssetTrack.h>

#define PCM_OUT_SAMPLE_RATE 44100.0
#define PCM_OUT_NUM_CHANNELS 2
#define PCM_OUT_BIT_DEPTH 16

// private interface
@interface SnibbeAudioConverter ()

- (AVURLAsset *) assetForFileName: (NSString *) fileName;
- (AVAssetWriter *) createAssetWriterForOutputName: (NSString *) outName searchDir: (NSSearchPathDirectory) searchDir outExportPath: (NSString **) ppExportPath;
- (AVAssetWriterInput *) createAssetWriterInput;

- (void) nilAll;
- (void) releaseAll;
- (void) releaseAndSucceed;
- (void) updateProgress: (NSNumber *) percentDone;

@end


@implementation SnibbeAudioConverter

@synthesize delegate_;


//
//
- (id) init
{
    if ( ( self = [super init] ) )
    {
        delegate_ = nil;

        state_ = eStateWaiting;
        [self nilAll];
    }
    
    return self;
}

//
//
- (void) nilAll
{
    // not the delegate
    
    assetReader_ = nil;
    assetWriter_ = nil;
    assetReaderOutput_ = nil;
    assetWriterInput_ = nil;
    exportPath_ = nil;
    state_ = eStateWaiting;
}


//
//
- (void) releaseAll
{
    [assetReader_ release];
    assetReader_ = nil;
    
    [assetReaderOutput_ release];
    assetReaderOutput_ = nil;
    
    [assetWriter_ release];
    assetWriter_ = nil;
    
    [assetWriterInput_ release];
    assetWriterInput_ = nil;
    
    [exportPath_ release];
    exportPath_ = nil;
}

//
//
- (void) releaseAndSucceed
{
    NSString * tempExportedPath = [NSString stringWithString: exportPath_];
    
    [self releaseAll];
    if ( delegate_ )
    {
        [delegate_ onComplete: tempExportedPath];
    }
}

//
//
- (void) updateProgress: (NSNumber *) percentDone
{
    if ( delegate_ )
    {
        //NSLog( @"percent: %.2f\n", [percentDone floatValue] );                             
        [delegate_ onProgressUpdate: percentDone];
    }
}

//
//
- (void) completedConversion
{
    [assetWriterInput_ markAsFinished];
    [assetWriter_ finishWriting];
    [assetReader_ cancelReading];
    //NSDictionary *outputFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:exportPath_ error:nil];
    //NSLog (@"done. file attributes: %@", [outputFileAttributes description] );    
    
    state_ = eStateWaiting;
    [self releaseAndSucceed];
    

}

//
//
- (bool) convertMP3Named: (NSString *) mp3Name
{
    
    if ( state_ != eStateWaiting )
    {    
        return false;
    }
    
    [self releaseAll];
    
    NSLog( @"mp3 convert begin\n" );
    AVURLAsset * srcAsset = [self assetForFileName: mp3Name];
    if ( srcAsset )
    {
        
        float songDuration = CMTimeGetSeconds( srcAsset.duration );
        int estimatedPCMKbSize = songDuration * PCM_OUT_SAMPLE_RATE * PCM_OUT_NUM_CHANNELS * PCM_OUT_BIT_DEPTH / 8;
        
        
        NSError *assetError = nil;
        assetReader_ = [AVAssetReader assetReaderWithAsset:srcAsset error:&assetError];        
        
        if (assetError) 
        {
            NSLog (@"error: %@", assetError);
            [self nilAll];
            return false;
                        
        }
        
        
        if ( assetReader_ )
        {
            
            assetReaderOutput_ = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks: srcAsset.tracks audioSettings: nil];
            if (! [assetReader_ canAddOutput: assetReaderOutput_]) 
            {
                NSLog (@"Error, can't add reader output\n");
                [self nilAll];
                return false;
            }
            
            [assetReader_ addOutput: assetReaderOutput_];
            NSString * outFile = [mp3Name stringByDeletingPathExtension];
            outFile = [outFile stringByAppendingPathExtension: @"caf"];
            exportPath_ = nil;
            
            assetWriter_ = [self createAssetWriterForOutputName:outFile searchDir:NSDocumentDirectory outExportPath: &exportPath_ ];            
            if ( !assetWriter_ )
            {
                [self nilAll];
                return false;
            }
            
            assetWriterInput_ = [self createAssetWriterInput];            
            if ( !assetWriterInput_ )
            {
                [self nilAll];
                return false;
            }
            
            if ([assetWriter_ canAddInput:assetWriterInput_]) 
            {
                [assetWriter_ addInput:assetWriterInput_];
                
                [assetWriter_ startWriting];
                [assetReader_ startReading];
                
                AVAssetTrack *soundTrack = [srcAsset.tracks objectAtIndex:0];
                CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
                [assetWriter_ startSessionAtSourceTime: startTime];
                
                
                // retain so block has access
                [assetReader_ retain];
                [assetReaderOutput_ retain];
                [assetWriter_ retain];
                [assetWriterInput_ retain];
                [exportPath_ retain];
                
                // do the sample transfer
                
                state_ = eStateConverting;
                
                __block UInt64 convertedByteCount = 0;
                dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
                [assetWriterInput_ requestMediaDataWhenReadyOnQueue:mediaInputQueue
                                                        usingBlock: ^
                 {
                     
                     while (assetWriterInput_.readyForMoreMediaData) 
                     {

                         if ( state_ != eStateConverting )
                         {
                             break;
                         }
                         
                         
                         CMSampleBufferRef nextBuffer = [assetReaderOutput_ copyNextSampleBuffer];
                             
                         if (nextBuffer) 
                         {
                             // append buffer
                             [assetWriterInput_ appendSampleBuffer: nextBuffer];


                             convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
                             NSNumber *convertedByteCountNumber = [NSNumber numberWithLong:convertedByteCount];
                             //NSLog( @"converted byte count: %d\n", [convertedByteCountNumber intValue] );
                             
                             
                             float percentDone = [convertedByteCountNumber floatValue] / estimatedPCMKbSize;
                             percentDone = MAX( percentDone, 0.0f );
                             percentDone = MIN( percentDone, 1.0f );
                                                          
                             NSNumber * numPercentDone = [NSNumber numberWithFloat: percentDone];
                             [self performSelectorOnMainThread: @selector( updateProgress: ) withObject:numPercentDone waitUntilDone:NO];
                                         
                             CFRelease( nextBuffer );
                         }
                         else
                         {
                             // done!
                             NSLog( @"done..\n" );
                             state_ = eStateComplete;
                             [self performSelectorOnMainThread:@selector(completedConversion) withObject:nil waitUntilDone:NO];
                             break;
                                         
                         }
                     }
                 } ]; // end of block
                
            } 
            else 
            {
                NSLog (@"Error, can't add asset writer input\n");
                [self nilAll];
                return false;
            }
            
            
        }
        else 
        {
        
            NSLog( @"error, couldn't create asset reader\n");
            [self nilAll];
            return false;
        }
        
        
    }
    


    
    

    return true;
}
    
//

#pragma mark private implementation

//
//
- (AVURLAsset *) assetForFileName: (NSString *) fileName
{
    NSString *srcFileNoExt = [fileName stringByDeletingPathExtension];
    NSString *srcFileExt = [fileName pathExtension];
    
    NSURL *srcURL = [[NSBundle mainBundle] URLForResource:srcFileNoExt withExtension:srcFileExt];
    AVURLAsset *srcAsset = [AVURLAsset URLAssetWithURL:srcURL options:nil];  
    return srcAsset;
        
}

//
//
- (AVAssetWriter *) createAssetWriterForOutputName: (NSString *) outName searchDir: (NSSearchPathDirectory) searchDir  outExportPath: (NSString **) ppExportPath
{
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(searchDir, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
    *ppExportPath = [documentsDirectoryPath stringByAppendingPathComponent:outName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:*ppExportPath]) 
    {
        [[NSFileManager defaultManager] removeItemAtPath:*ppExportPath error:nil];
    }
    
    NSURL *exportURL = [NSURL fileURLWithPath:*ppExportPath];
    NSError *assetError = nil;
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:exportURL
                                                          fileType:AVFileTypeCoreAudioFormat
                                                             error:&assetError];
    
    if (assetError) 
    {
        NSLog (@"error creating asset writer: %@", assetError);
        return nil;
    }
    
    return assetWriter;
    
}


//
//
- (AVAssetWriterInput *) createAssetWriterInput
{
    
    // set up the audio layout for the 
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;

    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                    [NSNumber numberWithFloat:PCM_OUT_SAMPLE_RATE], AVSampleRateKey,
                                    [NSNumber numberWithInt:PCM_OUT_NUM_CHANNELS], AVNumberOfChannelsKey,
                                    [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)],
                                    AVChannelLayoutKey,
                                    [NSNumber numberWithInt:PCM_OUT_BIT_DEPTH], AVLinearPCMBitDepthKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                    [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                    nil];
    
    AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:outputSettings];
    assetWriterInput.expectsMediaDataInRealTime = NO;
    
    return assetWriterInput;
    



}

@end

