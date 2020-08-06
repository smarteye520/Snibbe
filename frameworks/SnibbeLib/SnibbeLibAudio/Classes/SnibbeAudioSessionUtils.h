/*
 *  SnibbeAudioSessionUtils.h
 *  Shared
 *
 *  Created by Graham McDermott on 2/25/11.
 *  Copyright 2012 Scott Snibbe. All rights reserved.
 *
 *
 *  ---------------------------------------
 *  Helper functions for interfacing with the AudioSession API
 */


#ifndef __AUDIO_SESSION_UTILS_H__
#define __AUDIO_SESSION_UTILS_H__



///////////////////////////////////////////////////////////////////////////////
// AudioSessionHelpers
///////////////////////////////////////////////////////////////////////////////

extern "C" bool InitAudioSession();
extern "C" void IgnoreDeviceMute();





#endif // __AUDIO_SESSION_UTILS_H__