/*
 * Scoop.cpp
 * (c) 2010 Scott Snibbe
 */

#include "Scoop.h"
#include "ValueGraph.h"
#include "AudioUtils.h"
#include "ScoopEnvelopeManager.h"
#include "ScoopDefs.h"
#include "ScoopBeat.h"
#include "SoundInstance.h"
#include "ScoopUtils.h"

// equality comparison with some degree of variance
#define FUZZY_EQUAL( a, b, var ) ( (a-var <= b) && (a+var >= b) )

//#define	kTestSoundFile @"Krafted_3.wav"
#define	kTestSoundFile @"contemporary_break.wav"
#define kTestSoundFileLength 4.0

#define NUM_GRAPHS 3
//const float kBaseFrequency=220.0;  // A3
const float kBaseFrequency=123.47;  // A3

const int kNumEnvelopeCyclesPerLoop = 16;
const int kNumQuantizeSectionsPerLoop = 16;
const int kVerticalValueResolution = 128;

// some of the original drawing computation was based on this number so we
// need to account for it now that the numbers can change
const int kOrinalGraphSize = 16*20;

// scoop crown colors
const CGFloat PITCH_GRAPH_FRONT_COLOR[] = {248.0/255.0, 169.0/255.0, 19.0/255.0, 1.0};
const CGFloat PITCH_GRAPH_BACK_COLOR[] = {225.0/255.0, 188.0/255.0, 95.0/255.0, 1.0};
const CGFloat PITCH_GRAPH_BG_COLOR[] = {172.0/255.0, 216.0/255.0, 230.0/255.0, 1.0}; // bg color not currently used

const CGFloat FILTER_GRAPH_FRONT_COLOR[] = {225.0/255.0, 96.0/255.0, 64.0/255.0, 1.0};
const CGFloat FILTER_GRAPH_BACK_COLOR[] = {225.0/255.0, 129.0/255.0, 104.0/255.0, 1.0};
const CGFloat FILTER_GRAPH_BG_COLOR[] = {237.0/255.0, 255.0/255.0, 131/255.0, 1.0}; // bg color not currently used

const CGFloat VOLUME_GRAPH_FRONT_COLOR[] = {173.0/255.0, 187.0/255.0, 25.0/255.0, 1.0};
const CGFloat VOLUME_GRAPH_BACK_COLOR[] = {201.0/255.0, 205.0/255.0, 48.0/255.0, 1.0};
const CGFloat VOLUME_GRAPH_BG_COLOR[] = {255.0/255.0, 102.0/255.0, 106.0/255.0, 1.0}; // bg color not currently used



/*
#define SELECT_GRAPH_FRONT_COLOR	62, 78, 153		// deep blue, fwd selected graph
#define SELECT_GRAPH_BACK_COLOR		0, 171, 220		// lighter blue, back selected graph
#define SELECT_GRAPH_BG_COLOR		172, 216, 230	// cyan, bg selected graph

#define VOLUME_GRAPH_FRONT_COLOR	167, 11, 85		// deep blue, fwd selected graph
#define VOLUME_GRAPH_BACK_COLOR		227, 80, 84		// lighter blue, back selected graph
#define VOLUME_GRAPH_BG_COLOR		255, 102, 106	// cyan, bg selected graph

#define PITCH_GRAPH_FRONT_COLOR		62, 78, 153		// deep blue, fwd selected graph
#define PITCH_GRAPH_BACK_COLOR		0, 171, 220		// lighter blue, back selected graph
#define PITCH_GRAPH_BG_COLOR		172, 216, 230	// cyan, bg selected graph

#define FILTER_GRAPH_FRONT_COLOR	142, 166, 0		// deep blue, fwd selected graph
#define FILTER_GRAPH_BACK_COLOR		181, 212, 0		// lighter blue, back selected graph
#define FILTER_GRAPH_BG_COLOR		237, 255, 131	// cyan, bg selected graph
*/




/////////////////////////////////////////////////////////////////////////
// class ScoopState
/////////////////////////////////////////////////////////////////////////


//
//
ScoopState::ScoopState()
{
    normalizedTempo_ = 0.5;
    beatSetID_ = -1;
    activeBeatID_ = 0;
    uniqueID_ = -1;
}

//
//
ScoopState::~ScoopState()
{
    for ( int i = 0; i < NUM_VALUE_GRAPHS; ++i )
    {
        vgState_[i].clear();
    }
}

/////////////////////////////////////////////////////////////////////////
// class ObjCScoopState
/////////////////////////////////////////////////////////////////////////


NSString *codingKeyPV = @"pitch_values";
NSString *codingKeyPVVisual = @"pitch_values_visual";
NSString *codingKeyNumPV = @"num_pitch_values";
NSString *codingKeyFV = @"filter_values";
NSString *codingKeyFVVisual = @"filter_values_visual";
NSString *codingKeyNumFV = @"num_filter_values";
NSString *codingKeyVV = @"volume_values";
NSString *codingKeyVVVisual = @"volume_values_visual";
NSString *codingKeyNumVV = @"num_volume_values";

NSString *codingKeyNormTemp = @"normalized_tempo";
NSString *codingKeyActiveBeatID = @"active_beat_id";
NSString *codingKeyBeatSetID = @"beat_set_id";
NSString *codingKeyUniqueID = @"unique_id";


// private interface
@interface ObjCScoopState()

-(void) getDataAudio: (NSData ***) pppDataAud visual: (NSData ***) pppDataVis size: (NSNumber ***) pppSize forGraph: (int) graphIndex;

// NSCoding protocol methods

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;


@end


@implementation ObjCScoopState


@synthesize normalizedTempo_;
@synthesize activeBeatID_;
@synthesize beatSetID_;
@synthesize uniqueID_;

//
//
+ (ObjCScoopState *) objCScoopStateFromScoopState: (ScoopState *) ss
{
    ObjCScoopState * newSS = [[ObjCScoopState alloc] init];
    
    newSS.normalizedTempo_ = [NSNumber numberWithFloat: ss->getNormalizedTempo()];
    newSS.activeBeatID_ = [NSNumber numberWithInt: ss->getActiveBeatID() ];
    newSS.beatSetID_ = [NSNumber numberWithInt: ss->getBeatSetID() ];
    newSS.uniqueID_ = [NSNumber numberWithInt: ss->getUniqueID() ];
    
    ValueGraphState& vgPitch = ss->getValueGraphState(PITCH_GRAPH_INDEX);
    ValueGraphState& vgFilter = ss->getValueGraphState(FILTER_GRAPH_INDEX);
    ValueGraphState& vgVolume = ss->getValueGraphState(VOLUME_GRAPH_INDEX);
    
    [newSS setValuesAudio: vgPitch.getValuesAudio() visual: vgPitch.getValuesVisual() num:vgPitch.getNumValues() forGraph:PITCH_GRAPH_INDEX];
    [newSS setValuesAudio: vgFilter.getValuesAudio() visual: vgFilter.getValuesVisual() num:vgFilter.getNumValues() forGraph:FILTER_GRAPH_INDEX];
    [newSS setValuesAudio: vgVolume.getValuesAudio() visual: vgVolume.getValuesVisual() num:vgVolume.getNumValues() forGraph:VOLUME_GRAPH_INDEX];
    
    return [newSS autorelease];
}

//
// convert the scoop state to NSData for compatibility with user settings archiving
+ (NSData *) toData: (ObjCScoopState *) state
{
    if ( state )
    {
        return [NSKeyedArchiver archivedDataWithRootObject: state];
    }
    
    return nil;
}

//
// convert the data to scoop state for compatibility with user settings archiving 
+ (ObjCScoopState *) fromData: (NSData *) data
{
    if ( data )
    {
        return [NSKeyedUnarchiver unarchiveObjectWithData: data];
    }

    return nil;
}


//
//
-(id) init
{
    if ( (self=[super init]) )
    {
        pitchValuesAudio_ = nil;
        pitchValuesVisual_ = nil;
        numPitchValues_ = nil;
        filterValuesAudio_ = nil;
        filterValuesVisual_ = nil;
        numFilterValues_ = nil;
        volumeValuesAudio_ = nil;
        volumeValuesVisual_ = nil;
        numVolumeValues_ = nil;
        
        normalizedTempo_ = nil;
        beatSetID_ = nil;
        activeBeatID_ = nil;
        uniqueID_ = nil;
        
        
    }

    return self;
}

//
//
-(void) dealloc
{
    [self clear];
    [super dealloc];
}

//
//
-(void) clear
{
    self.normalizedTempo_ = nil;
    self.beatSetID_ = nil;
    self.activeBeatID_ = nil;
    self.uniqueID_ = nil;
    
    [self clearGraphData: PITCH_GRAPH_INDEX];
    [self clearGraphData: FILTER_GRAPH_INDEX];
    [self clearGraphData: VOLUME_GRAPH_INDEX];
        
}


// populate scoop state values based on the values in this objective-c ss object
// assumes that unique ID has already been assigned
-(void) populateScoopState: (ScoopState *) ss
{
    assert(ss);
    
    if ( ss )
    {
        
        // we've created a new c++ scoop state with the unique id we got
        // from the saved defaults.  populate it with the other data
        
        ss->setNormalizedTempo( [self.normalizedTempo_ floatValue] );
        ss->setActiveBeatID( [self.activeBeatID_ intValue] );
        ss->setBeatSetID( [self.beatSetID_ intValue] );
        
        ValueGraphState& vgPitch = ss->getValueGraphState( PITCH_GRAPH_INDEX );
        ValueGraphState& vgFilter = ss->getValueGraphState( FILTER_GRAPH_INDEX );
        ValueGraphState& vgVolume = ss->getValueGraphState( VOLUME_GRAPH_INDEX );
        
        vgPitch.setValues ( (float *) [pitchValuesAudio_ bytes], (float *) [pitchValuesVisual_ bytes], [numPitchValues_ intValue] );
        vgFilter.setValues( (float *) [filterValuesAudio_ bytes], (float *) [filterValuesVisual_ bytes], [numFilterValues_ intValue] );
        vgVolume.setValues( (float *) [volumeValuesAudio_ bytes],  (float *) [volumeValuesVisual_ bytes], [numVolumeValues_ intValue] );
        
    }
}


//
// release storage for the graph information corresponding to the given index
-(void) clearGraphData: (int) graphIndex
{
    NSData **ppDataAudio = 0;
    NSData **ppDataVisual = 0;
    NSNumber **ppSize = 0;
    
    [self getDataAudio: &ppDataAudio visual: &ppDataVisual size: &ppSize forGraph:graphIndex];
    if ( ppDataAudio && ppDataVisual && ppSize )
    {
        [*ppDataAudio release];
        *ppDataAudio = nil;
        
        [*ppDataVisual release];
        *ppDataVisual = nil;
        
        [*ppSize release];
        *ppSize = nil;
    }
}


// given an array of float values for the given graph index, copy the data into
// an objective-c compatible data structure
//-(void) setValues: (float const *) val num: (int) numValues forGraph: (int) graphIndex
-(void) setValuesAudio: (float const *) valA visual: (float const *) valV num: (int) numValues forGraph: (int) graphIndex;

{
    [self clearGraphData: graphIndex];
    
    NSData **ppDataAudio = 0;
    NSData **ppDataVisual = 0;
    NSNumber **ppSize = 0;
    
    [self getDataAudio: &ppDataAudio visual: &ppDataVisual size: &ppSize forGraph:graphIndex];

    if ( ppDataAudio && ppDataVisual && ppSize )
    {    
        // set the data
        *ppDataAudio = [NSData dataWithBytes: valA length: numValues * sizeof(float)];
        *ppDataVisual = [NSData dataWithBytes: valV length: numValues * sizeof(float)];
        
        [*ppDataAudio retain];
        [*ppDataVisual retain];
        
        // set the size
        *ppSize = [NSNumber numberWithInt:numValues];
        [*ppSize retain];
        
    }
}


// Return the number of float values that are stored in the graph data associated with
// the given graph index
-(int) getNumValuesForGraphIndex: (int) index
{
    NSData **ppDataA = 0;
    NSData **ppDataV = 0;
    NSNumber **ppSize = 0;
    
    [self getDataAudio: &ppDataA visual: &ppDataV size: &ppSize forGraph:index];
    if ( ppDataA && ppDataV && ppSize )
    {
        int numBytes = [(*ppSize) intValue];
        return numBytes / sizeof( float );
    }

    return 0;
}

// Return the objective-c NSData object containing the float values (graph data)
// associated with the given graph index
//-(NSData *) getDataForGraphIndex: (int) index
-(bool) getDataForGraphIndex: (int) index dataAudio: (NSData **) ppOutA dataVisual: (NSData **) ppOutVis;
{
    
    NSNumber **ppSize = 0;
    [self getDataAudio:&ppOutA visual:&ppOutVis size:&ppSize forGraph: index];
        
    return ppOutA && ppOutVis && ppSize;    

}


// private implementation

//
// helper to get the appropriate member vars for a the graph index
-(void) getDataAudio: (NSData ***) pppDataAud visual: (NSData ***) pppDataVis size: (NSNumber ***) pppSize forGraph: (int) graphIndex;
{
    assert( pppDataAud && pppDataVis && pppSize );
    
    if ( graphIndex == PITCH_GRAPH_INDEX )
    {
        *pppDataAud = &pitchValuesAudio_;
        *pppDataVis = &pitchValuesVisual_;
        *pppSize = &numPitchValues_;
    }
    else if ( graphIndex == FILTER_GRAPH_INDEX )
    {
        *pppDataAud = &filterValuesAudio_;
        *pppDataVis = &filterValuesVisual_;
        *pppSize = &numFilterValues_;
    }
    else if ( graphIndex == VOLUME_GRAPH_INDEX )
    {
        *pppDataAud = &volumeValuesAudio_;
        *pppDataVis = &volumeValuesVisual_;
        *pppSize = &numVolumeValues_;
    }
    else
    {
        *pppDataAud = nil;
        *pppDataVis = nil;
        *pppSize = nil;
    }
}


// NSCoding protocol methods

//
//
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    //[super encodeWithCoder: aCoder]; superclass doesn't support
    
    [aCoder encodeObject: pitchValuesAudio_ forKey: codingKeyPV];
    [aCoder encodeObject: pitchValuesVisual_ forKey: codingKeyPVVisual];
    [aCoder encodeObject: numPitchValues_ forKey: codingKeyNumPV];
    
    [aCoder encodeObject: filterValuesAudio_ forKey: codingKeyFV];
    [aCoder encodeObject: filterValuesVisual_ forKey: codingKeyFVVisual];
    [aCoder encodeObject: numFilterValues_ forKey: codingKeyNumFV];
    
    [aCoder encodeObject: volumeValuesAudio_ forKey: codingKeyVV];
    [aCoder encodeObject: volumeValuesVisual_ forKey: codingKeyVVVisual];
    [aCoder encodeObject: numVolumeValues_ forKey: codingKeyNumVV];
    
    [aCoder encodeObject: normalizedTempo_ forKey: codingKeyNormTemp ];
    [aCoder encodeObject: activeBeatID_ forKey: codingKeyActiveBeatID ];
    [aCoder encodeObject: beatSetID_ forKey: codingKeyBeatSetID ];
    [aCoder encodeObject: uniqueID_ forKey: codingKeyUniqueID];
    
        
}

//
//
- (id)initWithCoder:(NSCoder *)aDecoder
{
 
    self = [super init]; // superclass doesn't support NSCoder
    
    
    pitchValuesAudio_ = [[aDecoder decodeObjectForKey:codingKeyPV] retain];
    
    // backwards compatibility - may not exist
    if ( [aDecoder containsValueForKey: codingKeyPVVisual] )
    {
        pitchValuesVisual_ = [[aDecoder decodeObjectForKey:codingKeyPVVisual] retain];        
    }
    else 
    {    
        // todo - test this
        pitchValuesVisual_ = [[NSData dataWithData: pitchValuesAudio_] retain];
    }
    
    
    numPitchValues_ = [[aDecoder decodeObjectForKey:codingKeyNumPV] retain];
    
    
    
    filterValuesAudio_ = [[aDecoder decodeObjectForKey:codingKeyFV] retain];
    
    // backwards compatibility - may not exist
    if ( [aDecoder containsValueForKey: codingKeyFVVisual] )
    {
        filterValuesVisual_ = [[aDecoder decodeObjectForKey:codingKeyFVVisual] retain];        
    }
    else 
    {    
        // todo - test this
        filterValuesVisual_ = [[NSData dataWithData: filterValuesAudio_] retain];
    }    
    
    numFilterValues_ = [[aDecoder decodeObjectForKey:codingKeyNumFV] retain];
    
    
    
    volumeValuesAudio_ = [[aDecoder decodeObjectForKey:codingKeyVV] retain];
    // backwards compatibility - may not exist
    if ( [aDecoder containsValueForKey: codingKeyVVVisual] )
    {
        volumeValuesVisual_ = [[aDecoder decodeObjectForKey:codingKeyVVVisual] retain];        
    }
    else 
    {    
        // todo - test this
        volumeValuesVisual_ = [[NSData dataWithData: volumeValuesAudio_] retain];
    } 
    
    numVolumeValues_ = [[aDecoder decodeObjectForKey:codingKeyNumVV] retain];
    
    
    normalizedTempo_ = [[aDecoder decodeObjectForKey:codingKeyNormTemp] retain];
    activeBeatID_ = [[aDecoder decodeObjectForKey:codingKeyActiveBeatID] retain];
    beatSetID_ = [[aDecoder decodeObjectForKey:codingKeyBeatSetID] retain];
    uniqueID_ = [[aDecoder decodeObjectForKey:codingKeyUniqueID] retain];
    
    return self;
    
}


@end
 


/////////////////////////////////////////////////////////////////////////
// class Scoop
/////////////////////////////////////////////////////////////////////////





// declarations of custom DSP functions
FMOD_RESULT F_CALLBACK volEnvelopeDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels);
FMOD_RESULT F_CALLBACK clockSyncDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels);



// statics

Scoop * Scoop::msTheScoop_ = 0;

// static 
// create the one and only scoop
Scoop *Scoop::createScoop( int width, int height, float scaleFactorX, float scaleFactorY, int graphSize )
{
	if ( !msTheScoop_ )
	{
		msTheScoop_ = new Scoop( width, height, scaleFactorX, scaleFactorY, graphSize);
	}
	
	return msTheScoop_;
}

//
// static  
void Scoop::destroyScoop()
{
	if ( msTheScoop_ )
	{
		delete msTheScoop_;
		msTheScoop_ = 0;
	}
}

//
// static 
Scoop *Scoop::getScoop()
{
	return msTheScoop_;
}



Scoop::Scoop(int width, int height, float scaleFactorX, float scaleFactorY, int graphSize)
{
	//initMidi(hwnd);

	//setProgram(5);
	//controller_ = controller;
	
	scaleFactorX_ = scaleFactorX;
	scaleFactorY_ = scaleFactorY;

    currentTime_ = 0;
    
    lastTimeWithinSound_ = -1;
    numTotalLoops_ = 0;
    
    pauseLengthDuringCurrentChunk_ = 0;
    timeAtPause_ = 0;
    
	lowFps_ = 100.0;
    normalizedSpeed_ = .5f;
	
	state_ = Round;
	cursorXOff_ = 0;

    timeVolFadeEnd_ = -1.0f;
    timeVolFadeBegin_ = -1.0f;
    volFadeStart_ = -1.0f;
    volFadeTarget_ = -1.0f;
    
    normValueX_ = 0.0f;    
    lastNormValueX_ = 0.0f;
    
    numTrackWriteCountThisFrame_ = 0;
    
    activeBeatID_ = -1;
    activeBeatIndex_ = -1;
    
	graphSize_ = graphSize;
	halfGraphSize_ = graphSize/2;
	valSize_ = kVerticalValueResolution;
	startTime_ = intervalTime_ = 0;
	updateCount_ = 0;
	moveThreshold_ = 0.9;    
    
    channelPosAtLastDSPChunkLoad_ = 0;        
    timeAtLastDSPChunkLoad_ = CACurrentMediaTime();
    
	screenWidth_ = width;
	screenHeight_ = height;

	valueGraph_ = new ValueGraph* [3];
	valueGraph_[VOLUME_GRAPH_INDEX] = 0;
	valueGraph_[PITCH_GRAPH_INDEX] = 0;
    valueGraph_[FILTER_GRAPH_INDEX] = 0;
    
	writingTrack_ = Scoop_FocusNone;

	//float duration = 1.0;
	//float duration = 2.0;
	//wrapDuration_ = duration;
	
    currentFlatCamRotationCoef_ = 1.0f;
    
    forcedGraphIndex_ = Scoop_FocusNone;
    
	initSound();	// computes duration as wrapDuration_
	float duration = wrapDuration_;
	
    
	CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();

	valueGraph_[VOLUME_GRAPH_INDEX] = new ValueGraph(graphSize_, duration, valSize_-1,
									CGColorCreate(rgb, VOLUME_GRAPH_FRONT_COLOR),
									CGColorCreate(rgb, VOLUME_GRAPH_BACK_COLOR),
									CGColorCreate(rgb, VOLUME_GRAPH_BG_COLOR));
	valueGraph_[PITCH_GRAPH_INDEX] = new ValueGraph(graphSize_, duration, valSize_-1,
									CGColorCreate(rgb, PITCH_GRAPH_FRONT_COLOR),
									CGColorCreate(rgb, PITCH_GRAPH_BACK_COLOR),
									CGColorCreate(rgb, PITCH_GRAPH_BG_COLOR));
	valueGraph_[FILTER_GRAPH_INDEX] = new ValueGraph(graphSize_, duration, valSize_-1,
									CGColorCreate(rgb, FILTER_GRAPH_FRONT_COLOR),
									CGColorCreate(rgb, FILTER_GRAPH_BACK_COLOR),
									CGColorCreate(rgb, FILTER_GRAPH_BG_COLOR));	
	

    valueGraphDrawOrder_[PITCH_GRAPH_INDEX] = PITCH_GRAPH_INDEX;
    valueGraphDrawOrder_[FILTER_GRAPH_INDEX] = FILTER_GRAPH_INDEX;
    valueGraphDrawOrder_[VOLUME_GRAPH_INDEX] = VOLUME_GRAPH_INDEX;
    
	
	for (int i=0; i<3; i++)
		valueGraph_[i]->scale(scaleFactorX, scaleFactorY );	
	CGColorSpaceRelease(rgb);
	randomizeGraphs();

	reset(.5, 1.0, 1.0);

    numTimeUpdates_ = 0;
	
	focusOn(1);

	setQuantize(0,0);
	setQuantize(1,0);
	setQuantize(2,0);

	playBeat_ = true;
    
	curNumTouches_ = 0;
	lastNumTouches_ = 0;
	beenPaused_ = false;
    
    muteBeats_ = false;

    
	// short-circuit interpolation to initialize state
	moving_ = false;
	for (int i = 0; i < 3; i++) {
						
		pos_[i] = endPos_[i];
		size_[i].x = endSize_[i].x;
		size_[i].y = endSize_[i].y;

		valueGraph_[i]->translation(pos_[i]);
		valueGraph_[i]->scale(size_[i].x, size_[i].y);
	}	


/*
	blackBrush_ = GetStockObject(BLACK_BRUSH);	
	whiteBrush_ = GetStockObject(WHITE_BRUSH);	
	nullPen_ =  GetStockObject(NULL_PEN);
	blackPen_ =  GetStockObject(BLACK_PEN);
	playPen_ =  GetStockObject(WHITE_PEN);
*/
    
    
    clearDirty();
    
	
    
    
    
		
}

Scoop::~Scoop()
{
	
	ScoopEnvelopeManager::Release();
	envManager_ = nil;
	
	for (int i = 0; i < 3; i++) {
		delete valueGraph_[i];
	}
	delete valueGraph_;

	
	// dgm - stopBreak is undefined (commented out) so commenting out calls too
	
	//stopBreak(1, 36);
	//stopBreak(whichBeat_, 60);
	
	
	/*
	for (i = 1; i <= 16; i++) {
		stopBreak(i);
	}
	*/

	
	// dgm - killSound is undefined (commented out) so commenting out calls too
	
	//for (i = 1; i <= 16; i++) {
	//	killSound(i);
	//}
}

//
//
void Scoop::SaveState( ScoopState& state )
{
    valueGraph_[PITCH_GRAPH_INDEX]->saveState( state.getValueGraphState(PITCH_GRAPH_INDEX) );
    valueGraph_[FILTER_GRAPH_INDEX]->saveState( state.getValueGraphState(FILTER_GRAPH_INDEX) );
    valueGraph_[VOLUME_GRAPH_INDEX]->saveState( state.getValueGraphState(VOLUME_GRAPH_INDEX) );
    
    state.setNormalizedTempo( getNormalizedCurSpeed() );    
    state.setBeatSetID(curBeatSetID_);
    state.setActiveBeatID(activeBeatID_);
    
    clearDirty();
}

//
//

void Scoop::RestoreState( ScoopState& state )
{
    
    // todo: we will have to put the app in a state where changing these values is 
    // acceptable
    
    valueGraph_[PITCH_GRAPH_INDEX]->restoreState( state.getValueGraphState(PITCH_GRAPH_INDEX) );
    valueGraph_[FILTER_GRAPH_INDEX]->restoreState( state.getValueGraphState(FILTER_GRAPH_INDEX) );
    valueGraph_[VOLUME_GRAPH_INDEX]->restoreState( state.getValueGraphState(VOLUME_GRAPH_INDEX) );
    
    
    setBeatSet( state.getBeatSetID() );
    setCurBeat( state.getActiveBeatID() );
    
    // we no longer restore tempo with saves (to maintain cur tempo for more of a DJ feel)
    //setSpeed( state.getNormalizedTempo() );        
    
    clearDirty();
}

//
//
void Scoop::stopAllBeats()
{
    clearBeatSoundInstances();
    
    unsigned int iNumSetBeats = setBeats_.size();
    for( unsigned int i = 0; i < iNumSetBeats; ++i )
    {        
        setBeats_[i]->release();        
    }
    
    setBeats_.clear();
    
}


//
// sets the current set of beats playing and kicks off playback at volume zero
void Scoop::setBeatSet( int beatSetID )
{
    
    
    
    float timeToSetNewSoundsTo = 0.0f;
    bool bFirstTime = false;
    if ( setSoundInstances_.size() > 0 )
    {
        timeToSetNewSoundsTo = calculateTimeWithinSound(); ;                
    }
    else
    {
        bFirstTime = true;        
    }
    
    if ( beatSetID != curBeatSetID_ )
    {
        
        
        // move the current beats to the fading out beats
        
        unsigned int iNumSoundInstances = setSoundInstances_.size();
        for( unsigned int i = 0; i < iNumSoundInstances; ++i )
        {             
            setSoundInstances_[i]->fadeVolume( 0, ConvertMsToDSPTicks( BEAT_CROSSFADE_TIME * 1000 ) );            
            fadingOutSoundInstances_.push_back( setSoundInstances_[i] );                        
        }
        
        
        unsigned int iNumSetBeats = setBeats_.size();
        for ( unsigned int i = 0; i < iNumSetBeats; ++i )
        {
            fadingSetBeats_.push_back( setBeats_[i] );            
        }
        
        setBeats_.clear();
        setSoundInstances_.clear();
        
        
        
        
        
        
        //stopAllBeats();
        
        char buffer[200]   = {0};
        
        ScoopBeatSet *bs = ScoopLibrary::Library().beatSetWithID( beatSetID );
        
        
        if ( bs )
        {
        
            // create all sounds for the beat set        
            
            int numBeats = bs->getNumBeats();        
            for ( int iBeat = 0; iBeat < numBeats; ++iBeat )
            {
                            
                ScoopBeat *curBeat = bs->getBeatAt( iBeat );
                if ( curBeat )
                {

                    NSString *strFile = [NSString stringWithUTF8String:curBeat->getFilename()];
                    //strFile = [strFile lowercaseString];
                    
                    NSString *infoSouceFile = [[NSBundle mainBundle] pathForResource:strFile ofType:@"wav"];
                    [[NSString stringWithFormat:infoSouceFile, [[NSBundle mainBundle] resourcePath]] getCString:buffer maxLength:200 encoding:NSASCIIStringEncoding];
                    assert( infoSouceFile );
                                    
                    FMOD::Sound *pBeat = 0;                                
                    FMOD_RESULT result = system_->createStream(buffer, FMOD_SOFTWARE, NULL, &pBeat);                
                    ERRCHECK(result);
                    
                    if ( pBeat )
                    {                    
                    
                        unsigned int length;    
                        result = pBeat->getLength(&length, FMOD_TIMEUNIT_MS);
                        ERRCHECK(result);
                        
                        // we've deferred calculating the time for each beat until now
                        curBeat->setBeatDuration( (float) length / 1000.0 );
                        
                        // play the beat at volume 0
                        FMOD::Channel *beatChannel = playBeat( pBeat, 0.0f );
                        
                        if ( beatChannel )
                        {
                            
                            if ( iBeat == 0 )
                            {
                                // we use te first beat in the set as a timing reference
                                result = beatChannel->addDSP(dspClockSync_, NULL);
                                ERRCHECK(result);    
                            }
                            
                            if ( bFirstTime )
                            {
                                // in this situation we match the graph to the new sound
                                graphIndex_ = 0;
                            }
                            else
                            {
                                // in this situation we're already playing... match the new sound to the previous sounds
                                result = beatChannel->setPosition( timeToSetNewSoundsTo * 1000, FMOD_TIMEUNIT_MS );
                                
                                ERRCHECK(result);                                
                                
                            }
                            
                            beatChannel->setPaused( false );
                            SoundInstance *inst = new SoundInstance( beatChannel );
                            setSoundInstances_.push_back(inst);                        
                            
                            setBeats_.push_back(pBeat);

                        }                
                    }
                    
                }
            }
        
            curBeatSetID_ = beatSetID;
        
        }
        else
        {
            curBeatSetID_ = -1;
        }
        
        activeBeatID_ = -1;
        activeBeatIndex_ = -1;
    }
}

//
// transitions to the beat within the current set with id beatID
void Scoop::setCurBeat( int beatID )
{
 
    if ( beatID != activeBeatID_ )
    {
        ScoopBeatSet *bs = ScoopLibrary::Library().beatSetWithID( curBeatSetID_ );
        if ( bs )
        {
            int iIndexTarget = bs->getIndexForBeatUID( beatID );
            int iIndexPrevTarget = bs->getIndexForBeatUID(activeBeatID_);
            
            int iNumBeats = setSoundInstances_.size();
            
            
            if ( iIndexTarget >= 0 && iIndexTarget < iNumBeats )
            {
               
                
                // fade the new sound to full vol
                if ( iIndexTarget >=0 && iIndexTarget < iNumBeats )
                {
                    setSoundInstances_[iIndexTarget]->fadeVolume( beatVol_ , ConvertMsToDSPTicks( BEAT_CROSSFADE_TIME * 1000 ) );
                }
                
                // fade the prev sound to 0
                if ( iIndexPrevTarget >=0 && iIndexPrevTarget < iNumBeats )
                {
                    setSoundInstances_[iIndexPrevTarget]->fadeVolume( 0.0f, ConvertMsToDSPTicks( BEAT_CROSSFADE_TIME * 1000 ) );
                }
                
                
                activeBeatID_ = beatID;
                activeBeatIndex_ = iIndexTarget;
                
                ScoopBeat *theBeat = bs->getBeatAt(iIndexTarget);
                
                wrapDuration_ = theBeat->getBeatDuration();           
                wrapDurationBaseline_ = wrapDuration_;                                                                
                
                //NSLog( @"length of sound at index %d: %lf\n", iIndexTarget, wrapDurationBaseline_ );
                
                if ( valueGraph_ && valueGraph_[0] ) // test for edge case of first time
                {
                    setSpeed( normalizedSpeed_ );
                }
                
                setDirty();
                
            }
        }
    }
}

void Scoop::setCurBeatIndex( int beatIndex )
{
    ScoopBeatSet *bs = ScoopLibrary::Library().beatSetWithID( curBeatSetID_ );
    if ( bs )
    {
        
        ScoopBeat * beat = bs->getBeatAt(beatIndex);
        if ( beat )
        {
            setCurBeat( beat->getBeatUID() );
        }
        
    }

}


//
//
int Scoop::getActiveBeatIndex() const
{
    ScoopBeatSet *bs = ScoopLibrary::Library().beatSetWithID( curBeatSetID_ );
    if ( bs )
    {
        int iIndexTarget = bs->getIndexForBeatUID( activeBeatID_ );
        return iIndexTarget;
    }
    
    return -1;
}

//
//
void Scoop::loadAllBeats()
{

}

// 
//
void Scoop::setPaused( bool bPause )
{

    FMOD_RESULT result = FMOD_OK;

    
    for ( unsigned int i = 0; i < setSoundInstances_.size(); ++i )
    {
        setSoundInstances_[i]->pause( bPause );
    }
    
    if ( channelSynth_ )
    {
        result = channelSynth_->setPaused( bPause );
        ERRCHECK(result);
    }
    
    
    
    if ( bPause )
    {
        beenPaused_ = true;        
        timeAtPause_ = CACurrentMediaTime();
        
    }
    else
    {
        if ( paused_ )
        {
            // only process if we were formerly paused
            
            pauseLengthDuringCurrentChunk_ = CACurrentMediaTime() - timeAtPause_;
            timeAtPause_ = 0;
            
            lastTime_ = currentTime_;
        }
    }
    
    paused_ = bPause;    
    setIsPaused( paused_ ); // reflect this value globally
	
}


//
// Begin playing a looping beat at the given volume level
FMOD::Channel * Scoop::playBeat( FMOD::Sound *s, float level )
{
    
    FMOD_RESULT result = FMOD_OK;
    FMOD::Channel *beatChannel = 0;
    
	// play beat track
	result = system_->playSound(FMOD_CHANNEL_FREE, s, true, &beatChannel);
	ERRCHECK(result);
	
	result = beatChannel->setMode(FMOD_LOOP_NORMAL);
	ERRCHECK(result);
	result = beatChannel->setLoopCount(-1);
	ERRCHECK(result);
    
    result = beatChannel->setChannelGroup( channelGroupBeats_ );
	ERRCHECK(result);	
    
	result = beatChannel->setVolume(level );
    
	ERRCHECK(result);
    
    return beatChannel;
    

}

void
Scoop::randomizeGraphs()
{
	for (int i = 0; i < 3; i++) {
		valueGraph_[i]->randomizeGraph();
	}
}

void
Scoop::reset(float vol, float pitch, float filter)
{
	// dgm - this is probably wrong because which graph is which is completely confused
	
	valueGraph_[0]->resetGraph(vol);
	valueGraph_[1]->resetGraph(pitch);
	valueGraph_[2]->resetGraph(filter);
}

void
Scoop::resetRoll()
{
	for (int i = 0; i < 3; i++) {
		valueGraph_[i]->roll(0);
	}
}


//
//
double Scoop::calculateTimeWithinSound()
{
       
    if ( timeAtLastDSPChunkLoad_ > 0 )
    {
        
        double secIntoSound = channelPosAtLastDSPChunkLoad_;        
        double deltaIntoChunk = CACurrentMediaTime() - timeAtLastDSPChunkLoad_ - pauseLengthDuringCurrentChunk_;

        // now we need to modify the delta to account for our "time stretching"        
        deltaIntoChunk *= (wrapDurationBaseline_ / wrapDuration_ );
        
        double timeWithinSound = secIntoSound + deltaIntoChunk;
        
        
        
        return timeWithinSound;        
                
            
        
    }
    
    return 0.0f;
}



void
Scoop::updateTime()
{
	
    if ( paused_ )
    {
        return;
    }
    
	lastTime_ = currentTime_;
	
    numTimeUpdates_++;
    
    // the way we're calculating time now is through a combination of using this following
    // technique:
    //
    // 1. use a custom DSP callback to record the time when a chunk of audio data is loaded
    // and the position of playback at that time.
    // 2. calculate the delta into that chunk on a per frame basis, allowing us to know 
    // more or less exactly where we are in a particular sound.
    
    if ( timeAtLastDSPChunkLoad_ > 0 )
    {
        

        double timeWithinSound = calculateTimeWithinSound();                          
        
        bool incrementedLoops = false;
        
        if ( timeWithinSound < lastTimeWithinSound_  )
        {
            bool bWrapped = ( (lastTimeWithinSound_ - timeWithinSound) ) > wrapDurationBaseline_ * 0.5f;
            
            if ( bWrapped )
            {
                // we wrapped around
                numTotalLoops_++;
                incrementedLoops = true;
            }
            else if ( numTimeUpdates_ > 30 ) // don't catch this in the beginning
            {
                // this is probably not a wrap around... more likely our calculation based on the
                // dsp load time is slightly off and came back a little earlier than the last time.
                // This check helps fix a bug where the whole graph would be set to a single
                // value because a slight negative time delta looked like a wrap around
                timeWithinSound = lastTimeWithinSound_; 
            }
        }
        
        currentTime_ = numTotalLoops_ * wrapDurationBaseline_ + timeWithinSound;        
        lastTimeWithinSound_ = timeWithinSound;        
        
        deltaTime_ = currentTime_ - lastTime_;
                
        fps_ = 1.0 / deltaTime_;
        //NSLog(@"last %.2g cur %.2g delta %.2g fps %.2f",lastTime_, currentTime_, deltaTime_, fps_);
        //currentTime_ += 1.0/60.0;
        updateCount_++;
        
        if (fps_ < lowFps_) {
            lowFps_ = fps_;
            lowFpsTime_ = currentTime_;
        }
        if (currentTime_ - lowFpsTime_ > 3.0) lowFps_ = 30.0;
         
    }

}

//
//
	
void
Scoop::startUnwrap( float dur )
{
	//NSLog( @"starting unwrap\n" );

    state_ = IntoFlat;   
	for (int i = 0; i < 3; i++) {
		valueGraph_[i]->unwrap(dur);
	}
}

void
Scoop::startWrap( float dur )
{
	//NSLog( @"starting wrap\n" );
	
    state_ = IntoRound;
	for (int i = 0; i < 3; i++) {
		valueGraph_[i]->wrap(dur);
	}
}


// based on the wrapped / unwrapped state of the value 
// translate this into the concept of portrait/landscape
ScoopOrientationT Scoop::getScoopOrientation()
{
	ValueGraph::State vGraphState = valueGraph_[0]->state();
	
	switch (vGraphState) 
	{
		case ValueGraph::State_Cylinder:
			return eScoopPortrait;
		case ValueGraph::State_Flat:		
			return eScoopLandscape;
		case ValueGraph::State_FlatSpeedup:
        case ValueGraph::State_Wrap:
		case ValueGraph::State_Unwrap:		
			return eScoopTransitioning;
		default:
			return eScoopPortrait;
	}
}

// new logic:
// touchDown a valueGraph
//		if not selected - select and animate
//		else start drawing into graph

void
Scoop::update(float dt)
{
	int i; /*, track;*/

    
	updateTime();	
		
    
    // on the first frame, initiate a scale up to fade
    // the graphs in
    
    if ( numTimeUpdates_ == 1 )
    {        
        for (int i = 0; i < 3; i++) 
        {            
            startPos_[i] = endPos_[i];
            startSize_[i].x = startSize_[i].y = 0;            
            // endsize should already be set up            
        }	
        
        moving_ = true;
        startTime_ = currentTime_;
        intervalTime_ = 1.5f;
    }
    
    
    for (i = 0; i < 3; i++) {
		valueGraph_[i]->updateGraphOffset(currentTime_);
    }
    	
	if (moving_) {
		float linearInterp = (currentTime_ - startTime_) / intervalTime_;					  
		//float interp = pow(linearInterp*1.8,1/1.8);		                
		

        
        float interp = easeInOutRanged( startTime_, intervalTime_, currentTime_ ); 
        
        
		if (interp > 1.0) interp = 1.0;
		        
        
		for (int i = 0; i < 3; i++) {
			size_[i].x = startSize_[i].x * (1.0 - interp) + endSize_[i].x * interp;
			size_[i].y = startSize_[i].y * (1.0 - interp) + endSize_[i].y * interp;
			
			pos_[i].SetPos(
						   startPos_[i].GetX() * (1.0 - interp) + endPos_[i].GetX() * interp,
						   startPos_[i].GetY() * (1.0 - interp) + endPos_[i].GetY() * interp,
						   0);
			
			valueGraph_[i]->translation(pos_[i]);
			valueGraph_[i]->scale(size_[i].x, size_[i].y);
                                    
		}
		if (linearInterp >= 1.0) {
			moving_ = false;
		}
	}
	
    // we have to manage this rotation coeffecient b/c we won't want cam rotation in the flat state
    // and we have to transition to that gracefully
    
    currentFlatCamRotationCoef_ = valueGraph_[0]->getWrapProgress();
    
    if ( valueGraph_[0]->state() == ValueGraph::State_Unwrap )
    {
        
        currentFlatCamRotationCoef_ = currentFlatCamRotationCoef_ * currentFlatCamRotationCoef_;  // this weighs the transition to the end so we see more 3d goodness
        currentFlatCamRotationCoef_ = 1.0f - currentFlatCamRotationCoef_;        
    }
    else if ( valueGraph_[0]->state() == ValueGraph::State_Wrap )
    {
        // leav as is
    }
    else if ( valueGraph_[0]->state() == ValueGraph::State_Flat || 
              valueGraph_[0]->state() == ValueGraph::State_FlatSpeedup )
    {
        currentFlatCamRotationCoef_ = 0.0f;
    }
    
    
    
    if ( writingIntoSelectedTrack() )
    {
        // count the indices we write
        int iIndexForTime = valueGraph_[focusTrack_]->indexForTime(currentTime_);
        
        int indexDelta = iIndexForTime - lastGraphIndexForCurrentWrite_;
        if ( indexDelta >= 0 )
        {
            //NSLog(@"adding %d\n", indexDelta );
            totalGraphIndicesForCurrentWrite_ += indexDelta;
        }
        else
        {
            // wrapped around            
            totalGraphIndicesForCurrentWrite_ += (graphSize_ - lastGraphIndexForCurrentWrite_);
            totalGraphIndicesForCurrentWrite_ += iIndexForTime; 
            
            //NSLog(@"adding %d and %d\n", (graphSize_ - lastGraphIndexForCurrentWrite_), iIndexForTime );
        }
        
        lastGraphIndexForCurrentWrite_ = iIndexForTime;
        
    }
    
    
    
    
    
	switch (state_) {
		case IntoRound:
			
			state_ = IntoRound2;
			
			if (valueGraph_[0]->state() != ValueGraph::State_FlatSpeedup &&
				lastVGraphState_ == ValueGraph::State_FlatSpeedup) {
				focusOn(focusTrack_);
				lastVGraphState_ = valueGraph_[0]->state();
			}
			break;
		case IntoRound2:
			if (valueGraph_[0]->state() == ValueGraph::State_Cylinder)
				state_ = Round;
			if (valueGraph_[0]->state() != ValueGraph::State_FlatSpeedup &&
				lastVGraphState_ == ValueGraph::State_FlatSpeedup) {
				focusOn(focusTrack_);
				lastVGraphState_ = valueGraph_[0]->state();
			}
			break;
		case IntoFlat:
			state_ = IntoFlat2;
			break;
		case IntoFlat2:
			if (valueGraph_[0]->state() == ValueGraph::State_Flat)
				state_ = Flat;
			break;
		case Round:			
			
			
            if (valueGraph_[0]->state() == ValueGraph::State_Unwrap)
            {
                state_ = IntoFlat;
            }
                
            
			if ( focusTrack_ != Scoop_FocusNone )
			{
				graphIndex_ = valueGraph_[focusTrack_]->indexForTime(currentTime_);				
				//valueGraph_[focusTrack_]->updateGraphOffset(currentTime_);				                
                
                //NSLog(@"scoop update GI: %d\n", graphIndex_ );
                
                // this wasn't working out
                //float latencyForWriting = valueGraph_[0]->computeLatencyForDrawing() * valueGraph_[0]->getSize();
                float latencyForWriting = 0.0f;
                
				if (writingIntoSelectedTrack()) {
					
					// move value towards target value exponentially to smooth curve
					//float delta = normValue_ - lastNormValue_;
					//float graphValue = lastNormValue_ + delta * 0.5;
					
					// write the values based on current input into the graph we're editing
					// automatically quantizes or not depending on ValueGraph state
					
					
					// we're removing the filter functionality
					
								
					lastAdjustedNormValue_ = adjustedNormValue_;
					adjustedNormValue_ = normValue_;
					
					
//					// here we do adjustments for the different modes
//					if ( writingTrack_ == VOLUME_GRAPH_INDEX )
//					{
//											// access the envelope manager to get the values to interpolate between		
//						
//						int iEnvIndex = envManager_->getEnvelopeIndex( normValue_ );
//						float valBegin = 0.0f;
//						float valEnd = 0.0f;
//						
//						
//						envManager_->getEnvelopePoints( iEnvIndex, lastTime_, currentTime_, valBegin, valEnd );	
//						//NSLog( @"ind: %d, last: %f, cur: %f, val b: %f, val e: %f\n", iEnvIndex, lastTime_, currentTime_, valBegin, valEnd );	
//						
//						//lastNormValue_ = normValue_;
//						
//						adjustedNormValue_ = valEnd;
//						//NSLog( @"norm: %f, env: %d\n", normValue_, iEnvIndex );
//						
//					}
//					else if ( writingTrack_ == PITCH_GRAPH_INDEX )
//					{
//					}
//					else if ( writingTrack_ == FILTER_GRAPH_INDEX )
//					{
//					}
					
					
					
					// now trying with normalized floats instead of rounded ints
					
                    
                    
                    valueGraph_[focusTrack_]->setCurrentValues( eVGDataBoth, lastGraphIndex_ - latencyForWriting, graphIndex_ - latencyForWriting,
                                                               lastAdjustedNormValue_,
                                                               adjustedNormValue_);	
					
					
				}
				
				lastGraphIndex_ = graphIndex_;
				
			}
			
			
			
			break;
		case Flat:
            
            if (valueGraph_[0]->state() == ValueGraph::State_Wrap)
            {
                state_ = IntoRound;
            }
                        
            if (writingIntoSelectedTrack() && !valueGraph_[writingTrack_]->isScrolling() ) 
            {
               
                int graphSize = valueGraph_[writingTrack_]->getSize();
                
                lastAdjustedNormValue_ = adjustedNormValue_;
                adjustedNormValue_ = normValue_;
                

                // in flat mode we don't want to wrap around
                float normX =  MIN(normValueX_, 0.99999f);
                float lastNormX = MIN( lastNormValueX_, 0.99999f);
                
                
                
                valueGraph_[focusTrack_]->setCurrentValues( eVGDataBoth, lastNormX * graphSize, normX * graphSize,
                                                           lastAdjustedNormValue_,
                                                           adjustedNormValue_,
                                                           normValueX_ >= lastNormValueX_);
                                
            }
            
			break;
	}
	
    for (i = 0; i < 3; i++) 
    {
		valueGraph_[i]->update(currentTime_);
	}
    
    numTrackWriteCountThisFrame_ = 0;

    
	updateSound();
}


//
//
void Scoop::numTouchesChanged( int iNumTouches )
{
	curNumTouches_ = iNumTouches;	
}

//
// did the two times pass over the beat quantize point?
bool Scoop::passedBeatQuantizePoint( float secLow, float secHigh ) const
{
	float sectionLength = wrapDuration_ / kNumQuantizeSectionsPerLoop;
	return ( (int) (secLow / sectionLength) != (int) (secHigh / sectionLength ) );
}

/*
void
Scoop::updateSound()
{
	int amplitude = valueGraph_[0]->value(currentTime_);
	int pitch = valueGraph_[1]->value(currentTime_);
	int filter = valueGraph_[2]->value(currentTime_);

	setVolume(1, amplitude);
	setPitch(1, pitch);
	setFilter(1, filter);

	if (fmod(currentTime_, wrapDuration_) < 0.05) {
		if (playBeat_) {
			playBreak(whichBeat_, 60);
		}
		playBreak(1, 36);
	}
}
*/

void
Scoop::initSound()
{
	FMOD_RESULT   result        = FMOD_OK;	
    unsigned int  version       = 0;
	
    
    
    // init the tunable audio vals
    
    toneFrequency_ = kBaseFrequency;    
    toneRangeNumOctaves_ = PITCH_SHIFT_RANGE / 12.0f;
    filterMinCutoff_ = MIN_FILTER_CUTOFF;
    filterMaxCutoff_ = MAX_FILTER_CUTOFF;
    filterResonance_ = FILTER_RESONANCE;
    toneVolMax_ = SYNTH_VOL_MAX;   
    beatVol_ = BEAT_VOL;
    
    
    
    
    
    /*
	 Create a System object and initialize
	 */    
    result = FMOD::System_Create(&system_); 
    ERRCHECK(result);
    
    result = system_->getVersion(&version);
    ERRCHECK(result);
    
    if (version < FMOD_VERSION)
    {
        fprintf(stderr, "You are using an old version of FMOD %08x.  This program requires %08x\n", version, FMOD_VERSION);
        exit(-1);        
    }
	
    // here we're changing the DSP buffer size to help reduce
    // latency.  These calls have to come before the system init call
    
    // tune these as needed if the smaller buffer size is too taxing for
    // lower-end cpus

    unsigned int iBufferSize = 256;
    unsigned int iNumAudioBufs = 2;

    // version 1.0 settings
    //unsigned int iBufferSize = 1024;
    //unsigned int iNumAudioBufs = 4;

    
    result = system_->setDSPBufferSize(iBufferSize, iNumAudioBufs);    
    ERRCHECK(result);

    
    result = system_->init(32, FMOD_INIT_NORMAL /*| FMOD_INIT_ENABLE_PROFILE*/, NULL);
    ERRCHECK(result);
	
    // create channel groups
    
    result = system_->createChannelGroup( "Channel Group Beats", &channelGroupBeats_ );
    ERRCHECK( result );
    
    FMOD::ChannelGroup * masterGroup = 0;
    result = system_->getMasterChannelGroup( &masterGroup );

    masterGroup->addGroup( channelGroupBeats_ );
    
    
    /*
	 Create an oscillator DSP units for the tone.
	 */
    result = system_->createDSPByType(FMOD_DSP_TYPE_OSCILLATOR, &dsp_);
    ERRCHECK(result);
    result = dsp_->setParameter(FMOD_DSP_OSCILLATOR_RATE, toneFrequency_);   /* Musical note 'A2' */
    ERRCHECK(result);
	result = system_->createDSPByType(FMOD_DSP_TYPE_LOWPASS, &dspLowPass_);
    ERRCHECK(result);
	result = dspLowPass_->setParameter(FMOD_DSP_LOWPASS_CUTOFF, filterMaxCutoff_); 
	result = dspLowPass_->setParameter(FMOD_DSP_LOWPASS_RESONANCE, filterResonance_); 
    ERRCHECK(result);

	
	// custom DSP units	
	createVolumeEnvelopDSP();
    createClockSyncDSP();

    
    SetFMODSystem( system_ );
	InitGlobalAudioVals();

    // play the synth tone
    playSynth(); 
    
    // play the default beat     
    setBeatSet( 1 ); // todo - which beat set is this?
    setCurBeat(100);     // todo - which beat is this?
    
    
    
	// set up our envelope manager
	ScoopEnvelopeManager::Init();
	envManager_ = ScoopEnvelopeManager::Manager(); // cache it off
	
	envManager_->setNumEnvCyclesPerLoop( kNumEnvelopeCyclesPerLoop );
	envManager_->setLoopDuration( wrapDuration_ ); // length of our audio loop - should be updated as we adjust tempo
	        
    
	baselineMasterPitch_ = 0.0f;
	FMOD::ChannelGroup *cg;
	system_->getMasterChannelGroup(&cg);
	cg->getPitch(&baselineMasterPitch_);
		
}

void
Scoop::updateSound()
{
	FMOD_RESULT result              = FMOD_OK;
	//float       channelfrequency    = 0.0f;
	//float       channelvolume       = 0.0f;
	//bool        channelplaying      = false;
	
    
    if ( forcedGraphIndex_ != Scoop_FocusNone )
    {
        
        // here we are forcing a particular graph value for a certain number of indices.
        // we decrement the remaining amount and check if the period is over.
        
        int iDelta = graphIndex_ - lastForcedGraphIndex_;
                             
        
        if ( iDelta < 0 )
        {
            // wrapped around
            numForcedGraphIndicesRemaining_ -= (graphSize_ - lastForcedGraphIndex_);
            numForcedGraphIndicesRemaining_ -= graphIndex_;
        }
        else
        {
            numForcedGraphIndicesRemaining_ -= iDelta;
        }
        
        lastForcedGraphIndex_ = graphIndex_;
        if ( numForcedGraphIndicesRemaining_ <= 0 )
        {
            forcedGraphIndex_  = Scoop_FocusNone;
        }
        
    
                
    }
            
    
#if 0
	if (channel_ != NULL)
	{
		result = channel_->getFrequency(&channelfrequency);
		if ((result != FMOD_OK) && (result != FMOD_ERR_INVALID_HANDLE) && (result != FMOD_ERR_CHANNEL_STOLEN))
		{
			ERRCHECK(result);
		}
		
		result = channel_->getVolume(&channelvolume);
		if ((result != FMOD_OK) && (result != FMOD_ERR_INVALID_HANDLE) && (result != FMOD_ERR_CHANNEL_STOLEN))
		{
			ERRCHECK(result);
		}
		/*
		result = channel_->getPan(&channelpan);
		if ((result != FMOD_OK) && (result != FMOD_ERR_INVALID_HANDLE) && (result != FMOD_ERR_CHANNEL_STOLEN))
		{
			ERRCHECK(result);
		}        
		*/
		result = channel_->isPlaying(&channelplaying);
		if ((result != FMOD_OK) && (result != FMOD_ERR_INVALID_HANDLE) && (result != FMOD_ERR_CHANNEL_STOLEN))
		{
			ERRCHECK(result);
		}
	}
#endif
	
	float valA = 0.0f;
    float valV = 0.0f;
	// update pitch
#define NUM_TONES 30
	
	/*
	// f = 440 * 2^(d-69)/12 - midi pitch
	val = (float) valueGraph_[0]->value(currentTime_);
	val = val * (NUM_TONES/127.0);  // 0-127 -> 0-NUM_TONES - NUM_TONES/12 octaves
	val += NUM_TONES;	// start at C3
	if (valueGraph_[0]->quantize()) {
		// quantize to whole tones
		val = roundf(val);
	}
	float freq = 440.0 * powf(2.0, (val-69.0) / 12.0);	
	*/
	
	
	
    
		
    
	valueGraph_[PITCH_GRAPH_INDEX]->values(currentTime_, valA, valV);
    
    if ( forcedGraphIndex_ == PITCH_GRAPH_INDEX )
    {
        valA = forcedGraphValue_;
    }
    
    float baseShift = -12.0 * toneRangeNumOctaves_ / 2.0f;
    float pitchShift = baseShift + 12.0 * toneRangeNumOctaves_ * valA; 
    
	setPitch(pitchShift);
    //NSLog( @"p: %f\n", val);
	
	// update filter
	valueGraph_[FILTER_GRAPH_INDEX]->values(currentTime_, valA, valV);
    if ( forcedGraphIndex_ == FILTER_GRAPH_INDEX )
    {
        valA = forcedGraphValue_;
    }
 
	float filterCutoffRange = (filterMaxCutoff_ - filterMinCutoff_ );
	float newFilterCutoff = filterMinCutoff_ + valA * filterCutoffRange;

	setFilter(newFilterCutoff, filterResonance_);
	
	// update volume
	
	// we're back to doing this here instead of the DSP	
	valueGraph_[VOLUME_GRAPH_INDEX]->values(currentTime_, valA, valV);	
    if ( forcedGraphIndex_ == VOLUME_GRAPH_INDEX )
    {
        valA = forcedGraphValue_;
    }
    
	setVolume(valA);
    
	
	
	if (fmod(currentTime_, kTestSoundFileLength) < 0.05) {
		//if (playBeat_) {
		//	playBreak(whichBeat_, 60);
		//}
		//playBreak();
	}
	
    
    for ( unsigned int iBeat = 0; iBeat < setSoundInstances_.size(); ++iBeat )
    {
        setSoundInstances_[iBeat]->update();
    }
    
    
    
    // our fading beat set updates
    // really we should implement a "fire and forget" model for handling playback/cleanup so we 
    // don't have to do this sort of tracking thing
    
    unsigned int iNumFadingSoundInstances = fadingOutSoundInstances_.size();
    for( unsigned int i = 0; i < iNumFadingSoundInstances; ++i )
    { 
        fadingOutSoundInstances_[i]->update();
        
        if ( !fadingOutSoundInstances_[i]->isFading() )
        {
            // done!
            fadingOutSoundInstances_[i]->releaseChannel();
            delete fadingOutSoundInstances_[i];
            
            fadingSetBeats_[i]->release();
            
            fadingOutSoundInstances_.erase( fadingOutSoundInstances_.begin() + i );
            fadingSetBeats_.erase( fadingSetBeats_.begin() + i );
            
            //NSLog(@"cleaned up!\n" );
            --i;
            --iNumFadingSoundInstances;

        }
        
                
    }
    
    
    // the initial fade up to soften the app start    
    static bool bInit = false;
    if ( !bInit )
    {
        FadeMasterVol( 1.0f, INITIAL_FADE_UP_DURATION, 0.0f );                
        bInit = true;
    }
    
    
        
    
    
    // master volume fading    
    updateMasterVolFade();        
    
    
	if (system != NULL)
	{        
		result = system_->update();
		ERRCHECK(result);
	}
	
	/*
	status.text         = channelplaying ? @"Playing" : @"Stopped";
	frequencyvalue.text = [NSString stringWithFormat:@"%.1f", channelfrequency];
	volumevalue.text    = [NSString stringWithFormat:@"%.1f", channelvolume];
	panvalue.text       = [NSString stringWithFormat:@"%.1f", channelpan];
	 */
}

//
// Create our custom volume envelope DSP
void Scoop::createVolumeEnvelopDSP()
{

	FMOD_DSP_DESCRIPTION dspdesc; 
	memset(&dspdesc, 0, sizeof(FMOD_DSP_DESCRIPTION)); 

	strcpy(dspdesc.name, "Scoop Volume Envelope"); 
	dspdesc.channels     = 0;                   // 0 = whatever comes in, else specify. 
	dspdesc.read         = volEnvelopeDSPCallback; 
	dspdesc.userdata     = (void *)0x12345678; 

	FMOD_RESULT result = system_->createDSP(&dspdesc, &dspVolEnvelope_); 
	ERRCHECK(result); 
	
}


//
// Create our custom clock sync DSP
void Scoop::createClockSyncDSP()
{
    
	FMOD_DSP_DESCRIPTION dspdesc; 
	memset(&dspdesc, 0, sizeof(FMOD_DSP_DESCRIPTION)); 
    
	strcpy(dspdesc.name, "Scoop Clock Sync"); 
	dspdesc.channels     = 0;                   // 0 = whatever comes in, else specify. 
	dspdesc.read         = clockSyncDSPCallback; 
	dspdesc.userdata     = (void *)0x12345678; 
    
	FMOD_RESULT result = system_->createDSP(&dspdesc, &dspClockSync_); 
	ERRCHECK(result); 
	

    // trying to do the DSP in the way described here to avoid CPU overhead of copying
    // the input to output, but tabling this for now
    // http://www.fmod.org/forum/viewtopic.php?f=7&t=14307
    
//    FMOD::DSP *dspHead = nil;
//    result = system_->getDSPHead( &dspHead );
//    ERRCHECK(result);
//    assert( dspHead );
//    result = dspHead->addInput( dspClockSync_, nil );
//    ERRCHECK(result);
    
}



void
Scoop::playSynth()
{
    FMOD_RESULT result = FMOD_OK;



    // play oscillator
    result = dsp_->remove();
    ERRCHECK(result);
    result = system_->playDSP(FMOD_CHANNEL_REUSE, dsp_, true, &channelSynth_);
    ERRCHECK(result);
    result = channelSynth_->setVolume( 0.0f );
    ERRCHECK(result);
    result = dsp_->setParameter(FMOD_DSP_OSCILLATOR_TYPE, 1); // 1 == square
    ERRCHECK(result);
    result = channelSynth_->setPaused(false);
    ERRCHECK(result);
    result = channelSynth_->addDSP(dspLowPass_, NULL);

    // add custom DSP units

    // we're not using the volume envelope currently
    //result = channelSynth_->addDSP(dspVolEnvelope_, NULL);

    // test
    //result = channel_[kChannelTone]->addDSP(dspTremolo_, NULL);
    //ERRCHECK(result);

    ERRCHECK(result);    
    ERRCHECK(channelSynth_->getFrequency(&toneFrequency_));
		
		
}

void 
Scoop::setPitch(float pitchShift)	// semitone pitch shift, e.g. [-24, +24]
{
    //FMOD_RESULT result = FMOD_OK;
    
	//float freq;
	ERRCHECK(channelSynth_->setFrequency(powf(2.0f,pitchShift/12.0f) * toneFrequency_)); 
			 
	/*
    if (channel_)
    {
		float curFreq;
		char valueStr[32];
		
		dsp_->getParameter(FMOD_DSP_OSCILLATOR_RATE, &curFreq, valueStr, 32);
		if (curFreq != freq) {
			result = dsp_->setParameter(FMOD_DSP_OSCILLATOR_RATE, freq); 
			if ((result != FMOD_OK) && (result != FMOD_ERR_INVALID_HANDLE) && (result != FMOD_ERR_CHANNEL_STOLEN))
			{
				ERRCHECK(result);
			}
		}
	}
	 */
}

void
Scoop::setFilter(float f, float r)
{
    FMOD_RESULT result = FMOD_OK;

	result = dspLowPass_->setParameter(FMOD_DSP_LOWPASS_CUTOFF, f); 
	result = dspLowPass_->setParameter(FMOD_DSP_LOWPASS_RESONANCE, r); 

	if ((result != FMOD_OK) && (result != FMOD_ERR_INVALID_HANDLE) && (result != FMOD_ERR_CHANNEL_STOLEN))
	{
		ERRCHECK(result);
	}
	
	//FMOD_DSP_LOWPASS_CUTOFF,    /* Lowpass cutoff frequency in hz.   10.0 to 22000.0.  Default = 5000.0. */
    //FMOD_DSP_LOWPASS_RESONANCE  /* Lowpass resonance Q value. 1.0 to 10.0.  Default = 1.0. */
}

void
Scoop::setVolume(float v)
{
    FMOD_RESULT result = FMOD_OK;
    
	result = channelSynth_->setVolume( toneVolMax_ * v );
	if ((result != FMOD_OK) && (result != FMOD_ERR_INVALID_HANDLE) && (result != FMOD_ERR_CHANNEL_STOLEN))
	{
		ERRCHECK(result);
	}
}

//
//
void Scoop::clearBeatSoundInstances()
{
    for ( unsigned int i = 0; i < setSoundInstances_.size(); ++i )
    {
        delete setSoundInstances_[i];        
    }
    
    setSoundInstances_.clear();
}

//
//
SoundInstance *Scoop::getActiveSoundInstance()
{
        
    ScoopBeatSet *bs = ScoopLibrary::Library().beatSetWithID( curBeatSetID_ );
    if ( bs )
    {
        int iIndexActive = bs->getIndexForBeatUID( activeBeatID_ );
        if ( iIndexActive >= 0 && iIndexActive < (int) setSoundInstances_.size() )
        {
            return setSoundInstances_[iIndexActive];
        }
    }
    
    return nil;                            
    
}

#if 0
float
Scoop::normValue()
{

	FPoint position = controller_->position();
	float activeArea = 0.7;
	float normVal = (position.y + moveThreshold_*activeArea) / (moveThreshold_*activeArea*2);

	if (normVal < 0) normVal = 0;
	if (normVal > 1) normVal = 1;
	normVal = 1-normVal;

	return normVal;
}
#endif

void
Scoop::drawGL()
{
	for (int g = 2; g >= 0; g--) {
		valueGraph_[g]->drawGL();
	}
}

void
Scoop::drawDebugGL(float rotation)
{
	glDisableClientState(GL_COLOR_ARRAY);
	CGPoint linePts[4];
	
#if 1
	
	// draw bounding boxes of crowns
	for (int g = 2; g >= 0; g--) {
		valueGraph_[g]->drawBBoxGL(rotation);
	}

	
	// draw selection areas
	if (writingIntoSelectedTrack()) {
		
		glLineWidth(2);
		linePts[0].x = 0; linePts[0].y = graphBottom_;
		linePts[1].x = screenWidth_; linePts[1].y = graphBottom_;
		
		glVertexPointer(2, GL_FLOAT, 0, linePts);	
		glColor4f(0.25,0.25,0.25,1);
		glDrawArrays(GL_LINES, 0, 2);
		
		linePts[0].x = 0; linePts[0].y = graphTop_;
		linePts[1].x = screenWidth_; linePts[1].y = graphTop_;
		
		glColor4f(0.75,0.75,0.75,1);
		glVertexPointer(2, GL_FLOAT, 0, linePts);	
		glDrawArrays(GL_LINES, 0, 2);
	}
	 
#endif
	
	if ( writingTrack_ != Scoop_FocusNone )
	{
	
		// draw last cursor position
		glColor4f(0,0,0,1);		
		glLineWidth(2);
		lastTouch_.x = screenWidth_/2;
		linePts[0].x = lastTouch_.x-30; linePts[0].y = lastTouch_.y;
		linePts[1].x = lastTouch_.x+30; linePts[1].y = lastTouch_.y;
		linePts[2].x = lastTouch_.x; linePts[2].y = lastTouch_.y-30;
		linePts[3].x = lastTouch_.x; linePts[3].y = lastTouch_.y+30;
		glPointSize(6);
		glVertexPointer(2, GL_FLOAT, 0, linePts);	
		glDrawArrays(GL_LINES, 0, 4);
	}
	
	
	glEnableClientState(GL_COLOR_ARRAY);
}

void
Scoop::drawGL3D(ofxMSAShape3D *shape3D, float cameraRotation)
{
     
    
    
    
	for (int g = 0; g <= numCrowns()-1; g++) {
		//valueGraph_[g]->drawGL3D(shape3D);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);
		valueGraph_[ valueGraphDrawOrder_[g] ]->drawGL3DAA(shape3D, cameraRotation * currentFlatCamRotationCoef_);
	}
     
    // come back to this
    
    
#if 0
    // draw line to the cursor
    if ( writingTrack_ != Scoop_FocusNone )
	{
        
        glDisableClientState(GL_COLOR_ARRAY);
        
        glColor4f( 98.0f/255, 98.0f/255, 98.0f/255, 1);		
		glLineWidth(2);
                
        CGPoint linePts[2];        
        
		linePts[0].x = lastTouch_.x; linePts[0].y = lastTouch_.y;        
		linePts[1].x = screenWidth_/2; linePts[1].y = lastTouch_.y;
		
        if ( linePts[1].x > linePts[0].x )
        {
            linePts[1].x -= CURSOR_WIDTH / 2.0f;
        }
        else
        {
            linePts[1].x += CURSOR_WIDTH / 2.0f;
        }
        
		glPointSize(6);	
        glVertexPointer(2, GL_FLOAT, 0, linePts);	
		glDrawArrays(GL_LINES, 0, 2);
        
        glEnableClientState(GL_COLOR_ARRAY);
    }
#endif
    
    
	//drawDebugGL(cameraRotation);
}

void
Scoop::draw(CGContextRef ctx)
{
	for (int g = 2; g >= 0; g--) {
		valueGraph_[g]->draw(ctx);
	}
#if 0
	if (focusTrack_ != 3) {
		// draw cursor
		CGPoint p;

		if (state_ == Flat) {
			p.x = screenWidth_/2 + (float)cursorXOff_ * unwrapFactorH_;
			p.y = pos_[focusTrack_].GetY() - unwrapFactorV_*valSize_*normValue();

		} else {
			p.x = screenWidth_/2;
			p.y = pos_[focusTrack_].GetY() - valSize_*normValue();
		}

		float radius = 6*size_[focusTrack_].y;

		//POINT p;
		//p.x = ROUNDINT(pos.x);
		//p.y = ROUNDINT(pos.y);

		//int r = ROUNDINT(radius);

		// draw vertical crosshair
		if (state_ == Flat) {
			float x = fmod(currentTime_ + wrapDuration_ / 2, wrapDuration_) - wrapDuration_ / 2;
			x /= wrapDuration_;
			x = screenWidth_/2 + x * graphSize_ * unwrapFactorH_;

			CGContextSetLineWidth(ctx, 1);
			CGContextSetRGBStrokeColor(ctx, 1, 1, 1, 1);
			CGContextBeginPath(ctx);
			
			CGContextMoveToPoint(ctx, x, 0);
			CGContextAddLineToPoint(ctx, x, screenHeight_);
			
			CGContextClosePath(ctx);
			CGContextStrokePath(ctx);
		}

		/// white dot outlined in white
		CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);
		CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
		
		CGContextFillEllipseInRect (ctx, CGRectMake(p.x-radius, p.y-radius, radius*2, radius*2));

		// smaller black dot inside
		CGContextSetRGBFillColor(ctx, 0, 0, 0, 1);
		CGContextFillEllipseInRect (ctx, CGRectMake(p.x-radius*0.5, p.y-radius*0.5, radius, radius));
	}
#endif
}


// allow calling code to access the same Y-axis quantization used 
// internally in the value graph 
float Scoop::quantizeYVal( float normalizedVal, int track )
{
    assert(track>=0&&track<3);  
    return valueGraph_[track]->testAndQuantizeYVal( normalizedVal );
    
}

// speed of the audio and visuals, normalized (0-1)
//
void Scoop::setSpeed( float normVal )
{
	
    float wrapDurPrev = wrapDuration_;
    
	// do bpm calculations
	
	float baselineBPM = calculateBPM(wrapDurationBaseline_, NUM_BEATS_PER_LOOP);
	float bpmRange = MAX_BPM - MIN_BPM;
	float targetBPM = MIN_BPM + normVal * bpmRange;
	int iTargetBPM = ROUNDINT( targetBPM ); // need to quantize to nearest whole number
    targetBPM = iTargetBPM;
    
    
	float maxPitchCooef = MAX_BPM / baselineBPM;
	float minPitchCooef = MIN_BPM / baselineBPM;
	float pitchRange = maxPitchCooef - minPitchCooef;
	
	float newPitch = minPitchCooef + normVal * pitchRange;

	wrapDuration_ = baselineBPM/targetBPM * wrapDurationBaseline_;
	
	
	
	if ( system_ )
	{
        // old way
		//FMOD::ChannelGroup *cg;
		//system_->getMasterChannelGroup(&cg);		
		//cg->setPitch( newPitch );

        // new way - just the beats
        channelGroupBeats_->setPitch( newPitch );
        
        
		//NSLog(@"setting duration: %f\tpitch: %f\n", wrapDuration_, newPitch );
		
		for (int g = 2; g >= 0; g--) 
		{
            
            valueGraph_[g]->setTempoAdjustedDuration( wrapDuration_ );

            
            // no longer changing this now that we're syncing directly to the sound
            // position
            
			//valueGraph_[g]->setDuration( wrapDuration_, currentTime_);
		}
	}
  
    // changing the speed no longer sets the dirty bit - tempo isn't saved in the
    // save files
    
//    if (  !FUZZY_EQUAL( wrapDurPrev, wrapDuration_, .0001 ) )
//    {
//        setDirty();
//    }
    
    normalizedSpeed_ = normVal;
}

//
//
float Scoop::getNormalizedCurSpeed() const
{
	float bpm = calculateBPM(wrapDuration_, NUM_BEATS_PER_LOOP);
	float bpmRange = MAX_BPM - MIN_BPM;
	
	return ( (bpm - MIN_BPM) / bpmRange ); 
}

void
Scoop::focusOn(int whichTrack, float interpTime, bool userInitiated )
{
        
    
    int iNumCrowns = numCrowns();
    if ( whichTrack >= iNumCrowns &&
        whichTrack != Scoop_FocusNone )
    {
        return;
    }
    
    bool bInRoundState = ( state_ == Round ||
                           state_ == IntoRound ||
                          state_ == IntoRound2 );


    
    // time
    updateTime();
    startTime_ = currentTime_;
    intervalTime_ = interpTime;
    
    focusTrack_ = whichTrack;
    
    if ( !gbIsIPad )
    {
        if ( focusTrack_ == PITCH_GRAPH_INDEX )
        {
            valueGraphDrawOrder_[0] = FILTER_GRAPH_INDEX;
            valueGraphDrawOrder_[1] = PITCH_GRAPH_INDEX;
        }
        else
        {
            valueGraphDrawOrder_[0] = PITCH_GRAPH_INDEX;
            valueGraphDrawOrder_[1] = FILTER_GRAPH_INDEX;
        }
        
        
    }
    
    // portrait layout iPad
    float selScaleH = 2.4f * scaleFactorX_, selScaleV = 2.4f * scaleFactorY_;    
    float selUnscaleH = 1.4f * scaleFactorX_, selUnscaleV = 1.4f * scaleFactorY_;         
    float unselScaleH = 1.15f * scaleFactorX_ * 2, unselScaleV = 1.15f * scaleFactorY_ * 2;
        
    // portrait layout iPhone    
    float phoneSelectedScaleH = 4.04f * scaleFactorX_, phoneSelectedScaleV = 4.04f * scaleFactorY_;    
    float phoneUnselectedScaleH = 2.28f * scaleFactorX_, phoneUnselectedScaleV = 2.28f * scaleFactorY_;    
    float phoneNoFocusScaleH = 2.28f * scaleFactorX_, phoneNoFocusScaleV = 2.28f * scaleFactorY_;    
    
    // both (landscape)
    float flatScaleH = 1.45f * scaleFactorX_ * 2, flatScaleV = 1.45f * scaleFactorY_ * 2;        
    
    
    if ( iNumCrowns == 2 )
    {
        // iphone version.. only 2 crowns so increase vertical size to
        // use the space formerly used by the 3rd crown
        flatScaleV *= 1.5f;
    }
    
    
    
    // overall scaling factor - sorry man this code is too convoluted
    float overallScaleX = 1.47;
    float overallScaleY = 1.47;
    
    selScaleH *= overallScaleX;
    selScaleV *= overallScaleY;
    selUnscaleH *= overallScaleX;
    selUnscaleV *= overallScaleY;
    
    phoneSelectedScaleH *= overallScaleX;
    phoneSelectedScaleV *= overallScaleY;
    phoneUnselectedScaleH *= overallScaleX;
    phoneUnselectedScaleV *= overallScaleY;
    
    phoneNoFocusScaleH *= overallScaleX;
    phoneNoFocusScaleV *= overallScaleY;
    
    float factor = 16*24 / (float)graphSize_;	// ? 
    
    selScaleH *= factor;
    selUnscaleH *= factor;
    unselScaleH *= factor;
    flatScaleH *= factor;
    
    phoneSelectedScaleH *= factor;
    phoneUnselectedScaleH *= factor;
    phoneNoFocusScaleH *= factor;
    
    unwrapFactorH_ = unselScaleH;
    unwrapFactorV_ = unselScaleV;
    
    float tiltMult = 1.73; // $$$$!!!!
    //tiltMult = 1.0;
    tiltMult = 1.08f;
    
    float height = tiltMult * unselScaleV*(float)valSize_;
    float selHeight = tiltMult * selScaleV*(float)valSize_;
    float selUnheight = tiltMult * selUnscaleV*(float)valSize_;
    float vspace =  0.135*(float)screenHeight_;
    float totalSpace;
    float vMargin;
    float topOffset;
    
    // new approach
    
    //float newUnSelHeight = unselScaleV * (float)valSize_;
    float newFlatHeight = flatScaleV * (float) valSize_;
    
    float spacingAdjustment = selUnheight * 0.15f;
    
    
    for (int i = 0; i < 3; i++) {
        startPos_[i] = pos_[i];
        startSize_[i].x = size_[i].x;
        startSize_[i].y = size_[i].y;
    }
    
    // defaults, for selected state
    totalSpace = selHeight + selUnheight * 2 + vspace * 2;
    
    
    if ( gbIsIPad )
    {
    
        
        
        if ( bInRoundState )
        {
            vMargin = (screenHeight_ - totalSpace) / 2.5; // we're making room for the tempo slider here
            topOffset = vMargin / 2;
        }
        else
        {
            vMargin = (screenHeight_ - totalSpace) / 2.0;
            topOffset = vMargin / 2;
        }
            
        

        switch (state_) {
        case Round:
        case IntoRound:
        case IntoRound2:
            switch (focusTrack_) {
            case 0:
                endSize_[0].x = selScaleH;		endSize_[0].y = selScaleV;
                endSize_[1].x = selUnscaleH;	endSize_[1].y = selUnscaleV;
                endSize_[2].x = selUnscaleH;	endSize_[2].y = selUnscaleV;

                endPos_[0].SetPos(screenWidth_/2.0, 
                    topOffset+vMargin+selHeight, 0);
                endPos_[1].SetPos(screenWidth_/2.0, 
                    topOffset+vMargin+selHeight+vspace+selUnheight, 0);
                endPos_[2].SetPos(screenWidth_/2.0, 
                    topOffset+vMargin+selHeight+vspace+selUnheight+vspace+selUnheight, 0);
                break;
            case 1:
                endSize_[0].x = selUnscaleH;	endSize_[0].y = selUnscaleV;
                endSize_[1].x = selScaleH;		endSize_[1].y = selScaleV;
                endSize_[2].x = selUnscaleH;	endSize_[2].y = selUnscaleV;

                endPos_[0].SetPos(screenWidth_/2.0, 
                    topOffset+vMargin+selUnheight, 0);
                endPos_[1].SetPos(screenWidth_/2.0, 
                    topOffset+vMargin+selUnheight+vspace+selHeight + spacingAdjustment, 0);
                endPos_[2].SetPos(screenWidth_/2.0, 
                    topOffset+vMargin+selUnheight+vspace+selHeight+vspace+selUnheight, 0);
                break;
            case 2:
                endSize_[0].x = selUnscaleH;	endSize_[0].y = selUnscaleV;
                endSize_[1].x = selUnscaleH;	endSize_[1].y = selUnscaleV;
                endSize_[2].x = selScaleH;		endSize_[2].y = selScaleV;

                endPos_[0].SetPos(screenWidth_/2.0, 
                    topOffset+vMargin+selUnheight, 0);
                endPos_[1].SetPos(screenWidth_/2.0, 
                    topOffset+vMargin+selUnheight+vspace+selUnheight - spacingAdjustment, 0);
                endPos_[2].SetPos(screenWidth_/2.0, 
                    topOffset+vMargin+selUnheight+vspace+selUnheight+vspace+selHeight, 0);
                break;
            default:
            case 3:	// none selected
                endSize_[0].x = unselScaleH;	endSize_[0].y = unselScaleV;
                endSize_[1].x = unselScaleH;	endSize_[1].y = unselScaleV;
                endSize_[2].x = unselScaleH;	endSize_[2].y = unselScaleV;

                    
                    
                totalSpace = height * iNumCrowns + vspace * 2;
                vMargin = ROUNDINT((screenHeight_ - totalSpace) / 2.0);

                endPos_[0].SetPos(screenWidth_/2.0, topOffset+vMargin+height, 0);
                endPos_[1].SetPos(screenWidth_/2.0, topOffset+vMargin+height+vspace+height, 0);
                endPos_[2].SetPos(screenWidth_/2.0, topOffset+vMargin+height+vspace+height+vspace+height, 0);
                break;
            }
            break;
        case Flat:
        case IntoFlat:
        case IntoFlat2:
                
                
            endSize_[0].x = flatScaleH;	endSize_[0].y = flatScaleV;
            endSize_[1].x = flatScaleH;	endSize_[1].y = flatScaleV;
            endSize_[2].x = flatScaleH;	endSize_[2].y = flatScaleV;

            // new approach
                
            float totalCrownsHeight = newFlatHeight * iNumCrowns;
            float totalRemainingSpace = screenHeight_ - totalCrownsHeight;            
            float verticalSpacer = totalRemainingSpace / (float) (iNumCrowns+1);
                
            endPos_[0].SetPos(screenWidth_/2.0, verticalSpacer + newFlatHeight, 0);
            endPos_[1].SetPos(screenWidth_/2.0, 2 * verticalSpacer + 2 * newFlatHeight, 0);
            endPos_[2].SetPos(screenWidth_/2.0, 3 * verticalSpacer + 3 * newFlatHeight, 0);
             
            
            break;
        }

       
    }
    else
    {        
        
        // phone version... different UI rules
        
        // only move anything if we're changing focus                            
        // the positions in the phone version are fixed in portrait mode

        // unselected means top here, and selected means bottom
        
        float unselectedY = screenHeight_ - screenHeight_ * .66f;  // upper y
        float selectedY = screenHeight_ - screenHeight_ * .06f;    // lower y          
        
        int selectedIndex = whichTrack;                        
        int unselectedIndex = ( whichTrack == FILTER_GRAPH_INDEX ) ? PITCH_GRAPH_INDEX : FILTER_GRAPH_INDEX;                        
        int unusedIndex = VOLUME_GRAPH_INDEX;
        
        if ( whichTrack == Scoop_FocusNone  || !bInRoundState )
        {
            // in this case whatever graph is already lower in the y-direction is "selected" (actually higher y)
            
            if ( pos_[FILTER_GRAPH_INDEX].GetY() > pos_[PITCH_GRAPH_INDEX].GetY() )
            {
                selectedIndex = FILTER_GRAPH_INDEX;
                unselectedIndex = PITCH_GRAPH_INDEX;
            }
            else
            {
                selectedIndex = PITCH_GRAPH_INDEX;
                unselectedIndex = FILTER_GRAPH_INDEX;
            }
        }
        
        

        

        // iPhone version
        vspace *= 1.3;
        totalSpace = selHeight + selUnheight + vspace;
        
        

        // the unused graph is offscreen
        
        startPos_[unusedIndex].SetPos( screenWidth_/2.0, 999999.0f, 0);                        
        endPos_[unusedIndex].SetPos( screenWidth_/2.0, 999999.0f, 0);
        
        startSize_[unusedIndex].x = 1.0f;
        startSize_[unusedIndex].y = 1.0f;                        
        
        endSize_[unusedIndex].x = 1.0f;
        endSize_[unusedIndex].y = 1.0f;            
        
        float startScaleH = phoneUnselectedScaleH * 1.5f;
        float startScaleV = phoneUnselectedScaleV * 1.5f;
        
        if ( bInRoundState )
        {
            
            if ( userInitiated )
            {
                // only set up the start pos if it's a user initiated
                // "switch".. otherwise we interpolate from where we were
                //startPos_[unselectedIndex].SetPos( screenWidth_/2.0, unselectedY, 0);            
                //startPos_[selectedIndex].SetPos( screenWidth_/2.0, selectedY, 0);
            }
            
            endPos_[unselectedIndex].SetPos( screenWidth_/2.0, unselectedY, 0);            
            endPos_[selectedIndex].SetPos( screenWidth_/2.0, selectedY, 0);            

            if ( whichTrack != Scoop_FocusNone && userInitiated )
            {
                
                
                // we only do the adjusted start size for scaling on the phone
                // when the user initiates the focus in portrait mode
//                startSize_[unselectedIndex].x = startScaleH;
//                startSize_[unselectedIndex].y = startScaleV;
//                
//                startSize_[selectedIndex].x = startScaleH;
//                startSize_[selectedIndex].y = startScaleV;
                
            }
           
            endSize_[unselectedIndex].x = phoneUnselectedScaleH;
            endSize_[unselectedIndex].y = phoneUnselectedScaleV;
            
            endSize_[selectedIndex].x = phoneSelectedScaleH;
            endSize_[selectedIndex].y = phoneSelectedScaleV;
            
        }
        else
        {
            vMargin = (screenHeight_ - totalSpace) / 2.0;
            topOffset = vMargin / 2;
                                                            
            endSize_[selectedIndex].x = flatScaleH;	
            endSize_[selectedIndex].y = flatScaleV;
            
            endSize_[unselectedIndex].x = flatScaleH;	
            endSize_[unselectedIndex].y = flatScaleV;
                            
            float totalCrownsHeight = newFlatHeight * iNumCrowns;
            float totalRemainingSpace = screenHeight_ - totalCrownsHeight;            
            float verticalSpacer = totalRemainingSpace / (float) (iNumCrowns+1);
            
            endPos_[unselectedIndex].SetPos(screenWidth_/2.0, verticalSpacer + newFlatHeight, 0);
            endPos_[selectedIndex].SetPos(screenWidth_/2.0, 2 * verticalSpacer + 2 * newFlatHeight, 0);
                                                    
        
        }
        
    }
    
    
    if ( interpTime > 0 )
    {
        moving_ = true; 
    }
    else
    {
        
        // just set to end values
        
        for (int i = 0; i < 3; i++) 
        {
            pos_[i] = endPos_[i];
            size_[i] = endSize_[i];      
            
            valueGraph_[i]->translation(pos_[i]);
			valueGraph_[i]->scale(size_[i].x, size_[i].y);
        }
        
        moving_ = false;
    }
    
        
}


// alternate focus on code for when the app is in landscape editing mode.
// The original focus on code mixes the concepts of selecting the active
// graph with lots of translation and scaling code.  We only want the
// selection cod e here.
//
// In thi mode we also record where we're editing in the graph
void Scoop::focusOnLandscape( int whichTrack, CGPoint p, float cameraRotation )
{
    focusTrack_ = whichTrack;
    writingTrack_ = whichTrack;
    
}

int
Scoop::trackHitsPoint(CGPoint p, float cameraRotation, float scaleBBox )
{
	// reverse y due to coordinate systems
	p.y = screenHeight_ - p.y;
	p.x = screenWidth_ - p.x;
	
	for (int i=0; i<NUM_GRAPHS; i++) {
		if (valueGraph_[i]->intersects(p, cameraRotation, 0, scaleBBox )) {
			return i;
		}
	}
	return Scoop_FocusNone;
}


// Code particular to iPhone version... betweent the pitch and filter graph,
// whatever's currently on the bottom should get the focus on transitions to
// portrait mode.
int Scoop::trackShouldGetFocusOnPhoneTransitionToPortrait() const
{

    if ( pos_[FILTER_GRAPH_INDEX].GetY() > pos_[PITCH_GRAPH_INDEX].GetY() )
    {
        return FILTER_GRAPH_INDEX;
    }
    else
    {
        return PITCH_GRAPH_INDEX;
    }
}

#define SWAPF(x,y) float t;t=x;x=y;y=t;

bool	
Scoop::writeIntoSelectedTrack(bool start, float cameraRotation)
{
	
    
    setDirty();
    
	float yVal = lastTouch_.y;
	
	if (focusTrack_ == Scoop_FocusNone) {
		writingTrack_ = Scoop_FocusNone;
		return false;
	}
	
	// invert coordinate system
	//yVal = screenHeight_ - yVal;
	 
	// clamp to range
	float bottom, top;
	getSelectedTrackScreenYRange(bottom, top);
	SWAPF(bottom, top);
	if (yVal < bottom) yVal = bottom;
	else if (yVal > top) yVal = top;
	
	// compute normalized value
	float normVal = (yVal-bottom) / (top-bottom);
	normVal = 1-normVal;
					
	
		
       
    // reverse y due to coordinate systems
    
    CGPoint reversedTouch = CGPointMake(screenWidth_ - lastTouch_.x, screenHeight_ - lastTouch_.y);    
    CGPoint constrainedAndNormalizedInGraph = valueGraph_[focusTrack_]->constrainAndNormalizePointInGraph( reversedTouch, cameraRotation );

    numTrackWriteCountThisFrame_++;
    
    if ( numTrackWriteCountThisFrame_ == 1 )
    {
        // set it if we haven't set it yet before the next usage (allows us to augment, e.g. > 1 call to this func per frame)
        // otherwise we keep the old value to link the calls together
        lastNormValueX_ = normValueX_;
        lastNormValue_ = normValue_;
    }
    
    normValueX_ = constrainedAndNormalizedInGraph.x;
    
	
    
	if (start) {	// overwrite last value if starting to write
        
        int iIndexForTime = valueGraph_[focusTrack_]->indexForTime(currentTime_);
		writingTrack_ = focusTrack_;
		normValue_ = normVal;
		
		graphIndex_ = iIndexForTime;	
		
		adjustedNormValue_ = normValue_;
		lastAdjustedNormValue_ = normValue_;
        lastNormValueX_ = normValueX_;
        
        graphIndexAtWriteBegin_ = graphIndex_;
        totalGraphIndicesForCurrentWrite_ = 0;
        lastGraphIndexForCurrentWrite_ = graphIndexAtWriteBegin_;
        
        forcedGraphIndex_ = Scoop_FocusNone;
        
	}


        
    
    
    
	
	
	normValue_ = normVal;
	
	// for debugging
	graphTop_ = top;
	graphBottom_ = bottom;
		
	return true;
}

//
//
CGRect Scoop::getWritingTrackBoundingBox( float cameraRotation )
{
    if ( writingTrack_ != Scoop_FocusNone )
    {
        return valueGraph_[writingTrack_]->boundingBox( cameraRotation );
    }
    
    return CGRectZero;
}


void	
Scoop::stopWritingIntoSelectedTrack()
{
    

    
    int iIndicesInQuantizeStep = valueGraph_[0]->quantize();
    
    if( totalGraphIndicesForCurrentWrite_ < 0 )
    {
        NSLog(@"problem: %d\n", totalGraphIndicesForCurrentWrite_ );
    }
    
    if ( iIndicesInQuantizeStep > 0 && totalGraphIndicesForCurrentWrite_ < iIndicesInQuantizeStep && totalGraphIndicesForCurrentWrite_ >= 0 && state_ == Round )
    {
        // we want to force the graph values for our writing track to hold this value for the
        // duration of a quantized beat, even though it will be incorrect in time
                
        float valA = 0.0f;
        float valV = 0.0f;
        valueGraph_[0]->valuesAtIndex( graphIndexAtWriteBegin_, valA, valV );
        forcedGraphValue_ = valA;
        
        //forcedGraphValue_ = valueGraph_[0]->valueAtIndex( graphIndexAtWriteBegin_ );
        forcedGraphIndex_ = writingTrack_;

        numForcedGraphIndicesRemaining_ = iIndicesInQuantizeStep - totalGraphIndicesForCurrentWrite_;
        lastForcedGraphIndex_ = graphIndex_;
              
                        
        //NSLog( @"forced graph: %d, remaining ind: %d, tot in write were: %d, at wb: %d, \n", forcedGraphIndex_, numForcedGraphIndicesRemaining_, totalGraphIndicesForCurrentWrite_ , graphIndexAtWriteBegin_);
    }
    else
    {
        forcedGraphIndex_ = Scoop_FocusNone;
        numForcedGraphIndicesRemaining_ = 0;
    }
 
    
	writingTrack_ = Scoop_FocusNone;
    totalGraphIndicesForCurrentWrite_ = 0;
    graphIndexAtWriteBegin_ = 0;
    
}

//
//
void Scoop::SetToneFrequency( float hz )
{
    if ( channelSynth_ )
    {        
        FMOD_RESULT result = dsp_->setParameter(FMOD_DSP_OSCILLATOR_RATE, hz);   
        toneFrequency_ = hz;
        ERRCHECK(result);
        
        playSynth();
        
    }
}

//
//
void Scoop::SetBeatVol( float vol )
{
    SoundInstance *activeBeat = getActiveSoundInstance();
    if ( activeBeat )
    {
        if ( activeBeat->getChannel() )
        {
            activeBeat->getChannel()->setVolume(vol );
            beatVol_ = vol;
        }
    }
}



    
void Scoop::MuteBeats( bool bMute )
{ 
    muteBeats_ = bMute; 
    channelGroupBeats_->setMute( muteBeats_ );    
}

//
// lil helper for fading the master vol
void Scoop::FadeMasterVol( float target, float dur, float fromLevel )
{
    
    if ( dur < .000001 )
    {
        // 0 time... just set the value
        
        if ( system_ )
        {        
            FMOD::ChannelGroup *cg;
            system_->getMasterChannelGroup(&cg);
            cg->setVolume( target );
        }

    }
    else
    {
        timeVolFadeBegin_ = CACurrentMediaTime();
        timeVolFadeEnd_ = timeVolFadeBegin_ + dur;
        
        FMOD::ChannelGroup *cg = nil;
        if ( system_ )
        {                    
            system_->getMasterChannelGroup(&cg);
        }
        
        if ( fromLevel < -.01 )
        {
            fromLevel = 0.0f;
            
            // use the current level
            
            if ( cg )
            {                        
                cg->getVolume( &fromLevel );
            }
            
        }
        
        volFadeStart_ = fromLevel;
        volFadeTarget_ = target;
        
        if ( cg )
        {     
            // kick it off
            cg->setVolume( fromLevel );
        }
        
    }
    
    
}

//
//
void Scoop::updateMasterVolFade()
{
    if ( timeVolFadeBegin_ > 0 )
    {
        
        double curTime = CACurrentMediaTime();
        bool bDone = false;
        
        double percentThere = (curTime - timeVolFadeBegin_) / (timeVolFadeEnd_ - timeVolFadeBegin_);
        if ( percentThere >= 1.0f )
        {
            bDone = true;
            percentThere = 1.0f;
        }
        
        
        double masterVol = volFadeStart_ + (volFadeTarget_ - volFadeStart_) * percentThere;               
        
        if ( system_ )
        {        
            FMOD::ChannelGroup *cg;
            system_->getMasterChannelGroup(&cg);
            cg->setVolume( masterVol );
        }
        
        if ( bDone )
        {
            timeVolFadeEnd_ = -1.0f;
            timeVolFadeBegin_ = -1.0f;
            volFadeStart_ = -1.0f;
            volFadeTarget_ = -1.0f;
        }
    }
}

/*
void
Scoop::playBreak(BYTE channel, BYTE note)
{
#if 0
	MidiEvent	event;
	WORD		rc;

	//BYTE		note = 36;

	if (channel <= 16) {
		// noteoff
		event.status = 128 + channel-1;
		event.data1 = note;
		event.data2 = 127;

		rc = PutMidiOut(hMidiOut_, (LPMIDIEVENT)&event);

		// noteon
		event.status = 0x90 + channel-1;
		event.data1 = note;
		event.data2 = 127;

		rc = PutMidiOut(hMidiOut_, (LPMIDIEVENT)&event);
	}
#endif
}

void
Scoop::stopBreak(BYTE channel, BYTE note)
{
#if 0
	MidiEvent	event;
	WORD		rc;

	//BYTE		note = 60;

	if (channel) {
		// noteoff
		event.status = 128 + channel-1;
		event.data1 = note;
		event.data2 = 127;

		rc = PutMidiOut(hMidiOut_, (LPMIDIEVENT)&event);
	}
#endif
}

void
Scoop::setFilter(BYTE channel, BYTE filterValue)
{
#if 0
	MidiEvent	event;
	WORD		rc;

	BYTE controlNum = 1;

	event.status = 176 + channel-1;
	event.data1 = controlNum;
	event.data2 = filterValue;

	rc = PutMidiOut(hMidiOut_, (LPMIDIEVENT)&event);
#endif
}
									
void
Scoop::setPitch(BYTE channel, BYTE pitch)
{
#if 0
	MidiEvent	event;
	WORD		rc;

	BYTE lsb = 0;

	event.status = 224 + channel-1;
	event.data1 = 0;
	event.data2 = pitch;

	rc = PutMidiOut(hMidiOut_, (LPMIDIEVENT)&event);
#endif
}

void
Scoop::setVolume(BYTE channel, BYTE volume)
{
#if 0
	MidiEvent	event;
	WORD		rc;

	event.status = 176 + channel-1;	// 176 + channel
	event.data1 = 7;
	event.data2 = volume;

	rc = PutMidiOut(hMidiOut_, (LPMIDIEVENT)&event);
#endif
}

void
Scoop::setProgram(BYTE prog)
{
#if 0
	MidiEvent	event;
	WORD		rc;

	event.status = 192 + 0;
	event.data1 = prog-1;
	event.data2 = 0;

	rc = PutMidiOut(hMidiOut_, (LPMIDIEVENT)&event);
#endif
}

void
Scoop::killSound(BYTE channel)
{ 
#if 0
	MidiEvent	event;
	WORD		rc;

	event.status = 176 + channel-1;
	event.data1 = 123;
	event.data2 = 0;

	rc = PutMidiOut(hMidiOut_, (LPMIDIEVENT)&event);
#endif
} 
*/


///////////////////////////////////////////////////////////////////////////////
// Custom FMOD DSPs
///////////////////////////////////////////////////////////////////////////////
 

//static unsigned int totalSamplesProcessed = 0;
//static const int volEnvSampleRate = 22050;



// dsp callbacks
FMOD_RESULT Scoop::volumeEnvelopeDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels)
{

	
    // not using
    /*
    
	// we need to know what length of time this bit of data correlates to (even if we're slightly off with matching it up with the drum loop)	
	
    unsigned int    userdata    = 0;
    char            name[256]   = {0}; 
    FMOD::DSP      *thisdsp     = (FMOD::DSP *)dsp_state->instance; 
	
    
    
	
	float fToneFreq = 0.0f;
	channelSynth_->getFrequency( &fToneFreq );
	
	// where are we in the sound time-wise?
	
	Uint64P curTime;
	curTime.assignNow();
	curTime -= dspClockBegin_;
	
	//unsigned int elaspsedMS = ConvertDSPTicksToMS( curTime );
		
	float timeChunkBegin = (float)totalSamplesProcessed / fmodSystemSampleRate;
	float timeChunkEnd = timeChunkBegin + length / fmodSystemSampleRate;
			
	// use the value graph values, which should have already been set using the envelope
	float valBegin = (float) valueGraph_[VOLUME_GRAPH_INDEX]->value(timeChunkBegin);  // 0-1
	float valEnd = (float) valueGraph_[VOLUME_GRAPH_INDEX]->value(timeChunkEnd);  // 0-1
	
    
	// This redundant call just shows using the instance parameter of FMOD_DSP_STATE and using it to 
	// call a DSP information function. 
    thisdsp->getInfo(name, 0, 0, 0, 0);	
    thisdsp->getUserData((void **)&userdata);
	
    
	// This loop assumes inchannels = outchannels, which it will be if the DSP is created with '0' 
	// as the number of channels in FMOD_DSP_DESCRIPTION.  
	// Specifying an actual channel count will mean you have to take care of any number of channels coming in,
	// but outputting the number of channels specified.  Generally it is best to keep the channel 
	// count at 0 for maximum compatibility.
	
	float curMult = valBegin;
	float deltaMult = (valEnd - valBegin) / length;
	
    for (unsigned int sample = 0; sample < length; sample++) 
    { 
		
		
		// approximating an experienced linear volume adjustment (http://www.dr-lex.be/info-stuff/volumecontrols.html#table1)
		//float logVal = curMult;
		float logVal = curMult * curMult * curMult;
		// float logVal = .001 * exp( 6.908 * curMult );
		// float logVal = curMult * curMult * curMult * curMult;		
		
		// use a different approach for the lower end of the range (better transition to silence)
		if ( curMult < .1 ) 
		{
			logVal *= curMult*10;
		}
				
		outbuffer[sample] = inbuffer[sample] * logVal;
			
		curMult += deltaMult;
		
		
    } 
	
	totalSamplesProcessed += length;
	
     */
    
    return FMOD_OK; 
}



// dsp callbacks
FMOD_RESULT Scoop::clockSynchronizeDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels)
{
		
    // just syncing to the first beat in the set since they're all synced together
            
    if ( setSoundInstances_.size() > 0 )
    {


        
        int indexToUse = activeBeatIndex_;
        if ( !(indexToUse >= 0 && indexToUse < setSoundInstances_.size()) )
        {
            indexToUse = 0;
        }
        
        if ( indexToUse >= 0 && indexToUse < setSoundInstances_.size() )
        {
            
            SoundInstance * referenceInst =  setSoundInstances_[indexToUse];
            if ( referenceInst )            
            {
               unsigned int channelPos = 0;
               FMOD_RESULT result = referenceInst->getChannel()->getPosition( &channelPos, FMOD_TIMEUNIT_MS );
               ERRCHECK( result );
                
               channelPosAtLastDSPChunkLoad_ = channelPos * .001;                       
               timeAtLastDSPChunkLoad_ = CACurrentMediaTime();
               pauseLengthDuringCurrentChunk_ = 0.0f; 
                
             
            }
        }
    
    }
    
     	
	// not touching the audio data at all - straight copy
	memcpy(outbuffer, inbuffer, length * sizeof(float) );
    
    
    return FMOD_OK; 
}


//
//
FMOD_RESULT F_CALLBACK volEnvelopeDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels) 
{ 
	// pass this on to the member func so we have access to the values we need	
	return Scoop::getScoop()->volumeEnvelopeDSPCallback( dsp_state, inbuffer, outbuffer, length, inchannels, outchannels );

}

//
//
FMOD_RESULT F_CALLBACK clockSyncDSPCallback(FMOD_DSP_STATE *dsp_state, float *inbuffer, float *outbuffer, unsigned int length, int inchannels, int outchannels) 
{ 
	// pass this on to the member func so we have access to the values we need	
	if ( Scoop::getScoop() )
    {
        return Scoop::getScoop()->clockSynchronizeDSPCallback( dsp_state, inbuffer, outbuffer, length, inchannels, outchannels );
    }
    else
    {
        // not touching the audio data at all - straight copy
        memcpy(outbuffer, inbuffer, length * sizeof(float) );                
        return FMOD_OK; 
    }
    
}
