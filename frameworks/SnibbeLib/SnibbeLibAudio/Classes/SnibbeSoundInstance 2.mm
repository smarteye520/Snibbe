/*
 *  SnibbeSoundInstance.mm
 *  Shared
 *
 *  Created by Graham McDermott on 2/25/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */


#include "SnibbeSoundInstance.h"
#include "assert.h"
#include "math.h"
#include "fmod.h"
#include "fmod.hpp"
#include <stdio.h>
#include "SnibbeLibDefs.h"
#include "SSDSPClock.h"
#include <iostream>


static int totalInstCount = 0;

#define SSI_DEBUG_OUT 0

void updateInstCount( int increment )
{
    totalInstCount += increment;
    
#if SSI_DEBUG_OUT
    std::cout << "total SnibbeSoundInstances: " << (increment > 0 ? "+" : "") << increment << " count: " << totalInstCount << std::endl;
#endif
}

//
// Implicit construtor for subclassing, make sure to call init
SnibbeSoundInstance::SnibbeSoundInstance()
{
  
    updateInstCount(1);
    
    #if SSI_DEBUG_OUT
    
    #endif
}

#ifdef __OBJC__
//
//
SnibbeSoundInstance::SnibbeSoundInstance( NSString *name, NSString *ext, bool bStreaming, float vol, float pShift, bool startNow )
{
    updateInstCount(1);
    
    init( CreateFMODSound( name, ext, bStreaming), vol, pShift, startNow );
}
#endif

//
//
SnibbeSoundInstance::SnibbeSoundInstance( const std::string& fullPath, bool bStreaming, float vol, float pShift, bool startNow )
{
    updateInstCount(1);
    
    init( CreateFMODSoundFromPath( fullPath.c_str(), bStreaming), vol, pShift, startNow );
}

//
//
SnibbeSoundInstance::SnibbeSoundInstance( FMOD::Sound *sound, float vol, float pShift, bool startNow ) 
{
    updateInstCount(1);
    
    init( sound, vol, pShift, startNow );    
}

//static int iTotal = 0;

//
//
SnibbeSoundInstance::SnibbeSoundInstance( FMOD::Channel *channel, float soundLen )
{
    updateInstCount(1);
    
    instSound_ = nil;
    pitchShift_ = 1.0f;
    elapsedTime_ = 0.0f;
    scheduledBeginTime_ = 0;
    midiNote_ = 0;
    midiNoteLen_ = 0;
    calledInstanceStartedCB_ = false;
    
	if (channel) {
		channel->getVolume(&volume_);    
	}
	instChannel_ = channel;
    
    volumeInterpolator_.setValue( volume_ );
    
	isFinished_ = false;
	fadingOut_ = false;
	
    soundLength_ = soundLen;
    
    instanceCompleteCB_ = 0;
    instanceStartedCB_ = 0;
    
    startedPlaying_ = false;
    
    releaseSoundOnDealloc_ = false;

    completeCBAfterFade_ = false;
    pendingCompleteCBFromFade_ = false;
    
    // general fade code
	resetVolumeFade();
    resetScheduledFade();

    releaseChannelOnComplete_ = (SNIBBELIB_VER >= 2);
    
    //++iTotal;
    //printf( "total: %d\n", iTotal );

}

//
// virtual 
SnibbeSoundInstance::~SnibbeSoundInstance()
{
    
    updateInstCount(-1);
    
    
	if ( instChannel_ )
	{
		instChannel_->stop();
		instChannel_ = 0;
	}
    
    if ( releaseSoundOnDealloc_ && instSound_ )
    {
        instSound_->release();
        instSound_ = 0;
    }
    
    //--iTotal;
    //printf( "total: %d\n", iTotal );
    
}

//
// ctor common code
void SnibbeSoundInstance::init(FMOD::Sound *sound, float vol, float pShift, bool startNow)
{
    instSound_ = sound;
    pitchShift_ = pShift;
	volume_ = vol;
	instChannel_ = 0;
	isFinished_ = false;
	fadingOut_ = false;	
    elapsedTime_ = 0.0f;
    scheduledBeginTime_ = 0;
    midiNote_ = 0;
    midiNoteLen_ = 0;
    calledInstanceStartedCB_ = false;
    
    assert( instSound_ );
    unsigned int iLen = 0;
    instSound_->getLength( &iLen, FMOD_TIMEUNIT_MS );
    soundLength_ = iLen * .001f;
    
    volumeInterpolator_.setValue( vol );    
	
    instanceCompleteCB_ = 0;    
    startedPlaying_ = false;
    
    instanceStartedCB_ = 0;
    
    releaseSoundOnDealloc_ = false;
    completeCBAfterFade_ = false;
    pendingCompleteCBFromFade_ = false;
    
    // general fade code
	resetVolumeFade();
    resetScheduledFade();
    
    if ( startNow )
    {
        Uint64P timeNow;
        timeNow.assignNow();
        createChannel( timeNow );
    }
    
    releaseChannelOnComplete_ = (SNIBBELIB_VER >= 2);
    
}

//
//
void SnibbeSoundInstance::createChannel( Uint64P startTime )
{
	assert( !instChannel_ );
	
	FMOD::System *sys = GetFMODSystem();
	float channelFrequency;
	
	FMOD_RESULT result = sys->playSound( FMOD_CHANNEL_FREE, instSound_, true, &instChannel_);	
	ERRCHECK( result );	
	
	// Set the volume while it is paused.
	result = instChannel_->setVolume(volume_);		
	ERRCHECK(result);
	
	// pitch shift
	result = instChannel_->getFrequency(&channelFrequency);
	ERRCHECK(result);
	
	result = instChannel_->setFrequency( powf(2.0f,pitchShift_/12.0f) * channelFrequency ); 
	ERRCHECK(result);
	
    Uint64P nowTime;
    nowTime.assignNow();
    
	if ( startTime.value() > nowTime.value() )
	{				
		// schedule the sound in a sample-accurate way using the delay method
        scheduleDelayedStart( startTime );  
        
	}
	
	// hack for now to get dsp here
	//MusicPlayer::Player().applyDSPEffectsToChannel( instChannel_ );
	
	result = instChannel_->setPaused(false);
	ERRCHECK(result);
    
	startedPlaying_ = false;
    
    
    
}

//
//
void SnibbeSoundInstance::releaseChannel()
{
	if ( instChannel_ )
	{
		instChannel_->stop();
		instChannel_ = 0;
		isFinished_ = false;
        startedPlaying_ = false;
        resetVolumeFade();
        resetScheduledFade();
        calledInstanceStartedCB_ = false;
	}
}

void SnibbeSoundInstance::setChannel( FMOD::Channel *c )
{
    releaseChannel();
    
    instChannel_ = c;
}


//
//
bool SnibbeSoundInstance::isPlaying() const
{
	if ( instChannel_ )
	{
		bool bPlaying = false;
		instChannel_->isPlaying( &bPlaying );
		return bPlaying;
	}
	
	return false;
}

//
//
void SnibbeSoundInstance::pause( bool bPaused )
{
    if ( instChannel_ )
    {
        bool bCurPaused = false;
        instChannel_->getPaused( &bCurPaused );
        pauseStack_.push_back( bCurPaused );
        
        instChannel_->setPaused( bPaused );
        
        // $ todo update anything about the fading?
    }
}

//
//
void SnibbeSoundInstance::popLastPause()
{
    if ( pauseStack_.size() > 0 )
    {
        bool bPopped = pauseStack_.back();
        pauseStack_.pop_back();
        
        if ( instChannel_ )
        {
            instChannel_->setPaused( bPopped );
        }
    }
}

//
//
void SnibbeSoundInstance::setLooping( bool bLoop )
{
    if ( instChannel_ )
    {
        instChannel_->setMode( bLoop ? FMOD_LOOP_NORMAL : FMOD_LOOP_OFF );        
    }
}

//
//
bool SnibbeSoundInstance::getLooping()
{
    bool bLooping = false;
    if ( instChannel_ )
    {
        FMOD_MODE theMode;
        instChannel_->getMode( &theMode );
        
        bLooping = (theMode & FMOD_LOOP_NORMAL) || (theMode & FMOD_LOOP_BIDI);         
    }
    
    return bLooping;

}

//
// Are we at the end of play of a non-looping sound?
bool SnibbeSoundInstance::atSoundEnd()
{
    bool bLooping = getLooping();
    if ( !bLooping && startedPlaying_ )
    {            
        
        float curPos = getPosInSeconds();
        
        // position can be reported at zero when sound ends
        
        return ( curPos <= .00001 ||
                 curPos >= soundLength_ );
        
    }
    
    return false;
    
}


//
//
void SnibbeSoundInstance::reset()
{
    if ( instChannel_ )
    {
        instChannel_->setPosition( 0, FMOD_TIMEUNIT_MS );
        startedPlaying_ = false;
    }
}

//
//
float SnibbeSoundInstance::getPosInSeconds()
{
    unsigned int iPos = 0;
    if ( instChannel_ )
    {
        instChannel_->getPosition( &iPos, FMOD_TIMEUNIT_MS );        
    }
    
    return iPos * 0.001f;
}

//
//
void SnibbeSoundInstance::setPosInSeconds( float sec )
{
    unsigned int iPos = sec * 1000;
    if ( instChannel_ )
    {
        instChannel_->setPosition( iPos, FMOD_TIMEUNIT_MS );        
    }
}

// 
//
void SnibbeSoundInstance::scheduleDelayedStart( Uint64P startTime ) 
{
    if ( instChannel_ )
	{
		FMOD::Sound * snd;
		instChannel_->getCurrentSound(&snd);
//		assert(snd == instSound_);
		FMOD_RESULT result = instChannel_->setDelay( FMOD_DELAYTYPE_DSPCLOCK_START, startTime.mHi, startTime.mLo );
        ERRCHECK(result);						
	}
	else 
	{
		createChannel( startTime );
	}
   
    scheduledBeginTime_ = startTime;
    

    
    // NSLog(@"assigning scheduled begin time: %u\n", ConvertDSPTicksToMs( scheduledBeginTime_.value() ) );
}


//
//
void SnibbeSoundInstance::augmentDelayToStart( Uint64P ticksToAugment )
{
 
    if ( instChannel_ )
    {
                
        Uint64P curStartTime;
        FMOD_RESULT result = instChannel_->getDelay( FMOD_DELAYTYPE_DSPCLOCK_START, &curStartTime.mHi, &curStartTime.mLo );
        ERRCHECK(result);
        
        if ( curStartTime.mHi > 0 || curStartTime.mLo > 0 )
        {        
            curStartTime += ticksToAugment;
            instChannel_->setDelay( FMOD_DELAYTYPE_DSPCLOCK_START, curStartTime.mHi, curStartTime.mLo );  
            
            scheduledBeginTime_ = curStartTime;
            
        }        
        
    }
    
}


// Schedule a fade at some point in the future.  soundTimeToBeginFade indicates the time in seconds into the sound to begin
// the fade.  Otherwise same deal as normal fade properties.  Able to coexist with normal fades simultaneously, though
// when the scheduled fade is activated it will override any existing fades (the most recently initiated fade always
// overrides anything in progress)
void SnibbeSoundInstance::scheduleVolumeFade( float soundTimeToBeginFade, float targetVol, float fadeLength, bool completeCBAfterFade )
{
    
    assert( fadeLength > 0 );
    
    if ( fadeLength > 0 )
    {
        scheduledSoundTimeToBeginFade_ = soundTimeToBeginFade;
        scheduledFadeLength_ = fadeLength;
        scheduledFadeTargetVol_ = targetVol;    
        scheduleFadecompleteCBAfterFade_ = completeCBAfterFade;
    }
    
    
}

void SnibbeSoundInstance::scheduleVolumeFadeAfterElapsedTime( float elapsedTimeToBeginFade, float targetVol, float fadeLength, bool completeCBAfterFade )
{
    assert( fadeLength > 0 );
    
    if ( fadeLength > 0 )
    {
        elapsedTimeToBeginFade_ = elapsedTimeToBeginFade;
        scheduledFadeLength_ = fadeLength;
        scheduledFadeTargetVol_ = targetVol;
        scheduleFadecompleteCBAfterFade_ = completeCBAfterFade;
    }

}

//
//
void SnibbeSoundInstance::fadeVolume( float targetVol, float fadeLength, bool completeCBAfterFade )
{
    

    
    if ( instChannel_ )
    {
        
        float fadeBeginVol = 0.0f;
        instChannel_->getVolume( &fadeBeginVol);
        
        volumeInterpolator_.beginInterp( fadeBeginVol, targetVol, elapsedTime_, fadeLength );             
        
        fadingVolume_ = true;                
        completeCBAfterFade_ = completeCBAfterFade;
        pendingCompleteCBFromFade_ = false;
        
    }
}

//
//
void SnibbeSoundInstance::setVolume( float targetVol )
{
    if ( instChannel_ )
    {
        instChannel_->setVolume( targetVol );           
    }
}


// for transferring ownership of a sound object to this object...
// typically for instances created with a sound allocated elsewhere
void SnibbeSoundInstance::setSound( FMOD::Sound * sound )
{
    assert( instSound_ == nil );
    instSound_ = sound;
}



// per-frame update for sound instances.  handles updating volume interpolation,
// scheduled volume interpolation, complete callbacks, etc.
void SnibbeSoundInstance::update( float dt )
{

    
    
	Uint64P curTime;
	curTime.assignNow();
	
    float pos = getPosInSeconds();
    
    if ( !startedPlaying_ )
    {        
        if ( pos > .001 )
        {
            startedPlaying_ = true;
            
            if( (instanceStartedCB_ || instanceStartedCBFunc_)  && !calledInstanceStartedCB_)
            {
                if ( instanceStartedCB_ )
                {
                    instanceStartedCB_( this );
                }
                
                if ( instanceStartedCBFunc_ )
                {
                    instanceStartedCBFunc_( this );
                }
                
                calledInstanceStartedCB_ = true;
            }
        }
    }
    
    if ( startedPlaying_ )
    {
        elapsedTime_ += dt;
    }
    
    
    bool bAtEnd = atSoundEnd();
    
    if ( (instanceCompleteCB_ || instanceCompleteCBFunc_) && ( pendingCompleteCBFromFade_ || bAtEnd ) )
    {
        if ( instanceCompleteCB_ )
        {
            instanceCompleteCB_( this );
        }
        
        if ( instanceCompleteCBFunc_ )
        {
            instanceCompleteCBFunc_( this );
        }
        
        pendingCompleteCBFromFade_ = false;
        
        if ( SNIBBELIB_VER < 2 )
        {
            // compat with older versions
            instanceCompleteCB_ = 0;        
        }
    }

    if ( bAtEnd && releaseChannelOnComplete_ )
    {
        releaseChannel();
    }

    
    if ( instChannel_ )
    {

        
        // are we ready for a scheduled fade to begin?
        bool beginFade = false;
        float timeIntoFade = 0.0f;
        
        if ( scheduledSoundTimeToBeginFade_ >= 0  &&
             pos >= scheduledSoundTimeToBeginFade_ )
        {
            timeIntoFade = pos - scheduledSoundTimeToBeginFade_;
            beginFade = true;
        }

        
        if ( elapsedTimeToBeginFade_ > 0 &&
             elapsedTime_ > elapsedTimeToBeginFade_ )
        {
            timeIntoFade = elapsedTime_ - elapsedTimeToBeginFade_;
            beginFade = true;
        }
        
 
        if ( beginFade )
        {
            // we need to begin the fade!  First determine how far we are into the fade period
            // and adjust accordingly, then let the normal fading code take over from there.
            
            if ( timeIntoFade >= scheduledFadeLength_ )
            {
                scheduledFadeLength_ = 0.0f;
            }
            else
            {
                float percentThere = timeIntoFade / scheduledFadeLength_;
                float delta = scheduledFadeTargetVol_ - volumeInterpolator_.curVal();
                float curVol = delta * percentThere + volumeInterpolator_.curVal();
                volumeInterpolator_.setValue( curVol );
                scheduledFadeLength_ -= timeIntoFade;
            }
            
            fadeVolume( scheduledFadeTargetVol_, scheduledFadeLength_, scheduleFadecompleteCBAfterFade_ );                
            resetScheduledFade();                                        
        }

                        
        
        if ( fadingVolume_ )
        {
            volumeInterpolator_.update( elapsedTime_ );                
            instChannel_->setVolume( volumeInterpolator_.curVal() );
        }

        // NSLog( @"new vol: %f\n", volumeInterpolator_.curVal() );
        
        
        if ( fadingVolume_ && volumeInterpolator_.isComplete() )
        {
            
            if ( completeCBAfterFade_ )
            {
                pendingCompleteCBFromFade_ = true;
            }
            
            resetVolumeFade();
        }

        
    }

    
		
}

//
// Begin playing this sound instance after src reaches its end
void SnibbeSoundInstance::scheduleAfter( SnibbeSoundInstance * src )
{
    if ( src && src->instChannel_ )
    {
                
        unsigned int iPosSrc = 0;

        src->instChannel_->getPosition( &iPosSrc, FMOD_TIMEUNIT_MS );                         
        unsigned int iRemainingInSrc = src->soundLength_ * 1000 - iPosSrc;
        
        Uint64P delayToStart = ConvertMsToDSPTicks( iRemainingInSrc );
        
        Uint64P startTime;
        startTime.assignNow();        
        startTime += delayToStart;
        
        scheduleDelayedStart( startTime );        
                
    }
}

//
//
void SnibbeSoundInstance::syncWith( SnibbeSoundInstance * src )
{
    if ( src && src->instChannel_ && instChannel_ )
    {
        unsigned int iPosSrc = 0;
        src->instChannel_->getPosition( &iPosSrc, FMOD_TIMEUNIT_MS );            
        instChannel_->setPosition( iPosSrc, FMOD_TIMEUNIT_MS );
        
        bool bPausedSrc = false;
        src->instChannel_->getPaused( &bPausedSrc );
        
        instChannel_->setPaused( bPausedSrc );
        
    }
}


//
//
bool SnibbeSoundInstance::waitingForScheduledBegin() const
{
    if (scheduledBeginTime_.value() > 0 )
    {
        Uint64P now;
        now.assignNow();
                
        float fScheduled = ConvertDSPTicksToMs( scheduledBeginTime_ ) * .001;
        
        if ( SSDSPClock::clock().isActive() )
        {
            float absTime = SSDSPClock::clock().absoluteDSPTime();
            return fScheduled > absTime;
        }
        else
        {
        
            // little buggy b/c we're relying on DSP load chunk intervals... not precise
            float fNow = ConvertDSPTicksToMs( now ) * .001;
            return fScheduled > fNow;
        }
    }
    
    

    return false;
}

//
//
void SnibbeSoundInstance::resetVolumeFade()
{
    fadingVolume_ = false;
}

//
// reset the fade scheduling data
void SnibbeSoundInstance::resetScheduledFade()
{
    scheduledSoundTimeToBeginFade_ = -1.0f;
    elapsedTimeToBeginFade_ = -1.0f;
    scheduledFadeLength_ = -1.0f;
    scheduledFadeTargetVol_ = 0.0f;
    scheduleFadecompleteCBAfterFade_ = false;    
}


