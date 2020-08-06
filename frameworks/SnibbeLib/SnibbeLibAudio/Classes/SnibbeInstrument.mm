//
//  SnibbeInstrument.mm
//  SnibbeLib
//
//  Created by Graham McDermott on 5/7/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SnibbeInstrument.h"
#include "SnibbeAudioUtils.h"
#include <iostream.h>


//
//
SnibbeInstrument::SnibbeInstrument( FMOD::System * sys, int semitonesMaxShiftLower, int semitonesMaxShiftHigher ) :
    sys_(sys),
    semitonesMaxShiftLower_( semitonesMaxShiftLower ),
    semitonesMaxShiftHigher_( semitonesMaxShiftHigher),
    allowPitchShift_( true )
{
    
}

//
//
SnibbeInstrument::~SnibbeInstrument()
{
    clear();
}


// Register a sample for this instrument at a given midi pitch value.  The sample at
// the given path is loaded into a FMOD sound for later playback
//
// Note: this method should be called in ascending order from low midi pitch to high
void SnibbeInstrument::addSample( int midiVal, const char * filePath )
{
    
    if ( filePath )
    {
        
        SnibbeInstrumentSample newSample;
        newSample.samplePitch = midiVal;
        newSample.sampleSoundPath = std::string( filePath );
        newSample.sampleRange = std::pair<int, int>( midiVal - semitonesMaxShiftLower_, midiVal + semitonesMaxShiftHigher_ );                
        FMOD_RESULT result = sys_->createSound(filePath, FMOD_CREATESAMPLE | FMOD_SOFTWARE, NULL, &newSample.sampleSound);			
        ERRCHECK(result);	
        
        samples_.push_back(newSample);
        
        int iNumSamples = samples_.size();
        for ( int i = 0; i < iNumSamples-1; ++i )
        {
            if ( samples_[i].samplePitch >= samples_[i+1].samplePitch )
            {
                printf( "Error: SnibbeInstrument::addSample should be called in ascending pitch order!\n" );
                assert(0);
            }
        }
        
        // adjust the pitch range with previous sound so that they meet and agree without overlapping
        if ( iNumSamples > 1 )
        {
            SnibbeInstrumentSample & cur = samples_[iNumSamples-1];
            SnibbeInstrumentSample & prev = samples_[iNumSamples-2];
            
            int rangeBetween = cur.samplePitch - prev.samplePitch;
            if ( rangeBetween <= 1 )
            {
                // no dist between
                cur.sampleRange.first = cur.samplePitch;
                prev.sampleRange.second = prev.samplePitch;
            }
            if ( rangeBetween % 2 == 0 )
            {
                // even difference meaning an odd number of notes between
                
                int pitchAdjustMore = (rangeBetween) / 2;
                int pitchAdjustLess = pitchAdjustMore - 1;
                
                cur.sampleRange.first = cur.samplePitch - pitchAdjustLess;
                prev.sampleRange.second = prev.samplePitch + pitchAdjustMore;
            }
            else
            {
                int pitchAdjust = (rangeBetween - 1) / 2;
                cur.sampleRange.first = cur.samplePitch - pitchAdjust;
                prev.sampleRange.second = prev.samplePitch + pitchAdjust;
            }
            
        }
       
    }
        
}

//
//
void SnibbeInstrument::clear()
{
    int iNumSamples = samples_.size();
    for ( int iS = 0; iS < iNumSamples; ++iS )
    {
        if ( samples_[iS].sampleSound )
        {
            samples_[iS].sampleSound->release();
        }
    }
 
    samples_.clear();
}

//
// object relinquishes control of channel to client - client responsible for freeing
FMOD::Channel * SnibbeInstrument::createChannel(int midiVal, bool bPaused, float *length)
{
    FMOD::Channel * c = 0;
    int pitchShift = 0;
		unsigned int iLen = 0;
    
    SnibbeInstrumentSample * sample = sampleForNote( midiVal );
    if ( sample )
    {
        pitchShift = midiVal - sample->samplePitch;
        FMOD_RESULT r = sys_->playSound( FMOD_CHANNEL_FREE, sample->sampleSound, bPaused, &c );
        ERRCHECK( r );
        sample->sampleSound->getLength( &iLen, FMOD_TIMEUNIT_MS );        

    }
    
    
    
    // the allowPitchShift_ is sort of a hack for a quick shortcut on the Magnetism prototype.
    // really we should be mapping to scales
    
    if ( c && allowPitchShift_ )
    {
        float channelFrequency = 0;
        FMOD_RESULT r = c->getFrequency(&channelFrequency);
        ERRCHECK(r);                
        c->setFrequency( powf(2.0f,pitchShift/12.0f) * channelFrequency );

    }
	
	if (length != NULL) {
		*length = iLen * .001f;
	}

    return c;    
    
    
}


//
//
void SnibbeInstrument::debugOutSamples()
{
    int iNumSamples = samples_.size();
    for ( int iS = 0; iS < iNumSamples; ++iS )
    {
        
        float soundLen = 0.0f;        
        unsigned int iLen = 0;
        
        if ( samples_[iS].sampleSound )
        {        
            samples_[iS].sampleSound->getLength( &iLen, FMOD_TIMEUNIT_MS );         
            soundLen = iLen * .001f;
        }
        
        printf ( "%d. midi: %d, pitch min: %d, pitch max: %d, sound len: %.2f\n", iS, samples_[iS].samplePitch, samples_[iS].sampleRange.first, samples_[iS].sampleRange.second, soundLen );

    }
}

//
//
SnibbeInstrumentSample * SnibbeInstrument::sampleForNote( int midiVal )
{
    int iNumSamples = samples_.size();
    if ( iNumSamples > 0 )
    {
        if ( midiVal < samples_[0].sampleRange.first )
        {
            return &samples_[0];
        }
        else if ( midiVal > samples_[iNumSamples-1].sampleRange.second )
        {
            return &samples_[iNumSamples-1];            
        }
    }
    

    
    for (int iSample = 0; iSample < iNumSamples; ++iSample )
    {
        SnibbeInstrumentSample *curSample = &samples_[iSample];
                
        if ( midiVal >= curSample->sampleRange.first && midiVal <= curSample->sampleRange.second )
        {
            return curSample;                                    
        }
    }
    
    
    return 0;
}

