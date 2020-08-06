//
//  SequencerStepper.cpp
//  SnibbeLib
//
//  Created by Graham McDermott on 11/14/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SequencerStepper.h"
#include "SnibbeUtils.h"
#include "SequencerPage.h"
#include <assert.h>


using namespace ss;

SequencerStepper::SequencerStepper()
{
    
}

//
// virtual
SequencerStepper::~SequencerStepper()
{
    
}

//
// virtual
void SequencerStepper::initWithFiles( SequencerPlaybackT playbackType, const std::vector<std::string>& fileList, unsigned int numAudioTracks, unsigned int numTimeSlots, unsigned int numGroupsVisible )
{
    
    int iNumFiles = fileList.size();
    
    // for stepper, file count must be a multiple of the num tracks
    assert( iNumFiles % numAudioTracks == 0 );    
    assert( iNumFiles > 0 && numGroupsVisible > 0 );
    assert( playbackType == eSeqDiscrete );
    
    
    // great sequencers that display > 1 at a time as having larger groups
    unsigned int effectiveTimeSlots = numTimeSlots * numGroupsVisible;
    
    numGroupsVisible_ = numGroupsVisible;
    
    init( numAudioTracks, effectiveTimeSlots, playbackType );
    
    // create the data pages from the file list
    
    
    int iNumGroups = iNumFiles / effectiveTimeSlots + ( iNumFiles % effectiveTimeSlots == 0 ? 0 : 1 );
    
    
    for ( int iGroup = 0; iGroup < iNumGroups; ++iGroup )
    {
        // within each larger group there are sub-groups if numGroupsVisible > 1
        
        // subgroups are done on the same page (invisible to parent glass - just larger pages)
        SequencerPage * page = addPage();
        
        for ( int iGroupSubDiv = 0; iGroupSubDiv < numGroupsVisible; ++iGroupSubDiv )
        {
            
            
            //int numFilesLeft = iNumFiles - iCurFileIndex;
            
            int iNumFilesUsed = effectiveTimeSlots * iGroup + iGroupSubDiv * numTimeSlots;
            int numFilesLeft =  iNumFiles - iNumFilesUsed;
            
            
            
            for ( int iTimeSlot = 0; iTimeSlot < numTimeSlots; ++iTimeSlot )
            {
                
                
                int iEffectiveTimeSlot = iTimeSlot + iGroupSubDiv * numTimeSlots;
                int iCurFileIndex = iNumFilesUsed;
                
                
                for ( int iTrack = 0; iTrack < numAudioTracks; ++iTrack )
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
                        
                        // for steppers we increment the file index with each track... new sound per track
                        iCurFileIndex++;
                    }
                    
                }
                
                // for steppers, we reuse the final n-tracks of audio files for each remaining timeslot.
                // So we can optionally only specify audio for the first time slot and it will be repeated for the
                // whole sequencer.
                if ( iCurFileIndex == iNumFiles )
                {
                    iCurFileIndex -= numAudioTracks;
                }
                
                
            }
        }
    }
    
    setDefaultCellPattern();
}

