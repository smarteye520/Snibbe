//
//  SequencerPage.cpp
//  SnibbeLib
//
//  Created by Graham McDermott on 11/13/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#include "SequencerPage.h"
#include <assert.h>

using namespace ss;

//
//
SequencerPage::DataT::DataT() :
    on_( false ),
    filePath_(""),
    midiNote_(0)

{
    
}


//
//
SequencerPage::SequencerPage() :
    xSize_(0),
    ySize_(0)
{
    
}

//
//
SequencerPage::~SequencerPage()
{ 
    clear();
}

//
//
void SequencerPage::init( unsigned int xCount, unsigned int yCount )
{
    assert( xCount >= 0 );
    assert( yCount >= 0 );
    
    clear();
    
    for (int x = 0; x < xCount; ++x )
    {
        std::vector<DataT *> * newDataVec = new std::vector<DataT *>();
        
        for ( int y = 0; y < yCount; ++y )
        {
            DataT * newData = new DataT();
            newDataVec->push_back( newData );
        }
        
        pageData_.push_back( newDataVec );
    }
    
    xSize_ = xCount;
    ySize_ = yCount;
    
}

//
//
SequencerPage::DataT& SequencerPage::dataAt( unsigned int xIndex, unsigned int yIndex )
{
    assert( xIndex >= 0 && xIndex < xSize_ );
    assert( yIndex >= 0 && yIndex < ySize_ );
    
    return *(*(pageData_[xIndex]))[yIndex];
}

//
//
void SequencerPage::clear()
{
    for (int x = 0; x < xSize_; ++x )
    {
        std::vector<DataT *> * dataVec = pageData_[x];
        
        for ( int y = 0; y < ySize_; ++y )
        {
            delete (*dataVec)[y];
        }
        
        delete dataVec;
        
    }
    
    pageData_.clear();
    xSize_ = 0;
    ySize_ = 0;

}
