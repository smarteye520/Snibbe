//
//  SequencerOverride.cpp
//  SnibbeLib
//
//  Created by Graham McDermott on 11/29/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SequencerOverride.h"
#include <assert.h>
#include "SequencerPage.h"
#include "SnibbeUtils.h"
#include "SequencerCell.h"
#include "SnibbeSoundInstance.h"
#include <iostream>

#define OVERRIDE_MAIN_CHANNELGROUP_FADE_TIME 1.
#define OVERRIDE_MAIN_CHANNELGROUP_RESTORE_DELAY .5

using namespace ss;
using std::tr1::shared_ptr;


//
//
SequencerOverride::SequencerOverride()
{
 
    interpChannelGroupLevel_.setValue( 1.0 );
    pendingChannelGroupVolRestore_ = false;
}

//
// virtual
SequencerOverride::~SequencerOverride()
{
    
}


//
// virtual
// given a list of files, create data pages
void SequencerOverride::initWithFiles( SequencerPlaybackT playbackType, const std::vector<std::string>& fileList, unsigned int numTimeSlots )
{
    int iNumFiles = fileList.size();
    assert( numTimeSlots > 0 && iNumFiles > 0 );
    
    
    // for override sequencers, there's only one track per time slot
    init( 1, numTimeSlots, playbackType );
    
    // create the data pages from the file list
    
    
    int iNumGroups = iNumFiles / numTimeSlots + ( iNumFiles % numTimeSlots == 0 ? 0 : 1 );    
    int iNumFilesUsed = 0;
    
    for ( int iGroup = 0; iGroup < iNumGroups; ++iGroup )
    {


        SequencerPage * page = addPage();
                        
        //int iNumFilesUsed = groupSize * iGroup;
        int numFilesLeft =  iNumFiles - iNumFilesUsed;
        
        // if we have fewer than groupSize files left, only fill the page partially
        int slotsForGroup = MIN( numFilesLeft, numTimeSlots );
        
    
        for ( int iTimeSlot = 0; iTimeSlot < slotsForGroup; ++iTimeSlot )
        {


            if ( iNumFilesUsed < iNumFiles )
            {
                SequencerPage::DataT& cellData = page->dataAt( 0, iTimeSlot );
                cellData.filePath_ = fileList[iNumFilesUsed]; // should be fully qualified path
                
                // default - this is the on flag in the page data, which can optionally be used an
                // an initial state for the cell when the page is loaded to be active.  Ultimately
                // the SequencerCell "on" value is what determines whether the cell is played, but
                // this value can populate that if desired.
                
                // single track, linear playback - always on
                cellData.on_ = true;                
            }
            
            ++iNumFilesUsed;
            
            
        }
        
    }
}

//
// virtual
void SequencerOverride::update( SeqTimeT curTime, SeqTimeT deltaTime )
{
    Sequencer::update( curTime, deltaTime );
    
    interpChannelGroupLevel_.update( curTime );
    channelGroupCells_->setVolume( interpChannelGroupLevel_.curVal() );
 
    if ( pendingChannelGroupVolRestore_ )
    {
        timeUntilChannelGroupVolRestore_ -= deltaTime;
        if ( timeUntilChannelGroupVolRestore_ <= 0 )
        {
            // unmute the default audio
            interpChannelGroupLevel_.beginInterp( interpChannelGroupLevel_.curVal(), 1.0, curTime_, OVERRIDE_MAIN_CHANNELGROUP_FADE_TIME );

            pendingChannelGroupVolRestore_ = false;
        }
    }
    
}




//
//
void SequencerOverride::onOverrideBegin( int slotIndex )
{
    // stop the normal sequencer playback and fire off the audio for this slot

    if ( !findOverrideForIndex( slotIndex ) )
    {
       
        
        // only 1
        int iTrackIndex = 0;
        
        // create the sound instance independent of the one
        
        SequencerCell * pCellOver = cellAt( iTrackIndex, slotIndex );
        if ( pCellOver )
        {
         
            //std::cout << "override begin: " << slotIndex << std::endl;
            
            
            pCellOver->refreshSound();
            
            SnibbeSoundInstance * cellOverSound = pCellOver->getSound();
            if ( !cellOverSound )
            {
                return;
            }
            
            FMOD::Channel * c = 0;
            FMOD_RESULT result = GetFMODSystem()->playSound( FMOD_CHANNEL_FREE, cellOverSound->getSound(), false, &c);
            c->setVolume( vol_ );
            
            ERRCHECK( result );
            
            shared_ptr<OverrideAudio> pOver = shared_ptr<OverrideAudio>( new OverrideAudio() );
            pOver->slotIndex_ = slotIndex;
            
            overrides_.insert( pOver );            
            

            
            interpChannelGroupLevel_.beginInterp( interpChannelGroupLevel_.curVal(), 0.0, curTime_, OVERRIDE_MAIN_CHANNELGROUP_FADE_TIME );
            

            

        }
        else
        {
            return;
        }
        
        

    }
}


//
//
void SequencerOverride::onOverrideEnd( int slotIndex )
{
    if ( findOverrideForIndex( slotIndex ) )
    {

        // todo - remove it
        
        removeOverrideForIndex( slotIndex );
        
        //std::cout << "override end: " << slotIndex << std::endl;
        
        if ( overrides_.size() == 0 )
        {
            // begin timer until we restore audio
            pendingChannelGroupVolRestore_ = true;
            timeUntilChannelGroupVolRestore_ = OVERRIDE_MAIN_CHANNELGROUP_RESTORE_DELAY;
            
        }

    }
    
}

//
// populate a vector with floats denoting the activity level of each slot in
// the current sequencer page
void SequencerOverride::getOverrideLevels( std::vector<float>& outLevels )
{
    
    outLevels.clear();
    
    // for now just 1 or 0 based on whether we're overriding or not
 
    for ( int iSlot = 0; iSlot < numTimeSlots_; ++iSlot )
    {
    
        outLevels.push_back( findOverrideForIndex( iSlot ) ? 1.0 : 0.0 );
        
        
    }
    
   
}


#pragma protected methods

//
//
shared_ptr<SequencerOverride::OverrideAudio> SequencerOverride::findOverrideForIndex( int slotIndex )
{
    std::set< shared_ptr<OverrideAudio> >::iterator it;
    for ( it = overrides_.begin(); it != overrides_.end(); ++it )
    {
     
        if ( (*it)->slotIndex_ == slotIndex )
        {
            return *it;
        }
        
    }
    
    return shared_ptr<SequencerOverride::OverrideAudio>();
}

//
//
void SequencerOverride::removeOverrideForIndex( int slotIndex )
{
    std::set< shared_ptr<OverrideAudio> >::iterator it;
    
    while ( true )
    {
        bool bFound = false;
    
        for ( it = overrides_.begin(); it != overrides_.end(); ++it )
        {        
            if ( (*it)->slotIndex_ == slotIndex )
            {
                overrides_.erase( it );
                bFound = true;
                break;
            }
            
        }
        
        if ( !bFound )
        {
            break;
        }
        
    }
    
}


