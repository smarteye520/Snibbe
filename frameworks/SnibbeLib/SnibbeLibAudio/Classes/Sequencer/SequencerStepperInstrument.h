//
//  SequencerStepperInstrument.h
//  SnibbeLib
//
//  Created by Graham McDermott on 1/7/13.
//  Copyright (c) 2013 Scott Snibbe Studio. All rights reserved.
//
//  SequencerStepperInstrument
//  --------------------------
//  a stepper sequencer derived class which gets its audio data based on a virtual instrument
//  rather than straight file names.
//  This class doesn't use the paging/groups visible approach that parent classes use b/c it's meant
//  to be used as a straight-up as-is step sequencer without paging through list of samples.


#ifndef __SnibbeLib__SequencerStepperInstrument__
#define __SnibbeLib__SequencerStepperInstrument__

#include "SequencerStepper.h"
#include <vector>

// forward declarations
class SnibbeInstrument;

namespace sc
{
    class SequencerStepperInstrumentXMLReader;
};

namespace ss
{
        

    class SequencerStepperInstrument : public SequencerStepper
    {
                
        
    public:
        
        class InstrumentAndNotes
        {
            
        public:
            InstrumentAndNotes();
            ~InstrumentAndNotes();
                        
            SnibbeInstrument * instrument_;
            std::vector<unsigned int> midiNotes_;
        };

        
        
        SequencerStepperInstrument();
        virtual ~SequencerStepperInstrument();
        
        virtual void init( unsigned int numAudioTracks, unsigned int numTimeSlots, SequencerPlaybackT playbackType );
        
        InstrumentAndNotes * addInstrument();
        void selectInstrument( int index );
        
    protected:
                
        virtual SequencerCell * allocCell();
        
        // owns instruments
        
                
        std::vector<InstrumentAndNotes *> instruments_;
        
        
        
    };

};

#endif /* defined(__SnibbeLib__SequencerStepperInstrument__) */
