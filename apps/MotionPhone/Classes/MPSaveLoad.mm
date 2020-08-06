//
//  MPSaveLoad.m
//  MotionPhone
//
//  Created by Graham McDermott on 12/2/11.
//  Copyright (c) 2011 Scott Snibbe. All rights reserved.
//

#import "MPSaveLoad.h"
#import "MPArchiveFrame.h"
#include "defs.h"
#include "mcanvas.h"
#import "SnibbeCapture.h"
#import "UIImage+SnibbeTransformable.h"
#import "UIImage+SnibbeMaskable.h"

MPSaveLoad * saveLoad = nil;

NSString * keyScreenshot = @"mp_screenshot";
NSString * keySaveFileFormat = @"mp_savefileformat";
NSString * keyNumFrames = @"mp_numframes";
NSString * keyFrames = @"mp_frames";
NSString * keyFrame_Prefix = @"mp_frame_";
NSString * keyNextZ = @"mp_nextbrushz";
NSString * keyCanvasScale = @"mp_canvas_scale";
NSString * keyCanvasTranslateX = @"mp_canvas_translate_x";
NSString * keyCanvasTranslateY = @"mp_canvas_translate_y";

NSString * savePrefix = @"mp_save_";
NSString * savePostfix = @".mpsave";
NSString * imageExtension = @"mpimage";

#define SAVE_IMAGE_MAX_HEIGHT_IPAD 300.0f
#define SAVE_IMAGE_MAX_HEIGHT_IPHONE 960.0f

#define CUR_SAVE_FORMAT_VERSION 3

// private interface
@interface MPSaveLoad()

- (bool) save: (NSString *) filePath;
- (bool) load: (NSString *) filePath;

- (NSString *) constuctSaveString: (int) saveNum;
- (NSArray *) collectOrderedSavePaths;
- (NSString *) savePathForIndex: (int) saveNum;
- (NSString *) generateNextSaveName;

@end


@implementation MPSaveLoad


//
//
+ (MPSaveLoad *) getSL;
{
    return saveLoad;
}

//
//
+ (void) startup
{
    if ( !saveLoad )
    {
        saveLoad = [[MPSaveLoad alloc] init];
    }
}

//
//
+ (void) shutdown
{
    if ( saveLoad )
    {
        [saveLoad release];
        saveLoad = nil;
    }
}


//
//
- (id) init
{

    if ( (self = [super init]) )
    {
        saveFilePath_ = nil;
        saveData_ = nil;       
        saveImage_ = nil;
    }
    
    
    return self;
}

//
//
- (void) dealloc
{

}

//
//
- (int)  numSaves
{
    
    NSArray *saveNames = [self collectOrderedSavePaths];
    return [saveNames count];
        
}

//
//
- (bool) loadSaveAtIndex: (int) iIndex
{
        
    NSString *saveFilePath = [self savePathForIndex: iIndex];    
    return [self load: saveFilePath];    
    
}

//
//
- (bool) deleteSaveAtIndex: (int) iIndex
{
    

    
    NSString *saveFilePath = [self savePathForIndex: iIndex];    
    NSString * imagefilePath = [saveFilePath stringByDeletingPathExtension];
    imagefilePath = [imagefilePath stringByAppendingPathExtension: imageExtension];
    
    [[NSFileManager defaultManager] removeItemAtPath: imagefilePath error:nil];
    return [[NSFileManager defaultManager] removeItemAtPath: saveFilePath error:nil];
}

//
//
- (bool) save
{

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *saveDirectory = [paths objectAtIndex:0];            
    NSString *saveName = [self generateNextSaveName];    
	NSString *archivePath = [saveDirectory stringByAppendingPathComponent:saveName];
	
    return [[MPSaveLoad getSL] save: archivePath];
    
}

//
//
- (UIImage *) screenShotForSaveAtIndex: (int) iIndex
{
    
    NSString * saveFilePath = [self savePathForIndex: iIndex];
    if ( saveFilePath )
    {
        
        
        
        NSString * imagefilePath = [saveFilePath stringByDeletingPathExtension];
        imagefilePath = [imagefilePath stringByAppendingPathExtension: imageExtension];

        // first try image saved alongside save data
        NSData * dataImage = [NSData dataWithContentsOfFile: imagefilePath];
        if ( dataImage )
        {
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:dataImage];
            
            if ( unarchiver )
            {
                NSData * screenShotData = [unarchiver decodeObjectForKey: keyScreenshot];                
                UIImage * imageSS = [UIImage imageWithData: screenShotData];
                
                [unarchiver finishDecoding];
                [unarchiver release];
                
                return imageSS;                                
            }
        }
        
        
        // then fall back to look in the big save itself
        NSData * data = [NSData dataWithContentsOfFile:saveFilePath];
        if ( data )
        {
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            
            if ( unarchiver )
            {
                NSData * screenShotData = [unarchiver decodeObjectForKey: keyScreenshot];                
                UIImage * imageSS = [UIImage imageWithData: screenShotData];
                
                [unarchiver finishDecoding];
                [unarchiver release];
                
                return imageSS;                                
            }
            

        }
    }        
    
    return  nil;
    
}

#pragma mark private implementation

//
//
- (void) completeSave
{
    gMCanvas->postSave();
    [saveData_ release];
    [saveFilePath_ release];
    [saveImage_ release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationPendingEnd object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationSavedCanvas object:nil];
    
    
}


//
//
- (void) doSave: (NSKeyedArchiver *) archiver
{
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    int iNumFrames = gMCanvas->numFrames();
    int iSaveFileFormat = CUR_SAVE_FORMAT_VERSION;

    
    
    
    // potentially scale the image
    float maxHeight = IS_IPAD ? SAVE_IMAGE_MAX_HEIGHT_IPAD : SAVE_IMAGE_MAX_HEIGHT_IPHONE;
    UIImage * resizeImage = saveImage_;
    if ( saveImage_.size.height > maxHeight )
    {
        float scaleFactor = (maxHeight/saveImage_.size.height);
        resizeImage = [ saveImage_ imageByScalingToSize: CGSizeMake( saveImage_.size.width * scaleFactor, saveImage_.size.height * scaleFactor) ];        
        
    }
    
    // save the screenshot
    NSData *pngSS = UIImagePNGRepresentation( resizeImage );
    [archiver encodeObject: pngSS forKey:keyScreenshot];  
    
    
    
    // general canvas values
    
    gMCanvas->preSave();
    
    // next brush z
    [archiver encodeInt: gMCanvas->nextBrushZValForSave() forKey:keyNextZ];
    
    // editing params
    gParams->saveToArchive( archiver );        
    
    // save num frames
    [archiver encodeInt:iNumFrames forKey:keyNumFrames];
    
    // save file format
    [archiver encodeInt:iSaveFileFormat forKey:keySaveFileFormat];
    
    float scale = SCALE_DEFAULT;
    float translateX = 0.0f;
    float translateY = 0.0f;
    gMCanvas->getTransforms(scale, translateX, translateY);
    
    // canvas scale 
    [archiver encodeFloat:scale forKey: keyCanvasScale];
    
    // canvas translateX
    [archiver encodeFloat:translateX forKey: keyCanvasTranslateX];
    
    // canvas translateY
    [archiver encodeFloat:translateY forKey: keyCanvasTranslateY];
        
    // save out the frames
    
    /*
     // method 2
    NSMutableArray * arrayFrames = [[NSMutableArray alloc] init];
    for ( int iF = 0; iF < iNumFrames; ++ iF )
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                
        MPArchiveFrame * af = gMCanvas->saveFrame( iF );        
        [arrayFrames addObject: af];
        
        [pool release];
    }
        
    [archiver encodeObject: arrayFrames forKey:keyFrames];
    [arrayFrames release];
    

    
    //[arrayFrames release];
    
    */
    // method 3
    
    for ( int iF = 0; iF < iNumFrames; ++ iF )
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
     
        NSString * strKeyFrame = [NSString stringWithFormat: @"%@%d", keyFrame_Prefix, iF];                
        MPArchiveFrame * af = gMCanvas->saveFrame( iF );
        [archiver encodeObject: af forKey:strKeyFrame];        
        [pool release];
    }
     
	[archiver finishEncoding];
    
    SSLog( @"writing save file: size %d\n", [saveData_ length] );
    
	[saveData_ writeToFile:saveFilePath_ atomically:YES];
        
    
    [self performSelectorOnMainThread:@selector(completeSave) withObject:nil waitUntilDone:true];    
    [archiver release];
    
    [pool release];
    
}

// Save the MotionPhone app state to a file with the given path and
// name
- (bool) save: (NSString *) filePath
{
    bool bSuccess = false;
    
    saveFilePath_ = [filePath retain];
    
    SSLog( @"Saving document: %@\n", filePath );    
    
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationPendingBegin object:nil];
    
	saveData_ = [[NSMutableData data] retain];
	NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:saveData_];
                
    CGRect mainWindowBounds = [[UIScreen mainScreen] bounds];
    mainWindowBounds = CGRectMake( mainWindowBounds.origin.x, mainWindowBounds.origin.y, mainWindowBounds.size.width * gContentScaleFactor, mainWindowBounds.size.height * gContentScaleFactor );
    saveImage_ = [ssScreenShotUIImage( mainWindowBounds ) retain];
            
#ifdef MOTION_PHONE_MOBILE
     
    // add a rounded mask around the save image's edges
    // baking the rounded mask into the save image to avoid
    // the processing of masing each image in the load view 
    
    
    NSData * pngData = UIImagePNGRepresentation( saveImage_ ); // this is needed for the masking to work
    UIImage * newImage = [UIImage imageWithData: pngData];    
    
    [saveImage_ release];
    
    UIImage * imageMask = [UIImage imageNamed: @"savemask.png"];
    imageMask = [imageMask imageByScalingProportionallyToSize: newImage.size];
     
    if ( imageMask && newImage )
    {
        saveImage_ = [newImage imageByMasking: imageMask];
        [saveImage_ retain];
    }
    
#endif
    
    
    
    
    
    
    // create a parallel file with the save image
    
    NSMutableData * imageData = [NSMutableData data];
	NSKeyedArchiver * imageArchiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:imageData];
    NSString * imagefilePath = [saveFilePath_ stringByDeletingPathExtension];
    imagefilePath = [imagefilePath stringByAppendingPathExtension: imageExtension];
    
    float maxHeight = IS_IPAD ? SAVE_IMAGE_MAX_HEIGHT_IPAD : SAVE_IMAGE_MAX_HEIGHT_IPHONE;
    
    if ( IS_IPAD )
    {
        // ipad 3 resolution
        
        if ( gContentScaleFactor >= 1.999f )
        {        
            maxHeight *= 2.0f;
        }
    }
    
    
    UIImage * resizeImage = saveImage_;
    if ( saveImage_.size.height > maxHeight )
    {
        float scaleFactor = (maxHeight/saveImage_.size.height);
        resizeImage = [ saveImage_ imageByScalingToSize: CGSizeMake( saveImage_.size.width * scaleFactor, saveImage_.size.height * scaleFactor) ];                
    }    
    
    NSData *pngSS = UIImagePNGRepresentation( resizeImage );
    [imageArchiver encodeObject: pngSS forKey:keyScreenshot];          
    [imageArchiver finishEncoding];
	[imageData writeToFile:imagefilePath atomically:YES];        
    [imageArchiver release];
    
    
    
    // now onto the rest of the save    
    [NSThread detachNewThreadSelector:@selector(doSave:) toTarget:self withObject:archiver];
    
    return bSuccess;
}



- (void) completeLoadVer2
{
    
    if ( loadedFrames_ )
    {
        
        // clear out current!
        gMCanvas->onRequestEraseCanvas( false );
        
        
        int iCurFrameNum = 0;
        for ( MPArchiveFrame * af in loadedFrames_ )
        {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            gMCanvas->loadFrame( af, iCurFrameNum );
            iCurFrameNum++;            
            [pool release];
            
        }
        
        
        [loadedFrames_ release];        
        [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationLoadedCanvas object:nil];
        
        
    }
    
    
    loadedFrames_ = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationPendingEnd object:nil];
    
#ifdef MOTION_PHONE_MOBILE
    [[NSNotificationCenter defaultCenter] postNotificationName:gNotificationDismissUIDeep object:nil];
#endif
    
}

//
//
- (void) completeLoadVer3
{
    
    [self completeLoadVer2];        
    
}

- (void) doLoadAsync: (NSKeyedUnarchiver *) unarchiver
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    
    int iSaveFileFormat = [unarchiver decodeIntForKey: keySaveFileFormat];
    
    
    
    if ( iSaveFileFormat >= 2 )
    {
        // saved state introduced in save file format verion 2
        
        /* this isn't working yet - come back for 1.1 
        
        float scale = [unarchiver decodeFloatForKey: keyCanvasScale];
        float trans[2];
        trans[X] = [unarchiver decodeFloatForKey: keyCanvasTranslateX];
        trans[Y] = [unarchiver decodeFloatForKey: keyCanvasTranslateY];
        
        gMCanvas->setScale( scale );
        gMCanvas->translateAbsolute( trans );
                
         */
    }
    
    if ( iSaveFileFormat >= 1 && iSaveFileFormat <= 2 )
    {
        
        loadedFrames_ = [[unarchiver decodeObjectForKey: keyFrames] retain];
                
        // file format version 1.0                

        // global canvas vals
        
        // next z
        MCanvas::setNextBrushZ( [unarchiver decodeIntForKey: keyNextZ] );                
        
        // editing params
        gParams->loadFromArchive( unarchiver );           
        
        [self performSelectorOnMainThread:@selector(completeLoadVer2) withObject:nil waitUntilDone:false];
        
        [unarchiver finishDecoding];
        [unarchiver release];
        
    }
    else if ( iSaveFileFormat >= 3 )
    {
        
        // file format version 3.0                        
        int iNumFrames = [unarchiver decodeIntForKey: keyNumFrames];
        
        if ( loadedFrames_ )
        {
            [loadedFrames_ release];
            loadedFrames_ = nil;
        }
        
        loadedFrames_ = [[NSMutableArray alloc] init];
        
        for ( int iF = 0; iF < iNumFrames; ++iF )
        {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            NSString * strKeyFrame = [NSString stringWithFormat: @"%@%d", keyFrame_Prefix, iF];                
            MPArchiveFrame *af = [unarchiver decodeObjectForKey: strKeyFrame];
            [(NSMutableArray *) loadedFrames_ addObject: af];

            [pool release];
        }
            
        
        
        
        
        // global canvas vals
        
        // next z
        MCanvas::setNextBrushZ( [unarchiver decodeIntForKey: keyNextZ] );                
        
        // editing params
        gParams->loadFromArchive( unarchiver );           
        
        [self performSelectorOnMainThread:@selector(completeLoadVer3) withObject:nil waitUntilDone:false];
        
        [unarchiver finishDecoding];
        [unarchiver release];
    }
    
    [pool release];
}

// Load the MotionPhone app state from a file with the given path and
// name
- (bool) load: (NSString *) filePath
{
    bool bSuccess = false;
    
   

    
	NSData * data = [NSData dataWithContentsOfFile:filePath];
    if ( data )
    {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
        if ( unarchiver )
        {
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName: gNotificationPendingBegin object:nil];
                        
            SSLog( @"Loading document: %@\n", filePath );
                                
            [NSThread detachNewThreadSelector:@selector(doLoadAsync:) toTarget:self withObject:unarchiver];
            

        }
        
        
    }
        
    
    
    return bSuccess;    
}


//
// filename creation for saves
- (NSString *) constuctSaveString: (int) saveNum
{
    return [NSString stringWithFormat: @"%@%05d%@", savePrefix, saveNum, savePostfix];
}


//
- (NSArray *) collectOrderedSavePaths
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *saveDirectory = [paths objectAtIndex:0];    
        
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:saveDirectory error:nil];    
    NSArray *onlySaves = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.mpsave'"]];

    NSArray *sorted = [onlySaves sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    
    //NSLog(@"ordered saves:\n%@\n", [sorted description] );
    
    return sorted;
    
}

//
//
- (NSString *) savePathForIndex: (int) saveNum
{
    NSArray *saveNames = [self collectOrderedSavePaths];
    if ( saveNum >= 0 && saveNum < [saveNames count] )
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *saveDirectory = [paths objectAtIndex:0];    
        NSString *savePath = [saveDirectory stringByAppendingPathComponent: [saveNames objectAtIndex: saveNum]];        
        return savePath;                
    }
    
    return nil;
}


//
// the next available save name in ascending order
- (NSString *) generateNextSaveName
{
    NSArray *saveNames = [self collectOrderedSavePaths];

    if ( [saveNames count] > 0 )
    {

        NSString * highestSaveName = [saveNames objectAtIndex: [saveNames count] - 1];
        int num = 0;
        
        NSScanner * scan = [NSScanner scannerWithString: highestSaveName];
        [scan scanString: savePrefix intoString: nil];
        [scan scanInt: &num];
        
        num++;
        return [self constuctSaveString: num];
    
    }
    else
    {
        return [self constuctSaveString:0];
    }
}


@end
