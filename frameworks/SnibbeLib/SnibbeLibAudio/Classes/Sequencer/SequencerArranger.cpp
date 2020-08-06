//
//  SequencerArranger.cpp
//  SnibbeLib
//
//  Created by Graham McDermott on 11/14/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SequencerArranger.h"
#include "SequencerPage.h"
#include "SnibbeUtils.h"
#include "SequencerCell.h"
#include <assert.h>

using namespace ss;


//
//
SequencerArranger::SequencerArranger()
{
    
}

//
// virtual
SequencerArranger::~SequencerArranger()
{
    
}


//
// virtual
// given a list of files, create data pages
void SequencerArranger::initWithFiles( SequencerPlaybackT playbackType, const std::vector<std::string>& fileList, unsigned int numAudioTracks, unsigned int numTimeSlots, unsigned int numGroupsVisible )
{
    // for arranger, must be equal
    assert( numAudioTracks == numTimeSlots );
    

    int iNumFiles = fileList.size();
    assert( iNumFiles > 0 && numGroupsVisible > 0 );
    
    // great sequencers that display > 1 at a time as having larger groups
    unsigned int effectiveTimeSlots = numTimeSlots * numGroupsVisible;
    
    numGroupsVisible_ = numGroupsVisible;
    
    init( numAudioTracks, effectiveTimeSlots, playbackType );
    
    // create the data pages from the file list
    
    
    int iNumGroups = iNumFiles / effectiveTimeSlots + ( iNumFiles % effectiveTimeSlots == 0 ? 0 : 1 );    
    
    
    for ( int iGroup = 0; iGroup < iNumGroups; ++iGroup )
    {
        // within each larger group there are sub-groups if numGroupsVisible > 1
        
        // arranger subgroups are done on the same page (invisible to parent glass - just larger pages)
        SequencerPage * page = addPage();
        
        for ( int iGroupSubDiv = 0; iGroupSubDiv < numGroupsVisible; ++iGroupSubDiv )
        {
            
            
            //int numFilesLeft = iNumFiles - iCurFileIndex;
            
            int iNumFilesUsed = effectiveTimeSlots * iGroup + iGroupSubDiv * numTimeSlots;
            int numFilesLeft =  iNumFiles - iNumFilesUsed;
            
            
            // if we have fewer than groupSize files left, only fill the page partially
            int tracksForSubGroup = MIN( numFilesLeft, numAudioTracks_ );
            int slotsForSubGroup = MIN( numFilesLeft, numTimeSlots );
            
            
            
            
            for ( int iTimeSlot = 0; iTimeSlot < slotsForSubGroup; ++iTimeSlot )
            {
                
                
                int iEffectiveTimeSlot = iTimeSlot + iGroupSubDiv * numTimeSlots;
                int iCurFileIndex = iNumFilesUsed;
                
                
                for ( int iTrack = 0; iTrack < tracksForSubGroup; ++iTrack )
                {
                    

                    if ( iCurFileIndex < iNumFiles )
                    {
                        SequencerPage::DataT& cellData = page->dataAt( iTrack, iEffectiveTimeSlot );
                        cellData.filePath_ = fileList[iCurFileIndex]; // need full path?
                        
                        // default - this is the on flag in the page data, which can optionally be used an
                        // an initial state for the cell when the page is loaded to be active.  Ultimately
                        // the SequencerCell "on" value is what determines whether the cell is played, but
                        // this value can populate that if desired.
                        
                        cellData.on_ = true;
                    }
                                        
                    
                    iCurFileIndex++;
                }
                
                
            }
        }
    }
    
    setCellPatternLinear();
    
}

//
//
void SequencerArranger::setCellPatternLinear()
{
    for ( int iSlot = 0; iSlot < numTimeSlots_; ++iSlot )
    {
        for ( int iTrack = 0; iTrack < numAudioTracks_; ++iTrack )
        {
            SequencerCell * cell = cellAt( iTrack, iSlot );
            cell->setOn( iTrack == ( iSlot % (numTimeSlots_ / numGroupsVisible_) ) );
        }
    }

}

//
// virtual
bool SequencerArranger::toggleCellAt( unsigned int track, unsigned int slot )
{
    // in arrangers, we only allow one cell per time slot to be on at once
    
    SequencerCell * cell = cellAt( track, slot );
    bool currentlyOn = cell->getOn();
    
    if ( !currentlyOn )
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
    
    // toggle
    cell->setOn( !cell->getOn() );
    
    return cell->getOn();
}
