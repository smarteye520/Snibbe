//
//  SequencerOverride.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/29/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef __SnibbeLib__SequencerOverride__
#define __SnibbeLib__SequencerOverride__

#include "Sequencer.h"
#include <set>
#include <vector>
#include "SnibbeInterpolator.h"
#include <tr1/memory>

namespace ss
{
    class SequencerOverride : public Sequencer
    {
        
    public:
        
        SequencerOverride();
        virtual ~SequencerOverride();
        
        virtual void initWithFiles( SequencerPlaybackT playbackType, const std::vector<std::string>& fileList, unsigned int numTimeSlots );
        virtual void update( SeqTimeT curTime, SeqTimeT deltaTime );
        
        
        void onOverrideBegin( int slotIndex );
        void onOverrideEnd( int slotIndex );
        
        void getOverrideLevels( std::vector<float>& outLevels );
        
        int overrideCount() const { return overrides_.size(); }
        
    protected:
        
        
        class OverrideAudio
        {
            
        public:
            int slotIndex_;            
        };

        
        std::tr1::shared_ptr<OverrideAudio> findOverrideForIndex( int slotIndex );
        void removeOverrideForIndex( int slotIndex );
        
        std::set< std::tr1::shared_ptr<OverrideAudio> > overrides_;
        SnibbeInterpolator<float, SeqTimeT> interpChannelGroupLevel_;
        
        float timeUntilChannelGroupVolRestore_;
        bool  pendingChannelGroupVolRestore_;
    };
}
#endif /* defined(__SnibbeLib__SequencerOverride__) */
