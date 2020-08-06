//
//  ScoopUtils.mm
//  Scoop
//
//  Created by Graham McDermott on 4/6/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#include "ScoopUtils.h"
#include "ScoopDefs.h"
#import "AVFoundation/AVAssetWriter.h"
#import "AVFoundation/AVFoundation.h"
#import "OpenGlES/ES1/gl.h"
#import "CCDirectorIOS.h"
#import "ccMacros.h"

bool gbIsIPad = false; 
bool retinaEnabled = false;
bool gbIsPaused = false; // so top level aspects of the code can access the paused state as needed
//
//
void testForIPad()
{
    gbIsIPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

//
//
void setRetinaEnabled( bool bRetina )
{
    retinaEnabled = bRetina;
}

//
//
int numCrowns()
{
    return ( gbIsIPad ? 3 : 2 );
}

//
//
int maxSaves()
{
    return ( gbIsIPad ? MAX_SAVED_SCOOPS_IPAD : MAX_SAVED_SCOOPS_IPHONE );    
}

//
//
int maxVisibleBeats()
{
    return ( gbIsIPad ? MAX_BEATS_PER_SET_IPAD : MAX_BEATS_PER_SET_IPHONE );
}

//
// just reflects the scoop paused state
void setIsPaused( bool bPaused )
{
    gbIsPaused = bPaused;
}

//
//
bool getIsPaused()
{
    return gbIsPaused;
}



//
//
bool shouldHandleDeviceOrientation( UIDeviceOrientation orientation )
{

    bool bOrientationWeCareAbout = true;

    if ( orientation == UIDeviceOrientationFaceDown ||
         orientation == UIDeviceOrientationFaceUp || 
         orientation == UIDeviceOrientationUnknown )
    {
        // we don't care about these
        bOrientationWeCareAbout = false;
    }
    
    return bOrientationWeCareAbout;
}


//
// platform-specific name for resource
NSString * getPlatformResourceName( NSString * extensionlessBaseFilename, NSString * extension )
{
    
    // temp!
    //NSString *noExt = nil; // since I can't seem to find a function to strip extensions from a string
    
    if ( gbIsIPad )
    {        
        return [NSString stringWithFormat: @"%@.%@", extensionlessBaseFilename, extension ];                
    }    
    else
    {
        NSString *val = nil;

        
        if ( retinaEnabled )
        {
            val = [NSString stringWithFormat: @"%@-ret.%@", extensionlessBaseFilename, extension ];                        
            //noExt = [NSString stringWithFormat: @"%@-ret", extensionlessBaseFilename ];                        
        }
        else
        {
            val = [NSString stringWithFormat: @"%@-nonret.%@", extensionlessBaseFilename, extension ];            
            //noExt = [NSString stringWithFormat: @"%@-nonret", extensionlessBaseFilename ];  
        }
        
        return val;
        
           /*             
        // temp for debugging (hurts performance)
        if ( [[NSBundle mainBundle] pathForResource: noExt ofType:extension] )
        {            
            return val;
        }
        else
        {
            // just use the ipad version since we have it
            return [NSString stringWithFormat: @"%@.%@", extensionlessBaseFilename, extension ];    
        }    
            */
        
    }
    
}

//
//
float easeInOutMinMax( float min, float max, float input )  
{  
    float interp = (input - min) / (max - min);  
    
    interp = MAX( interp, 0.0f );
    interp = MIN( interp, 1.0f );
    
    float smoothed = interp * interp * (3.0f - 2.0f * interp);  
    
    smoothed = MAX( smoothed, 0.0f );
    smoothed = MIN( smoothed, 1.0f );
    
    return smoothed;
}   

//
//
float easeInOutRange( float min, float range, float input )
{
    return easeInOutMinMax(min, min+range, input);
}

//
//
float easeInOutMinMaxd( double min, double max, double input )  
{  
    float interp = (input - min) / (max - min);  
    
    interp = MAX( interp, 0.0f );
    interp = MIN( interp, 1.0f );
    
    float smoothed = interp * interp * (3.0f - 2.0f * interp);  
    
    smoothed = MAX( smoothed, 0.0f );
    smoothed = MIN( smoothed, 1.0f );
    
    return smoothed;
}   

//
//
float easeInOutRanged( double min, double range, double input )
{
    return easeInOutMinMaxd(min, min+range, input);
}




//
// Taken from the internets and modded slightly
UIImage* screenShotUIImage( CGRect region )
{
    
    CGSize winSize		= region.size;
    
	//Create buffer for pixels
	//GLuint bufferLength = displaySize.width * displaySize.height * 4;
    GLuint bufferLength = region.size.width * region.size.height * 4;
    
	GLubyte* buffer = (GLubyte*)malloc(bufferLength);
    
	//Read Pixels from OpenGL
	glReadPixels(region.origin.x, region.origin.y, region.size.width, region.size.height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
	//Make data provider with data.
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
    
	//Configure image
	int bitsPerComponent = 8;
	int bitsPerPixel = 32;
	int bytesPerRow = 4 * region.size.width;
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	CGImageRef iref = CGImageCreate(region.size.width, region.size.height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
	uint32_t* pixels = (uint32_t*)malloc(bufferLength);
	CGContextRef context = CGBitmapContextCreate(pixels, winSize.width, winSize.height, 8, winSize.width * 4, CGImageGetColorSpace(iref), kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
	CGContextTranslateCTM(context, 0, region.size.height);
	CGContextScaleCTM(context, 1.0f, -1.0f);
    
    ccDeviceOrientation orientation = [[CCDirector sharedDirector] deviceOrientation];
	switch ( orientation )
	{
		case CCDeviceOrientationPortrait: break;
		case CCDeviceOrientationPortraitUpsideDown:
			CGContextRotateCTM(context, CC_DEGREES_TO_RADIANS(180));
			CGContextTranslateCTM(context, -region.size.width, -region.size.height);
			break;
		case CCDeviceOrientationLandscapeLeft:
			CGContextRotateCTM(context, CC_DEGREES_TO_RADIANS(-90));
			CGContextTranslateCTM(context, -region.size.height, 0);
			break;
		case CCDeviceOrientationLandscapeRight:
			CGContextRotateCTM(context, CC_DEGREES_TO_RADIANS(90));
			CGContextTranslateCTM(context, region.size.width * 0.5f, -region.size.height);
			break;
	}
    
	CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, region.size.width, region.size.height), iref);
	CGImageRef imageRef = CGBitmapContextCreateImage(context);
	UIImage *outputImage = [UIImage imageWithCGImage:imageRef];
    
	//Dealloc
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGImageRelease(iref);
	CGColorSpaceRelease(colorSpaceRef);
	CGContextRelease(context);
	free(buffer);
	free(pixels);
    
	return outputImage;
}



////////////////////////////////////////////////////////////////////
// movie recording
////////////////////////////////////////////////////////////////////
static AVAssetWriter *videoWriter = nil;
static AVAssetWriterInput* videoWriterInput = nil;
static AVAssetWriterInput* audioWriterInput = nil;
static AVAssetWriterInputPixelBufferAdaptor *adaptor = nil;
static CGSize videoSize;


// helper
CVPixelBufferRef pixelBufferFromCGImage( CGImageRef image,  CGSize size );



//
// 
bool recordMovieBegin( NSString * path, CGSize size, int audioSampleRate, int audioNumChannels, int audioPCMBitDepth )
{
    bool bSuccess = false;
    
    NSLog(@"Write Started at %@", path);
   
    // todo - check for version of iOS that works with this code...
    
    if ( videoWriter != nil )
    {
        NSLog( @"movie in progress, not started...\n" );
        return false;
    }
    
    NSError *error = nil;
    
    videoWriter = [[AVAssetWriter alloc] initWithURL:
                   [NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie
                   error:&error];    


    if ( videoWriter )
    {
    
        NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                       AVVideoCodecH264, AVVideoCodecKey,
                                       [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                       [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                       nil];
        
        videoWriterInput = [[AVAssetWriterInput
                             assetWriterInputWithMediaType:AVMediaTypeVideo
                             outputSettings:videoSettings] retain];
        
        if ( !videoWriterInput )
        {
            [videoWriter release];
            videoWriter = nil;
        }
        else
        {            

            AudioChannelLayout channelLayout;
            memset(&channelLayout, 0, sizeof(AudioChannelLayout));
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;            
            NSData *channelLayoutData = [NSData dataWithBytes: &channelLayout length: sizeof( AudioChannelLayout )];            
            
            NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithInt: kAudioFormatLinearPCM], AVFormatIDKey,
                                           [NSNumber numberWithInt: audioSampleRate], AVSampleRateKey,
                                           [NSNumber numberWithInt: audioNumChannels], AVNumberOfChannelsKey,
                                           channelLayoutData, AVChannelLayoutKey,
                                           [NSNumber numberWithInt:audioPCMBitDepth], AVLinearPCMBitDepthKey,
                                           [NSNumber numberWithBool:false], AVLinearPCMIsBigEndianKey,
                                           [NSNumber numberWithBool:true], AVLinearPCMIsFloatKey,
                                           [NSNumber numberWithBool:true], AVLinearPCMIsNonInterleaved,
                                           nil];
            
            audioWriterInput = [[AVAssetWriterInput
                                 assetWriterInputWithMediaType:AVMediaTypeAudio
                                 outputSettings:audioSettings] retain];
            
            
            if ( !audioWriterInput )
            {
                [videoWriterInput release];
                videoWriterInput = nil;
                
                [videoWriter release];
                videoWriter = nil;
            }
            else
            {
            
                adaptor = [[AVAssetWriterInputPixelBufferAdaptor
                           assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                           sourcePixelBufferAttributes:nil] retain];
                
                
                if ( adaptor )
                {
                    
                    assert([videoWriter canAddInput:videoWriterInput]);
                    
                    //videoWriterInput.expectsMediaDataInRealTime = YES;
                    [videoWriter addInput:videoWriterInput];
                    
                    //audioWriterInput.expectsMediaDataInRealTime = YES;
                    [videoWriter addInput:audioWriterInput];
                    
                    [videoWriter startWriting];
                    [videoWriter startSessionAtSourceTime:kCMTimeZero];
                    
                    videoSize = size;
                    bSuccess = true;
                }
                else
                {
                    [videoWriterInput release];
                    videoWriterInput = nil;
                    
                    [audioWriterInput release];
                    audioWriterInput = nil;
                    
                    [videoWriter release];
                    videoWriter = nil;
                    
                    
                }
            }
        }
        
        
    }
   
    return bSuccess;
}

//
//
bool recordMovieAddFrame( UIImage * image, float atTime )
{
    bool bSuccess = false;
    
    if ( videoWriter && videoWriterInput && adaptor && image )
    {
        
        CVPixelBufferRef buffer = NULL;
        
        //convert uiimage to CGImage.        
        buffer = pixelBufferFromCGImage( [image CGImage], videoSize );        
        
        if (adaptor.assetWriterInput.readyForMoreMediaData) 
        {
            //printf("appending %d attemp %d\n", frameCount, j);
            
            CMTime frameTime = CMTimeMakeWithSeconds( atTime, (int32_t) 1);            
            bSuccess = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
            
            if(buffer)
            {
                CVBufferRelease(buffer);
            }
                        
        } 
        else 
        {
            printf("adaptor not ready\n" );           
            bSuccess = false;
        }

     
        
    }
    
    return bSuccess;

    
}

//
//
bool recordMovieAddAudio()
{

    // todo
    CMSampleBufferRef sampleBuffer;
    
    // translate the audio blob into a sample buffer ref
    
    
    
    if ( videoWriter && audioWriterInput )
    {
        
        if( videoWriter.status != AVAssetWriterStatusWriting )
        {
            NSLog(@"Warning: writer status is %d", videoWriter.status);
            return false;
        }
        
        if( ![audioWriterInput appendSampleBuffer:sampleBuffer] )
        {
            NSLog(@"Unable to write to audio input");
            return false;
        }
    
        return true;
            
    }
    
    return false;
        
}

//
//
void recordMovieAddFrame()
{
    
    if ( videoWriter && videoWriterInput && adaptor )
    {
        
        // Or you can use AVAssetWriterInputPixelBufferAdaptor.
        // That lets you feed the writer input data from a CVPixelBuffer
        // that’s quite easy to create from a CGImage.
     
        
        /*
         
         AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
         assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
         sourcePixelBufferAttributes:nil];
         
         assert(videoWriterInput);
         assert([videoWriter canAddInput:videoWriterInput]);
         
         videoWriterInput.expectsMediaDataInRealTime = YES;
         [videoWriter addInput:videoWriterInput];
         
         //Start a session:
         //[videoWriter startWriting];
         //[videoWriter startSessionAtSourceTime:kCMTimeZero];
         
         CVPixelBufferRef buffer = NULL;
         
         //convert uiimage to CGImage.
         
         int frameCount = 0;
         
         for(UIImage * img in imageArray)
         {
         buffer = [self pixelBufferFromCGImage:[img CGImage] andSize:size];
         
         BOOL append_ok = NO;
         int j = 0;
         while (!append_ok && j < 30) 
         {
         if (adaptor.assetWriterInput.readyForMoreMediaData) 
         {
         printf("appending %d attemp %d\n", frameCount, j);
         
         CMTime frameTime = CMTimeMake(frameCount,(int32_t) kRecordingFPS);
         append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
         
         if(buffer)
         CVBufferRelease(buffer);
         [NSThread sleepForTimeInterval:0.05];
         } 
         else 
         {
         printf("adaptor not ready %d, %d\n", frameCount, j);
         [NSThread sleepForTimeInterval:0.1];
         }
         j++;
         }
         if (!append_ok) {
         printf("error appending image %d times %d\n", frameCount, j);
         }
         frameCount++;
         }
         }
         
         */
            
    }

}


//
//
void recordMovieEnd()
{

    if ( videoWriter && videoWriterInput )
    {
        [videoWriterInput markAsFinished];  
//        [videoWriter endSessionAtSourceTime:___];  need this?
        [videoWriter finishWriting];

        [adaptor release];
        adaptor = nil;
        
        [videoWriterInput release];
        videoWriterInput = nil;
        
        [audioWriterInput release];
        audioWriterInput = nil;
        
        [videoWriter release];
        videoWriter = nil;
        
        NSLog(@"Write Ended");
        
    }
}


//
//
CVPixelBufferRef pixelBufferFromCGImage( CGImageRef image,  CGSize size )
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (CFDictionaryRef) options, 
                                          &pxbuffer);
    assert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    assert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace, 
                                                 kCGImageAlphaNoneSkipFirst);
    assert(context);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), 
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}
