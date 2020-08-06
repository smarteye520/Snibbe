//
//  SequencerCellInstrument.h
//  SnibbeLib
//
//  Created by Graham McDermott on 1/7/13.
//  Copyright (c) 2013 Scott Snibbe Studio. All rights reserved.
//

#ifndef __SnibbeLib__SequencerCellInstrument__
#define __SnibbeLib__SequencerCellInstrument__

#include "SequencerCell.h"

// forward declarations
class SnibbeInstrument;

namespace ss
{
    class SequencerCellInstrument : public SequencerCell
    {
        
    public:
        
        SequencerCellInstrument();
        virtual ~SequencerCellInstrument();
        
        virtual void schedule(  SeqTimeT absDSPTimeCur, SeqTimeT atAbsDSPSeconds, SeqTimeT maxJitter = 0 );
        virtual void initFromPageData( SequencerPage::DataT& pageData, bool preserveOn = true );
        
        void setInstrument( SnibbeInstrument * instrument );
        void setMidiNote( unsigned int note );        
        
        virtual bool canPlay() const;
        
    protected:
        
        virtual bool allocSoundInstance();
        
        int midiNote_;
        int pitchShift_;
        
        // doesn't assume ownership of this
        SnibbeInstrument * instrument_;
        
        
    };

};


#endif /* defined(__SnibbeLib__SequencerCellInstrument__) */
