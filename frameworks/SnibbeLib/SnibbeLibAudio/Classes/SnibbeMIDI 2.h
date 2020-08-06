//
//  SnibbeMIDI.h
//  SnibbeLibAudio
//
//  Created by Henrique Manfroi on 8/23/11.
//  Based on PGMidi created by Pete Goodliffe on 10/12/10, available at http://goodliffe.blogspot.com/
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//

// iOs version detection adapted from http://cocoawithlove.com/2010/07/tips-tricks-for-conditional-ios3-ios32.html

#ifndef kCFCoreFoundationVersionNumber_iPhoneOS_4_0
#define kCFCoreFoundationVersionNumber_iPhoneOS_4_0 550.32
#endif

#ifndef kCFCoreFoundationVersionNumber_iPhoneOS_4_1
#define kCFCoreFoundationVersionNumber_iPhoneOS_4_1 550.38
#endif

#ifndef kCFCoreFoundationVersionNumber_iPhoneOS_4_2
// NOTE: THIS IS NOT THE FINAL NUMBER
// 4.2 is not out of beta yet, so took the beta 1 build number
#define kCFCoreFoundationVersionNumber_iPhoneOS_4_2 550.47
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
#define IF_IOS4_OR_GREATER(...) \
if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iPhoneOS_4_0) \
{ \
__VA_ARGS__ \
}
#else
#define IF_IOS4_OR_GREATER(...) \
if (false) \
{ \
}
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40200
#define IF_IOS4_2_OR_GREATER(...) \
if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iPhoneOS_4_2) \
{ \
__VA_ARGS__ \
}
#else
#define IF_IOS4_2_OR_GREATER(...) \
if (false) \
{ \
}
#endif

#define IF_IOS_HAS_COREMIDI(...) IF_IOS4_2_OR_GREATER(__VA_ARGS__)

//actual class

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

@interface SnibbeMIDI : NSObject {
    
    MIDIClientRef      client;
    MIDIPortRef        outputPort;
    MIDIPortRef        inputPort;
    uint64_t           referenceTime;
    NSMutableArray    *sources, *destinations;
}

@property (nonatomic,readonly) NSUInteger         numberOfConnections;
@property (nonatomic,readonly) NSMutableArray    *sources;
@property (nonatomic,readonly) NSMutableArray    *destinations;

/// Enables or disables CoreMIDI network connections
- (void) enableNetwork:(BOOL)enabled;

/// Send a MIDI byte stream to every connected MIDI port
- (void) sendBytes:(const UInt8*)bytes size:(UInt32)size;
- (void) sendPacketList:(const MIDIPacketList *)packetList;
- (void) testSend;

/// singleton
+ (SnibbeMIDI*)sharedMIDI;

/// interfaces
-(void) sendNoteOn:(int) note vel:(int)velocity;
-(void) sendNoteOff:(int) note;
-(void) playNote:(int) note vel:(int)velocity dur:(double)duration;
-(void) allNotesOff;
-(void) sendCC:(int) controller val:(int)value;

/// deferred sending
//-(void) sendMultipleNotes:(bool)noteOnOff vel:(int)velocity note:(NSNumber*)firstNote, ... NS_REQUIRES_NIL_TERMINATION;

-(void) sendChord3:(bool)noteOnOff vel:(int)velocity note1:(int)n1 note2:(int)n2 note3:(int)n3;

/// support for MAMPlayer
-(void) setMIDIReferenceTime:(uint64_t)ref;
-(void) flushMIDIOutput;
-(void) scheduleNote:(int)pitch         // MIDI pitch
                 vel:(int)velocity      // MIDI velocity
                 chn:(int)channel       // MIDI channel
                 tim:(double)startTime  // wrt referenceTime, seconds
                 dur:(double)duration;  // seconds
-(void) scheduleBytes:(const UInt8*)data size:(UInt32)size mt:(uint64_t) machTime;
-(void) allNotesOffAllChannels;


@end
