//
//  ScoopUtils.h
//  Scoop
//
//  Created by Graham McDermott on 4/6/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#define ROUNDINT( d ) ((int)((d) + ((d) > 0 ? 0.5 : -0.5)))


extern bool gbIsIPad;      // single point of access for iPad test
extern bool retinaEnabled; // running on a phone and retina display is enabled



extern void testForIPad();
extern void setRetinaEnabled( bool bRetina );
extern int  numCrowns();
extern int  maxSaves();
extern int  maxVisibleBeats();
extern void setIsPaused( bool bPaused ); // just reflects the scoop paused state
extern bool getIsPaused();


extern bool shouldHandleDeviceOrientation( UIDeviceOrientation orientation );

// general resource loading
extern NSString * getPlatformResourceName( NSString * iPadName, NSString * extension );

//
extern float easeInOutMinMax( float min, float max, float input );
extern float easeInOutRange( float min, float range, float input );

extern float easeInOutMinMaxd( double min, double max, double input );
extern float easeInOutRanged( double min, double range, double input );


extern UIImage* screenShotUIImage( CGRect region );

extern bool recordMovieBegin( NSString * path, CGSize size, int audioSampleRate, int audioNumChannels, int audioPCMBitDepth );
extern bool recordMovieAddFrame( UIImage * image, float atTime );
extern bool recordMovieAddAudio( );
extern void recordMovieAddFrame();
extern void recordMovieEnd();
