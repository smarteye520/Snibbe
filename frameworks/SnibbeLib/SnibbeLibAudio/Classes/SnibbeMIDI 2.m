//
//  SnibbeMIDI.m
//  SnibbeLibAudio
//
//  Created by Henrique Manfroi on 8/23/11.
//  Copyright 2011 Scott Snibbe Studio. All rights reserved.
//

#import "SnibbeMIDI.h"

#include <mach/mach.h>
#include <mach/mach_time.h>

// static double resolution=0;  // defined but not used

static double machToSecondsFactor=0;
static double secondsToMachFactor=0;

static double BachTime()
{
    if (!machToSecondsFactor)
    {
        mach_timebase_info_data_t timebase;
        mach_timebase_info(&timebase);
        machToSecondsFactor = ((double)timebase.numer / (double)timebase.denom) / 1000000000.0f;
        secondsToMachFactor = 1.0/machToSecondsFactor;
    }
    return (double)(mach_absolute_time() * machToSecondsFactor);
}



static void SMIDINotifyProc(const MIDINotification *message, void *refCon);
static void SMIDIReadProc(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon);

void SMIDINotifyProc(const MIDINotification *message, void *refCon)
{
}

void SMIDIReadProc(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon)
{
}

@implementation SnibbeMIDI

#pragma mark Properties

//@synthesize delegate;
@synthesize sources,destinations;

- (NSUInteger) numberOfConnections
{
    return sources.count + destinations.count;
}

#pragma mark -
#pragma mark Singleton
 
static SnibbeMIDI *sharedSingleton = 0;

+ (void)initialize
{
    static BOOL initialized = NO;
    
    IF_IOS_HAS_COREMIDI
    (   
        if(!initialized)
        {
            initialized = YES;
            sharedSingleton = [[SnibbeMIDI alloc] init];
        }
    );
    
    if(!initialized) {
        
        NSLog(@"CoreMIDI not supported; SnibbeMIDI was not initialized");
    }
}

+ (SnibbeMIDI*)sharedMIDI {
    
    return sharedSingleton;
}

#pragma mark -
#pragma mark init


- (id) init
{
    if ((self = [super init]))
    {
        sources      = [NSMutableArray new];
        destinations = [NSMutableArray new];
        
        OSStatus s;
        
        s = MIDIClientCreate((CFStringRef)@"MidiMonitor MIDI Client", SMIDINotifyProc, self, &client);
        //NSLog(@"Create MIDI client (%i)", (int)s);
        
        s = MIDIOutputPortCreate(client, (CFStringRef)@"MidiMonitor Output Port", &outputPort);
        //NSLog(@"Create output MIDI port (%i)", (int)s);
        
        s = MIDIInputPortCreate(client, (CFStringRef)@"MidiMonitor Input Port", SMIDIReadProc, self, &inputPort);
        //NSLog(@"Create input MIDI port (%i)", (int)s);
    }
    
    return self;
}

- (void) dealloc
{
    [self allNotesOff];
    
    if (outputPort)
        MIDIPortDispose(outputPort);
    
    if (inputPort)
        MIDIPortDispose(inputPort);
    
    if (client)
        MIDIClientDispose(client);
    
    [sources release];
    [destinations release];
    
    [super dealloc];
}


#pragma mark -
#pragma mark Connect/disconnect

- (void) enableNetwork:(BOOL)enabled
{
    MIDINetworkSession* session = [MIDINetworkSession defaultSession];
    session.enabled = YES;
    session.connectionPolicy = MIDINetworkConnectionPolicy_Anyone;
    //NSLog(@"SnibbeMIDI starting MIDI session.");
}

#pragma mark -
#pragma mark MIDI send

- (void) sendPacketList:(const MIDIPacketList *)packetList
{
    for (ItemCount index = 0; index < MIDIGetNumberOfDestinations(); ++index)
    {
        MIDIEndpointRef outputEndpoint = MIDIGetDestination(index);
        if (outputEndpoint)
        {
            // Send it
            OSStatus statusError = MIDISend(outputPort, outputEndpoint, packetList);
            
            if(statusError)
            {
                NSLog(@"Ouch!");
            }
        }
    }
}

- (void) sendBytes:(const UInt8*)data size:(UInt32)size
{
    //NSLog(@"sendBytes (%i bytes to core MIDI)", (int)size);
    assert(size < 65536);
    Byte packetBuffer[size+100];
    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer;
    MIDIPacket     *packet     = MIDIPacketListInit(packetList);
    
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, data);
    
    [self sendPacketList:packetList];
}

- (void) testSendInternal {
    
    for (int n = 0; n < 20; ++n)
    {
        const UInt8 note      = rand() / (RAND_MAX / 127);
        const UInt8 noteOn[]  = { 0x90, note, 127 };
        const UInt8 noteOff[] = { 0x80, note, 0   };
        
        [self sendBytes:noteOn size:sizeof(noteOn)];
        [NSThread sleepForTimeInterval:0.1];
        [self sendBytes:noteOff size:sizeof(noteOff)];
    }
}

- (void) testSend {
    
    [self performSelectorInBackground:@selector(testSendInternal) withObject:nil];
}

-(void) sendNoteOn:(int) note vel:(int)velocity {

    //NSLog(@"SnibbeMIDI: Note on %i (%f)", note, BachTime());
    const UInt8 noteOn[] = {0x90, note, velocity};
    [self sendBytes:noteOn size:sizeof(noteOn)];
}

-(void) sendNoteOff:(int) note {

    //NSLog(@"SnibbeMIDI: Note off %i (%f)", note, BachTime());
    const UInt8 noteOff[] = {0x80, note, 0};
    [self sendBytes:noteOff size:sizeof(noteOff)];
}

-(void) sendNoteOnInternal:(NSNumber*)note vel:(int)velocity {
    
    [self sendNoteOn:[note intValue] vel:velocity];
}

-(void) sendNoteOffInternal:(NSNumber*)note {
    
    [self sendNoteOff:[note intValue]];
}

-(void) allNotesOff {
    
    //NSLog(@"SnibbeMIDI: allNotesOff");

    const UInt8 allNotesOff[] = {0xB0, 123, 0};
    [self sendBytes:allNotesOff size:sizeof(allNotesOff)];
    
    const UInt8 allSoundsOff[] = {0xB0, 120, 0};
    [self sendBytes:allSoundsOff size:sizeof(allSoundsOff)];
    
    //hack... the above was not working...
//    for (int n = 0; n < 128; n++)
//        [self sendNoteOff:n];
    
    //better hack :)
    int size = 3;
    Byte packetBuffer[size * 128 + 100];
    
    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer;
    MIDIPacket *packet = MIDIPacketListInit(packetList);
    
    for (int n = 0; n < 128; n++) {
        
        const UInt8 noteOff[] = {0x80, n, 0};
        packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, noteOff);
    }
    
    [self sendPacketList:packetList];
}

-(void) playNote:(int) note vel:(int)velocity dur:(double)duration {
    
    [self sendNoteOn:note vel:velocity];
    NSNumber* n = [NSNumber numberWithInt:note];
    [self performSelector:@selector(sendNoteOffInternal:) withObject:n afterDelay:duration];
    
    //NSLog(@"SnibbeMIDI: playNote %i / %fs (%f), vel: %d", note, duration, BachTime(), velocity);
}

-(void) sendCC:(int)controller val:(int)value {
    
    const UInt8 controllerCC[] = {0xB0, controller, value};
    [self sendBytes:controllerCC size:sizeof(controllerCC)];
}
//
//
//-(void) sendMultipleNotes:(bool)noteOnOff vel:(int)velocity note:(NSNumber*)firstNote, ... {
// 
//    int nCommand = noteOnOff ? 0x90 : 0x80;
//    
//    va_list args;
//    va_start(args, firstNote);
//    
//    //get num of vararg
//    int nCount = 0;
//    for (NSNumber* note = firstNote; note != nil; note = va_arg(args, NSNumber*))
//        nCount++;
//    
//    //first note
//    const UInt8 firstNoteOn[] = {nCommand, [firstNote intValue], velocity};
//    int size = sizeof(firstNoteOn);
//    
//    Byte packetBuffer[size * nCount + 100];
//    
//    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer;
//    
//    MIDIPacket *packet = MIDIPacketListInit(packetList);
//    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, firstNoteOn);
//    
//    //do the next notes
//    for (NSNumber* note = firstNote; note != nil; note = va_arg(args, NSNumber*))
//    {
//        //skip first
//        if(note == firstNote)
//            continue;
//        
//        //send note
//        int nNote = [note intValue];
//        const UInt8 noteOn[] = {nCommand, nNote, velocity};
//        packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, noteOn);
//    }
//    
//    //send the notes
//    [self sendPacketList:packetList];
//    
//    va_end(args);
//}

-(void) sendChord3:(bool)noteOnOff vel:(int)velocity note1:(int)n1 note2:(int)n2 note3:(int)n3 {
    
    int size = 3;
    Byte packetBuffer[size * 3 + 100];
    
    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer;
    MIDIPacket *packet = MIDIPacketListInit(packetList);
    
    int nCommand = noteOnOff ? 0x90 : 0x80;
    
    const UInt8 noteOn1[] = {nCommand, n1, velocity};
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, noteOn1);
    
    const UInt8 noteOn2[] = {nCommand, n2, velocity};
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, noteOn2);
    
    const UInt8 noteOn3[] = {nCommand, n3, velocity};
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, noteOn3);    
    
    //send the notes
    [self sendPacketList:packetList];    
}


// added for MAMPlayer support
- (void) scheduleBytes:(const UInt8*)data size:(UInt32)size mt:(uint64_t) machTime
{
    assert(size < 65536);
    Byte packetBuffer[size+100];
    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer;
    MIDIPacket     *packet     = MIDIPacketListInit(packetList);
    
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, machTime, size, data);
    
    [self sendPacketList:packetList];    
}

-(void) setMIDIReferenceTime:(uint64_t)ref {
    referenceTime=ref;
}

-(void) allNotesOffAllChannels
{    
    //NSLog(@"SnibbeMIDI: allNotesOffAllChannels");
    
    UInt8 allNotesOff[] = {0xB0, 123, 0};
    for(int channel=0; channel<16; ++channel)
    {  
        allNotesOff[0] = (allNotesOff[0]&0xf0) | channel;
        [self sendBytes:allNotesOff size:sizeof(allNotesOff)];
    }
}



-(void) scheduleNote:(int)pitch 
                 vel:(int)velocity 
                 chn:(int)channel
                 tim:(double)startTime
                 dur:(double)duration {
    double endTime=startTime+duration;
    //uint64_t machNow=mach_absolute_time();
    uint64_t machStart=(startTime*secondsToMachFactor)+referenceTime;
    uint64_t machEnd  =(endTime  *secondsToMachFactor)+referenceTime;
    //NSLog(@"scheduleNote:\tpitch\t%d\t%.3f\t%.3f\t\t%lld\t%lld\t%lld\t%lld",pitch,startTime,endTime,machStart,machEnd,machNow,referenceTime);
    const UInt8 noteOnMessage[] = {0x90|channel, pitch, velocity};
    [self scheduleBytes:noteOnMessage size:3 mt:machStart];
    const UInt8 noteOffMessage[] = {0x80|channel, pitch, 0};
    [self scheduleBytes:noteOffMessage size:3 mt:machEnd];
}

-(void) flushMIDIOutput {
    // note: this does not work through network MIDI
    OSStatus statusError = MIDIFlushOutput(NULL);   // NULL means "all"
    
    if(statusError)
    {
        NSLog(@"flushMIDIOutput ERROR (%ld)!",statusError);
    }
}


@end
