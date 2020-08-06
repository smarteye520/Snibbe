//
//  SnibbeYouTube.m
//  SnibbeLib
//
//  Created by Graham McDermott on 12/14/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "SnibbeYouTube.h"
#import "SnibbeUtils.h"
#import "SnibbeUtilsiOS.h"

#import "GDataServiceGoogleYouTube.h"
#import "GDataMediaGroup.h"
#import "GDataMediaCategory.h"
#import "GDataYouTubeMediaElements.h"
#import "GDataYouTubeConstants.h"
#import "GDataEntryYouTubeUpload.h"


// private interface
@interface SnibbeYouTube()

- (void) clear;
- (GDataServiceGoogleYouTube *) getYouTubeService;


// youtube data delegates
- (void) ticket:(GDataServiceTicketBase *)ticket hasDeliveredByteCount:(unsigned long long)numberOfBytesRead ofTotalByteCount:(unsigned long long)dataLength;
- (void) serviceTicket:(GDataServiceTicket *)ticket finishedWithEntry:(GDataEntryBase *)entry error:(NSError *)error;

@end


@implementation SnibbeYouTube

@synthesize userName_;
@synthesize password_;
@synthesize developerKey_;
@synthesize delegate_;


- (id) init
{
    if ( ( self = [super init] ) )
    {
        
        self.userName_ = @"";
        self.password_ = @"";
        self.developerKey_= @"";
        self.delegate_ = nil;
        service_ = nil;
        ticket_ = nil;
        dataEntryVideo_ = nil;
    }
    
    return self;
}


- (void) dealloc
{

    [self clear];
    

    [super dealloc];
}





- (void) uploadVideo: (NSString *) path title: (NSString *) title category: (NSString *) cat description: (NSString *) desc keywords: (NSString *) keywords
{    
    
    
    if ( service_ )
    {
        [service_ release];
        service_ = nil;
    }
    
    if ( ticket_ )
    {
        [ticket_ release];
        ticket_ = nil;
    }
    
    if ( dataEntryVideo_ )
    {
        [dataEntryVideo_ release];
        dataEntryVideo_ = nil;
    }
    
    service_ = [[self getYouTubeService] retain];
    [service_ setYouTubeDeveloperKey:developerKey_];
        
            
    NSURL *url = [GDataServiceGoogleYouTube youTubeUploadURLForUserID: userName_];
    
    NSLog( @"feed url: %@\n", [url description] );
    
    // load the file data    
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSString *filename = [path lastPathComponent];
    
    // gather all the metadata needed for the mediaGroup        
    GDataMediaTitle *gDataTitle = [GDataMediaTitle textConstructWithString:title];  
    
    GDataMediaCategory *category = [GDataMediaCategory mediaCategoryWithString:cat];    
    [category setScheme: kGDataSchemeYouTubeCategory];
    
    GDataMediaDescription *gDataDesc = [GDataMediaDescription textConstructWithString:desc];
    
    GDataMediaKeywords *gDataKeywords = [GDataMediaKeywords keywordsWithString:keywords];
    
    BOOL isPrivate = NO;
    
    GDataYouTubeMediaGroup *mediaGroup = [GDataYouTubeMediaGroup mediaGroup];
    [mediaGroup setMediaTitle:gDataTitle];
    [mediaGroup setMediaDescription:gDataDesc];
    [mediaGroup addMediaCategory:category];
    [mediaGroup setMediaKeywords:gDataKeywords];
    [mediaGroup setIsPrivate:isPrivate];
    
    NSString *mimeType = [GDataUtilities MIMETypeForFileAtPath:path
                                               defaultMIMEType:@"video/mp4"];
    
    // create the upload entry with the mediaGroup and the file
    GDataEntryYouTubeUpload *entry;
    entry = [GDataEntryYouTubeUpload uploadEntryWithMediaGroup:mediaGroup
                                                          data:data
                                                      MIMEType:mimeType
                                                          slug:filename];
    
    
    SEL progressSel = @selector(ticket:hasDeliveredByteCount:ofTotalByteCount:);
    [service_ setServiceUploadProgressSelector:progressSel];
    
    ticket_ = [[service_ fetchEntryByInsertingEntry:entry
                                      forFeedURL:url
                                        delegate:self
                               didFinishSelector:@selector(serviceTicket:finishedWithEntry:error:)] retain];
    
    
}

//
//
- (void) cancelUpload
{
    if ( ticket_ )
    {
        [ticket_ cancelTicket];
    }
}

//
// delete the video that was just successfully uploaded
- (void) deleteVideo
{
    if ( dataEntryVideo_ && service_ )
    {
        [service_ deleteEntry: dataEntryVideo_ delegate: nil didFinishSelector: nil];                
    }
}


#pragma mark private implementation

//
//
- (void) clear
{
    if ( service_ )
    {
        [service_ release];
        service_ = nil;
    }
    
    if ( dataEntryVideo_ )
    {
        [dataEntryVideo_ release];
        dataEntryVideo_ = nil;
    }
    
    if ( ticket_ )
    {
        [ticket_ release];
        ticket_ = nil;
    }
    
    if ( userName_ )
    {
        [userName_ release];
        userName_ = nil;
    }
    
    if ( password_ )
    {
        [password_ release];
        password_ = nil;
    }
    
    if ( developerKey_ )
    {
        [developerKey_ release];
        developerKey_ = nil;
    }
    
}

//
//
- (GDataServiceGoogleYouTube *) getYouTubeService 
{
    GDataServiceGoogleYouTube* service = nil;
    
    if (!service) {
        service = [[GDataServiceGoogleYouTube alloc] init];
        
        //[service setShouldCacheDatedData:YES];
        [service setServiceShouldFollowNextLinks:YES];
        [service setIsServiceRetryEnabled:YES];
    }
    
    
    if ([userName_ length] > 0 && [password_ length] > 0) {
        [service setUserCredentialsWithUsername:userName_
                                       password:password_];
    } else {
        // fetch unauthenticated
        [service setUserCredentialsWithUsername:nil
                                       password:nil];
    }
    
    
    [service setYouTubeDeveloperKey:developerKey_];
    
    return [service autorelease];
}


#pragma mark youtube data delegates

//
//
- (void)ticket:(GDataServiceTicketBase *)ticket hasDeliveredByteCount:(unsigned long long)numberOfBytesRead ofTotalByteCount:(unsigned long long) dataLength
{
    SSLog( @"youtube bytes delivered: %llu of total: %llu\n", numberOfBytesRead, dataLength );
    
    if ( delegate_ )
    {
        float percentThere = (float) numberOfBytesRead / dataLength;
        percentThere = MAX( percentThere, 0.0f );
        percentThere = MIN( percentThere, 1.0f );
        
        [delegate_ onVideoUploadProgress: percentThere];
    }

    
}

//
//
- (void)serviceTicket:(GDataServiceTicket *)ticket finishedWithEntry:(GDataEntryBase *)entry error:(NSError *)error
{
    
    
    bool gotValidLink = false;
    
    if ( error != nil )
    {
       SSLog( @"youtube finished.  error is %@\n", [error description] );
    }
    else
    {
        if ( delegate_ && entry )
        {
            NSArray * links = [entry links];
            if ( [links count] > 0 )
            {
                gotValidLink = true;
                GDataLink * first = (GDataLink *) [links objectAtIndex:0];                
                NSString * videoURL = [first href];
                dataEntryVideo_ = [entry retain];
                [delegate_ performSelector: @selector( onVideoDidUpload: ) withObject: videoURL];                
            }
        }
    }
    
    if ( !gotValidLink )
    {
        if ( delegate_ )
        {
            [delegate_ performSelector: @selector(onVideoDidFail)];
        }

    }
}

@end
