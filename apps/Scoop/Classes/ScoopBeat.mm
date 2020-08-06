//
//  ScoopBeat.mm
//  Scoop
//
//  Created by Graham McDermott on 3/23/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#include "ScoopBeat.h"


/////////////////////////////////////////////////////////////
// class ScoopBeat
/////////////////////////////////////////////////////////////

//
//
ScoopBeat::ScoopBeat()
{
    setFilename("");
    setBeatUID(-1);
}

//
//
ScoopBeat::ScoopBeat( int iID, const char *filename )
{
    setFilename(filename);
    setBeatUID(iID);
}

//
//
ScoopBeat::~ScoopBeat()
{
    
}


//
//
void ScoopBeat::setFilename( const char * name )
{
    strncpy(beatFilename, name, MAX_SCOOP_BEAT_FILENAME_LEN);
}


/////////////////////////////////////////////////////////////
// class ScoopBeatSet
/////////////////////////////////////////////////////////////

//
//
ScoopBeatSet::ScoopBeatSet()
{
    setName("");
    uniqueID_ = -1;
}

//
//
ScoopBeatSet::~ScoopBeatSet()
{
    
}

//
//
ScoopBeat * ScoopBeatSet::getBeatAt( int iIndex ) const
{
    if ( iIndex >= 0 && iIndex < (int) beats_.size() )
    {
        return const_cast<ScoopBeat *>( &beats_[iIndex] );
    }
    
    return 0;
}

//
//
void ScoopBeatSet::addBeat( int uniqueID, const char *filename )
{
    beats_.push_back( ScoopBeat( uniqueID, filename ) );        
}

//
//
int ScoopBeatSet::getIndexForBeatUID( int uniqueID ) const
{
    int iNumBeats = beats_.size();
    for ( int i = 0; i < iNumBeats; ++i )
    {
        if ( beats_[i].getBeatUID() == uniqueID )
        {
            return i;
        }
    }
    
    return -1;
}

//
//
void ScoopBeatSet::setName( const char *name )
{
    strncpy(name_, name, MAX_SCOOP_BEAT_FILENAME_LEN);
}

//
//
void ScoopBeatSet::setDescription( const char *d )
{
    strncpy(description_, d, MAX_SCOOP_BEAT_DESCRIPTION_LEN);
}



/////////////////////////////////////////////////////////////
// class ScoopLibrary
/////////////////////////////////////////////////////////////

// static
ScoopLibrary ScoopLibrary::msLibrary_;


ScoopLibrary::ScoopLibrary()
{
    
}

//
//
ScoopLibrary::~ScoopLibrary()
{
    
}

//
//
ScoopBeatSet * ScoopLibrary::addBeatSet()
{
    beatSets_.push_back( ScoopBeatSet() );
    return &beatSets_[beatSets_.size() - 1];
}

//
//
ScoopBeatSet * ScoopLibrary::beatSetAt( int iIndex )
{
    if ( iIndex >= 0 && iIndex < (int) beatSets_.size() )
    {
        return &beatSets_[iIndex];
    }
    
    return 0;
}


//
//
ScoopBeatSet * ScoopLibrary::beatSetWithID( int iUniqueID )
{
    unsigned int iNumSets = beatSets_.size();
    for ( unsigned int i = 0; i < iNumSets; ++i )
    {
        if ( beatSets_[i].getUID() == iUniqueID )
        {
            return &beatSets_[i];
        }
    }
    
    return nil;
}

