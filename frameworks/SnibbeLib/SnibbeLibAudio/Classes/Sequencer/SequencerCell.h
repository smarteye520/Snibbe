//
//  SequencerCell.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/13/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef __SnibbeLib__SequencerCell__
#define __SnibbeLib__SequencerCell__

#include "SequencerDefs.h"
#include "SSTypeDefs.h"
#include "SequencerPage.h"
#include <set>

class SnibbeSoundInstance;

namespace ss
{
    class SequencerCell
    {
        
    public:
        
        SequencerCell();
        virtual ~SequencerCell();
        
        // ensures that a sound instance is allocated with the current file path
        void refreshSound( bool bStartPaused = true );
        
        virtual void schedule(  SeqTimeT absDSPTimeCur, SeqTimeT atAbsDSPSeconds, SeqTimeT maxJitter = 0 );
        
        void update( SeqTimeT curTime, SeqTimeT deltaTime );
        
        virtual void initFromPageData( SequencerPage::DataT& pageData, bool preserveOn = true );
        void setSilentFilePath( std::string& filePath ) { filePathSilent_ = filePath; }
        
        //void setSound( shared_ptr<SnibbeSoundInstance> soundInst ) { soundInst_ = soundInst; }
        SnibbeSoundInstance * getSound() { return soundInst_; }
        
        void setOn( bool bOnOff );
        bool getOn() const { return on_; }
        
        void setVolume( float vol );
        float getVolume() const { return vol_; }
        
        void stop();
        
        virtual bool canPlay() const;
        bool dirty() const { return dirty_ || filePathDirty_; }
        void clearDirty() { dirty_ = false; filePathDirty_ = false; }
        void onSoundInstanceComplete( SnibbeSoundInstance * pInst );
        
        static std::set<SequencerCell *> allCells_;
        
    protected:
        
        virtual bool allocSoundInstance();
        
        SnibbeSoundInstance * soundInst_;
        SnibbeSoundInstance * soundInstPrev_;
        
        std::string filePath_;
        std::string filePathSilent_;
        
        bool on_;
        bool filePathDirty_;
        bool dirty_;
        float vol_;
        bool usePrevInstance_;
        
        //float muteFadeTime_;
        //bool muted_;
    };

};


extern "C" void onCellInstanceComplete ( SnibbeSoundInstance * pInst );

#endif /* defined(__SnibbeLib__SequencerCell__) */
