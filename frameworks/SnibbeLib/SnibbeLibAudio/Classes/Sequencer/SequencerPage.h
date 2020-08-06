//
//  SequencerPage.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/13/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef __SnibbeLib__SequencerPage__
#define __SnibbeLib__SequencerPage__

#include <string>
#include <vector>

namespace ss
{
  
    class SequencerPage
    {
        
    public:
        
        //
        // Fields used to populate sequencers for playback
        typedef struct DataT
        {
            DataT();
            
            bool on_;
            std::string filePath_;
            unsigned int midiNote_; // optional
            
        } DataT;
        
        
        SequencerPage();
        ~SequencerPage();
        
        void init( unsigned int xCount, unsigned int yCount );
        DataT& dataAt( unsigned int xIndex, unsigned int yIndex );
        
        void clear();
        
        unsigned int getSizeX() const { return xSize_; }
        unsigned int getSizeY() const { return ySize_; }
        
    private:
        
        std::vector< std::vector<DataT *> * > pageData_;
        unsigned int xSize_;
        unsigned int ySize_;
    };
};

#endif /* defined(__SnibbeLib__SequencerPage__) */
