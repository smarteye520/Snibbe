/*
 *  SoundInstance.mm
 *  Shared
 *
 *  Created by Graham McDermott on 2/25/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */

#include "SoundInstance.h"
#include "assert.h"
#include "math.h"
#include <stdio.h>

//
//
SoundInstance::SoundInstance( FMOD::Sound *sound, float vol, float pShift ) 
{
	instSound_ = sound;
    pitchShift_ = pShift;
	volume_ = vol;
	instChannel_ = 0;
	isFinished_ = false;
	fadingOut_ = false;
	
	// hardcoded for now (tesla code)	
	fadeBeginTicks_ = ConvertMsToDSPTicks( 250 );
	fadeLengthTicks_ = ConvertMsToDSPTicks( 250 );
	
    // general fade code
	resetVolumeFade();
}

//
//
SoundInstance::SoundInstance( FMOD::Channel *channel )
{
    instSound_ = nil;
    pitchShift_ = 1.0f;

    channel->getVolume(&volume_);    
	instChannel_ = channel;
    
	isFinished_ = false;
	fadingOut_ = false;
	
	// hardcoded for now (tesla code)	
	fadeBeginTicks_ = ConvertMsToDSPTicks( 250 );
	fadeLengthTicks_ = ConvertMsToDSPTicks( 250 );
	
    // general fade code
	resetVolumeFade();

}

//
// virtual 
SoundInstance::~SoundInstance()
{
	if ( instChannel_ )
	{
		instChannel_->stop();
		instChannel_ = 0;
	}
}

//
//
void SoundInstance::createChannel( Uint64P ticksDelayToStart, Uint64P startTime, Uint64P fadeBeginDelta, Uint64P fadeLength )
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
	
	if ( ticksDelayToStart.value() > 0 )
	{				
		// schedule the sound in a sample-accurate way using the delay method
		result = instChannel_->setDelay( FMOD_DELAYTYPE_DSPCLOCK_START, startTime.mHi, startTime.mLo );
		ERRCHECK(result);
	}
	
	// hack for now to get dsp here
	//MusicPlayer::Player().applyDSPEffectsToChannel( instChannel_ );
	
	result = instChannel_->setPaused(false);
	ERRCHECK(result);
	
	beginTime_ = startTime;
	
	fadeBeginTicks_ = fadeBeginDelta;
	fadeLengthTicks_ = fadeLength;
}

//
//
void SoundInstance::releaseChannel()
{
	if ( instChannel_ )
	{
		instChannel_->stop();
		instChannel_ = 0;
		isFinished_ = false;
        resetVolumeFade();
	}
}

void SoundInstance::setChannel( FMOD::Channel *c )
{
    releaseChannel();
    
    instChannel_ = c;
}


//
//
bool SoundInstance::isPlaying() const
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
void SoundInstance::pause( bool bPaused )
{
    if ( instChannel_ )
    {
        instChannel_->setPaused( bPaused );
        
        // $ todo update anything about the fading?
    }
}

	
//
//
void SoundInstance::setDelayToStart( Uint64P ticksDelayToStart, Uint64P startTime, Uint64P fadeBeginDelta, Uint64P fadeLength )
{
	
	if ( instChannel_ )
	{

		FMOD_RESULT result = instChannel_->setDelay( FMOD_DELAYTYPE_DSPCLOCK_START, startTime.mHi, startTime.mLo );
		ERRCHECK(result);
		
		beginTime_ = startTime;
		
		fadeBeginTicks_ = fadeBeginDelta;
		fadeLengthTicks_ = fadeLength;
		
	}
	else 
	{
		createChannel( ticksDelayToStart, startTime, fadeBeginDelta, fadeLength );
	}

}

void SoundInstance::fadeVolume( float targetVol, Uint64P fadeLength )
{
    if ( instChannel_ )
    {
        fadeBeginTimeVol_.assignNow();
        fadeDurationVol_ = fadeLength;
        fadeTargetVol_ = targetVol;        
        instChannel_->getVolume( &fadeBeginVol_);       
        fadingVolume_ = true;
    }
}

//
//
//void SoundInstance::createChannel( unsigned int msDelayToStart )
//{
//	createChannel( ConvertMsToDSPTicks( msDelayToStart ) );	
//}
//
//
//
//void SoundInstance::setDelayToStart( unsigned int msDelayToStart )
//{
//	setDelayToStart( ConvertMsToDSPTicks( msDelayToStart ) );	
//}

//
//
void SoundInstance::update()
{

	// respond to envelope.
	// just simple linear fade now
	
	
	Uint64P curTime;
	curTime.assignNow();
	
	Uint64P passedTime = curTime;
	passedTime -= beginTime_;
	
    
    // new general fade code
    
    if ( fadingVolume_ && instChannel_ )
    {
        Uint64P passedTimeFade = curTime;
        passedTimeFade -= fadeBeginTimeVol_;
        
        float percentThere = (float) passedTimeFade.value() / fadeDurationVol_.value();	
        
        bool bDone = false;
        if ( percentThere > 0.999f )
        {
            percentThere = 1.0f;
            bDone = true;
        }
                
		percentThere = MIN( percentThere, 1.0f );
        percentThere = MAX( percentThere, 0.0f );
        


        float newVol = (fadeTargetVol_-fadeBeginVol_) * percentThere + fadeBeginVol_;
        
        instChannel_->setVolume( newVol );

        //NSLog( @"per: %f, new vol: %f\n", percentThere, newVol );
        
        if ( bDone )
        {
            resetVolumeFade();
        }
    }
    
    
    // fading code from Tesla...
    
    
#if 0 // come back to this for tesla - (breaks scoop)
    
	if ( !fadingOut_ )
	{
		if ( passedTime.value() >= fadeBeginTicks_.value() )
		{
			fadingOut_ = true;
			
			instChannel_->getVolume( &volAtFadeBegin_ );		
		}
	}
	
	if ( fadingOut_ )
	{
		passedTime -= fadeBeginTicks_;		
		// now passed time has the duration of the fade
		
		if ( passedTime.value() >= fadeLengthTicks_.value() )
		{
			// we're done
			instChannel_->setVolume( 0.0f );
			isFinished_ = true;
		}
		else 
		{
			float percentThere = (float) passedTime.value() / fadeLengthTicks_.value();			
			instChannel_->setVolume( (1-percentThere) * volAtFadeBegin_ );
		}

		
	}
     
#endif 
		
}


//
//
void SoundInstance::resetVolumeFade()
{
    fadeBeginTimeVol_.clear();
    fadeDurationVol_.clear();
    fadeTargetVol_ = 0;
    fadeBeginVol_ = 0;
    fadingVolume_ = false;
}