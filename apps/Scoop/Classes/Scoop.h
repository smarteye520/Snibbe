/*
 * Scoop.h
 * (c) 2010 Scott Snibbe
 */

#pragma once

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include "dumb3d.h"
#include "ValueGraph.h"
#include "ofxMSAShape3D.h"
#import "fmod.hpp"
#import "fmod_errors.h"
#import "AudioUtils.h"
#import "ScoopDefs.h"
#include <vector>

class SoundInstance;

typedef unsigned char BYTE;

typedef enum
{
	eScoopPortrait = 1,
	eScoopLandscape,
	eScoopTransitioning,
} ScoopOrientationT;



// forward declarations
class ScoopEnvelopeManager; 

@class ObjCScoopState;



/////////////////////////////////////////////////////////////////////////
// class ScoopState
// ----------------------
// represents the state need to save/restore a scoop session
/////////////////////////////////////////////////////////////////////////

class ScoopState
{
    
public:
    
    ScoopState();
    ~ScoopState();
    
    ValueGraphState& getValueGraphState( int iIndex ) { assert( iIndex >= 0 && iIndex < NUM_VALUE_GRAPHS ); return vgState_[iIndex]; }
    
    float getNormalizedTempo() const    { return normalizedTempo_; }
    void setNormalizedTempo( float f )  { normalizedTempo_ = f; }
    
    int getBeatSetID() const               { return beatSetID_; }
    void setBeatSetID( int setid )        { beatSetID_ = setid; }
    
    int getActiveBeatID() const               { return activeBeatID_; }
    void setActiveBeatID( int beatID )        { activeBeatID_ = beatID; }

    
    void setUniqueID( int uid )         { uniqueID_ = uid; }
    int  getUniqueID() const            { return uniqueID_; }
    
protected:
    
    ValueGraphState vgState_[NUM_VALUE_GRAPHS];    
    float           normalizedTempo_;
    int             activeBeatID_;
    int             beatSetID_;
    int             uniqueID_;
    
    // anything else needed to be saved?
    
};


/////////////////////////////////////////////////////////////////////////
// class ObjCScoopState
// ----------------------
// flattened objective-c version of a scoop state... more compatible with
// user defaults serialization.
// This has knowledge of the innards of ValueGraphState but it's done for
// the sake of ease of access for save/load and because our state is simple.
/////////////////////////////////////////////////////////////////////////



@interface ObjCScoopState : NSObject <NSCoding>
{
    
    // pitch    
    NSData *pitchValuesAudio_;
    NSData *pitchValuesVisual_;
    NSNumber *numPitchValues_;
        
    // filter
    NSData *filterValuesAudio_;
    NSData *filterValuesVisual_;
    NSNumber *numFilterValues_;
    
    // volume
    NSData *volumeValuesAudio_;
    NSData *volumeValuesVisual_;
    NSNumber *numVolumeValues_;    
    
    NSNumber *      normalizedTempo_;
    
    NSNumber *      activeBeatID_;  
    NSNumber *      beatSetID_;
    
    NSNumber *      uniqueID_;
}


+ (ObjCScoopState *) objCScoopStateFromScoopState: (ScoopState *) ss;
+ (NSData *) toData: (ObjCScoopState *) Xstate;
+ (ObjCScoopState *) fromData: (NSData *) data;

-(id) init;
-(void) dealloc;
-(void) clear;

-(void) populateScoopState: (ScoopState *) ss;

-(void) clearGraphData: (int) graphIndex;

-(void) setValuesAudio: (float const *) valA visual: (float const *) valV num: (int) numValues forGraph: (int) graphIndex;

-(int) getNumValuesForGraphIndex: (int) index;
-(bool) getDataForGraphIndex: (int) index dataAudio: (NSData **) ppOutA dataVisual: (NSData **) ppOutVis;

@property (nonatomic, copy) NSNumber * normalizedTempo_;

@property (nonatomic, copy) NSNumber * activeBeatID_;
@property (nonatomic, copy) NSNumber * beatSetID_;
@property (nonatomic, copy) NSNumber * uniqueID_;


@end



/////////////////////////////////////////////////////////////////////////
// class Scoop
// ----------------------
/////////////////////////////////////////////////////////////////////////

#define Scoop_FocusNone 3

class Scoop {
public:
	
	static Scoop *createScoop( int width, int height, float scaleFactorX, float scaleFactorY, int graphSize );
	static void destroyScoop();
	static Scoop *getScoop();
	
	Scoop(int width, int height, float scaleFactorX, float scaleFactorY, int graphSize = 16*10);
	~Scoop();

    void SaveState( ScoopState& state );
    void RestoreState( ScoopState& state );
    
    void stopAllBeats();
    void setBeatSet( int beatSetID );       // sets the current set of beats playing and kicks off playback at volume zero
    void setCurBeat( int beatID );          // transitions to the beat within the current set with id beatID
    void setCurBeatIndex( int beatIndex );  // transitions to the beat within the current set with index beatIndex

    int  getBeatSet() const { return curBeatSetID_; }
    int  getActiveBeatIndex() const;    
    
    void loadAllBeats();
    
    void setPaused( bool bPause );    // pauses all audio / visuals
    bool isPaused() const { return paused_; }
    
    FMOD::Channel * playBeat( FMOD::Sound *s, float level );
    
    float getNormalizedBeatPosition() const { return (float)valueGraph_[0]->indexForTime(currentTime_) / graphSize_; }
    bool isDirty() const { return dirty_; }
    bool isMoving() const { return moving_; }
    
	//void    setScreenDimensions( int width, int height ) { screenWidth_ = width; screenHeight_ = height; }
	
    void   test() { valueGraph_[0]->scale( .2f, .2f ); }
    
    void    setSize( CGSize s ) { screenWidth_ = s.width; screenHeight_ = s.height; }
    CGSize  getSize() const { return CGSizeMake( screenWidth_, screenHeight_ );  }
    
	void	draw(CGContextRef ctx);
	void	drawGL();
	void	drawGL3D(ofxMSAShape3D *shape3D, float cameraRotation);
	
	void	update(float dt);		// update animation and any cached graphics
    
	void    numTouchesChanged( int iNumTouches );
	void	reset(float vol, float pitch, float filter);
	void	randomizeGraphs();
	void	setQuantize(int track, int steps) { assert(track>=0&&track<3); if (steps != 0) valueGraph_[track]->setQuantize(graphSize_ / steps); else valueGraph_[track]->setQuantize(0); } // make sure divisible!!
	void	setQuantizeY(int track,  float *quantizeSteps, int numSteps ) { assert(track>=0&&track<3);  valueGraph_[track]->setQuantizeY( quantizeSteps, numSteps ); }            
	float   quantizeYVal( float normalizedVal, int track );
    
	void    setSpeed( float normVal ); // speed of the audio and visuals, normalized (0-1)
	float   getNormalizedCurSpeed() const;
	
	int		quantize(int track) { return valueGraph_[track]->quantize(); }
	
    void	focusOn(int whichTrack,				// 0-3, 3 means none, starts interpolating
					float interpTime = WRAP_SCENE_TRANSFORMATION_DURATION, bool userInitiated = false );	
    
    void    focusOnLandscape( int whichTrack, CGPoint p, float cameraRotation ); // focus code for landscape mode (doesn't involve the translation and scaling of the normal focus on code)
    
	int		focusTrack() { return focusTrack_; }
    void    reFocus() { focusOn( focusTrack(), 0.0f ); }
	int		trackHitsPoint(CGPoint p, float cameraRotation, float scaleBBox = -1.0f );	// does the point intersect the track
    int     trackShouldGetFocusOnPhoneTransitionToPortrait() const;
    
	void startUnwrap( float dur = WRAP_SCENE_TRANSFORMATION_DURATION );
	void startWrap( float dur = WRAP_SCENE_TRANSFORMATION_DURATION );
	ScoopOrientationT getScoopOrientation();  
	

    
    
	float	fps()	{ return fps_; }
	float	lowFps()	{ return lowFps_; }
	
	void	scaleFactor(float x, float y) { scaleFactorX_ = x; scaleFactorY_ = y; }
	bool	getSelectedTrackScreenYRange(float& bottom, float& top) 	{
		if (focusTrack_ != Scoop_FocusNone) {
			valueGraph_[focusTrack_]->sliderScreenYRange(bottom, top);
			return true;
		}
		return false;
	}

	bool	writeIntoSelectedTrack(bool start, float cameraRotation);
    CGRect  getWritingTrackBoundingBox( float cameraRotation );
    
	void	stopWritingIntoSelectedTrack();	
	bool	writingIntoSelectedTrack() { return writingTrack_ != Scoop_FocusNone; }
	
	// this represents either the last position in single touch mode or the average of all
	// touch positions in multi-touch mode
	void	lastTouch(CGPoint pos, double touchTime) { lastTouch_.x = screenWidth_ - pos.x; 
									                       lastTouch_.y = screenHeight_ - pos.y; 
														   lastTouchTime_ = touchTime; }
		
    CGPoint getLastTouch() const { return lastTouch_; }
    double  lastTime() const { return lastTime_; }
    float   wrapDuration() const { return wrapDuration_; }
    float   baselineWrapDuration() const { return wrapDurationBaseline_; }
    float   getCurBPM() const { return calculateBPM(wrapDuration_, NUM_BEATS_PER_LOOP); }
    
    void clearDirty() { dirty_ = false; }
    
    
    // settings values for audio tuning
    
    
    void SetToneFrequency( float hz );
    void SetToneRange( float octaves ) { toneRangeNumOctaves_ = octaves; }
    void SetMinCutoff( float hz ) { filterMinCutoff_ = hz; }
    void SetMaxCutoff( float hz ) { filterMaxCutoff_ = hz; }
    void SetResonance( float q ) { filterResonance_ = q; }
    void SetToneVolMax( float vol ) { toneVolMax_ = vol; }
    void SetBeatVol( float vol );
    
    void MuteBeats( bool bMute );
    bool BeatsMuted() const { return muteBeats_; }
    
    void FadeMasterVol( float target, float dur = INITIAL_FADE_UP_DURATION, float fromLevel = -1.0f );
    
	// dsp callbacks
	FMOD_RESULT volumeEnvelopeDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels);
	FMOD_RESULT clockSynchronizeDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels);

	
private:
	
    
	static Scoop * msTheScoop_; // singleton
	
	void drawDebugGL(float rotation);
	void resetRoll();

    double calculateTimeWithinSound();
	void updateTime();
	
    void updateMasterVolFade();
	
	float	normValue();	// return normalized value from controller for editing graph

	// custom DSP effects
	void createVolumeEnvelopDSP();
    void createClockSyncDSP();
	
	// old sound code
	//void playBreak(BYTE channel, BYTE note = 36);
	//void stopBreak(BYTE channel, BYTE note = 36);

	void setFilter(BYTE channel, BYTE filterValue);
	void setPitch(BYTE channel, BYTE pitch);
	void setVolume(BYTE channel, BYTE volume);
	void setProgram(BYTE prog);
	void killSound(BYTE channel);

	bool passedBeatQuantizePoint( float secLow, float secHigh ) const;
	//void initMidi(HWND hwnd);
	
	// new sound code: FMOD
	void initSound();
	void updateSound();
    
	void playSynth();

	void setPitch(float freq);
	void setFilter(float freq, float resonance);
	void setVolume(float v);

    void clearBeatSoundInstances();
    SoundInstance *getActiveSoundInstance();
    
    void setDirty() { dirty_ = true; }
    
    
	enum State {
		Round,
		Flat,
		IntoRound,
		IntoRound2,
		IntoFlat,
		IntoFlat2
	} state_;

	//Controller	*controller_;
	ValueGraph **valueGraph_;

    int valueGraphDrawOrder_[NUM_VALUE_GRAPHS];

	
	int		focusTrack_;
	bool	lastButtonA_;
	bool	lastButtonB_;
	bool    paused_;
    bool    beenPaused_;
	int		writingTrack_;
	
	float   baselineMasterPitch_;

	// MaxMIDI
	//HMOUT hMidiOut_;		// handle to the midi out device
	
	ScoopEnvelopeManager *envManager_;
	
	// audio
	FMOD::System   *system_;
    
    FMOD::ChannelGroup *channelGroupBeats_;

    
    std::vector<FMOD::Sound *> setBeats_;
    std::vector<FMOD::Sound *> fadingSetBeats_;
    
    std::vector<SoundInstance *> setSoundInstances_;
    std::vector<SoundInstance *> fadingOutSoundInstances_;
    
    FMOD::Channel  *channelSynth_;
    
    FMOD::DSP      *dsp_;
	FMOD::DSP	   *dspLowPass_;
	FMOD::DSP      *dspVolEnvelope_;
	FMOD::DSP      *dspClockSync_;
	
	//Uint64P		    dspClockBegin_; // start time of the DSP	
	
	//FMOD::DSP      *dspTremolo_; for testing

	CGPoint	size_[3];	// Size of each loop
	point_4	pos_[3];	// Pos of each loop

	// initial and final states while interpolating
	CGPoint	startSize_[3];
	CGPoint	endSize_[3];
	point_4	startPos_[3];
	point_4	endPos_[3];

	float	unwrapFactorH_, unwrapFactorV_;	// scale factor for unwrapped graph in relation to 1:1
	float	cursorXOff_;

	bool	moving_;		// whether we are in transition from 1 configuration to another
	bool	justMoved_;
	bool	triggerMode_;

	double	startTime_;
	double	currentTime_, lastTime_, deltaTime_;
	double	intervalTime_;

    double  timeAtLastDSPChunkLoad_;
    double  channelPosAtLastDSPChunkLoad_;
    double  lastTimeWithinSound_;
    double  beginTime_;
    double  timeAtPause_;
    double  pauseLengthDuringCurrentChunk_;
    unsigned int numTotalLoops_;
    
	float	wrapDuration_;
	float   wrapDurationBaseline_;

	float	boundarySize_;
	float	normalSize_;
	float	focusSize_;
	float	screenWidth_;
	float	screenHeight_;

	float	moveThreshold_;

	//clock_t	rawTime_;
	int		graphSize_, valSize_, halfGraphSize_;
	int		updateCount_;

	int		lastGraphIndex_, graphIndex_;
	float	normValue_, lastNormValue_;
	float	adjustedNormValue_, lastAdjustedNormValue_;
    float   normValueX_, lastNormValueX_;
    
    float   currentFlatCamRotationCoef_;
    
    int     activeBeatID_;
    int     activeBeatIndex_;
    int     curBeatSetID_;        
    
	//bool	quantize_[3];
	bool	playBeat_;

	ValueGraph::State lastVGraphState_;

	float	fps_, lowFps_;
	double	lowFpsTime_;
	
	float	scaleFactorX_;
    float	scaleFactorY_;
    
	double	lastTouchTime_;
	
	int     lastNumTouches_;
	int     curNumTouches_;
	
    bool    dirty_;
    float   normalizedSpeed_;
    
    bool    muteBeats_;

    // volume fading
    double timeVolFadeEnd_;
    double timeVolFadeBegin_;
    float  volFadeStart_;
    float  volFadeTarget_;
    
    

	// test
	//float modulationAmp_;
	//float modulationFreq_;
	
    // tunable audio vals
    
    float toneFrequency_;        // hz
    float toneRangeNumOctaves_;
    float filterMinCutoff_;      // hz
    float filterMaxCutoff_;      // hz
    float filterResonance_;      // q
    float toneVolMax_;   
    float beatVol_;
    
    int   numTimeUpdates_;
    int   numTrackWriteCountThisFrame_;
    
    int   totalGraphIndicesForCurrentWrite_;
    int   lastGraphIndexForCurrentWrite_;

    int   graphIndexAtWriteBegin_;
    float forcedGraphValue_;
    int   forcedGraphIndex_;
    int   numForcedGraphIndicesRemaining_;
    int   lastForcedGraphIndex_;
    
    
	
	// debug
	float	graphBottom_, graphTop_;
	CGPoint	lastTouch_;
};
