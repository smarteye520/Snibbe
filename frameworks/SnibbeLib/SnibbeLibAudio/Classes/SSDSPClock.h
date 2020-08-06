//
//  SSDSPClock.h
//  SnibbeLib
//
//  Created by Graham McDermott on 7/2/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "fmod.hpp"

#ifndef SnibbeLib_SSDSPClock_h
#define SnibbeLib_SSDSPClock_h

typedef enum
{
    eSSDSPLinear = 0,
    eSSDSPSmooth,
} SSDSPClockInterpT;


class SSDSPClock
{
    
public:
    
    
    ~SSDSPClock();
    
    void    initialize( FMOD::System * pSys );
    void    syncToReferenceChannel( FMOD::Channel * pChannel, float soundLen, float secondsBeatReference = -1.0f, float secondsBeatPeriod = -1.0f );
    
    void    reset();
    void    update();     // call once a frame
    double  time() const; // return the computed time - DSP accuracy + interpolation
    double  absoluteDSPTime() const; // use same interpolation approach as time() but for absolute DSP time
    double  frameTime() const { return currentTime_ - lastTime_; }
    void    setActive( bool bActive );
    bool    isActive() const { return active_; }
    
    float   normalizedBeatPos( SSDSPClockInterpT interpT = eSSDSPLinear, bool bWrapAround = false );
    
    void    onPause( bool bPause );
    
    double  timeIntoChunkLoad() const;
    
    FMOD_RESULT clockSynchronizeDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels);
    void createClockSyncDSP( FMOD::System * pSys );

    // currently only singleton supported
    static SSDSPClock& clock() { return msDspClock; }
    
private:
    
    SSDSPClock();
    static SSDSPClock msDspClock;

    
    double  calculateTimeWithinSound();

    
    FMOD::DSP  *dspClockSync_;
    FMOD::Channel *syncChannel_;
    FMOD::DSPConnection *syncConnection_;
    
	double	currentTime_;
    double  lastTime_;
    double  deltaTime_;
    
    int   numTimeUpdates_;
    
    double  timeAtPause_;
    double  pauseLengthDuringCurrentChunk_;
    unsigned int numTotalLoops_;

    
    
	double	intervalTime_;
    
    double  timeAtLastDSPChunkLoad_;    
    double  channelPosAtLastDSPChunkLoad_;    
    double  lastTimeWithinSound_;

    // for adjusting tempo if desired
    float	wrapDuration_;
	float   wrapDurationBaseline_;
    
    float   secondsBeatReference_;
    float   secondsBeatPeriod_;
    bool    calculatingBeat_;
    
    float   fps_;
    float   lowFps_;    
    double	lowFpsTime_;
    
    bool    paused_;
    bool    beenPaused_;
    bool    active_;
};

#endif
