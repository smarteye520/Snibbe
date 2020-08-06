//
//  SequencerCellInstrument.cpp
//  SnibbeLib
//
//  Created by Graham McDermott on 1/7/13.
//  Copyright (c) 2013 Scott Snibbe Studio. All rights reserved.
//

#include "SequencerCellInstrument.h"
#include "SnibbeInstrument.h"
#include "SnibbeSoundInstance.h"
#include <iostream>


using namespace ss;
using namespace std;

//
//
SequencerCellInstrument::SequencerCellInstrument() :
instrument_(0)
{
    usePrevInstance_ = false;
}

//
// virtual
SequencerCellInstrument::~SequencerCellInstrument()
{
    
}

//
//
void SequencerCellInstrument::setInstrument( SnibbeInstrument * instrument )
{
    instrument_ = instrument;
    filePathDirty_ = true;
    
}

//
// virtual
void SequencerCellInstrument::schedule(  SeqTimeT absDSPTimeCur, SeqTimeT atAbsDSPSeconds, SeqTimeT maxJitter )
{
    SequencerCell::schedule( absDSPTimeCur, atAbsDSPSeconds, maxJitter );
    
    
    
    
    if ( soundInst_ )
    {
        float channelFrequency = 0;
        FMOD_RESULT r = soundInst_->getChannel()->getFrequency(&channelFrequency);
        ERRCHECK(r);        
        soundInst_->getChannel()->setFrequency( powf(2.0f,pitchShift_/12.0f) * channelFrequency );
    }
  
    
}
//
// virtual
void SequencerCellInstrument::initFromPageData( SequencerPage::DataT& pageData, bool preserveOn )
{
    SequencerCell::initFromPageData( pageData, preserveOn);
    //midiNote_ = pageData.midiNote_;
    
    // do nothing!  this type doesn't use paging
    
}

//
//
void SequencerCellInstrument::setMidiNote( unsigned int note )
{
    midiNote_ = note;
    filePathDirty_ = true;
}

//
// virtual
bool SequencerCellInstrument::SequencerCellInstrument::canPlay() const
{ 
    return on_ && instrument_;
}

//
// virtual
bool SequencerCellInstrument::allocSoundInstance()
{
    bool bStreaming = true;
    bool bReturn = false;
    
    if ( instrument_ )
    {
        
        const SnibbeInstrumentSample * sample = instrument_->getSampleForNote( midiNote_ );
        if ( sample )
        {
            const string& path = (on_ || filePathSilent_.length() == 0 ) ? sample->sampleSoundPath : filePathSilent_;
        
            if ( path.length() > 0 )
            {
                soundInst_ = new SnibbeSoundInstance( path, bStreaming, 1.0, 0, false );
                soundInst_->setInstanceCompleteCB( onCellInstanceComplete );
                soundInst_->setReleaseSoundOnDealloc( true );
                
                pitchShift_ = midiNote_ - sample->samplePitch;
                
                //std::cout << "allocating cell midi: " << midiNote_ << "pitch shift: " << pitchShift_ << "using sound: " << sample->sampleSoundPath << "\n";
                
                bReturn = (bool) soundInst_;
            }
            
            filePathDirty_ = false;
            dirty_ = false;
            
        }
        
    }    
    
    return bReturn;
}

