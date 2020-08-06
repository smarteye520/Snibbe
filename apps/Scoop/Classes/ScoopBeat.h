//
//  ScoopBeat.h
//  Scoop
//
//  Created by Graham McDermott on 3/23/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//
//  Classes relating to scoop beats and groups of scoop beats

#ifndef __SCOOP_BEAT_H__
#define __SCOOP_BEAT_H__


#include "ScoopDefs.h"
#include <vector>

/////////////////////////////////////////////////////////////
// class ScoopBeat
// ---------------
// Represents a single audio loop
/////////////////////////////////////////////////////////////


class ScoopBeat
{
    
public:

    ScoopBeat();
    ScoopBeat( int iID, const char *filename );
    ~ScoopBeat();

    int getBeatUID() const { return beatUID_; }
    void setBeatUID( int uid ) { beatUID_ = uid; }
    
    const char *getFilename() const { return beatFilename; }
    void setFilename( const char * name );
    
    float getBeatDuration() const { return beatDuration_; }
    void setBeatDuration( float seconds ) { beatDuration_ = seconds; }
    
private:
    
    int beatUID_;
    char beatFilename[MAX_SCOOP_BEAT_FILENAME_LEN];
    float beatDuration_;
    
};


/////////////////////////////////////////////////////////////
// class ScoopBeatSet
// ------------------
// represents a collection of individual beats 
/////////////////////////////////////////////////////////////

class ScoopBeatSet
{
public:
    
    ScoopBeatSet();
    ~ScoopBeatSet();
    
    int getNumBeats() const { return beats_.size(); }
    ScoopBeat * getBeatAt( int iIndex ) const;    
    void addBeat( int uniqueID, const char *filename );
    
    int getIndexForBeatUID( int uniqueID ) const;
    
    int getUID() const { return uniqueID_; }
    void setUID( int uid ) { uniqueID_ = uid; }

    void setName( const char *name );
    const char * getName() const { return name_; }

    void setDescription( const char *d );
    const char * getDescription() const { return description_; }
    
private:
    
    std::vector<ScoopBeat> beats_;
    char name_[MAX_SCOOP_BEAT_FILENAME_LEN];
    char description_[MAX_SCOOP_BEAT_DESCRIPTION_LEN];
    int uniqueID_;
};


/////////////////////////////////////////////////////////////
// class ScoopLibrary
// ------------------
// represents all beat sets available in the app, purchased 
// or not.
/////////////////////////////////////////////////////////////

class ScoopLibrary
{
public:
    
    static ScoopLibrary& Library() { return msLibrary_; }
    
    ScoopLibrary();
    ~ScoopLibrary();
    
    int numBeatSets() const { return beatSets_.size(); }
    ScoopBeatSet * addBeatSet();
    ScoopBeatSet * beatSetAt( int iIndex );
    ScoopBeatSet * beatSetWithID( int iUniqueID );
    
private:
    
    static ScoopLibrary msLibrary_;
    
    std::vector<ScoopBeatSet> beatSets_;
};

#endif // __SCOOP_BEAT_H__ 