//
//  Sequencer.cpp
//  SnibbeLib
//
//  Created by Graham McDermott on 11/13/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "Sequencer.h"
#include "SequencerPage.h"
#include "SequencerCell.h"
#include <assert.h>
#include <iostream.h>
#include "SSDSPClock.h"
#include "SnibbeAudioUtils.h"
#include "SnibbeSoundInstance.h"
#include <sstream>

using namespace ss;
using namespace std;



#pragma mark public methods

static int numSequencers = 0;

//
//
Sequencer::Sequencer() :
    numAudioTracks_( 0 ),
    numTimeSlots_( 0 ),
    curTimeSlot_(-1),
    cellDur_( 1.0f ),
    curTime_(0),
    curPage_(-1),
    lastScheduledTimes_(0),
    nextScheduledTimes_(0),
    loopPage_( false ),
    audioScheduleLeadTime_( 1.0 ),
    dspClock_(0),
    state_( eNotPlaying ),
    vol_(1.0),
    playbackType_( eSeqDiscrete ),
    exclusiveRows_(false),
    cellDurMultiplier_(1.0),
    effectiveCellDur_(1.0)
{
   
    ++numSequencers;
    std::stringstream ss;
    ss << numSequencers;
    string strGroupName = string("group sequencer ") + ss.str();
    
    FMOD_RESULT r = GetFMODSystem()->createChannelGroup( strGroupName.c_str(), &channelGroupCells_ );
    ERRCHECK( r );
    
    interpChannelGroupVol_.setValue( 1.0 );
}


//
// virtual
Sequencer::~Sequencer()
{

    channelGroupCells_->release();
    clearPages();
    clearCells();
}


// virtual
// Resets the state of the cells by reading in page data
void Sequencer::reset()
{
    // default nothing?
    
    // todo... read from page... reset audio
    
    if ( curPage_ >= 0 )
    {
        loadPageAtIndex( curPage_ );
    }
}

//
// virtual
void Sequencer::update( SeqTimeT curTime, SeqTimeT deltaTime )
{
    
    dspClock_->update();
    
    //std::cout << "cur time slot: " << curTimeSlot_ << "\n";
    
    if ( state_ == eComplete )
    {
        // nothing more to update
        printf("warning, sequencer playback completed.  Skipping scheduling...\n" );
    }
    
    if ( state_ != ePlaying )
    {
        return;
    }
    
    //curTime_ = curTime;
    curTime_ = dspClock_->absoluteDSPTime();
    
    
    
    
#if SEQUENCER_DEBUG
    //std::cout << "cur time: " << curTime_ << "\n";
#endif
    
    
    // update each cell
    for ( int i = 0; i < cells_.size(); ++i )
    {
        std::vector<SequencerCell *> * cellsColumn = cells_[i];
        for ( int j = 0; j < cellsColumn->size(); ++j )
        {
            (*cellsColumn)[j]->update( curTime_, dspClock_->frameTime() );
        }
    }
    
    if ( playbackType_ == eSeqSentence )
    {
        if ( curTimeSlot_ != numTimeSlots_ - 1 )
        {
            testAndLoadPageAtPageEnd_ = true;
        }
        
        
        // todo
    }
    
    
    
    interpChannelGroupVol_.update( curTime );
    channelGroupCells_->setVolume( interpChannelGroupVol_.curVal() );
    
    
    // update curTimeSlot... the slot begins with the sounding of the slot's audio
    // samples and ends when the next slot plays
    
    updateCurTimeSlot();
    
    if ( curTimeSlot_ < 0 )
    {
        return;
    }
    
    
    // are we on the final cell of the page after it has been scheduled?
    bool testLoadPage = false;
    
    if ( playbackType_ == eSeqSentence )
    {
        testLoadPage = curTimeSlot_ == numTimeSlots_ - 1 &&
        testAndLoadPageAtPageEnd_;
    }
    else if ( playbackType_ == eSeqDiscrete )
    {
        testLoadPage = curTimeSlot_ == numTimeSlots_ - 1 &&
        curSequenceStartTime_ < curTime_;
    }
    
    
    if ( testLoadPage )
    {
        
        // do we need to load a new page of audio samples?
        if ( !loopPage_ )
        {
            //  we advance it if not looping
            
            if ( curPage_ < pages_.size() )
            {
                curPage_++;
                loadPageAtIndex( curPage_ );
            }
            else
            {
                // done!
                // what to do? don't increment page
                
                state_ = eComplete;
                curPage_ = 0;                
                
            }
            
        }
        
        if ( playbackType_ == eSeqDiscrete )
        {
            // compute the timing for the upcoming page
            
            // test new method            
            computePageTimeScheduleDiscrete( lastScheduledTimes_[numTimeSlots_-1] + effectiveCellDur_ );
            
            //computePageTimeScheduleDiscrete( curSequenceStartTime_ + numTimeSlots_ * cellDur_ );
        }
        else if ( playbackType_ == eSeqSentence )
        {
            testAndLoadPageAtPageEnd_ = false;
        }
        
        
        
    }

    if ( playbackType_ == eSeqDiscrete )
    {
        testAndScheduleDiscrete();
    }
    else if ( playbackType_ == eSeqSentence )
    {
        testAndUpdateSentence();
    }
    
    prevTimeSlot_ = curTimeSlot_;
    
}

//
//
void Sequencer::play( Uint64P startTimeDSP )
{
    if ( state_ == eNotPlaying )
    {
        // kick it off for the first time
        
        assert( pages_.size() > 0 );
        
        if ( playbackType_ == eSeqDiscrete )
        {
            // only in discrete mode have we not loaded the initial page yet
            if ( curPage_ < 0 )
            {
                curPage_ = 0;
            }
            
            reset();
            

            
            // start time of first sound
            
            SeqTimeT absDSPTime = SSDSPClock::clock().absoluteDSPTime();
            SeqTimeT delta = ConvertDSPTicksToMs( startTimeDSP ) * .001 - absDSPTime;
            
            curTime_ = dspClock_->absoluteDSPTime();
            std::cout << "cur time: " << curTime_ << "\n";
            
            startTime_ = curTime_ + delta;
            computePageTimeScheduleDiscrete( startTime_ );

        }
        else if ( playbackType_ == eSeqSentence )
        {
            
            
            
            
            // create the master sound            
            // Set up the FMOD_CREATESOUNDEXINFO structure for the user stream with room for 2 subsounds (our subsound double buffer)
            
            
            FMOD_CREATESOUNDEXINFO  exinfo      = {0};
            memset(&exinfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));
            exinfo.cbsize           = sizeof(FMOD_CREATESOUNDEXINFO);
            exinfo.defaultfrequency = 44100;
            exinfo.numsubsounds     = numTimeSlots_;
            exinfo.numchannels      = 2;
            exinfo.format           = FMOD_SOUND_FORMAT_PCM16;
            
            
            // Create the 'parent' stream that contains the substreams.  Set it to loop so that it loops between subsound 0 and 1
            
            FMOD::Sound * s = 0;
            FMOD_RESULT result = GetFMODSystem()->createStream(NULL, FMOD_LOOP_NORMAL | FMOD_OPENUSER, &exinfo, &s);
            ERRCHECK(result);
            
            soundSentence_ = std::tr1::shared_ptr<SnibbeSoundInstance>( new SnibbeSoundInstance( s, vol_, 0.0, false ) );
            soundSentence_->pause( true );
            
            // set up the sentence array that will guide the seamless sound playback
            
            int soundList[256]; // max sounds
            assert ( sizeof( soundList ) / sizeof( soundList[0] ) > numTimeSlots_ );
            
            for ( int i = 0; i < numTimeSlots_; ++i )
            {
                soundList[i] = i;
            }
            
            result = s->setSubSoundSentence(soundList, numTimeSlots_);
            ERRCHECK(result);
            
            // in this mode we need to load page 0 right away
            loadPageAtIndex( 0 );
            
            // next we need to seed sounds for all the slots in the sentence
            createSubSoundsSentence( 0, numTimeSlots_-1 );
            

            
            // test

            soundSentence_->scheduleDelayedStart( startTimeDSP );
            soundSentence_->pause( false );
            

            SeqTimeT absDSPTime = SSDSPClock::clock().absoluteDSPTime();
            SeqTimeT delta = ConvertDSPTicksToMs( startTimeDSP ) * .001 - absDSPTime;
            curSequenceStartTime_ = absDSPTime + delta;
            
            testAndLoadPageAtPageEnd_ = true;
            
            curTimeSlot_ = 0;
            prevTimeSlot_ = 0;
            prevSubSentence_ = 0;
            
            
        }
        

        
        state_ = ePlaying;
        
    }
    

}

//
// stop, don't change cur page
void Sequencer::stop()
{
    if ( state_ == ePlaying )
    {
        for ( int iTrack = 0; iTrack < numAudioTracks_; ++iTrack )
        {
            for ( int iSlot = 0; iSlot < numTimeSlots_; ++iSlot )
            {
                SequencerCell * pCell = cellAt( iTrack, iSlot );
                pCell->stop();
            }
        }

        state_ = eNotPlaying;
    }
}

//
// Stop playback with the intention of restarting
//void Sequencer::pause( bool bPaused )
//{
//    // todo
//    
//}



void Sequencer::setCurPage( int curPage )
{
    assert( curPage >= 0 && curPage < pages_.size() );
    
    curPage_ = curPage;
    
    // todo - will this do everything that's needed for audio?
    loadPageAtIndex( curPage_  );
}

//
//
SequencerPage * Sequencer::addPage()
{
    
    if ( numAudioTracks_ == 0 ||
         numTimeSlots_ == 0 )
    {
        std::cout << "Error, cannot add sequencer page without initializing sequencer first\n";
        return 0;
    }
    
    SequencerPage * newPage = new SequencerPage();
    newPage->init( numAudioTracks_, numTimeSlots_ );
    pages_.push_back( newPage );
    return newPage;
}

SequencerPage * Sequencer::pageAtIndex( unsigned int iIndex )
{
    assert( iIndex < pages_.size() );
    return pages_[iIndex];
}

//
//
void Sequencer::clearPages()
{
 
    for ( int i = 0; i < pages_.size(); ++i )
    {
        delete pages_[i];
    }
    
    pages_.clear();
}


//
//
SequencerCell * Sequencer::cellAt( int track, int slot )
{
    if ( ( track < 0 || track >= numAudioTracks_ ) ||
         ( slot < 0 || slot >= numTimeSlots_ ) )
    {
        return 0;
    }
    
    return (*(cells_[track]))[slot];
}

//
//
void Sequencer::setCellDuration( SeqTimeT dur )
{
    cellDur_ = dur;
    
    effectiveCellDur_ = cellDur_ * cellDurMultiplier_;
    // by default schedule one cell ahead
    audioScheduleLeadTime_ = effectiveCellDur_;
    
    if ( curTime_ > .0001 )
    {
        // update if we're started playback, not before
        updatePageTimeScheduleDiscrete();
    }
}

//
//
void Sequencer::setCellDurationMultiplier( float mult )
{
    cellDurMultiplier_ = mult;
    
    effectiveCellDur_ = cellDur_ * cellDurMultiplier_;
    audioScheduleLeadTime_ = effectiveCellDur_;
    
    if ( curTime_ > .0001 )
    {
        // update if we're started playback, not before
        updatePageTimeScheduleDiscrete();
    }
    
    
}


//
//
void Sequencer::setSilentFile( std::string silentFileName )
{
    silentFileName_ = silentFileName;    
    //silentInstance_ = std::tr1::shared_ptr<SnibbeSoundInstance>( new SnibbeSoundInstance( silentFileName, true, 1.0, 0, false ) );
    
    setSilentSoundPathCells();
    
}

void Sequencer::setVolume( float vol )
{
    vol_ = vol;
 
    for ( int iTrack = 0; iTrack < numAudioTracks_; ++iTrack )
    {
        for ( int iSlot = 0; iSlot < numTimeSlots_; ++iSlot )
        {
            SequencerCell * pCell = cellAt( iTrack, iSlot );
            pCell->setVolume( vol );
        }
    }
    
#if SEQUENCER_DEBUG
    //std::cout << "setting volume: " << vol_ << "\n";
#endif

}

//
//
void Sequencer::fadeCellChannelGroupLevelTo( float level, float duration )
{
    interpChannelGroupVol_.beginInterp( interpChannelGroupVol_.curVal(), level, curTime_, duration );
}


//
//
float Sequencer::getCellChannelGroupLevel() const
{
    float vol = 0.0f;
    
    if ( channelGroupCells_ )
    {
        
        channelGroupCells_->getVolume( &vol );
    }
    
    return vol;
}

//
//
bool Sequencer::toggleCellAt( unsigned int track, unsigned int slot )
{
    SequencerCell * cell = cellAt( track, slot );
    if ( cell )
    {
        
        bool currentlyOn = cell->getOn();
        
        if ( exclusiveRows_ && !currentlyOn )
        {
            // we're turning it on... turn all others in this slot off
            
            for ( int i = 0; i < numAudioTracks_; ++i )
            {
                SequencerCell * c = cellAt( i, slot );
                if ( c )
                {
                    c->setOn( false );
                }
            }
        }

        
        cell->setOn( !cell->getOn() );
        return cell->getOn();
    }
    
    return false;
}

//
// virtual
void Sequencer::setDefaultCellPattern()
{
    
    for ( int iSlot = 0; iSlot < numTimeSlots_; ++iSlot )
    {
        cellAt( 0, iSlot )->setOn( true );
    }
}

//
// Simply plays a sound correlating to the track and slot. Fire and forget.
void Sequencer::playOneShot( unsigned int track, unsigned int slot )
{
    SequencerCell * pCell = cellAt( track, slot );
    if ( pCell )
    {
        
        
        pCell->refreshSound();
        
        SnibbeSoundInstance * cellSound = pCell->getSound();
        if ( !cellSound )
        {
            return;
        }
        
        FMOD::Channel * c = 0;
        FMOD_RESULT result = GetFMODSystem()->playSound( FMOD_CHANNEL_FREE, cellSound->getSound(), false, &c);
        c->setVolume( vol_ );
        
        ERRCHECK( result );
        
    }
}


#pragma mark protected methods

//
// virtual
void Sequencer::init( unsigned int numAudioTracks, unsigned int numTimeSlots, SequencerPlaybackT playbackType )
{
    // default implementation
    
    playbackType_ = playbackType;
    
    assert( numAudioTracks_ == 0 && numTimeSlots_ == 0 );
    
    numAudioTracks_ = numAudioTracks;
    numTimeSlots_ = numTimeSlots;
    
    for ( int iTrack = 0; iTrack < numAudioTracks_; ++iTrack )
    {
    
        std::vector<SequencerCell *> * pCellsVec = new std::vector<SequencerCell *>();
        
        for ( int iSlot = 0; iSlot < numTimeSlots_; ++iSlot )
        {
            SequencerCell * pCell = allocCell();
            pCell->setVolume( vol_ );
            (*pCellsVec).push_back( pCell );
        }
        
        cells_.push_back( pCellsVec );
    }
    
    lastScheduledTimes_ = new SeqTimeT[numTimeSlots];
    nextScheduledTimes_ = new SeqTimeT[numTimeSlots_];
    for ( int i = 0; i < numTimeSlots; ++i )
    {
        lastScheduledTimes_[i] = -1;
        nextScheduledTimes_[i] = -1;
    }
    
    if ( usingSilentSound() )
    {
        setSilentSoundPathCells();
    }
    
    
}


//
// virtual
//
// default implementation from file list increments the file with each subsequent timeslot,
// suitable for a single-track linear sequencer
void Sequencer::initWithFiles( SequencerPlaybackT playbackType, const std::vector<std::string>& fileList, unsigned int numAudioTracks, unsigned int numTimeSlots, unsigned int numGroupsVisible )
{
    int iNumFiles = fileList.size();
    assert( iNumFiles > 0 && numGroupsVisible > 0 );
    
    // great sequencers that display > 1 at a time as having larger groups
    unsigned int effectiveTimeSlots = numTimeSlots * numGroupsVisible;
    numGroupsVisible_ = numGroupsVisible;
    init( numAudioTracks, effectiveTimeSlots, playbackType );
    
    // create the data pages from the file list
    
    
    int iPageFileIndex = 0;
    
    int iNumGroups = iNumFiles / effectiveTimeSlots + ( iNumFiles % effectiveTimeSlots == 0 ? 0 : 1 );
    
    
    for ( int iGroup = 0; iGroup < iNumGroups; ++iGroup )
    {
        // within each larger group there are sub-groups if numGroupsVisible > 1        
        // arranger subgroups are done on the same page (invisible to parent glass - just larger pages)
        SequencerPage * page = addPage();
        iPageFileIndex = 0;
        
        for ( int iGroupSubDiv = 0; iGroupSubDiv < numGroupsVisible; ++iGroupSubDiv )
        {
            
                        
            
            int iNumFilesUsed = effectiveTimeSlots * iGroup + iGroupSubDiv * numTimeSlots;
            int numFilesLeft =  iNumFiles - iNumFilesUsed;
            
            
            // if we have fewer than groupSize files left, only fill the page partially
            int tracksForSubGroup = MIN( numFilesLeft, numAudioTracks_ );
            int slotsForSubGroup = MIN( numFilesLeft, numTimeSlots );
            
            
                        
            for ( int iTimeSlot = 0; iTimeSlot < slotsForSubGroup; ++iTimeSlot )
            {
                
                
                for ( int iTrack = 0; iTrack < tracksForSubGroup; ++iTrack )
                {
                    
                    int iFileIndex = iNumFilesUsed + iPageFileIndex;
                    
                    if ( iFileIndex < iNumFiles )
                    {
                        SequencerPage::DataT& cellData = page->dataAt( iTrack, iPageFileIndex );
                        
                        
                        
                        cellData.filePath_ = fileList[iFileIndex]; // need full path?
                        
                        //std::cout << "filepath: " << cellData.filePath_ << "\n";
                        
                        // default - this is the on flag in the page data, which can optionally be used an
                        // an initial state for the cell when the page is loaded to be active.  Ultimately
                        // the SequencerCell "on" value is what determines whether the cell is played, but
                        // this value can populate that if desired.
                        
                        cellData.on_ = true;
                    }
                   
                }
                
                iPageFileIndex++;                
                
            }
        }
    }

}

//
// virtual
void Sequencer::loadPageAtIndex( unsigned int iIndex )
{
    if ( iIndex < pages_.size() )
    {
        // load it up!
        
        SequencerPage * page = pages_[iIndex];
        if ( page )
        {
            
#if SEQUENCER_DEBUG
            std::cout << "loading page: " << iIndex << "\n";
#endif
      
            
            
            if ( page->getSizeX() != numAudioTracks_ ||
                page->getSizeY() != numTimeSlots_ )
            {
                std::cout << "Error, cannot load sequencer page with dimensions (" << page->getSizeX() << ", " << page->getSizeY() << ") into sequencer with dimensions: (" << numAudioTracks_ << ", " << numTimeSlots_ << ")\n";
            }
            
            assert( page->getSizeX() == numAudioTracks_ &&
                    page->getSizeY() == numTimeSlots_ );
            
            // set up each cell object to reflect the corresponding entry in the data matrix, 
            
            for ( int iTrack = 0; iTrack < numAudioTracks_; ++iTrack )
            {
                for ( int iSlot = 0; iSlot < numTimeSlots_; ++iSlot )
                {
                    SequencerCell * pCell = cellAt( iTrack, iSlot );
                    SequencerPage::DataT& data = page->dataAt( iTrack, iSlot );
                    
                    pCell->initFromPageData( data );
                }
            }
        }
        
    }
    
}


// virtual
// Allocate and initialize the type of cell used by the concrete type of this Sequencer
SequencerCell * Sequencer::allocCell()
{
    // default
    return new SequencerCell();
    
}

//
//
void Sequencer::clearCells()
{
    
    for ( int i = 0; i < cells_.size(); ++i )
    {
        std::vector<SequencerCell *> * cellsColumn = cells_[i];
        for ( int j = 0; j < cellsColumn->size(); ++j )
        {
            delete (*cellsColumn)[j];
        }
        
        delete cellsColumn;
    }
    
    cells_.clear();

    if ( lastScheduledTimes_ )
    {
        delete[] lastScheduledTimes_;
        lastScheduledTimes_ = 0;
            
    }
    
    if ( nextScheduledTimes_ )
    {
        delete[] nextScheduledTimes_;
        nextScheduledTimes_ = 0;
    }
    
    numAudioTracks_ = 0;
    numTimeSlots_ = 0;
}

//
// virtual
void Sequencer::setAllCellsOn( bool bOn )
{
    for ( int iTrack = 0; iTrack < numAudioTracks_; ++iTrack )
    {
        for ( int iSlot = 0; iSlot < numTimeSlots_; ++iSlot )
        {
            cellAt( iTrack, iSlot )->setOn( bOn );
        }
    }
}

//
// passes the silent file path on to each cell if needed
void Sequencer::setSilentSoundPathCells()
{
    if ( usingSilentSound() )
    {
        for ( int iTrack = 0; iTrack < numAudioTracks_; ++iTrack )
        {
            for ( int iSlot = 0; iSlot < numTimeSlots_; ++iSlot )
            {
                SequencerCell * pCell = cellAt( iTrack, iSlot );
                pCell->setSilentFilePath( silentFileName_ );
            }
        }
    }

}


#pragma mark common timing methods


// Using the scheduled upcoming times for the current page of samples,
// determine which slot we're currently in based on the current time
void Sequencer::updateCurTimeSlot()
{
    
#if SEQUENCER_DEBUG
    int prevCurSlot = curTimeSlot_;
#endif
    
    // new way
    
    if ( playbackType_ == eSeqSentence )
    {
        
        if ( !soundSentence_ || !soundSentence_->getChannel() )
        {
            return;
        }
        
        if ( curTime_ >= curSequenceStartTime_ )
        {
            // todo - if we ever return to this it will need to account for cellDur_ being
            // variable
            
            assert( cellDur_ > 0.0 );
            SeqTimeT delta = curTime_ - curSequenceStartTime_;
            float numCellsSinceStart = delta / cellDur_;
            curTimeSlot_ = (int) numCellsSinceStart;
            curTimeSlot_ %= numTimeSlots_;
        }
        
        // this isn't working well for long term
        
        
        unsigned int subSoundIndex = 0;
        FMOD_RESULT result = soundSentence_->getChannel()->getPosition(&subSoundIndex, (FMOD_TIMEUNIT)(FMOD_TIMEUNIT_SENTENCE_SUBSOUND /*| FMOD_TIMEUNIT_BUFFERED*/));
        ERRCHECK(result);
        
    
        if ( subSoundIndex == 0 && prevSubSentence_ != 0 )
        {
            curSequenceStartTime_ = curTime_;
        }
    
        prevSubSentence_ = subSoundIndex;
    
        
    }
    else if ( playbackType_ == eSeqDiscrete )
    {
        
        
        if ( curTime_ < startTime_ )
        {
            curTimeSlot_ = -1;
        }
        else
        {
            // default to final slot index            
            curTimeSlot_ = numTimeSlots_ - 1;
            
            for (int i = 0; i < numTimeSlots_; ++i )
            {
                if ( nextScheduledTimes_[i] > curTime_ )
                {
                    curTimeSlot_ = (i == 0 ? numTimeSlots_ - 1 : i-1 );
                    break;
                }
            }
        }
        
    }
    
    
#if SEQUENCER_DEBUG
    
    if ( curTimeSlot_ != prevCurSlot )
    {
        std::cout << "Updating cur time slot: " << curTimeSlot_ << std::endl;
    }
    
#endif
    
    
}

#pragma mark discrete timing methods

//
//
int Sequencer::testAndScheduleDiscrete()
{
    // where are we in the sequence?
    //SeqTimeT timeIntoSeq = curTime_ - curSequenceStartTime_;
    
    
    
    //if ( timeIntoSeq > 0 )
    if ( curTimeSlot_ >= 0 )
    {
        //int curIndex = timeIntoSeq / cellDur_;
     
        // check the next slot
        
        int iNextSlot = (curTimeSlot_ == numTimeSlots_ - 1 ? 0 : curTimeSlot_ + 1);
        
        if ( lastScheduledTimes_[iNextSlot] < curTime_ )
        {
            // if the last scheduled start time for the upcoming slot is in the past,
            // we know we need to schedule it
            
            scheduleSlotDiscrete( iNextSlot );
            
        }
        
    }
    else
    {
        std::cout << "warning, negative time slot\n";
    }
    
    
}


//
// Schedule audio for all appropriate cells in the given slot
void Sequencer::scheduleSlotDiscrete( int slotIndex )
{
    assert( slotIndex >= 0 && slotIndex < numTimeSlots_ );
    
    SeqTimeT timeToSchedule = nextScheduledTimes_[slotIndex];
    if ( timeToSchedule > curTime_ )
    {
    
        // for each cell that's on and has a valid sound, schedule it!
        for ( int iTrack = 0; iTrack < numAudioTracks_; ++iTrack )
        {
            SequencerCell * cell = cellAt( iTrack, slotIndex );
            if ( cell->canPlay() )
            {
                //printf( "scheduling for time: %f, cur time: %f\n", timeToSchedule, curTime_ );
                cell->schedule( curTime_, timeToSchedule );

                if ( cell->getSound() && cell->getSound()->getChannel() )
                {                                    
                    cell->getSound()->getChannel()->setChannelGroup( channelGroupCells_ );
                }
                
                                
                
            }
        }
        
    }
    
    // keep track of what we just scheduled
    lastScheduledTimes_[slotIndex] = timeToSchedule;
    
}

//
//
void Sequencer::computePageTimeScheduleDiscrete( SeqTimeT pageTimeBegin )
{
    SeqTimeT nextTime = pageTimeBegin;
    
#if SEQUENCER_DEBUG
    std::cout << "page time schedule: \n";
#endif
    
    for ( int i = 0; i < numTimeSlots_; ++ i )
    {
        nextScheduledTimes_[i] = nextTime;
        
#if SEQUENCER_DEBUG
        std::cout << "slot: " << i << "   time: " << nextTime << std::endl;
#endif
        
        nextTime += effectiveCellDur_;
    }
    
    curSequenceStartTime_ = pageTimeBegin;
    
    
    //curTimeSlot_ = ???  maybe not
}


//
// updates the remaining schedule times for the current sound sequence
// based on the most recent cell duration
void Sequencer::updatePageTimeScheduleDiscrete()
{
    int iIndexToStartUpdate = 9999;
    
    // use the full beat duration
    SeqTimeT nextTime = curSequenceStartTime_;
    
    for ( int iSlot = curTimeSlot_+1; iSlot < numTimeSlots_; ++iSlot )
    {
        
        if ( curTime_ > lastScheduledTimes_[iSlot] )
        {
            iIndexToStartUpdate = iSlot;            
            nextTime = iSlot == 0 ? curSequenceStartTime_ : lastScheduledTimes_[iSlot-1];
            
            //std::cout << "index to begin: " << iIndexToStartUpdate << "\n";
            break;
        }
        else
        {
            //std::cout << "last scheduled time: " << lastScheduledTimes_[iSlot] << "\n";
        }
    }
    
    // here we ensure that the start time for the timing updates is a multiple of
    // effectiveCellDur_ relative to the start time;
    
    float startTimeDelta = nextTime - startTime_;
    float remainder = fmodf( startTimeDelta, effectiveCellDur_ );
    const float threshold = .0001;
    if ( remainder > threshold )
    {
        nextTime += (effectiveCellDur_ - remainder);
    }
     
    
    for ( int iSlot = iIndexToStartUpdate; iSlot < numTimeSlots_; ++iSlot )
    {
        nextTime += effectiveCellDur_;
        nextScheduledTimes_[iSlot] = nextTime;
        
        //std::cout << "NEW scheduled time: " << nextScheduledTimes_[iSlot] << "\n";
    }
}


#pragma mark sentence timing methods

//
//
void Sequencer::testAndUpdateSentence()
{
    
    // are any cells in the upcoming slot dirty?
    

    
    int numSlotsToTest = 4;
    int iCurSlotIndex = (curTimeSlot_ + 2) % numTimeSlots_;

    for ( int i = 0; i < numSlotsToTest; ++i )
    {
        
        for ( int iTrack = 0; iTrack < numAudioTracks_; ++iTrack )
        {
            SequencerCell * cell = cellAt( iTrack, iCurSlotIndex );
            if ( cell->dirty() )
            {
                createSubSoundsSentence( iCurSlotIndex, iCurSlotIndex );
                break;

            }
        }
        
        ++iCurSlotIndex;
        iCurSlotIndex %= numTimeSlots_;

        
    }
    
       
    
}

//
//
void Sequencer::createSubSoundsSentence( int slotIndexMin, int slotIndexMax )
{
    for ( int iSlot = slotIndexMin; iSlot <= slotIndexMax; ++iSlot )
    {
        if ( iSlot < 0 || iSlot >= numTimeSlots_ )
        {
            continue;
            
        }
        
        SequencerCell * cellForSubSound = 0;
        
        // for each cell that's on and has a valid sound, ensure that  it!
        for ( int iTrack = 0; iTrack < numAudioTracks_; ++iTrack )
        {
            SequencerCell * cell = cellAt( iTrack, iSlot );
            
            if ( !cellForSubSound && usingSilentSound() )
            {
                // we need some sound to occupy the subsound slot... generally we'll use the first one that's
                // on, but if none are found we'll just use track 0 and set volume to 0.
                cellForSubSound = cell;
            }
            
            if (  cell->getOn() )
            {
                cellForSubSound = cell;
                break;
            }
                        
            
        }
        
        if ( cellForSubSound )
        {
            cellForSubSound->refreshSound();
            float cellVol = cellForSubSound->getVolume();
            
            if ( !cellForSubSound->getOn() )
            {
                //cellVol = 0.0f;
            }
            
            SnibbeSoundInstance * pInst = cellForSubSound->getSound();
            //pInst->setVolume( cellVol );
            
            //FMOD_RESULT result = soundSentence_->getSound()->setSubSound( iSlot,  pInst->getSound() );
            
            FMOD_RESULT result = soundSentence_->getSound()->setSubSound( iSlot, pInst->getSound() );                                    
            ERRCHECK(result);
            
        }
//        else
//        {
//            // use the silent sound
//            
//            FMOD_RESULT result = soundSentence_->getSound()->setSubSound( iSlot, silentInstance_->getSound());
//            ERRCHECK(result);
//        }
        
        for ( int iTrack = 0; iTrack < numAudioTracks_; ++iTrack )
        {
            SequencerCell * cell = cellAt( iTrack, iSlot );
            cell->clearDirty();
        }

        
        
        
        
    }
}



