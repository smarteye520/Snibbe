// Gravilux.mm (c) 1998-2010 Scott Snibbe

#include "Gravilux.h"
#include "Grain.h"
#include "Parameters.h"
#include "ForceState.h"
#include "Visualizer.h"
#include <set>

//#import "TVOutManager.h"

//#import "mtiks.h"

//--------------------------------------------------------------

#define RESET_IDLE_TIMER(SET) if (params_->galleryMode()) [interfaceViewController_ resetIdleTimer:(SET)]
#define DRAW_IN_CONTEXT false
#define SEED_IMAGE @"text-guide.png"

#define MAXGRAINS 

Gravilux::Gravilux() {
	params_ = new Parameters(this);
	
	grains_ = NULL;
	nGrains_ = nAllocGrains_ = 0;
	running_ = true; //negate_ = false; heat_ = false;
	firstTap_ = false;
	sizeScale_ = (float) ((UIScreen *)[[UIScreen screens] objectAtIndex:0]).bounds.size.height / 320.0;	// designed for 320 screen, so scale to simulate
	sizeScale_ *= sizeScale_*2;
	//gravityScale_ = 1.0;
	//heatScale_ = DEFHEATSCALE;
	//heat_ = false;
	maxVelocity_ = 1.f; 
	
	//initTextures();
	
	drawVertexArray_ = true;
	vertexArrayObject.setSafeMode(false);
	vertexArrayObject.enableNormal(false);
	vertexArrayObject.enableTexCoord(false);
	vertexArrayObject.enableColor(true);
	
	vertexArrayObject.reserve(MAX_ROWS*MAX_ROWS);
	
	initGrains();
	
	// activeTouches = [NSSet set];
	forceState_ = new ForceState();
	visualizer_ = new Visualizer();
	forceState_->insertSubstate(visualizer_->forceState());
	
	params_->load(); // load parameters from "disk", should only be done after the above initialization
	
	setStarSize(params_->deviceStarSize());
	
	interactedYet_ = false;
}


//--------------------------------------------------------------
void Gravilux::update(){
	dt_ = 1./60.;
	if (running_) simulate(dt_);
}

//--------------------------------------------------------------
void Gravilux::draw(){
	drawGrains();
	
#ifdef DEBUG
	drawForceState();
#endif
	
#if 0
	ofPushStyle();
	ofSetColor(255,0,0);
		
	font_.drawString("acc: ("
					 +ofToString(ofxAccelerometer.getForce().x, 2)+", "
					 +ofToString(ofxAccelerometer.getForce().y, 2)+", "
					 +ofToString(ofxAccelerometer.getForce().z, 2)+")", 10, 100);
	
	ofPopStyle();
#endif
}

void Gravilux::exit() {
	delete visualizer_;
	delete forceState_;
	delete params_;
	//[[TVOutManager sharedInstance] stopTVOut];
	
	//[[mtiks sharedSession] stop];
	//delete params_;
	//[interfaceViewController_ release];
}

//--------------------------------------------------------------
/*
void Gravilux::touches(NSSet * touches)
{
	activeTouches = touches;
}
*/
/*
 void Gravilux::touchesBegan(NSSet *touches)
{
	if (!running_) running_ = true;
	
	touchesMoved(touches);
}

void Gravilux::touchesMoved(NSSet *touches)
{
	if([touches count] < MAXTOUCHES) {
		if (isTouching) {
			[activeTouches release];
		}
		isTouching = true;
		activeTouches = [touches retain];
	}
}

void Gravilux::touchesEnded(NSSet *touches)
{
	if (isTouching) {
		[activeTouches release];
	}
	isTouching = false;
}*/

/*void Gravilux::touchDown(ofTouchEventArgs &touch) {
	//printf("touchDown: %i, %i %i\n", x, y, touchId);
	//things[touchId].moveTo(x, y);
	//ofPoint mPos;
	
	// turn off info display if on
	interactedYet_ = true;
	
	if (!running_) running_ = true;
	
	if (!interfaceViewController_.view.hidden && !interfaceViewController_.appearing
		&& ![interfaceViewController_ isInToolbar:CGPointMake(touch.x, touch.y)]) {
		[interfaceViewController_ dismissToolbar:NO];	// dismiss toolbar if visible
	} else if (touch.id == 0
			   && [interfaceViewController_ isOnSides:CGPointMake(touch.x, touch.y)]) {
		bottomTap_ = true;
	}
	
	if (!bottomTap_) { 
		if (touch.id < MAXTOUCHES) {
			// register touches
			touchDown_[touch.id] = YES;
			touchPoints_[touch.id].x = touch.x;
			touchPoints_[touch.id].y = touch.y;
		}
	}
	
	RESET_IDLE_TIMER(YES);
}


void Gravilux::touchMoved(ofTouchEventArgs &touch) {
	//printf("touchMoved: %i, %i %i\n", x, y, touchId);
	//things[touchId].moveTo(x, y);
	
	if (touch.id == 0) bottomTap_ = false;
	
	if (touch.id < MAXTOUCHES) {
		touchDown_[touch.id] = YES;
		touchPoints_[touch.id].x = touch.x;
		touchPoints_[touch.id].y = touch.y;
	}
	
	//applyPointForce(ofPoint(touch.x,touch.y), touch.id != 0);
}


void Gravilux::touchUp(ofTouchEventArgs &touch) {
	//printf("touchUp: %i, %i %i\n", x, y, touchId);
	//clearPointForces();
	
	if (bottomTap_ && touch.id == 0 
		&& interfaceViewController_.view.hidden
		&& [interfaceViewController_ isOnSides:CGPointMake(touch.x, touch.y)]) {

			firstTap_ = true;

	}
	
	if (touch.id == 0) bottomTap_ = false;
	
	if (touch.id < MAXTOUCHES) {
		touchDown_[touch.id] = NO;
		touchPoints_[touch.id].x = touch.x;
		touchPoints_[touch.id].y = touch.y;
	}	
	
	RESET_IDLE_TIMER(YES);
}


void Gravilux::touchDoubleTap(ofTouchEventArgs &touch) {
	//printf("touchDoubleTap: %i, %i %i\n", x, y, touchId);
	//ofToggleFullscreen();	
	interactedYet_ = true;
	
	if (touch.id == 0 
		&& interfaceViewController_.view.hidden
		&& [interfaceViewController_ isOnSides:CGPointMake(touch.x, touch.y)]) {
		
		[interfaceViewController_ showView];
		//NSLog(@"touchDoubleTap:showView");
		//firstTap_ = false;
	}
	

 //	if ([interfaceViewController_ isInCorner:CGPointMake(touch.x, touch.y)])
 //		[interfaceViewController_ showView];
 
}
*/

//--------------------------------------------------------------
void Gravilux::gotMemoryWarning(){
	
}

//--------------------------------------------------------------
void Gravilux::deviceOrientationChanged(int newOrientation){
	//printf("orientation changed to %d, ", newOrientation);
	
	//UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	//printf("device orientation = %d\n", orientation);
	
	/*
	UIInterfaceOrientation iOrientation;
	switch (orientation) {
		case UIDeviceOrientationPortrait:
			iOrientation = UIInterfaceOrientationPortrait;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			iOrientation = UIInterfaceOrientationPortraitUpsideDown;
			break;
		case UIDeviceOrientationLandscapeLeft:
			iOrientation = UIInterfaceOrientationLandscapeLeft;
			break;
		case UIDeviceOrientationLandscapeRight:
			iOrientation = UIInterfaceOrientationLandscapeRight;
			break;
	}
	*/
	
	//[[UIDevice currentDevice] setOrientation:iOrientation];
		
	//iPhoneSetOrientation(orientation);
	//[settingsViewController shouldAutorotateToInterfaceOrientation:iOrientation];
	//[settingsViewController.view layoutSubviews];
}

void
Gravilux::initGrains()
{
	allocGrains();
	resetGrains();

/*
 // - seed with image
 	UIImage *image = [UIImage imageNamed:SEED_IMAGE];
	resetGrainsRandomImage(image);
	resetGrainsMatrixImage(image, 10);
 */
}

/*
void
Gravilux::initTextures()
{
	
	// $$$ note that PNGs are compressed on iPhone, so the images for textures must
	// be included in xcode as "folder references":
	// http://wiki.openframeworks.cc/index.php?title=OfxiPhone_comprehensive_guide#the_png_problem
	
	char imagePath[48];
	for (int i=1; i<= 5; i++) {
		ofImage *image = new ofImage;
		sprintf(imagePath, "images/star%d.png", i);
		image->loadImage(imagePath);
		image->setAnchorPoint((image->width-1) * 0.5, (image->height-1) * 0.5);
		
		gTextures.push_back(image);
	}
}
*/

void
Gravilux::resetGrains()
{
	int g;
	CGPoint p, v, inset;
	
	v.x = v.y = 0;
	
	int rows = params_->rows();
	int cols = params_->cols();
	
	nGrains_ = rows*cols;
	CGSize screenSize = ((UIScreen*)[[UIScreen screens] objectAtIndex:0]).bounds.size;
	inset.x = (screenSize.width - ROUNDINT((((float)cols-1.0)/(float)cols * screenSize.width))) / 2;
	inset.y = (screenSize.height - ROUNDINT((((float)rows-1.0)/(float)rows * screenSize.height))) / 2;
	
	for (int r = 0; r < rows; r++) {
		p.y = inset.y + (float)r/rows * screenSize.height;
		for (int c = 0; c < cols; c++) {
			p.x = inset.x + (float)c/cols * screenSize.width;
			
			// round positions to avoid jitter
			//p.x = ROUNDINT(p.x);
			//p.y = ROUNDINT(p.y);
			
			g = r*cols + c;
			grains_[g]->pos(p);
			grains_[g]->vel(v);
			grains_[g]->showHeat(params_->heat());
			grains_[g]->size(params_->starSize());			
		}
	}
}

void
Gravilux::resetGrainsType(NSString * text, UIInterfaceOrientation orientation, int rowSkip) {
	UIImage *image = renderType(text, orientation);
	resetGrainsMatrixImage(image, rowSkip);
}

UIImage *
Gravilux::renderType(NSString * text, UIInterfaceOrientation orientation)
{
	assert([text length] <= MAX_TYPE_LENGTH);
	// set up a GCContext buffer for drawing the text
	CGSize screenSize = ((UIScreen*)[[UIScreen screens] objectAtIndex:0]).bounds.size;
	NSUInteger width = screenSize.width;
	NSUInteger height = screenSize.height;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSUInteger bytesPerPixel = 4;
	NSUInteger bytesPerRow = bytesPerPixel * width;
	NSUInteger bitsPerComponent = 8;
	CGContextRef context = CGBitmapContextCreate(NULL,
												 width,
												 height,
												 bitsPerComponent,
												 bytesPerRow,
												 colorSpace,
												 kCGImageAlphaPremultipliedLast
												 | kCGBitmapByteOrder32Big);
	
	// Push UI context
	UIGraphicsPushContext(context);
	// Push graphics state as we will modify the CTM
	CGContextSaveGState(context);
	
	// Calculate drawing region based on orientation.
	CGSize drawingSize; // To be defined based on orientation
	double rotation;
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		 /* Assume left orientation (supported by usage stats:
		  http://www.greengar.com/2010/04/usc-landscape/ ) unless right is detected */
		// Reverse the about statement as UIDeviceOrientationRight == UIInterfaceOrientationLeft
		if(orientation == UIInterfaceOrientationLandscapeLeft)
			rotation = M_PI_2;
		else
			rotation = -M_PI_2;
		
		/* OF will give us the portrait dimentions regardless of our orientation,
		   so we must flip the components if in landscape */
		drawingSize = CGSizeMake(screenSize.height, screenSize.width);
		
		CGContextTranslateCTM(context,
							  +(screenSize.width/2),
							  +(screenSize.height/2));
		CGContextRotateCTM(context, rotation);
		CGContextTranslateCTM(context,
							  -(screenSize.height/2),
							  (screenSize.width/2));
		// UIKit/QuickDraw coordinate system
		CGContextScaleCTM(context, 1.f, -1.f);
	}
	// draw in portrait if detected orientation is portrait, flat or unknown
	else {
		rotation = 0.f;
		// set the screen size rect to the real screen
		drawingSize = screenSize;
		
		// convert to UIKit/QuickDraw coordinate system with a special case for upsidedown
		if(orientation == UIInterfaceOrientationPortraitUpsideDown) {
			CGContextTranslateCTM(context, screenSize.width, 0.f);
			CGContextScaleCTM(context, -1.f, 1.f);
		}
		else {
			CGContextTranslateCTM(context, 0.f, screenSize.height);
			CGContextScaleCTM(context, 1.f, -1.f);
		}
	}
	
	// Initalize font with max size
	int fontSize = 1000;
	UIFont * font = [UIFont fontWithName: @"HelveticaNeue-Bold" size: fontSize];
	CGSize fontSizeConstraint = CGSizeMake(drawingSize.width, MAXFLOAT);
	// Find largest usable font

	// Check word by word that nothing will character break
	// If we find an instance of improper formatting decrease by 10% and test again
	NSArray *words = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	for (NSString * word in words) {
		// Calculate size to render just the current word
		CGSize wordSizeAtCurrentFont = [word sizeWithFont: font
										constrainedToSize: fontSizeConstraint
											lineBreakMode: UILineBreakModeWordWrap];
		while (wordSizeAtCurrentFont.height > font.lineHeight) { // TODO: test 3.0!!!!
			fontSize *= .9;
			font = [font fontWithSize:fontSize];
			wordSizeAtCurrentFont = [word sizeWithFont: font
									 constrainedToSize: fontSizeConstraint
										 lineBreakMode: UILineBreakModeWordWrap];
		}
	}

	// Check that nothing goes off the botttom of screen, and if so decrease by 10%
	CGSize textSizeAtCurrentFont = [text sizeWithFont:font
									constrainedToSize:fontSizeConstraint
										lineBreakMode:UILineBreakModeWordWrap];
	while (textSizeAtCurrentFont.height > drawingSize.height) {
		fontSize *= .9;
		font = [font fontWithSize:fontSize];
		textSizeAtCurrentFont = [text sizeWithFont:font
								 constrainedToSize:fontSizeConstraint
									 lineBreakMode:UILineBreakModeWordWrap];
	}
	
	CGSize textSize = [text sizeWithFont: font
					   constrainedToSize: drawingSize
						   lineBreakMode: UILineBreakModeWordWrap];
	[[UIColor whiteColor] set]; // This could be any color as the image reader checks for non-black
	
	// Pad to center the image, as UIKit only gives us the tight bounds of the type
	CGRect drawingArea = CGRectMake((drawingSize.width-textSize.width)/2.,
									(drawingSize.height-textSize.height)/2.,
									textSize.width,
									textSize.height);
	
	// Draw text into buffer
	[text drawInRect: drawingArea
			withFont: font
	   lineBreakMode: UILineBreakModeWordWrap
		   alignment: UITextAlignmentCenter];
	
	// Render bitmap and pack into a UIImage
	CGImageRef cgBitmap = CGBitmapContextCreateImage(context);
	UIImage *uiImage = [UIImage imageWithCGImage:cgBitmap];
	CGImageRelease(cgBitmap);
	
	// Pop graphics state
	CGContextRestoreGState(context);
	UIGraphicsPopContext();
	
	// Clean up memory
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	
	return uiImage;
}

UIColor* 
getColorFromImage(UIImage* image, int xx, int yy)
{
    // "image" contains (xx,yy)?
    if(!CGRectContainsPoint(CGRectMake(0,0,image.size.width,image.size.height),CGPointMake(xx,yy)))
        return nil;
	
    // generates 1x1 uiimage corresponding to point (xx,yy)
    UIGraphicsBeginImageContext(CGSizeMake(1,1));
    [image drawAtPoint:CGPointMake(-xx, -yy)];
    UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
    // generates CGContextRef with uiimage above
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) malloc(4);
    CGContextRef context = CGBitmapContextCreate(rawData, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), resultImg.CGImage);
    CGContextRelease(context);
	
    // manipulates data of CGContextRef above
    CGFloat red   = (rawData[0]*1.0)/255.0;
    CGFloat green = (rawData[1]*1.0)/255.0;
    CGFloat blue  = (rawData[2]*1.0)/255.0;
    CGFloat alpha = (rawData[3]*1.0)/255.0;
    free(rawData);
	
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}


void
Gravilux::resetGrainsRandomImage(UIImage *uiImage)
{
	CGPoint p, ip, v, inset;
	
	// First get the image into your data buffer
	CGImageRef imageRef = [uiImage CGImage];
	NSUInteger width = CGImageGetWidth(imageRef);
	NSUInteger height = CGImageGetHeight(imageRef);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	unsigned char *rawData = (unsigned char*) malloc(height * width * 4);
	NSUInteger bytesPerPixel = CGImageGetBitsPerPixel(imageRef)/8;
	NSUInteger bytesPerRow = CGImageGetBytesPerRow(imageRef);
	NSUInteger bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
	CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colorSpace);
	
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
	CGContextRelease(context);
	
	v.x = v.y = 0;
	
	int nGrains = params_->rows() * params_->cols();
	
	// how to scale from screen to image space
	CGSize screenSize = ((UIScreen*)[[UIScreen screens] objectAtIndex:0]).bounds.size;
	CGPoint scale = CGPointMake(screenSize.width / uiImage.size.width,
								screenSize.height / uiImage.size.height);
	
	int i=0;
	while (i<nGrains) {
		
		// choose a random point
		p.x = RANDOM(0, uiImage.size.width-1);
		p.y = RANDOM(0, uiImage.size.height-1);
		
		// if the pixel is non-black in image, add it
		//		UIColor *c = getColorFromImage(image, roundf(p.x), roundf(p.y));
		//		const float* colors = CGColorGetComponents( c.CGColor );
		
		int xx = roundf(p.x);
		int yy = roundf(p.y);
		
		// Now your rawData contains the image data in the RGBA8888 pixel format.
		int byteIndex = (bytesPerRow * yy) + xx * bytesPerPixel;
		unsigned char red   = rawData[byteIndex];
		unsigned char green = rawData[byteIndex + 1];
		unsigned char blue  = rawData[byteIndex + 2];
		//unsigned char alpha = rawData[byteIndex + 3];
		
		if (!(red==0 && green==0 && blue==0)) {
			// compute image position
			ip.x = p.x * scale.x;
			ip.y = p.y * scale.y;
			
			grains_[i]->pos(ip);
			grains_[i]->vel(v);
			grains_[i]->showHeat(params_->heat());
			grains_[i]->size(params_->starSize());	
			
			i++;
			
		} else {
			//  otherwise keep looking
		}
		
		// idea - base on color of image $$$!!!
	}
	
	free(rawData);
}

void
Gravilux::resetGrainsMatrixImage(UIImage *uiImage, int rowSkip)
{
	CGPoint p, ip, v, inset;
	
	// First get the image into your data buffer
	CGImageRef imageRef = [uiImage CGImage];
	NSUInteger width = CGImageGetWidth(imageRef);
	NSUInteger height = CGImageGetHeight(imageRef);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	unsigned char *rawData = (unsigned char*) malloc(height * width * 4);
	NSUInteger bytesPerPixel = 4;
	NSUInteger bytesPerRow = CGImageGetBytesPerRow(imageRef);
	NSUInteger bitsPerComponent = 8;
	CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colorSpace);
	
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
	CGContextRelease(context);
	
	v.x = v.y = 0;
		
	// how to scale from screen to image space
	CGSize screenSize = ((UIScreen*)[[UIScreen screens] objectAtIndex:0]).bounds.size;
	CGPoint scale = CGPointMake(screenSize.width / uiImage.size.width,
								screenSize.height / uiImage.size.height);
	
	int i = 0;
 	
	for (int xx = 0; xx < uiImage.size.width; xx += rowSkip) {
		for (int yy = 0; yy < uiImage.size.height; yy += rowSkip) {
			
			// Now your rawData contains the image data in the RGBA8888 pixel format.
			int byteIndex = (bytesPerRow * yy) + xx * bytesPerPixel;
			unsigned char red   = rawData[byteIndex];
			unsigned char green = rawData[byteIndex + 1];
			unsigned char blue  = rawData[byteIndex + 2];
			//unsigned char alpha = rawData[byteIndex + 3];
			
			if (!(red==0 && green==0 && blue==0)) {
				// $$$$ look for going beyond # of grains, if so, reallocate
				if (i >= nAllocGrains_) 
				{
					allocGrains(nAllocGrains_*1.1);
				}
				assert(i < nAllocGrains_);
				
				// compute image position
				ip.x = (float)xx * scale.x + 0.5;
				ip.y = (float)yy * scale.y + 0.5;
				
				grains_[i]->pos(ip);
				grains_[i]->vel(v);
				grains_[i]->showHeat(params_->heat());
				grains_[i]->size(1);	
				
				i++;
				
			} else {
				//  otherwise keep looking
			}
			// idea - base on color of image $$$!!!
		}
	}
	
	
	// Don't draw any grains that did not get placed when processing uiImage
	nGrains_ = i;
	
	free(rawData);
}

void
Gravilux::resetIdleTimer(bool set)
{
//	[interfaceViewController_ resetIdleTimer:set];
}

// Our method to create a PDF file natively on the iPhone
// This method takes two parameters, a CGRect for size and
// a const char, which will be the name of our pdf file
CGContextRef 
Gravilux::createPDFFile (CGRect pageRect, const char *filename) {
	
	// This code block sets up our PDF Context so that we can draw to it
	CGContextRef pdfContext;
	CFStringRef path;
	CFURLRef url;
	CFMutableDictionaryRef myDictionary = NULL;
	// Create a CFString from the filename we provide to this method when we call it
	path = CFStringCreateWithCString (NULL, filename,
									  kCFStringEncodingUTF8);
	// Create a CFURL using the CFString we just defined
	url = CFURLCreateWithFileSystemPath (NULL, path,
										 kCFURLPOSIXPathStyle, 0);
	CFRelease (path);
	// This dictionary contains extra options mostly for 'signing' the PDF
	myDictionary = CFDictionaryCreateMutable(NULL, 0,
											 &kCFTypeDictionaryKeyCallBacks,
											 &kCFTypeDictionaryValueCallBacks);
	CFDictionarySetValue(myDictionary, kCGPDFContextTitle, CFSTR("Bubble Harp Art"));
	CFDictionarySetValue(myDictionary, kCGPDFContextCreator, CFSTR("Bubble Harp"));
	// Create our PDF Context with the CFURL, the CGRect we provide, and the above defined dictionary
	pdfContext = CGPDFContextCreateWithURL (url, &pageRect, myDictionary);
	// Cleanup our mess
	CFRelease(myDictionary);
	CFRelease(url);
	//CFRelease(path);
	// Done creating our PDF Context, now it's time to draw to it
	
	return pdfContext;
}

bool
Gravilux::drawToPDF(NSString *path,
					float dotSize, // all values in points, 72dpi
					float pointWidth, float pointHeight)
{
	
	// calculate scaling from screen to page
	
	CGSize screenSize = ((UIScreen*)[[UIScreen screens] objectAtIndex:0]).bounds.size;
	FPoint ptScale;
	ptScale.x = pointWidth / (float) (screenSize.width);
	ptScale.y = pointHeight / (float) (screenSize.height);
	
	// create PDF file
	CGRect mediaBox;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *saveDirectory = [paths objectAtIndex:0];
	NSString *newFilePath = [saveDirectory stringByAppendingPathComponent:path];
	const char *filename = [newFilePath UTF8String];
	
    mediaBox = CGRectMake (0, 0, pointWidth, pointHeight);
    CGContextRef myPDFContext = createPDFFile (mediaBox, filename);    
	
	// start drawing into PDF
	CGContextBeginPage(myPDFContext, &mediaBox);
	
	// fill background with black
	CGContextSetRGBFillColor (myPDFContext, 0, 0, 0, 1);
	CGContextFillRect (myPDFContext, CGRectMake (0, 0, pointWidth, pointHeight ));
	
	// white dots
	CGContextSetRGBStrokeColor(myPDFContext, 1,1,1, 1);
	CGContextSetRGBFillColor(myPDFContext, 1,1,1, 1);
	
	int v;
	
	if (params_->heatColor()) {
		int nColors = params_->nColors();
		assert(nColors == 3);
		
		Color gradientColors[3];
		
		params_->getColors(gradientColors);
		
		for (v = 0; v < nGrains_; v++) {
			grains_[v]->drawToPDFColor(myPDFContext, dotSize*0.5, ptScale, 
									   pointWidth, pointHeight, true, gradientColors, nColors);
		}
		
	} else {
		// draw all the points in white or greys
		for (v = 0; v < nGrains_; v++) {
			grains_[v]->drawToPDF(myPDFContext, dotSize*0.5, ptScale, pointWidth, pointHeight);
		}
	}
	
	// write out "Bubble Harp 2010 05 12 14:32 Scott Snibbe and ____ 1/1" at bottom $$$$
	
	CGContextEndPage(myPDFContext);// 6
    CGContextRelease(myPDFContext);
	
	return true;
}

#pragma mark - Private Methods

void
Gravilux::allocGrains(int nGrains)
{
	nGrains_ = nGrains;
	CGPoint p;
	
	// only allocate if we go beyond buffer
	if (nGrains_ > nAllocGrains_) {
		
		p = CGPointMake(0,0);
		
		Grain** oldGrains = grains_;
		
		grains_ = new Grain* [nGrains_];
		
		CGSize screenSize = ((UIScreen *)[[UIScreen screens] objectAtIndex:0]).bounds.size;
		
		for (int i = 0; i < nGrains_; i++) {
			grains_[i] = new Grain(p, 1, 0.95, params_->heatScale() * (screenSize.width/1024.0));
			grains_[i]->size(params_->starSize());
			
			// copy old points
			if (i < nAllocGrains_) {
				grains_[i]->pos(oldGrains[i]->pos());
				grains_[i]->radius(oldGrains[i]->radius());
				// $$$ set anything else necessary
			}
		}
		
		delete [] oldGrains;
		nAllocGrains_ = nGrains_;
	}
}

void
Gravilux::allocGrains()
{
	allocGrains(params_->rows()*params_->cols());
}

void
Gravilux::wrapGrains()
{
	CGPoint p;
	CGSize screenSize = ((UIScreen*)[[UIScreen screens] objectAtIndex:0]).bounds.size;
	for (int i = 0; i < nGrains_; i++) {
		p = grains_[i]->pos();
		if (p.x < 0)
			p.x += screenSize.width;
		else if (p.x > screenSize.width)
			p.x -= screenSize.width;
		if (p.y < 0)
			p.y += screenSize.height;
		else if (p.y > screenSize.height)
			p.y -= screenSize.height;
		grains_[i]->pos(p);
	}	
}

bool
Gravilux::applyForceState(ForceState *fs, bool addForce)
{
	FPoint sumForce;
	if (fs->active()) {
		for (int i = 0; i < nGrains_; i++) {
			sumForce = fs->sumForce(grains_[i]->pos(), sizeScale_);// Grains should use FPoint!
			
			grains_[i]->applyForce(sumForce, addForce);
		}
	}
	
	return addForce;
}
/*
void
Gravilux::applyPointForce(Force *force, bool addForce)
{
	float forceStrength = force->strength();
	FPoint forcePoint = force->position();
	bool antigravity = params_->antigravity();
	CGPoint grainPoint, sumForce;
	
	float lengthSq, factor, g;	
	
	for (int i = 0; i < nGrains_; i++) {
		grainPoint = grains_[i]->pos();
		
		sumForce.x = (forcePoint.x - grainPoint.x);
		sumForce.y = (forcePoint.y - grainPoint.y);
		
		
		
		lengthSq = sumForce.x*sumForce.x + sumForce.y*sumForce.y;
		
		g = GRAVITY_CONSTANT * forceStrength * sizeScale_;
		factor = g/lengthSq;
		sumForce.x *= factor;
		sumForce.y *= factor;
		
		if (antigravity && force->isTouch()) {
			sumForce.x = -sumForce.x;
			sumForce.y = -sumForce.y;
		}
		
		grains_[i]->applyForce(sumForce, addForce);
	}
}*/

void
Gravilux::clearPointForces()
{
	CGPoint f = CGPointMake(0,0);
	
	for (int i = 0; i < nGrains_; i++) {
		grains_[i]->applyForce(f);
	}
}


/*bool
Gravilux::isShaking(float threshold = SHAKE_FORCE)
{
	ofPoint f = ofxAccelerometer.getForce();
	f.x = fabs(f.x);
	f.y = fabs(f.y);
	f.z = fabs(f.z);
	
	if ((f.x > SHAKE_FORCE && f.y > SHAKE_FORCE) ||
		(f.x > SHAKE_FORCE && f.z > SHAKE_FORCE) ||
		(f.y > SHAKE_FORCE && f.z > SHAKE_FORCE)) {
		return true;
	}
	return false;
}*/

void
Gravilux::simulate(float dt)
{
	clearPointForces();
	
	forceState_->simulate(dt);
	visualizer_->simulate(dt);

	
	// apply forces
	applyForceState(forceState_, false);
	
	for (int i = 0; i < nGrains_; i++) {
		grains_[i]->simulate(dt);
	}
	
	wrapGrains();
}

void
Gravilux::setDamp(float d)
{
	for (int i = 0; i < nGrains_; i++) {
		grains_[i]->damp(d);
	}
}

void
Gravilux::showHeat(bool h)
{
	CGSize screenSize = ((UIScreen *)[[UIScreen screens] objectAtIndex:0]).bounds.size;
#warning I think the hard coded 320 is wrong
	float hs = params_->heatScale() / params_->gravity() * (float) screenSize.width / 320.0;
	
	for (int i = 0; i < nGrains_; i++) {
		grains_[i]->heatScale(hs);
		grains_[i]->showHeat(h);
	}
	
}

void
Gravilux::setStarSize(int s)
{	
	//assert (s >0 && s<=6);
	for (int i = 0; i < nGrains_; i++) {
		grains_[i]->size(s);		
	}
}

void
Gravilux::drawInContext(CGContext *ctx)
{
	int v;
	
	int nColors = params_->nColors();
	assert(nColors == 3);
	
	Color gradientColors[3];
	
	params_->getColors(gradientColors);
	
	// for single color drawing
	CGContextSetRGBStrokeColor(ctx, 1,1,1, 1.0);
	
	for (v = 0; v < nGrains_; v++) {
		if (params_->heatColor()) {
			//grains_[v]->drawColorCG(gradientColors, nColors);
		} else {
			grains_[v]->drawCG(ctx);
		}
	}
}	

void
Gravilux::drawVertexArray()
{
	int g, i1, i2;
	float v, pvmax, vNorm, interp, oneMinusInterp;
	Color gradientColors[3];
	CGPoint pos, vel;
	
	vertexArrayObject.setClientStates();
	vertexArrayObject.begin(GL_POINTS);
	
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glPointSize(params_->deviceStarSize());
	
	if (params_->heatColor()
		|| (visualizer()->running() && visualizer()->colorWalk())) {
		params_->getColors(gradientColors);
		
		vNorm = 1.f / (maxVelocity_*0.25f);
		maxVelocity_ = 1.f;
		for (g = 0; g < nGrains_; g++) {
			pos = grains_[g]->pos();
			vel = grains_[g]->vel();
			
			pvmax = MAX(vel.x, vel.y);
			if (pvmax > maxVelocity_) maxVelocity_ = pvmax;
			
			v = MAX(ABS(vel.x), ABS(vel.y));
			
			interp = sqrtf(v*vNorm) * 2.f;
			
			if (interp > 1.) {
				i1 = 1;
				interp -= 1.f;
			} else {
				i1 = 0;
			}
			i2 = i1+1;
			
			oneMinusInterp = 1. - interp;
			
			vertexArrayObject.setColor(gradientColors[i1].r * oneMinusInterp + gradientColors[i2].r * interp,
									   gradientColors[i1].g * oneMinusInterp + gradientColors[i2].g * interp,
									   gradientColors[i1].b * oneMinusInterp + gradientColors[i2].b * interp,
									   1.);
			vertexArrayObject.addVertex(pos.x, pos.y);
//			grains_[g]->drawVertexArrayColor(&vertexArrayObject, gradientColors, nColors);
		}
	}
	else {
		vertexArrayObject.setColor(1,1,1,1);
		for (g = 0; g < nGrains_; g++) {
			grains_[g]->drawVertexArray(&vertexArrayObject);
		}
	}	
	// end vertices and draw to screen
	vertexArrayObject.end();
	
	vertexArrayObject.restoreClientStates();
	
	glDisable(GL_POINT_SMOOTH);
	glDisable(GL_BLEND);
}

void
Gravilux::drawGrains()
{
	
	if (DRAW_IN_CONTEXT) {
		
		//[quartzView setNeedsDisplay]; // which will trigger callback to drawInContext
		
	} else if (drawVertexArray_) {
	
		drawVertexArray();
		
	} else {
/*		int v;
		
		int nColors = params_->nColors();
		assert(nColors == 3);
		
		Color gradientColors[3];
		
		params_->getColors(gradientColors);
		
		//ofEnableAlphaBlending();
		ofSetCircleResolution(8);
		
		// for single color drawing
		ofSetColor(255, 255, 255, 255);
		
		for (v = 0; v < nGrains_; v++) {
			if (params_->heatColor()) {
				grains_[v]->drawColor(gradientColors, nColors);
			} else {
				grains_[v]->draw();
			}
		}*/
	}
	//ofDisableAlphaBlending();
 
}

void
Gravilux::drawForceState(ForceState * fs)
{
	if (fs == NULL) { // we have note recurred yet, so take from object scope
		fs = forceState_;
	}
	
	vertexArrayObject.setClientStates();
	
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glPointSize(15);
	
	vertexArrayObject.begin(GL_POINTS);
	
	set<Force*>::iterator force;
	for (force = fs->begin(); force != fs->end(); force++) {
		if((*force)->active()) {
			vertexArrayObject.setColor(1,1,0,(*force)->state()->strength());
			FPoint pos = (*force)->position();
			vertexArrayObject.addVertex(pos.x, pos.y);
		}
	}
	
	// end vertices and draw to screen
	vertexArrayObject.end();
	
	vertexArrayObject.restoreClientStates();
	
	glDisable(GL_POINT_SMOOTH);
	glDisable(GL_BLEND);

	
	set<ForceState*> substates = fs->substates();
	set<ForceState*>::iterator substate;
	for (substate = substates.begin(); substate != substates.end(); substate++) {
		drawForceState(*substate);
	}
}
