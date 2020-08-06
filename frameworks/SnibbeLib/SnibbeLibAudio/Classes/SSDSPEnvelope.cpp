//
//  SSDSPEnvelope.cpp
//  SnibbeLib
//
//  Created by Graham McDermott on 9/17/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SSDSPEnvelope.h"
#include <assert.h>
#include "SnibbeAudioUtils.h"
#include <math.h>
#include <iostream.h>

////////////////////////////////////////////////////
// SSDSPEnvelope
////////////////////////////////////////////////////


//
//
SSDSPEnvelope::SSDSPEnvelope() :
    fadeFunc_( eFadeDefault )
{
    totalSamplesRead_ = 0;
    releaseTime_ = 0;
    releaseLen_ = 0;
    attackLen_ = 0;
    attackTime_ = 0;
}

//
//
void SSDSPEnvelope::initialize( unsigned int envelopeSetIndex )
{
            
    FMOD_DSP_DESCRIPTION dspdesc;
    memset(&dspdesc, 0, sizeof(FMOD_DSP_DESCRIPTION));
    
    strcpy(dspdesc.name, "Snibbe Volume Envelope");
    dspdesc.channels     = 0;                   // 0 = whatever comes in, else specify.
    dspdesc.read         = ssVolEnvelopeDSPCallback;
    dspdesc.userdata     = (void *)envelopeSetIndex;
    
    FMOD_RESULT result = GetFMODSystem()->createDSP(&dspdesc, &dsp_);
    ERRCHECK(result);
}

//
//
SSDSPEnvelope::~SSDSPEnvelope()
{
    dsp_->release();
}

//
//
void SSDSPEnvelope::setEnvelope( float releaseTime, float releaseLength /*, unsigned int samplesPerSecond */, FadeFunctionT fadeFunc )
{
    setEnvelope( 0, 0, releaseTime, releaseLength, fadeFunc );
}

//
//
void SSDSPEnvelope::setEnvelope( float attackTime, float attackLength, float releaseTime, float releaseLength, FadeFunctionT fadeFunc )
{
    // todo - consolidate these into a more fleshed out envelope struct (full adsr)
    
    attackTime_ = attackTime;
    attackLen_ = attackLength;
    releaseTime_ = releaseTime;
    releaseLen_ = releaseLength;
    
    fadeFunc_ = fadeFunc;
    
    samplesPerSecond_ = fmodSystemSampleRate;
    invSamplesPerSecond_ = 1.0f / samplesPerSecond_;
    
    numSamplesAttackLen_ = secondsToSamples( attackLen_ );
    numSamplesAtRelease_ = secondsToSamples( releaseTime_ );
    numSamplesAtAttack_ = secondsToSamples( attackTime_ );
    numSamplesReleaseLen_ = secondsToSamples( releaseLen_ );
    
    if ( numSamplesReleaseLen_ > 0 )
    {
        invNumSamplesReleaseLen_ = 1.0f / numSamplesReleaseLen_;
    }
    
    if ( numSamplesAttackLen_ > 0 )
    {
        invNumSamplesAttackLen_ = 1.0f / numSamplesAttackLen_;
    }
    
    //std::cout << "num samples at attack: " << numSamplesAtAttack_ << "\n";
    //std::cout << "num samples attack len: " << numSamplesAttackLen_ << "\n";
    //std::cout << "num samples at release: " << numSamplesAtRelease_ << "\n";
    //std::cout << "num samples release len: " << numSamplesReleaseLen_ << "\n";
    
}


void SSDSPEnvelope::augmentSampleCount( float secondsSampleDelta )
{
    unsigned int samplesToAugment = secondsToSamples( secondsSampleDelta );
    totalSamplesRead_ += samplesToAugment;
}

//
//
void SSDSPEnvelope::reset()
{
    totalSamplesRead_ = 0;
    
}


//
//
float SSDSPEnvelope::samplesToSeconds( unsigned int numSamples )
{ 
    return numSamples * invSamplesPerSecond_;
}

//
//
unsigned int SSDSPEnvelope::secondsToSamples( float seconds )
{
    return seconds * samplesPerSecond_;
}


///////////////////////////////////////////////////////////////////////////////
// Custom FMOD DSPs
///////////////////////////////////////////////////////////////////////////////


//static unsigned int totalSamplesProcessed = 0;
//static const int volEnvSampleRate = 22050;




// dsp callbacks
FMOD_RESULT SSDSPEnvelope::callback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels)
{
    
    
    
    //static unsigned int totalSamples = 0;
    //totalSamples += length;
    //printf( "total read: %d\n", totalSamplesRead_ );
    
    
    // we need to know what length of time this bit of data correlates to (even if we're slightly off with matching it up with the drum loop)
    
    //unsigned int    userdata    = 0;
    //char            name[256]   = {0};
    //FMOD::DSP      *thisdsp     = (FMOD::DSP *)dsp_state->instance;
    
    
    
    
    //float fToneFreq = 0.0f;
    //channelSynth_->getFrequency( &fToneFreq );
    
    // where are we in the sound time-wise?
    
    //Uint64P curTime;
    //curTime.assignNow();
    //curTime -= dspClockBegin_;
    
    //unsigned int elaspsedMS = ConvertDSPTicksToMS( curTime );
    
    //float timeChunkBegin = (float)totalSamplesRead_ / fmodSystemSampleRate;
    //float timeChunkEnd = timeChunkBegin + length / fmodSystemSampleRate;
    
    // use the value graph values, which should have already been set using the envelope
    //float valBegin = (float) valueGraph_[VOLUME_GRAPH_INDEX]->value(timeChunkBegin);  // 0-1
    //float valEnd = (float) valueGraph_[VOLUME_GRAPH_INDEX]->value(timeChunkEnd);  // 0-1
    
    
    unsigned int iSampleCountBegin = totalSamplesRead_;
    unsigned int iSampleCountEnd = totalSamplesRead_ + length;
    
    
    // This redundant call just shows using the instance parameter of FMOD_DSP_STATE and using it to
    // call a DSP information function.
    //thisdsp->getInfo(name, 0, 0, 0, 0);
    //thisdsp->getUserData((void **)&userdata);
    
    
    // This loop assumes inchannels = outchannels, which it will be if the DSP is created with '0'
    // as the number of channels in FMOD_DSP_DESCRIPTION.
    // Specifying an actual channel count will mean you have to take care of any number of channels coming in,
    // but outputting the number of channels specified.  Generally it is best to keep the channel
    // count at 0 for maximum compatibility.
    
    //float curMult = valBegin;
    //float deltaMult = (valEnd - valBegin) / length;
    

        
        
    unsigned int iCurSample = totalSamplesRead_ + 1;
    unsigned int numSamplesAtReleaseEnd = numSamplesAtRelease_ + numSamplesReleaseLen_;
    
    
    //std::cout << "addr: " << (unsigned int) this << "  dsp load, size: " << length << "\n";
    
    for (unsigned int sample = 0; sample < length; sample++ )
    {
        for (int chan = 0; chan < outchannels; chan++)
        {

            float progress = -1.0;
            float coef = 1.0f;
            
            if ( numSamplesAttackLen_ > 0 && iCurSample <= numSamplesAtAttack_ )
            {
                outbuffer[(sample * outchannels) + chan] = 0;
            }
            else if ( numSamplesAttackLen_ > 0 && iCurSample < numSamplesAtAttack_ + numSamplesAttackLen_ )
            {
                // within the attack                                
                progress = (iCurSample - numSamplesAtAttack_)  * invNumSamplesAttackLen_;
                coef = progress;
            }
            else if ( iCurSample < numSamplesAtRelease_ )
            {
                outbuffer[(sample * outchannels) + chan] = inbuffer[(sample * inchannels) + chan];                
                //printf( "%d, samples read: %d (0)\n", (unsigned int) this, totalSamplesRead_ );
                
            }
            
            else if ( iCurSample > numSamplesAtReleaseEnd )
            {
                //printf( "%d, samples read: %d (1)\n", (unsigned int) this, totalSamplesRead_ );
                outbuffer[(sample * outchannels) + chan] = 0;
            }
            else
            {
                // within the release                
                progress = (iCurSample - numSamplesAtRelease_) * invNumSamplesReleaseLen_;
                coef = 1.0f - progress;                                
            }
            
            
            if ( progress >= 0 )
            {
                // we're in the middle of an attack or release... apply
                // the desired
                
                switch ( fadeFunc_ )
                {
                        
                    case eFadeLinear:
                    {
                        break;
                    }
                    case eFadeConstantPower:
                    {
                        coef = 1.0 - coef;
                        coef = cosf( M_PI_2 * coef );
                        //coef = cosf( M_PI_2 * (1.0f - coef) );
                        
                        //std::cout << "addr: " << (unsigned int) this << "  cur sample: " << iCurSample << "  prog: " << progress << "  coef: " << coef << "\n";
                        
                        break;
                    }
                    default:
                    case eFadeDefault:
                    {
                        coef = coef * coef;
                        break;
                    }
                        
                        
                        
                }
                
                
                outbuffer[(sample * outchannels) + chan] = inbuffer[(sample * inchannels) + chan] * coef;
            }

            
                
        }
        
        ++iCurSample;
        
    }
    
    
        
    
    
    //for (unsigned int sample = 0; sample < length; sample++)
    //{
        
        //float valueCoef = 1.0f;
        

        
        
        
        
        
        // approximating an experienced linear volume adjustment (http://www.dr-lex.be/info-stuff/volumecontrols.html#table1)
        //float logVal = curMult;
        //float logVal = curMult * curMult * curMult;
        
        // float logVal = .001 * exp( 6.908 * curMult );
        // float logVal = curMult * curMult * curMult * curMult;
        
        // use a different approach for the lower end of the range (better transition to silence)
        //if ( curMult < .1 )
        //{
        //    logVal *= curMult*10;
        //}
        
      //  outbuffer[sample] = inbuffer[sample] * logVal;
        
        //curMult += deltaMult;
        
        
    //}
    
    
    totalSamplesRead_ += length;
    
    //std::cout << "addr: " << (unsigned int) this << "  total samples: " << totalSamplesRead_ << "\n";
    
    
    return FMOD_OK; 
}



//
//

FMOD_RESULT F_CALLBACK ssVolEnvelopeDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels)
{
    unsigned int    userdata    = 0;
    FMOD::DSP      *thisdsp     = (FMOD::DSP *)dsp_state->instance;
    
    
    thisdsp->getUserData((void **)&userdata);
    
    // userdata is the index of the envelope in the static set
    
    SSDSPEnvelope * pEnv = SSDSPEnvelopeSet::set().envelopeAt( userdata );
    if ( pEnv )
    {
        return pEnv->callback( dsp_state, inbuffer, outbuffer, length, inchannels, outchannels );
    }
    
    return FMOD_OK;
    
    
}


////////////////////////////////////////////////////
// SSDSPEnvelopeSet
////////////////////////////////////////////////////


//
// static
SSDSPEnvelopeSet SSDSPEnvelopeSet::msEnvelopeset;


//
//
SSDSPEnvelopeSet::SSDSPEnvelopeSet() :
numEnvelopes_(0),
lastEnvelopeIndex_(0)
{
    
}

//
//
SSDSPEnvelopeSet::~SSDSPEnvelopeSet()
{
    clear();
}

//
//
void SSDSPEnvelopeSet::setNumEnvelopes( unsigned int iNum )
{
    clear();
    
    numEnvelopes_ = iNum;
    for ( int i = 0; i < iNum; ++i )
    {        
        SSDSPEnvelope * pNewEnvelope = new SSDSPEnvelope();
        pNewEnvelope->initialize( i );
        envelopes_.push_back( pNewEnvelope );
    }
    

    lastEnvelopeIndex_ = 0;
    
    
}

//
// returns the LRU envelope after resetting it
SSDSPEnvelope * SSDSPEnvelopeSet::nextEnvelope()
{
    assert( numEnvelopes_ > 0 );
 
    ++lastEnvelopeIndex_;
    lastEnvelopeIndex_ %= numEnvelopes_;
    
    SSDSPEnvelope * pEnv = envelopes_[lastEnvelopeIndex_];
    pEnv->reset();
    
    //printf( "returning envelope index: %d\n", lastEnvelopeIndex_ );
    
    return pEnv;

}

//
//
SSDSPEnvelope * SSDSPEnvelopeSet::envelopeAt( unsigned int iIndex )
{
    if ( iIndex < numEnvelopes_ )
    {
        return envelopes_[iIndex];
    }
    
    return 0;
}

//
//
void SSDSPEnvelopeSet::clear()
{
    for ( int i = 0; i < envelopes_.size(); ++i )
    {
        delete envelopes_[i];
    }
    
    envelopes_.clear();
    numEnvelopes_ = 0;
}



