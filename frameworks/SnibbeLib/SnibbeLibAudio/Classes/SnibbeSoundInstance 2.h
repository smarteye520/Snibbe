/*
 *  SnibbeSoundInstance.h
 *  Shared
 *
 *  Created by Graham McDermott on 2/25/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 *  class Snibbe
 *  -------------------
 *  Wrapper class encapsulating a running instance of an FMOD audio channel.
 *  Allows updates to levels and other parameters over time.
 */

#ifndef __SNIBBE_SOUND_INSTANCE_H__
#define __SNIBBE_SOUND_INSTANCE_H__


#import "fmod.hpp"
#import "SnibbeAudioUtils.h"
#import "SnibbeInterpolator.h"
#import "SnibbeUserDataOwner.h"
#import <vector>
#import <string>
#include <tr1/functional>

class SnibbeSoundInstance;




typedef void (*SnibbeSoundInstanceCompleteCB) ( SnibbeSoundInstance * );
typedef void (*SnibbeSoundInstanceStartedCB) ( SnibbeSoundInstance * );

class SnibbeSoundInstance : public SnibbeUserDataOwner
{

public:

	typedef std::tr1::function< void (SnibbeSoundInstance *) > soundCBFunctionT;

    
#ifdef __OBJC__
    SnibbeSoundInstance( NSString *name, NSString *ext, bool bStreaming, float vol = 1.0f, float pShift = 0.0f, bool startNow = true );
#endif
    
    SnibbeSoundInstance( const std::string& fullPath, bool bStreaming, float vol = 1.0f, float pShift = 0.0f, bool startNow = true );
	SnibbeSoundInstance( FMOD::Sound *sound, float vol = 1.0f, float pShift = 0.0f, bool startNow = true );
	SnibbeSoundInstance( FMOD::Channel *channel, float soundLen );
    
	virtual ~SnibbeSoundInstance();
		
    void init(FMOD::Sound *sound, float vol, float pShift, bool startNow);
    
    // for managing the channel internally
	void createChannel( Uint64P startTime );
	void releaseChannel();
	
    // can also set the channel externally
    void setChannel( FMOD::Channel *c );
    
    bool hasChannel() const { return instChannel_; }
	bool isPlaying() const;
	
    bool isFading() const { return volumeInterpolator_.isInterpolating(); }
    
    void pause( bool bPaused );
    void popLastPause();
    
    void reset();
    void setLooping( bool bLoop );
    bool getLooping();
    float getPosInSeconds();
    void setPosInSeconds( float sec );
    bool atSoundEnd();
    float getSoundLength() const { return soundLength_; }
    
    void scheduleDelayedStart( Uint64P startTime ); 
	void augmentDelayToStart( Uint64P ticksToAugment );
    
    void scheduleVolumeFade( float soundTimeToBeginFade, float targetVol, float fadeLength, bool completeCBAfterFade = false );
    void scheduleVolumeFadeAfterElapsedTime( float elapsedTimeToBeginFade, float targetVol, float fadeLength, bool completeCBAfterFade = false );
    void resetScheduledFade();
    
    void fadeVolume( float targetVol, float fadeLength, bool completeCBAfterFade = false );
    void setVolume( float targetVol );    
	
	void update( float dt );
	bool isFinished() const { return isFinished_; }
	
    void scheduleAfter( SnibbeSoundInstance * src );
    void syncWith( SnibbeSoundInstance * src );
    
	Uint64P getScheduledBeginTime() const { return scheduledBeginTime_; }
	bool waitingForScheduledBegin() const;
    
    FMOD::Channel *getChannel() { return instChannel_; }
    
    void setSound( FMOD::Sound * sound );
    FMOD::Sound * getSound() { return instSound_; }
    
    void setMIDINote( int iNote ) { midiNote_ = iNote; }
    int  getMIDINote() const { return midiNote_; }
    
    void setMIDINoteLen( float len ) { midiNoteLen_ = len; }
    float getMIDINoteLen() const { return midiNoteLen_; }
    
    // older c-style callbacks
    void setInstanceCompleteCB( SnibbeSoundInstanceCompleteCB cb ) { instanceCompleteCB_ = cb; } // called when the sound reaches its end (if not looping)    
    void setInstanceStartedCB ( SnibbeSoundInstanceStartedCB cb) { instanceStartedCB_ = cb; } //called when the sound started
    
    // newer c++ style callbacks
    void setInstanceCompleteCBFunc( soundCBFunctionT func ) { instanceCompleteCBFunc_ = func; }
    void setInstanceStartedCBFunc( soundCBFunctionT func ) { instanceStartedCBFunc_ = func; }
    
    void setReleaseSoundOnDealloc( bool b ) { releaseSoundOnDealloc_ = b; }
    
protected:

	SnibbeSoundInstance(); // allow subclasses an implicit constructor, make sure to call init
	
	void resetVolumeFade();
    
    
	FMOD::Channel *instChannel_;
	FMOD::Sound *instSound_;	
	
    std::vector<bool> pauseStack_;
    
    float elapsedTime_; // instance update time, NOT time within the sound
    
	float pitchShift_;   // semitones to shift if we initiate the sound	
	float volume_;
	float soundLength_;
    
    // midi tracking
    int   midiNote_;
    float midiNoteLen_;
    
	Uint64P scheduledBeginTime_;
	bool    isFinished_;
	bool    fadingVolume_;	
    
    SnibbeInterpolator<float, float> volumeInterpolator_;
    
    // for scheduled future fades   
    
    float scheduledSoundTimeToBeginFade_;
    float elapsedTimeToBeginFade_;
    float scheduledFadeLength_;
    float  scheduledFadeTargetVol_;
    bool   scheduleFadecompleteCBAfterFade_;
	
	bool       fadingOut_;
	bool       startedPlaying_;
    bool       releaseSoundOnDealloc_;
    
	bool       deleteSelfAfterFade_; // flag the instance to clean up after itself post-fade 
	
    bool       completeCBAfterFade_;
    bool       pendingCompleteCBFromFade_;      
    bool       releaseChannelOnComplete_;
    
    // original c-style callbacks
    SnibbeSoundInstanceCompleteCB instanceCompleteCB_;
    SnibbeSoundInstanceStartedCB instanceStartedCB_;
    
    // c++ style callbacks
    soundCBFunctionT instanceCompleteCBFunc_;
    soundCBFunctionT instanceStartedCBFunc_;
    
    
    bool       calledInstanceStartedCB_;
    
};


#endif  // __SNIBBE_SOUND_INSTANCE_H__