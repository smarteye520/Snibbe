//
//  SequencerStepperInstrument.cpp
//  SnibbeLib
//
//  Created by Graham McDermott on 1/7/13.
//  Copyright (c) 2013 Scott Snibbe Studio. All rights reserved.
//

#include "SequencerStepperInstrument.h"
#include "SequencerCellInstrument.h"
#include "SequencerPage.h"
#include "SnibbeInstrument.h"
#include "SnibbeAudioUtils.h"
#include <assert.h>


using namespace ss;

//
//
SequencerStepperInstrument::InstrumentAndNotes::InstrumentAndNotes()
{
    instrument_ = new SnibbeInstrument( GetFMODSystem(), 10, 10 );
}

//
//
SequencerStepperInstrument::InstrumentAndNotes::~InstrumentAndNotes()
{
 
    delete instrument_;
}


SequencerStepperInstrument::SequencerStepperInstrument()
{
    
}

//
// virtual
SequencerStepperInstrument::~SequencerStepperInstrument()
{
    
    for ( int i = 0; i < instruments_.size(); ++i )
    {
        delete instruments_[i];
    }
}

//
// virtual
void SequencerStepperInstrument::init( unsigned int numAudioTracks, unsigned int numTimeSlots, SequencerPlaybackT playbackType )
{
    
    assert( playbackType == eSeqDiscrete );
    
    // for instrument stepper, one midi note per track
    unsigned int effectiveTimeSlots = numTimeSlots;
    
    numGroupsVisible_ = 1;
    
    Sequencer::init( numAudioTracks, effectiveTimeSlots, eSeqDiscrete );
    
    
    // this style of sequencer doesn't use data pages for now
    
    
    // create the single dummy data page for this type of sequencer
    // this type doesn't use this mechanism but we make one anyway so it
    // plays nice like a regular sequencer
    
    SequencerPage * page = addPage();
    
    for ( int iTimeSlot = 0; iTimeSlot < numTimeSlots; ++iTimeSlot )
    {
        for ( int iTrack = 0; iTrack < numAudioTracks; ++iTrack )
        {
            SequencerPage::DataT& cellData = page->dataAt( iTrack, iTimeSlot );
            cellData.on_ = true;                        
            
        }
    }

    setDefaultCellPattern();

    
}

//
//
SequencerStepperInstrument::InstrumentAndNotes * SequencerStepperInstrument::addInstrument()
{
            
    InstrumentAndNotes * instAndNotes = new InstrumentAndNotes();
    instruments_.push_back( instAndNotes );
    return instAndNotes;
    
}

//
//
void SequencerStepperInstrument::selectInstrument( int index )
{
    if ( index >= 0 && index < instruments_.size() )
    {        
    
        InstrumentAndNotes& iAndN = *instruments_[index];
        
        for ( int iTrack = 0; iTrack < numAudioTracks_; ++iTrack )
        {
            for ( int iSlot = 0; iSlot < numTimeSlots_; ++iSlot )
            {
                // temp
                SequencerCell * pC = cellAt( iTrack, iSlot );
                
                SequencerCellInstrument * pCell = (SequencerCellInstrument *) cellAt( iTrack, iSlot );
                pCell->setInstrument( iAndN.instrument_ );
                pCell->setMidiNote( iAndN.midiNotes_[iTrack] );
            }
        }
    }

}

// virtual
// Allocate and initialize the type of cell used by the concrete type of this Sequencer
SequencerCell * SequencerStepperInstrument::allocCell()
{
    // default
    return new SequencerCellInstrument();
    
}
