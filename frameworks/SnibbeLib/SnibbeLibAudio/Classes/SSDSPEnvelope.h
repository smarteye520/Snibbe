//
//  SSDSPEnvelope.h
//  SnibbeLib
//
//  Created by Graham McDermott on 9/17/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef __SnibbeLib__SSDSPEnvelope__
#define __SnibbeLib__SSDSPEnvelope__

#include "fmod.h"
#include "fmod.hpp"
#include <vector>

// global callback
FMOD_RESULT F_CALLBACK ssVolEnvelopeDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels);





////////////////////////////////////////////////////
// SSDSPEnvelope
////////////////////////////////////////////////////


//
//
class SSDSPEnvelope
{
    
public:
    
    typedef enum
    {
        eFadeDefault = 0,
        eFadeLinear,
        eFadeConstantPower
    } FadeFunctionT;
    
     
    SSDSPEnvelope();
    ~SSDSPEnvelope();
    
    void initialize( unsigned int envelopeSetIndex );
    
    void setEnvelope( float releaseTime, float releaseLength /*, unsigned int samplesPerSecond */, FadeFunctionT fadeFunc = eFadeDefault );
    void setEnvelope( float attackTime, float attackLength, float releaseTime, float releaseLength, FadeFunctionT fadeFunc = eFadeDefault );
    
    void augmentSampleCount( float secondsSampleDelta );
    
    void reset();
    
    FMOD::DSP * getDSP() { return dsp_; }
    
    FMOD_RESULT callback( FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels );
    
    
private:        
    
    
    float samplesToSeconds( unsigned int numSamples );
    unsigned int secondsToSamples( float seconds );
    
    FMOD::DSP * dsp_;
    
    // can calculate place in sound by number of samples that have been read so far.. though that breaks if setPos or similar is used
    
    unsigned int totalSamplesRead_;
    unsigned int samplesPerSecond_;
    float invSamplesPerSecond_;
    
    float attackLen_;
    float releaseTime_;
    float attackTime_;
    float releaseLen_;
    
    
    unsigned int numSamplesAtRelease_;
    unsigned int numSamplesReleaseLen_;
    unsigned int numSamplesAtAttack_;
    unsigned int numSamplesAttackLen_;
    float        invNumSamplesAttackLen_;
    float        invNumSamplesReleaseLen_;
    
    FadeFunctionT fadeFunc_;
    
    
    
    
};


////////////////////////////////////////////////////
// SSDSPEnvelopeSet
////////////////////////////////////////////////////


//
//
class SSDSPEnvelopeSet
{
    
public:
    
    SSDSPEnvelopeSet();
    ~SSDSPEnvelopeSet();
    
    void setNumEnvelopes( unsigned int iNum );
    void clear();
    
    SSDSPEnvelope * nextEnvelope(); // returns the LRU envelope
    SSDSPEnvelope * envelopeAt( unsigned int iIndex );
    
    static SSDSPEnvelopeSet& set() { return msEnvelopeset; }
    
private:
    

    static SSDSPEnvelopeSet msEnvelopeset;
    
    
    
    std::vector<SSDSPEnvelope *> envelopes_;
    int lastEnvelopeIndex_;
    unsigned int numEnvelopes_;
    
};


#endif /* defined(__SnibbeLib__SSDSPEnvelope__) */
