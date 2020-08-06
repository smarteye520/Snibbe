//
//  Sequencer.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/13/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//
//  Sequencer
//  ----------
//  base class for audio sequencer classes.
//
//  - advance and load pages
//  - report total time for a given page and slot
//  - pause/restart
//  - monitor self to schedule sounds and advance pages if needed
//  - respond to interaction
//  - mute / unmute / set vol
//  - 
//

#ifndef __SnibbeLib__Sequencer__
#define __SnibbeLib__Sequencer__

#include "SequencerDefs.h"
#include <vector>
#include <string>
#include "SSTypeDefs.h"
#include "Uint64P.h"
#include <tr1/memory>
#include "SnibbeInterpolator.h"

class SSDSPClock;
class SnibbeSoundInstance;

namespace FMOD
{
    class ChannelGroup;
};

namespace ss
{

    class SequencerCell;
    class SequencerPage;
    
    class Sequencer
    {
        
    public:
        
        typedef enum
        {
            eNotPlaying = 0,
            ePlaying,
            eComplete
            //ePaused
        } StateT;
        
        Sequencer();
        virtual ~Sequencer();
        
        virtual void init( unsigned int numAudioTracks, unsigned int numTimeSlots, SequencerPlaybackT playbackType );
        virtual void initWithFiles( SequencerPlaybackT playbackType, const std::vector<std::string>& fileList, unsigned int numAudioTracks, unsigned int numTimeSlots, unsigned int numGroupsVisible = 1 );
        
        virtual void reset();
        virtual void update( SeqTimeT curTime, SeqTimeT deltaTime );
        
        void play( Uint64P startTimeDSP );
        void stop();
        //void pause( bool bPaused );
        
        void clear() { setAllCellsOn( false ); }
        
        void            setCurPage( int curPage );
        int             getCurPage() const { return curPage_; }
        int             getNumPages() const { return pages_.size(); }
        SequencerPage * addPage();
        SequencerPage * pageAtIndex( unsigned int iIndex );
        void            clearPages();        
        unsigned int    cellsPerPage() const { return numAudioTracks_ * numTimeSlots_; }
        SequencerCell * cellAt( int track, int slot );
        
        void setLoopPage( bool bLoop ) { loopPage_ = bLoop; }
        bool getLoopPage() const { return loopPage_; }
        
        // todo - callbacks for communication with clients
        
        void setCellDuration( SeqTimeT dur );
        int  getCurTimeSlot() const { return curTimeSlot_; }
        
        void setCellDurationMultiplier( float mult );
        float getCellDurationMultiplier() const { return cellDurMultiplier_; };
        
        void                setName( std::string& n ) { name_ = n; }
        const std::string&  getName() const { return name_; }
        
        void setSilentFile( std::string silentFileName );
        
        unsigned int getNumAudioTracks() const { return numAudioTracks_; }
        unsigned int getNumTimeSlots() const { return numTimeSlots_; }
        
        void setDSPClock( SSDSPClock * clock ) { dspClock_ = clock; }        
        
        void setVolume( float vol );
        float getVolume() const { return vol_; }
        

        void fadeCellChannelGroupLevelTo( float level, float duration );
        float getCellChannelGroupLevel() const;
        
        // interaction
        
        virtual bool toggleCellAt( unsigned int track, unsigned int slot );
        virtual void setDefaultCellPattern();
        
        void setExclusiveRows( bool b ) { exclusiveRows_ = b; }
        void playOneShot( unsigned int track, unsigned int slot );
        
    protected:
        
        virtual void loadPageAtIndex( unsigned int iIndex );
        virtual SequencerCell * allocCell();
        
        void clearCells();                
        void setAllCellsOn( bool bOn );
        bool usingSilentSound() const { return silentFileName_.length() > 0; }
        void setSilentSoundPathCells();
        
        // timing: common

        void    updateCurTimeSlot();
        
        // timing: discrete mode
        
        int     testAndScheduleDiscrete();
        void    scheduleSlotDiscrete( int slotIndex );
        void    computePageTimeScheduleDiscrete( SeqTimeT pageTimeBegin );
        void    updatePageTimeScheduleDiscrete();
        
        
        // timing: sentence mode
        void    testAndUpdateSentence();
        void    createSubSoundsSentence( int slotIndexMin, int slotIndexMax );
        
        
        
        SeqTimeT curTime_;
        SeqTimeT startTime_;
        
        // timing: discrete
        
        SeqTimeT curSequenceStartTime_;
        SeqTimeT audioScheduleLeadTime_;
        SeqTimeT * lastScheduledTimes_; // last scheduled time for each slot
        SeqTimeT * nextScheduledTimes_; // upcoming scheduled time for each slot
        
        // timing: sentence
        
        bool testAndLoadPageAtPageEnd_;
        int prevSubSentence_;
        SSDSPClock * dspClock_;
        
        
        std::tr1::shared_ptr<SnibbeSoundInstance> soundSentence_;
        //shared_ptr<SnibbeSoundInstance> silentInstance_;
        FMOD::ChannelGroup * channelGroupCells_;
        
        SnibbeInterpolator<float, SeqTimeT> interpChannelGroupVol_;
        
        SequencerPlaybackT playbackType_;
        
        SeqTimeT cellDur_;
        float    cellDurMultiplier_;
        SeqTimeT effectiveCellDur_;
        //unsigned int groupSize_;
        
        std::vector<SequencerPage *> pages_;
        //unsigned int slotsPerPage_;
        
        unsigned int numAudioTracks_;
        unsigned int numTimeSlots_;
        std::string silentFileName_;
        
        unsigned int numGroupsVisible_;
        
        std::vector< std::vector<SequencerCell *> * > cells_;
        std::string name_;

        int curPage_;
        int curTimeSlot_;
        int prevTimeSlot_;
        bool loopPage_;
        float vol_;
        bool exclusiveRows_;
        
        StateT state_;
        
    };
}


#endif /* defined(__SnibbeLib__Sequencer__) */
