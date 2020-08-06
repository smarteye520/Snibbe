//
//  SnibbeInstrument.h
//  SnibbeLib
//
//  Created by Graham McDermott on 5/7/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//
//  class SnibbeInstrument
//  -----------------------
//  Represents a virtual instrument implemented as a collection of audio samples
//  at pitch intervals.
//  Implemented using FMOD.
// 
//  Able to generate and return FMOD Channel objects at a desired MIDI pitch.
//



#ifndef SnibbeLib_SnibbeInstrument_h
#define SnibbeLib_SnibbeInstrument_h

#import "fmod.hpp"
#include <vector>
#include <string>

// for a given note n, mapping notes n-1 -> n+2 to to pitch shift to it.
// assuming that pitching up is favorable over pitching down in terms of 
// artifacts.  If this isn't the case we can change to n-2 -> n+1.

#define SEMITONES_MAX_SHIFT_LOWER 1
#define SEMITONES_MAX_SHIFT_HIGHER 2



struct SnibbeInstrumentSample
{
	int samplePitch;
	FMOD::Sound * sampleSound;
	std::pair<int, int> sampleRange;
    std::string sampleSoundPath;
};




class SnibbeInstrument
{
  
public:
    
    SnibbeInstrument( FMOD::System * sys, int semitonesMaxShiftLower = SEMITONES_MAX_SHIFT_LOWER, int semitonesMaxShiftHigher = SEMITONES_MAX_SHIFT_HIGHER);
    ~SnibbeInstrument();
    
    void addSample( int midiVal, const char * filePath );
    void clear();
    
    FMOD::Channel * createChannel( int midiVal, bool bPaused, float *length = NULL); // object relinquishes control of channel to client - client responsible for freeing
    const SnibbeInstrumentSample * getSampleForNote( int midiVal ) { return sampleForNote( midiVal ); } // public version of method with const return
    
    void setAllowPitchShift( bool b ) { allowPitchShift_ = b; }
    void debugOutSamples();
    
private:
    
    SnibbeInstrumentSample * sampleForNote( int midiVal );
    
    std::vector<SnibbeInstrumentSample> samples_;
    int semitonesMaxShiftLower_;
    int semitonesMaxShiftHigher_;
    
    FMOD::System * sys_;  // cached reference to the FMOD sys (doesn't own)
    bool allowPitchShift_;
};


#endif
