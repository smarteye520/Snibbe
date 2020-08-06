/*
 *  SnibbeAudioUtils.mm
 *  SnibbeLib
 *
 *  Created by Graham McDermott on 2/25/11.
 *  Copyright 2011 Scott Snibbe. All rights reserved.
 *
 */


#include "SnibbeAudioUtils.h"
#include <stdio.h>
#include "fmod_errors.h"


///////////////////////////////////////////////////////////////////////////////
// BPM calculations
///////////////////////////////////////////////////////////////////////////////

float calculateBPM( float loopLength, int beatsPerLoop )
{	
	float bps = beatsPerLoop / loopLength;
	return bps * 60.0f;		
}





///////////////////////////////////////////////////////////////////////////////
// FMOD helpers
///////////////////////////////////////////////////////////////////////////////

int fmodSystemSampleRate = 0;
double invFMODSystemSampleRate = 0.0f;
FMOD::System * system_ = 0;


//
//
void ERRCHECK(FMOD_RESULT result)
{
    if (result != FMOD_OK)
    {
        fprintf(stderr, "FMOD error! (%d) %s\n", result, FMOD_ErrorString(result));
    }
}

//
//
void ERRCHECK_CHANNEL(FMOD_RESULT result)
{
    if (result != FMOD_OK && result != FMOD_ERR_INVALID_HANDLE
        && result != FMOD_ERR_CHANNEL_STOLEN)
    {
        fprintf(stderr, "FMOD error! (%d) %s\n", result, FMOD_ErrorString(result));        
    }
}


//
// global setter for fmod system
FMOD::System * GetFMODSystem()
{    
    return system_;
}

//
// global setter for fmod system
void SetFMODSystem( FMOD::System * s)    
{
    system_ = s;
}

//
//
void InitGlobalAudioVals()
{
	GetFMODSystem()->getSoftwareFormat( &fmodSystemSampleRate, NULL, NULL, NULL, NULL, NULL );
    invFMODSystemSampleRate = 1.0f / (double)fmodSystemSampleRate;
}

//
// seconds expressed in fmod DSP clock ticks
Uint64P ConvertSecToDSPTicks( double s )
{
	
    // important to do right multiply first or we exceed the 32 bit value easily
	return Uint64P( fmodSystemSampleRate * s );	
}

//
// milliseconds expressed in fmod DSP clock ticks
Uint64P ConvertMsToDSPTicks( unsigned int ms )
{
	
    // important to do right multiply first or we exceed the 32 bit value easily
	return Uint64P( fmodSystemSampleRate * ((double)ms * .001f) );	
}

//
//
unsigned int ConvertDSPTicksToMs( Uint64P ticks )
{
    return ticks.value() * (invFMODSystemSampleRate * 1000.0f);
}

//
// convert beats per minute to milliseconds per beat
float BpmToMSPerBeat( float bpm )
{
    return 1.0f / (bpm * 0.000016666666667f );
}

//
// convert milliseconds per beat to beats per minute
float MsPerBeatToBpm( float msPerBeat )
{
    return 1.0f / (msPerBeat * 0.000016666666667f );
}

//
//
double getFMODBufferDuration()
{

    unsigned int bufSize = 0;
    int numBuffers = 0;
    
    FMOD_RESULT result = system_->getDSPBufferSize( &bufSize, &numBuffers );
    ERRCHECK(result);
    
    return bufSize * invFMODSystemSampleRate;
    


}



//
// create a sound (streamed or loaded) using FMOD given the filename and extension of a file in the main bundle

#ifdef __OBJC__

FMOD::Sound * CreateFMODSound( NSString *name, NSString *ext, bool bStreaming )
{
    
    // revisit this if we need to and remove the biophilia calls
        
    
    FMOD::Sound *pSound = 0;
    
    FMOD_RESULT result        = FMOD_OK;
    char pathBuffer[PATH_MAX]   = {0};
    
    if ( name && ext )
    {
        
        //NSString *tmpString = [NSString stringWithFormat:@"%@.%@", name, ext];
        NSBundle *pBundle = [NSBundle mainBundle]; 
        NSString *resPath = [pBundle pathForResource: name ofType: ext];
        
        if ( resPath )
        {
            
            [resPath getCString:pathBuffer maxLength:PATH_MAX encoding:NSASCIIStringEncoding];
            return CreateFMODSoundFromPath( pathBuffer, bStreaming );                        
            
        }
        else 
        {
            result = FMOD_ERR_INVALID_PARAM;
        }
        
    }
    else 
    {
        result = FMOD_ERR_INVALID_PARAM;
    }
    
    ERRCHECK(result);	
    
    return pSound;
    
    
    return 0;
}

//
// create a sound (streamed or loaded) using FMOD given a URL
FMOD::Sound * CreateFMODSoundURL( NSURL *url, bool bStreaming )
{
    
    // revisit this if we need to and remove the biophilia calls
    
    
    
    FMOD::Sound *pSound = 0;
    
    FMOD_RESULT result        = FMOD_OK;
    char pathBuffer[PATH_MAX]   = {0};
    
    if ( url )
    {
        NSString *resPath = [url path];
        
        if ( resPath )
        {
            [resPath getCString:pathBuffer maxLength:PATH_MAX encoding:NSASCIIStringEncoding];			
            
            if ( bStreaming )
            {
                result = system_->createStream(pathBuffer, FMOD_CREATECOMPRESSEDSAMPLE | FMOD_SOFTWARE, NULL, &pSound);			
            }
            else
            {
                result = system_->createSound(pathBuffer, FMOD_CREATECOMPRESSEDSAMPLE | FMOD_SOFTWARE, NULL, &pSound);			                
            }
            
        }
        else 
        {
            result = FMOD_ERR_INVALID_PARAM;
        }
        
    }
    else 
    {
        result = FMOD_ERR_INVALID_PARAM;
    }
    
    ERRCHECK(result);	
    
    return pSound;
    
    
    return 0;
}

#endif // #ifdef __OBJC__


//
//
FMOD::Sound * CreateFMODSoundFromPath( const char * fullPath, bool bStreaming )
{
    FMOD_RESULT result = FMOD_OK;
    FMOD::Sound *pSound = 0;
    
    if ( bStreaming )
    {
        result = system_->createStream(fullPath, FMOD_CREATECOMPRESSEDSAMPLE | FMOD_SOFTWARE, NULL, &pSound);
    }
    else
    {
        result = system_->createSound(fullPath, FMOD_CREATECOMPRESSEDSAMPLE | FMOD_SOFTWARE, NULL, &pSound);
    }
    
    ERRCHECK( result );
    
    return pSound;
}

