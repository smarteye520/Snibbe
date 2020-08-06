/*
 *  SnibbeAudioSessionUtils.mm
 *  SnibbeLib
 *
 *  Created by Graham McDermott on 2/25/11.
 *  Copyright 2012 Scott Snibbe. All rights reserved.
 *
 */


#include "SnibbeAudioSessionUtils.h"
#import <AudioToolbox/AudioServices.h>


///////////////////////////////////////////////////////////////////////////////
// AudioSession helpers
///////////////////////////////////////////////////////////////////////////////

static bool gAudioSessionInit = false;

//
//
bool InitAudioSession()
{
    AudioSessionInterruptionListener    inInterruptionListener = NULL;
    OSStatus error;
    error = AudioSessionInitialize (NULL, NULL, inInterruptionListener, NULL);
    
    if ( error != kAudioSessionNoError )
    {
        return false;
    }
    else
    {
        // success!        
        gAudioSessionInit = true;
        return true;
    }
    
}

//
// AudioSession must be init before callling.
// This call instructs the app to either respect the system's mute setting or
// ignore it.
void IgnoreDeviceMute()
{
    if ( gAudioSessionInit )
    {
        UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;        
        AudioSessionSetProperty( kAudioSessionProperty_AudioCategory, sizeof(sessionCategory) , &sessionCategory );
        
    }
}



