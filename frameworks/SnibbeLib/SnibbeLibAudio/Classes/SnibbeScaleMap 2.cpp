//
//  SnibbeScaleMap.cpp
//  SnibbeLib
//
//  Created by Graham McDermott on 9/14/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SnibbeScaleMap.h"

#define MAX(X,Y) ((X) > (Y) ? (X) : (Y) )
#define MIN(X,Y) ((X) < (Y) ? (X) : (Y) )

//
//
SnibbeScaleMap::SnibbeScaleMap()
{
    lowNoteMidiVal_ = -1;
    highNoteMidiVal_ = -1;
}

//
//
SnibbeScaleMap::~SnibbeScaleMap()
{
    clearNotes();
}

//
//
ScaleNote * SnibbeScaleMap::addNote( int midiNote )
{
    ScaleNote *newNote = new ScaleNote();
    newNote->midiNote_ = midiNote;
    notes_.push_back( newNote );
    
    return notes_[notes_.size()-1];
}

//
//
void SnibbeScaleMap::clearNotes()
{
    int iNumScaleNotes = notes_.size();

    for ( int i = 0; i < iNumScaleNotes; ++i )
    {
        delete notes_[i];
    }
    
    notes_.clear();
    
    lowNoteMidiVal_ = -1;
    highNoteMidiVal_ = -1;
}

//
//
ScaleNote * SnibbeScaleMap::noteForValue( float normalizedValue )
{
 
    int iIndexLow = 0;
    int iIndexHigh = notes_.size() - 1;
    
    int iNumNotes = notes_.size();
    
    if ( lowNoteMidiVal_ > 0 )
    for ( int i = 0; i < iNumNotes; ++i )
    {
        iIndexLow = i;
        if ( notes_[i]->midiNote_ >= lowNoteMidiVal_ )
        {
            // found first valid
            break;
        }
    }
    
    if ( highNoteMidiVal_ > 0 )
    {
        for ( int i = iNumNotes-1; i >= 0; --i )
        {
            iIndexHigh = i;
            if ( notes_[i]->midiNote_ <= highNoteMidiVal_ )
            {
                // found first valid
                break;
            }
        }
    }
    
    if ( iIndexHigh < iIndexLow )
    {
        return 0;
    }
    else if ( iIndexHigh == iIndexLow )
    {
        return notes_[iIndexHigh];
    }
    

    int iNumBuckets = iIndexHigh - iIndexLow + 1;
    
    int iBucketIndexDelta = MIN( normalizedValue, 0.999 ) * iNumBuckets;
    int iFinalIndex = iIndexLow + iBucketIndexDelta;
    
    // debugging output
    //printf( "input: %.2f, output index: %d, output note: %d\n", normalizedValue, iFinalIndex, notes_[iFinalIndex]->midiNote_ );
    
    return notes_[iFinalIndex];
    
}


//
//
void SnibbeScaleMap::setMidiRange( int lowNote, int highNote )
{
    lowNoteMidiVal_ = lowNote;
    highNoteMidiVal_ = highNote;
}

std::vector<ScaleNote> ;