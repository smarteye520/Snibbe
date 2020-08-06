//
//  SnibbeCapture.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/30/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#ifndef SnibbeLib_SnibbeCapture_h
#define SnibbeLib_SnibbeCapture_h

#import <UIKit/UIKit.h>

extern UIImage* ssScreenShotUIImage( CGRect region );
extern UIImage* ssScreenShotUIImage( CGRect region, UIDeviceOrientation deviceOrient );


//extern bool ssRecordMovieBegin( NSString * path, CGSize size, int audioSampleRate, int audioNumChannels, int audioPCMBitDepth );
//extern bool ssRecordMovieAddFrame( UIImage * image, float atTime );
//extern bool ssRecordMovieAddAudio( );
//extern void ssRecordMovieAddFrame();

extern bool ssRecordMovieBegin( NSString * path, CGSize size, int timeScale );
extern bool ssRecordMovieAddFrame( UIImage * image, int frameIndex );
extern bool ssRecordMovieReadyForData();
extern void ssRecordMovieEnd();


#endif
