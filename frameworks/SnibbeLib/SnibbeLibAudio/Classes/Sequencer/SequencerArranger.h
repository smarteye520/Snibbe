//
//  SequencerArranger.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/14/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//
//  class SequencerArranger
//  -----------------------
//  Rearraging variant on sequencer.  Interaction involves re-arranging a grid of
//  cells to play back in a particular order, or more specifically selecting the particular
//  audio segment to play back at a given time


#ifndef __SnibbeLib__SequencerArranger__
#define __SnibbeLib__SequencerArranger__

#include "Sequencer.h"


namespace ss
{
    class SequencerArranger : public Sequencer
    {
        
    public:
        
        SequencerArranger();
        virtual ~SequencerArranger();
        
        virtual void initWithFiles( SequencerPlaybackT playbackType, const std::vector<std::string>& fileList, unsigned int numAudioTracks, unsigned int numTimeSlots, unsigned int numGroupsVisible = 1 );
        
       
        virtual void setDefaultCellPattern() { setCellPatternLinear(); }
        
        virtual bool toggleCellAt( unsigned int track, unsigned int slot );
        
    protected:
                
        void setCellPatternLinear();
        
        
        
    };
}

#endif /* defined(__SnibbeLib__SequencerArranger__) */
