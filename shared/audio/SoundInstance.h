/*
 *  SoundInstance.h
 *  Shared
 *
 *  Created by Graham McDermott on 2/25/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 *  class SoundInstance
 *  -------------------
 *  Wrapper class encapsulating a running instance of an FMOD audio channel.
 *  Allows updates to levels and other parameters over time.
 */

#ifndef __SOUND_INSTANCE_H__
#define __SOUND_INSTANCE_H__

#import "fmod.hpp"
#import "AudioUtils.h"


class SoundInstance
{

public:
	
	SoundInstance( FMOD::Sound *sound, float vol = 1.0f, float pShift = 0.0f );
	SoundInstance( FMOD::Channel *channel );
    
	virtual ~SoundInstance();
	
	
    // for managing the channel internally
	void createChannel( Uint64P ticksDelayToStart, Uint64P startTime, Uint64P fadeBeginDelta, Uint64P fadeLength );
	void releaseChannel();
	
    // can also set the channel externally
    void setChannel( FMOD::Channel *c );
    
    bool hasChannel() const { return instChannel_; }
	bool isPlaying() const;
	
    bool isFading() const { return fadingVolume_; }
    
    void pause( bool bPaused );
    
	void setDelayToStart( Uint64P ticksDelayToStart, Uint64P startTime, Uint64P fadeBeginDelta, Uint64P fadeLength ); 
	
    void fadeVolume( float targetVol, Uint64P fadeLength );
    
	//void createChannel( unsigned int msDelayToStart );
	//void setDelayToStart( unsigned int msDelayToStart ); 
	
	void update();
	bool isFinished() const { return isFinished_; }
	
	Uint64P getScheduledBeginTime() const { return beginTime_; }
	
    FMOD::Channel *getChannel() { return instChannel_; }
    
protected:

	void resetVolumeFade();
    
	FMOD::Channel *instChannel_;
	FMOD::Sound *instSound_;	
	
	float pitchShift_;   // semitones to shift if we initiate the sound	
	float volume_;
	
	Uint64P beginTime_;
	bool isFinished_;
	
    // for managing a volume fade
    Uint64P fadeBeginTimeVol_;
    Uint64P fadeDurationVol_;
    float fadeTargetVol_;
    float fadeBeginVol_;
    bool fadingVolume_;
	
	// envelope information (for now just simple linear fade)
	
	Uint64P    fadeBeginTicks_;     // ticks after sounds begins to start fade
	Uint64P    fadeLengthTicks_;    // length of fade in ticks
	
	float           volAtFadeBegin_;
	bool            fadingOut_;
	
	bool       deleteSelfAfterFade_; // flag the instance to clean up after itself post-fade 
	
};

#endif  __SOUND_INSTANCE_H__