//
//  SSDSPClock.mm
//  SnibbeLib
//
//  Created by Graham McDermott on 7/2/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SSDSPClock.h"
#import <QuartzCore/QuartzCore.h>
#import "SnibbeAudioUtils.h"
#import "SnibbeUtils.h"


// static singleton
SSDSPClock SSDSPClock::msDspClock;

// C prototypes
FMOD_RESULT F_CALLBACK clockSyncDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels);



//
//
SSDSPClock::SSDSPClock()
{
    dspClockSync_ = 0;
    syncChannel_ = 0;
    active_ = false;
    
    reset();
}

//
//
SSDSPClock::~SSDSPClock()
{
    
}

//
//
void SSDSPClock::initialize( FMOD::System * pSys )
{
    createClockSyncDSP( pSys );
}


// Here we set up the channel that will serve as our master timing reference.  We install our
// DSP callback on it.
void SSDSPClock::syncToReferenceChannel( FMOD::Channel * pChannel, float soundLen, float secondsBeatReference, float secondsBeatPeriod )
{
    reset();
    
    syncChannel_ = pChannel;
    assert( pChannel );
    wrapDurationBaseline_ = soundLen;
    wrapDuration_ = soundLen;
    active_ = true;
    
    //NSLog( @"dur: %f, base: %f\n", wrapDuration_, wrapDurationBaseline_ );
    
    secondsBeatPeriod_ = secondsBeatPeriod;
    secondsBeatReference_ = secondsBeatReference;
    calculatingBeat_ = secondsBeatPeriod > 0;
}


//
//
void SSDSPClock::reset()
{
    // todo - check for all
    
    currentTime_ = 0;
    lowFpsTime_ = 0;
    lastTimeWithinSound_ = -1;
    numTotalLoops_ = 0;    
    pauseLengthDuringCurrentChunk_ = 0;
    timeAtPause_ = 0;
    numTimeUpdates_ = 0;
    paused_ = false;
    beenPaused_ = false;
    fps_ = 0.0f;
    lowFps_ = 100.0;
    syncChannel_ = 0;
    active_ = false;
    
    secondsBeatReference_ = -1.0f;
    secondsBeatPeriod_ = -1.0f;    
    calculatingBeat_ = false;
    
    channelPosAtLastDSPChunkLoad_ = 0;        
    timeAtLastDSPChunkLoad_ = CACurrentMediaTime();
}

//
//
void SSDSPClock::update()
{
    
    
    if ( paused_ || !syncChannel_ || !active_ )
    {
        return;
    }
    
    lastTime_ = currentTime_;
    
    numTimeUpdates_++;
    
    // the way we're calculating time now is through a combination of using this following
    // technique:
    //
    // 1. use a custom DSP callback to record the time when a chunk of audio data is loaded
    // and the position of playback at that time.
    // 2. calculate the delta into that chunk on a per frame basis, allowing us to know 
    // more or less exactly where we are in a particular sound.
    
    if ( timeAtLastDSPChunkLoad_ > 0 )
    {
        
        
        double timeWithinSound = calculateTimeWithinSound();                          
        
        bool incrementedLoops = false;
        
        if ( timeWithinSound < lastTimeWithinSound_  )
        {
            bool bWrapped = ( (lastTimeWithinSound_ - timeWithinSound) ) > wrapDurationBaseline_ * 0.5f;
            
            if ( bWrapped )
            {
                // we wrapped around
                numTotalLoops_++;
                incrementedLoops = true;
            }
            else if ( numTimeUpdates_ > 30 ) // don't catch this in the beginning
            {
                // this is probably not a wrap around... more likely our calculation based on the
                // dsp load time is slightly off and came back a little earlier than the last time.
                // This check helps fix a bug where the whole graph would be set to a single
                // value because a slight negative time delta looked like a wrap around
                timeWithinSound = lastTimeWithinSound_; 
            }
        }
        
        currentTime_ = numTotalLoops_ * wrapDurationBaseline_ + timeWithinSound;
        

        
        lastTimeWithinSound_ = timeWithinSound;
        deltaTime_ = currentTime_ - lastTime_;
        
        
        fps_ = 1.0 / deltaTime_;
        
        //NSLog(@"last %.2g cur %.2g delta %.2g fps %.2f",lastTime_, currentTime_, deltaTime_, fps_);
        //currentTime_ += 1.0/60.0;
        
        //updateCount_++;
        
        if (fps_ < lowFps_) {
            lowFps_ = fps_;
            lowFpsTime_ = currentTime_;
        }
        
        if (currentTime_ - lowFpsTime_ > 3.0) lowFps_ = 30.0;
        
    }
    
}

//
//
double SSDSPClock::time() const
{
    return currentTime_;
}

//
// Similar to time() but uses the same interpolation approach to give a more accurate version
// of absolute DSP time (not relative to the synchronized sound)
double SSDSPClock::absoluteDSPTime() const
{
    double deltaIntoChunk = CACurrentMediaTime() - timeAtLastDSPChunkLoad_ - pauseLengthDuringCurrentChunk_;
    
    Uint64P t;
    t.assignNow();
    float dspSec = ConvertDSPTicksToMs( t ) * .001;
    return (double) dspSec + deltaIntoChunk;    
}


//
//
void SSDSPClock::setActive( bool bActive )                      
{

    active_ = bActive;
    if ( dspClockSync_ )
    {
        dspClockSync_->setActive( active_ );
    }
}

//
// 1.0 = exactly on the beat, 0.0 = upbeat or exactly between beats
float SSDSPClock::normalizedBeatPos( SSDSPClockInterpT interpT, bool bWrapAround )
{
    if ( calculatingBeat_ )
    {
        double delta = fabs( currentTime_ - secondsBeatReference_ );
        double deltaMod = fmod( delta, secondsBeatPeriod_ );
        double normDeltaMod = (deltaMod / secondsBeatPeriod_);
        float beatNorm = normDeltaMod;
        
        if ( !bWrapAround )
        {
            beatNorm = (float) fabs( normDeltaMod * 2.0 - 1.0 );
        }
        
        if ( interpT == eSSDSPSmooth )
        {
            beatNorm = easeInOutMinMax( 0.0, 1.0, beatNorm );
        }
        
        //NSLog ( @"norm: %.4f\n", beatNorm );
        
        return beatNorm;                
    }
    
    return 0;    
}
                      
//
// Doesn't pause the actual sounds... that should be handled by clients
void SSDSPClock::onPause( bool bPause )
{
    
    
    if ( bPause )
    {
        beenPaused_ = true;        
        timeAtPause_ = CACurrentMediaTime();
        //printf( "pausing: time at pause: %f\n", timeAtPause_ );
        
    }
    else
    {
        if ( paused_ )
        {
            // only process if we were formerly paused
            
            pauseLengthDuringCurrentChunk_ = CACurrentMediaTime() - MAX( timeAtPause_, timeAtLastDSPChunkLoad_ );
            
            //printf( "unpausing: pause len dur current chunk: %f, cur time: %f\n", pauseLengthDuringCurrentChunk_, CACurrentMediaTime() );
            
            timeAtPause_ = 0;
            
            lastTime_ = currentTime_;
        }
    }
    
    paused_ = bPause;    
    
}

//
//
double SSDSPClock::timeIntoChunkLoad() const
{
    return CACurrentMediaTime() - timeAtLastDSPChunkLoad_ - pauseLengthDuringCurrentChunk_;
}



//
//
double SSDSPClock::calculateTimeWithinSound()
{
    if ( timeAtLastDSPChunkLoad_ > 0 )
    {
        
        double secIntoSound = channelPosAtLastDSPChunkLoad_;        
        double deltaIntoChunk = CACurrentMediaTime() - timeAtLastDSPChunkLoad_ - pauseLengthDuringCurrentChunk_;
        
        //printf( "sec into: %f delta into: %f\n", secIntoSound, deltaIntoChunk );
        
        // now we need to modify the delta to account for our "time stretching"        
        deltaIntoChunk *= (wrapDurationBaseline_ / wrapDuration_ );
        
        double timeWithinSound = secIntoSound + deltaIntoChunk;
        

        
        
        return timeWithinSound;        
        
    }
    
    return 0.0f;
}


 //
 // Create our custom clock sync DSP
void SSDSPClock::createClockSyncDSP( FMOD::System * pSys )
{
 
    assert( pSys );
    
    FMOD_DSP_DESCRIPTION dspdesc; 
    memset(&dspdesc, 0, sizeof(FMOD_DSP_DESCRIPTION)); 
    
    strcpy(dspdesc.name, "SS Clock Sync"); 
    dspdesc.channels     = 0;                   // 0 = whatever comes in, else specify. 
    dspdesc.read         = clockSyncDSPCallback;
    dspdesc.setposition = 0;
    dspdesc.userdata     = (void *)0x12345678; 
    
    FMOD_RESULT result = pSys->createDSP(&dspdesc, &dspClockSync_); 
    ERRCHECK(result); 
       
    
    // creating DSP in the way described here to avoid CPU overhead of copying
    // the input to output
    // http://www.fmod.org/forum/viewtopic.php?f=7&t=14307

    FMOD::DSP *dspHead = nil;
    result = pSys->getDSPHead( &dspHead );
    ERRCHECK(result);
    assert( dspHead );

    result = dspHead->addInput( dspClockSync_, &syncConnection_ );
    dspClockSync_->setActive( true );

    ERRCHECK(result);
 
}
 



 
// dsp callback as method.
// Since we've created this dsp as a dangling node, we don't really need to copy any data.
// just use it to update our timers.
FMOD_RESULT SSDSPClock::clockSynchronizeDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels)
{

    // use our reference channel to sync
    
    if ( syncChannel_ && active_ )
    {
        unsigned int channelPos = 0;
        FMOD_RESULT result = syncChannel_->getPosition( &channelPos, FMOD_TIMEUNIT_MS );
        
        if ( result == FMOD_OK )
        {            
            channelPosAtLastDSPChunkLoad_ = channelPos * .001;                       
            timeAtLastDSPChunkLoad_ = CACurrentMediaTime();
            pauseLengthDuringCurrentChunk_ = 0.0f;




        }
    }
        
    // not touching the audio data at all
    
    return FMOD_OK; 

}
 


//
//
FMOD_RESULT F_CALLBACK clockSyncDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels) 
{ 
	// pass this on to the member func so we have access to the values we need	    
    return SSDSPClock::clock().clockSynchronizeDSPCallback( dsp_state, inbuffer, outbuffer, length, inchannels, outchannels );    
    
}




