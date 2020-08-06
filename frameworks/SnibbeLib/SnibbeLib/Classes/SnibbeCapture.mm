//
//  SnibbeCapture.mm
//  SnibbeLib
//
//  Created by Graham McDermott on 11/30/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "SnibbeCapture.h"
#import "AVFoundation/AVAssetWriter.h"
#import "AVFoundation/AVFoundation.h"
#import "OpenGlES/ES1/gl.h"

#define DEGREES_TO_RADIANS(degrees_) ((degrees_) * 0.01745329252f)

//
//
UIImage* ssScreenShotUIImage( CGRect region )
{ 
    return ssScreenShotUIImage( region, UIDeviceOrientationPortrait ); // default is portrait
}


//
// Taken from the internets and modded slightly
UIImage* ssScreenShotUIImage( CGRect region, UIDeviceOrientation deviceOrient )
{
    
    CGSize winSize		= region.size;
    
	//Create buffer for pixels
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
        
	switch ( deviceOrient )
	{
		
		case UIDeviceOrientationPortraitUpsideDown:
        {
			CGContextRotateCTM(context, DEGREES_TO_RADIANS(180));
			CGContextTranslateCTM(context, -region.size.width, -region.size.height);
			break;
        }
		case UIDeviceOrientationLandscapeLeft:
		{
            CGContextRotateCTM(context, DEGREES_TO_RADIANS(-90));
			CGContextTranslateCTM(context, -region.size.height, 0);
			break;
        }
		case UIDeviceOrientationLandscapeRight:
		{            
            CGContextRotateCTM(context, DEGREES_TO_RADIANS(90));
			CGContextTranslateCTM(context, region.size.width * 0.5f, -region.size.height);
			break;
        }
        case UIDeviceOrientationPortrait: 
        default:
        {
            break;
        }
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
static int videoTimeScale = 60;

//
// helper
CVPixelBufferRef pixelBufferFromCGImage( CGImageRef image,  CGSize size );

////
//// 
//bool recordMovieBegin( NSString * path, CGSize size, int audioSampleRate, int audioNumChannels, int audioPCMBitDepth )
//{
//    bool bSuccess = false;
//    
//    NSLog(@"Write Started at %@", path);
//    
//    // todo - check for version of iOS that works with this code...
//    
//    if ( videoWriter != nil )
//    {
//        NSLog( @"movie in progress, not started...\n" );
//        return false;
//    }
//    
//    NSError *error = nil;
//    
//    videoWriter = [[AVAssetWriter alloc] initWithURL:
//                   [NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie
//                                               error:&error];    
//    
//    
//    if ( videoWriter )
//    {
//        
//        NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                       AVVideoCodecH264, AVVideoCodecKey,
//                                       [NSNumber numberWithInt:size.width], AVVideoWidthKey,
//                                       [NSNumber numberWithInt:size.height], AVVideoHeightKey,
//                                       nil];
//        
//        videoWriterInput = [[AVAssetWriterInput
//                             assetWriterInputWithMediaType:AVMediaTypeVideo
//                             outputSettings:videoSettings] retain];
//        
//        if ( !videoWriterInput )
//        {
//            [videoWriter release];
//            videoWriter = nil;
//        }
//        else
//        {            
//            
//            AudioChannelLayout channelLayout;
//            memset(&channelLayout, 0, sizeof(AudioChannelLayout));
//            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;            
//            NSData *channelLayoutData = [NSData dataWithBytes: &channelLayout length: sizeof( AudioChannelLayout )];            
//            
//            NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                           [NSNumber numberWithInt: kAudioFormatLinearPCM], AVFormatIDKey,
//                                           [NSNumber numberWithInt: audioSampleRate], AVSampleRateKey,
//                                           [NSNumber numberWithInt: audioNumChannels], AVNumberOfChannelsKey,
//                                           channelLayoutData, AVChannelLayoutKey,
//                                           [NSNumber numberWithInt:audioPCMBitDepth], AVLinearPCMBitDepthKey,
//                                           [NSNumber numberWithBool:false], AVLinearPCMIsBigEndianKey,
//                                           [NSNumber numberWithBool:true], AVLinearPCMIsFloatKey,
//                                           [NSNumber numberWithBool:true], AVLinearPCMIsNonInterleaved,
//                                           nil];
//            
//            audioWriterInput = [[AVAssetWriterInput
//                                 assetWriterInputWithMediaType:AVMediaTypeAudio
//                                 outputSettings:audioSettings] retain];
//            
//            
//            if ( !audioWriterInput )
//            {
//                [videoWriterInput release];
//                videoWriterInput = nil;
//                
//                [videoWriter release];
//                videoWriter = nil;
//            }
//            else
//            {
//                
//                adaptor = [[AVAssetWriterInputPixelBufferAdaptor
//                            assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
//                            sourcePixelBufferAttributes:nil] retain];
//                
//                
//                if ( adaptor )
//                {
//                    
//                    assert([videoWriter canAddInput:videoWriterInput]);
//                    
//                    //videoWriterInput.expectsMediaDataInRealTime = YES;
//                    [videoWriter addInput:videoWriterInput];
//                    
//                    //audioWriterInput.expectsMediaDataInRealTime = YES;
//                    [videoWriter addInput:audioWriterInput];
//                    
//                    [videoWriter startWriting];
//                    [videoWriter startSessionAtSourceTime:kCMTimeZero];
//                    
//                    videoSize = size;
//                    bSuccess = true;
//                }
//                else
//                {
//                    [videoWriterInput release];
//                    videoWriterInput = nil;
//                    
//                    [audioWriterInput release];
//                    audioWriterInput = nil;
//                    
//                    [videoWriter release];
//                    videoWriter = nil;
//                    
//                    
//                }
//            }
//        }
//        
//        
//    }
//    
//    return bSuccess;
//}
//


//
// begin a silent movie
bool ssRecordMovieBegin( NSString * path, CGSize size, int timeScale )
{
    bool bSuccess = false;
    
    NSLog(@"Write Started at %@, video size: %@", path, NSStringFromCGSize(size));
    
    // todo - check for version of iOS that works with this code...
    
    if ( videoWriter != nil )
    {
        NSLog( @"movie in progress, not started...\n" );
        return false;
    }
    
    NSError *error = nil;    
    videoTimeScale = timeScale;
    
    videoWriter = [[AVAssetWriter alloc] initWithURL:
                   [NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie
                                               error:&error];    
    
    
    if ( videoWriter )
    {
        

        
//        NSDictionary *codecSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                       [NSNumber numberWithInt:960000], AVVideoAverageBitRateKey,
//                                       [NSNumber numberWithInt:1],AVVideoMaxKeyFrameIntervalKey,
//                                       nil];
        
        NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                       AVVideoCodecH264, AVVideoCodecKey,
                                       [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                       [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                       /*codecSettings,AVVideoCompressionPropertiesKey,*/
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
            
                            
            adaptor = [[AVAssetWriterInputPixelBufferAdaptor
                        assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                        sourcePixelBufferAttributes:nil] retain];
            
            
            if ( adaptor )
            {
                
                assert([videoWriter canAddInput:videoWriterInput]);
                
                videoWriterInput.expectsMediaDataInRealTime = YES;
                [videoWriter addInput:videoWriterInput];
                                                     
                [videoWriter startWriting];
                [videoWriter startSessionAtSourceTime:kCMTimeZero];
                
                videoSize = size;
                bSuccess = true;
            }
            else
            {
                [videoWriterInput release];
                videoWriterInput = nil;            
                
                [videoWriter release];
                videoWriter = nil;
                
                
            }

        }
        
        
    }
    
    return bSuccess;
}



// ensure that atTime is a multiple of 1.0f/timeScale (and that each subsequent
// call to this function has a unique atTimeValue. If they aren't in this relationship
// the code could quantize two frames to the same time which causes movie
// creation to fail.
//
// timeScale is the quantization value per second, so a value of 60 would
// ensure that frames are added and quantized to 1/60 of a second.




bool ssRecordMovieAddFrame( UIImage * image, int frameIndex )
{
    bool bSuccess = false;
    
    if ( videoWriter && videoWriterInput && adaptor && image )
    {
        
        CVPixelBufferRef buffer = NULL;
        
        //convert uiimage to CVPixelBufferRef.        
        buffer = pixelBufferFromCGImage( [image CGImage], videoSize );        
        
        if (adaptor.assetWriterInput.readyForMoreMediaData) 
        {                        

            CMTime frameTime = CMTimeMake( frameIndex, videoTimeScale );            
            bSuccess = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
            
            //NSLog ( @"appending frame at time %f (orig: %f)\n", CMTimeGetSeconds( frameTime ), atTime );
            
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
////
////
//bool recordMovieAddAudio()
//{
//    
//    // todo
//    CMSampleBufferRef sampleBuffer;
//    
//    // translate the audio blob into a sample buffer ref
//    
//    
//    
//    if ( videoWriter && audioWriterInput )
//    {
//        
//        if( videoWriter.status != AVAssetWriterStatusWriting )
//        {
//            NSLog(@"Warning: writer status is %d", videoWriter.status);
//            return false;
//        }
//        
//        if( ![audioWriterInput appendSampleBuffer:sampleBuffer] )
//        {
//            NSLog(@"Unable to write to audio input");
//            return false;
//        }
//        
//        return true;
//        
//    }
//    
//    return false;
//    
//}
//
////
////
//void recordMovieAddFrame()
//{
//    
//    if ( videoWriter && videoWriterInput && adaptor )
//    {
//        
//        // Or you can use AVAssetWriterInputPixelBufferAdaptor.
//        // That lets you feed the writer input data from a CVPixelBuffer
//        // that’s quite easy to create from a CGImage.
//        
//        
//        /*
//         
//         AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
//         assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
//         sourcePixelBufferAttributes:nil];
//         
//         assert(videoWriterInput);
//         assert([videoWriter canAddInput:videoWriterInput]);
//         
//         videoWriterInput.expectsMediaDataInRealTime = YES;
//         [videoWriter addInput:videoWriterInput];
//         
//         //Start a session:
//         //[videoWriter startWriting];
//         //[videoWriter startSessionAtSourceTime:kCMTimeZero];
//         
//         CVPixelBufferRef buffer = NULL;
//         
//         //convert uiimage to CGImage.
//         
//         int frameCount = 0;
//         
//         for(UIImage * img in imageArray)
//         {
//         buffer = [self pixelBufferFromCGImage:[img CGImage] andSize:size];
//         
//         BOOL append_ok = NO;
//         int j = 0;
//         while (!append_ok && j < 30) 
//         {
//         if (adaptor.assetWriterInput.readyForMoreMediaData) 
//         {
//         printf("appending %d attemp %d\n", frameCount, j);
//         
//         CMTime frameTime = CMTimeMake(frameCount,(int32_t) kRecordingFPS);
//         append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
//         
//         if(buffer)
//         CVBufferRelease(buffer);
//         [NSThread sleepForTimeInterval:0.05];
//         } 
//         else 
//         {
//         printf("adaptor not ready %d, %d\n", frameCount, j);
//         [NSThread sleepForTimeInterval:0.1];
//         }
//         j++;
//         }
//         if (!append_ok) {
//         printf("error appending image %d times %d\n", frameCount, j);
//         }
//         frameCount++;
//         }
//         }
//         
//         */
//        
//    }
//    
//}
//
//

//
//
bool ssRecordMovieReadyForData()
{

    if ( videoWriter && videoWriterInput && adaptor )
    {
        return adaptor.assetWriterInput.readyForMoreMediaData;
    }
    
    return false;
    
}


//
//
void ssRecordMovieEnd()
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
        
        if ( audioWriterInput )
        {
            [audioWriterInput release];
            audioWriterInput = nil;
        }
        
        [videoWriter release];
        videoWriter = nil;
        
        NSLog(@"Write Ended");
        
    }
}



//
// helper
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


