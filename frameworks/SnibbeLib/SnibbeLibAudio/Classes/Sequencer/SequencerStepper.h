//
//  SequencerStepper.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/14/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//
//  class SequencerStepper
//  -----------------------
//   Drum-machine like variant on sequencer.  Interaction involves toggling on/off
//   the individual audio cells


#ifndef __SnibbeLib__SequencerStepper__
#define __SnibbeLib__SequencerStepper__

#include "Sequencer.h"

namespace ss
{
    class SequencerStepper : public Sequencer
    {
        
    public:
        
        SequencerStepper();
        virtual ~SequencerStepper();
        
        virtual void initWithFiles( SequencerPlaybackT playbackType, const std::vector<std::string>& fileList, unsigned int numAudioTracks, unsigned int numTimeSlots, unsigned int numGroupsVisible = 1 );
                
        virtual void setDefaultCellPattern() { setAllCellsOn(false); }
        
    protected:
        
        
        
        
        
    };
}

#endif /* defined(__SnibbeLib__SequencerStepper__) */
