//
//  SnibbeScaleMap.h
//  SnibbeLib
//
//  Created by Graham McDermott on 9/14/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef __SnibbeLib__SnibbeScaleMap__
#define __SnibbeLib__SnibbeScaleMap__

#include <vector>


struct ScaleNote
{
    int midiNote_;
};



typedef enum
{
    eChromatic = 0,
} ScaleT;



class SnibbeScaleMap
{

public:
    
    SnibbeScaleMap();
    ~SnibbeScaleMap();
    
    ScaleNote * addNote( int midiNote ); // should be called in ascending order of midi notes
    void        clearNotes();
    ScaleNote * noteForValue( float normalizedValue );
    
    // todo
    //void        populateWithScale( ScaleT scale, int key, int lowMidiNote, int highMidiNote );
    
    void setMidiRange( int lowNote, int highNote );
    
    std::vector<ScaleNote *> notes_;

    // can limit the range of notes mapped to
    int lowNoteMidiVal_;
    int highNoteMidiVal_;
    
    
};

#endif /* defined(__SnibbeLib__SnibbeScaleMap__) */
