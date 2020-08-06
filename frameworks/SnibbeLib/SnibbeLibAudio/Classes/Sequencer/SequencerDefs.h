//
//  SequencerDefs.h
//  SnibbeLib
//
//  Created by Graham McDermott on 11/13/12.
//  Copyright (c) 2012 Scott Snibbe Studio. All rights reserved.
//

#ifndef SnibbeLib_SequencerDefs_h
#define SnibbeLib_SequencerDefs_h

#define SEQUENCER_DEBUG 0

typedef double SeqTimeT;

// The playback style of a sequencer.
// Sentence: sounds play seamlessly back to back (limit of once sound per slot)
// Discrete: sounds are triggered individually, and length of each time slot is independent of sound length

typedef enum
{
    eSeqSentence = 0,
    eSeqDiscrete
} SequencerPlaybackT;


#endif
