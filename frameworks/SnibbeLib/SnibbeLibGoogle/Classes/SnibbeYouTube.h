//
//  SnibbeYouTube.h
//  SnibbeLib
//
//  Created by Graham McDermott on 12/14/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GDataServiceGoogleYouTube;
@class GDataServiceTicket;
@class GDataEntryBase;

@protocol SnibbeYouTubeDelegate <NSObject>

- (void) onVideoDidUpload: (NSString *) videoURL;
- (void) onVideoUploadProgress: (float) percent;
- (void) onVideoDidFail;

@end


@interface SnibbeYouTube : NSObject
{

    NSString * userName_;
    NSString * password_;
    NSString * developerKey_;
    
    GDataServiceGoogleYouTube *service_;
    GDataServiceTicket *ticket_;
    GDataEntryBase * dataEntryVideo_;
    
    id<SnibbeYouTubeDelegate> delegate_;
}

@property (nonatomic, retain) NSString * userName_;
@property (nonatomic, retain) NSString * password_;
@property (nonatomic, retain) NSString * developerKey_;
@property (nonatomic, assign) id<SnibbeYouTubeDelegate> delegate_;

- (void) uploadVideo: (NSString *) path title: (NSString *) title category: (NSString *) cat description: (NSString *) desc keywords: (NSString *) keywords;
- (void) cancelUpload;
- (void) deleteVideo;

@end
