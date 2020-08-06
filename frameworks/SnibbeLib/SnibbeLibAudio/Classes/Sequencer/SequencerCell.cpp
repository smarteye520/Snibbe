//
//  SequencerCell.cpp
//  SnibbeLib
//
//  Created by Graham McDermott on 11/13/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SequencerCell.h"
#include "SnibbeAudioUtils.h"
#include "SequencerDefs.h"
#include "SnibbeSoundInstance.h"
#include <iostream>
#include "SnibbeUtils.h"
#include "SSDSPEnvelope.h"


using namespace ss;
using namespace std;

// static
std::set<SequencerCell *> SequencerCell::allCells_;

//
//
void onCellInstanceComplete ( SnibbeSoundInstance * pInst )
{
    std::set<SequencerCell *>::iterator it;
    for ( it = SequencerCell::allCells_.begin(); it != SequencerCell::allCells_.end(); ++it )
    {     
        (*it)->onSoundInstanceComplete( pInst );
    }
}

//
//
SequencerCell::SequencerCell() : on_(false),
filePathDirty_( false ),
dirty_(false),
vol_(1.0),
soundInst_(0),
soundInstPrev_(0),
usePrevInstance_(true)
//muted_(false),
//muteFadeTime_( 0.1 )
{
    allCells_.insert( this );
}

//
// virtual
SequencerCell::~SequencerCell()
{
    if ( soundInst_ )
    {
        delete soundInst_;
    }
    
    
    if ( usePrevInstance_ && soundInstPrev_ )
    {
        delete soundInstPrev_;
    }
    
    allCells_.erase( allCells_.find( this ) );
}



//
// Called before the client schedules this - ensures the the sound is up to date and
// reflects the latest path
void SequencerCell::refreshSound( bool bStartPaused )
{

    if ( usePrevInstance_ )
    {
        if ( soundInstPrev_ )
        {
            soundInstPrev_->releaseChannel();
            delete soundInstPrev_;
            soundInstPrev_ = 0;
        }
        
        if ( soundInst_ )
        {
            soundInstPrev_ = soundInst_;
            soundInst_ = 0;
        }
    }
    else
    {
        if ( soundInst_ )
        {
            soundInst_->releaseChannel();
            delete soundInst_;
            soundInst_ = 0;
        }
        
    }
    
    if ( filePathDirty_ )
    {
        allocSoundInstance();
    }
            
        
    // if we don't have an instance...
    if ( !soundInst_ )
    {
        if ( !allocSoundInstance() )
        {
            return;
        }
    }
    
#if SEQUENCER_DEBUG    
    std::cout << "Refreshing cell" << std::endl;
#endif
    
    
    if ( !bStartPaused )
    {
        soundInst_->pause( false );
    }
    
    soundInst_->setVolume( vol_ );
    
//    if ( muted_ )
//    {
//        soundInst_->setVolume( 0.0f );
//    }


        
    
}

//
//
void SequencerCell::schedule( SeqTimeT absDSPTimeCur, SeqTimeT atAbsDSPSeconds, SeqTimeT maxJitter )
{
 
    refreshSound( true );
    
    if ( soundInst_ )
    {
        SeqTimeT jitterAmt = randFloat( -maxJitter, maxJitter );
        atAbsDSPSeconds += jitterAmt;
        
        
        Uint64P dspStartTime = ConvertMsToDSPTicks( atAbsDSPSeconds * 1000 );
     
        
#if SEQUENCER_DEBUG
        std::cout << "Scheduling cell at: " << atAbsDSPSeconds << std::endl;
#endif
        

        soundInst_->scheduleDelayedStart( dspStartTime );        
        soundInst_->pause( false );
        soundInst_->setVolume( vol_ );
        
        
        SeqTimeT soundLen = soundInst_->getSoundLength();
        SeqTimeT fadeLen = .03;
        SeqTimeT startFromNow = atAbsDSPSeconds - absDSPTimeCur;
        
        //SSDSPEnvelope * env = SSDSPEnvelopeSet::set().nextEnvelope();
        
        
        //printf( "decay start: %f, decay length: %f\n", timeDecayStart, decayLength );
        
        // this is needed because of a curious FMOD interaction between FMOD_DELAYTYPE_DSPCLOCK_START
        // and custom DSP callbacks - the dsp callback continues to fire even before the sound begins playing
        // causing our envelope calculation to be incorrect.  this corrects for that.
        //float deltaFromNowBeginSound = ConvertDSPTicksToMs( dspStartTime ) * .001 - realCurTime;
        
        float timeReleaseStartPlusStartDelta = soundLen-fadeLen + startFromNow;
        float timeAttackStartPlusStartDelta = startFromNow;
        
        
        //env->setEnvelope( timeAttackStartPlusStartDelta, fadeLen, timeReleaseStartPlusStartDelta, fadeLen );
        //soundInst_->getChannel()->addDSP( env->getDSP(), 0 );
        
        /*
        
        float soundLen = 0;
        FMOD::Channel * pChannel = instrument_->createChannel( iMidiNote, true, &soundLen );
        pChannel->setVolume( instrumentVol_ );
        
        float timeDecayStart = noteDur * .66;
        timeDecayStart = constrain<float>( timeDecayStart, minDecayStart_, maxDecayStart_ );
        
        float decayLength = noteDur * .33;
        decayLength = constrain<float>( decayLength, minDecayLen_, maxDecayLen_ );
        
        SnibbeSoundInstance * pNewInst = new SnibbeSoundInstance(pChannel, soundLen);
        SSDSPEnvelope * env = SSDSPEnvelopeSet::set().nextEnvelope();
        
        
        //printf( "decay start: %f, decay length: %f\n", timeDecayStart, decayLength );
        
        // this is needed because of a curious FMOD interaction between FMOD_DELAYTYPE_DSPCLOCK_START
        // and custom DSP callbacks - the dsp callback continues to fire even before the sound begins playing
        // causing our envelope calculation to be incorrect.  this corrects for that.
        //float deltaFromNowBeginSound = ConvertDSPTicksToMs( dspStartTime ) * .001 - realCurTime;
        float timeDecayStartPlusStartDelta = timeDecayStart + targetFromCurTime;
        
        
        
        
        
        env->setEnvelope( timeDecayStartPlusStartDelta, decayLength );
        pNewInst->getChannel()->addDSP( env->getDSP(), 0 );
        */
        
    }
    
    


}

//
//
void SequencerCell::update( SeqTimeT curTime, SeqTimeT deltaTime )
{
    if ( soundInst_ )
    {
        soundInst_->update( deltaTime );
    }
    
    if ( usePrevInstance_ && soundInstPrev_ )
    {
        soundInstPrev_->update( deltaTime );
    }
    
}

//
//
void SequencerCell::initFromPageData( SequencerPage::DataT& pageData, bool preserveOn )
{
    
    
    filePath_ = pageData.filePath_;
    filePathDirty_ = true;
    dirty_ = true;
    
    if ( soundInst_ )
    {
        // clear it
        //soundInst_ = shared_ptr<SnibbeSoundInstance>();
    }
    
    
    // should we create the instance immediately?  let's try no to conserve channels
    //allocSoundInstance();
    
    if ( !preserveOn )
    {
        on_ = pageData.on_;
    }
}


//
//
void SequencerCell::setOn( bool bOnOff )
{
    
    if ( bOnOff != on_ )
    {
        dirty_ = true;
    }
    
    on_ = bOnOff;

//    if ( !on_ )
//    {
//        if ( soundInst_.get() )
//        {
//            soundInst_->releaseChannel();
//        }
//    }
}
//
//
bool SequencerCell::canPlay() const
{    
    return ( ( soundInst_ || filePath_.size() > 0 ) && on_ );
}




//
//
void SequencerCell::onSoundInstanceComplete( SnibbeSoundInstance * pInst )
{
    if ( pInst == soundInst_ )
    {
        // this one's ours!
        
        //if ( !on_ )
        {            
            soundInst_->releaseChannel();
            delete soundInst_;
            soundInst_ = 0;
        }
        
    }
    else if ( usePrevInstance_ && pInst == soundInstPrev_ )
    {
        soundInstPrev_->releaseChannel();
        delete soundInstPrev_;
        soundInstPrev_ = 0;
    }
    
}

//
//
void SequencerCell::setVolume( float vol )
{
    vol_ = vol;
    if ( soundInst_ )
    {
        soundInst_->setVolume( vol_);
    }
    
    
    if ( usePrevInstance_ && soundInstPrev_  )
    {
        soundInstPrev_->setVolume( vol_ );
    }
}

void SequencerCell::stop()
{
    if ( soundInst_ && soundInst_->getChannel() )
    {
        soundInst_->getChannel()->stop();
    }

    if ( usePrevInstance_ && (soundInstPrev_ && soundInstPrev_->getChannel() ) )
    {
        soundInstPrev_->getChannel()->stop();
    }


}

    


//
//
bool SequencerCell::allocSoundInstance()
{
    bool bStreaming = true;
    bool bReturn = false;
    
    const string& path = (on_ || filePathSilent_.length() == 0 ) ? filePath_ : filePathSilent_;
    
    if ( path.length() > 0 )
    {        
        soundInst_ = new SnibbeSoundInstance( path, bStreaming, 1.0, 0, false );
        soundInst_->setInstanceCompleteCB( onCellInstanceComplete );
        soundInst_->setReleaseSoundOnDealloc( true );
        
//        if ( muted_ )
//        {
//            soundInst_->setVolume( 0.0f );
//        }
        
        bReturn = (bool) soundInst_;
    }
    
    filePathDirty_ = false;
    dirty_ = false;
    
    return bReturn;
}




