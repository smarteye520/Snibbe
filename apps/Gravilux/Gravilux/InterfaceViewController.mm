//
//  InterfaceViewController.m
//  Gravilux
//
//  Created by Colin Roache on 10/4/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "InterfaceViewController.h"
#include <stdlib.h>
//#import "FlurryAnalytics.h"

#define TRANSITION_LENGTH_S .3f
@interface InterfaceViewController (Private)
- (void)hideInterface;
- (void)showInterface;
- (void)setHeight;				// Pulls height from current active tab
- (void)setHeight:(int)height;	// Allows an exact height
- (void)skinControls;
- (void)syncControls;
- (void)syncControlsColor;
- (void)updatePickerFromColors;
- (void)updateColorsFromPicker;
- (void)showTypeAuxView:(NSNotification*)notification;
- (void)hideTypeAuxView:(NSNotification*)notification;
@end

@implementation InterfaceViewController
@synthesize currentOrientation;

#pragma mark - Overridden Subclass Methods
#pragma mark UIView
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		UIDevice* thisDevice = [UIDevice currentDevice];
		self.currentOrientation = UIInterfaceOrientationPortrait;
		if(thisDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
		{
			// iPad
			infoVC = [[[InfoViewController alloc] initWithNibName:@"InfoView-iPad" bundle:nil] retain];
			helpVC = [[[HelpViewController alloc] initWithNibName:@"HelpView-iPad" bundle:nil] retain];
		}
		else
		{
			// iPhone
			infoVC = [[[InfoViewController alloc] initWithNibName:@"InfoView-iPhone" bundle:nil] retain];
			helpVC = [[[HelpViewController alloc] initWithNibName:@"HelpView-iPhone" bundle:nil] retain];
		}		
		activeColor = [[UIColor colorWithWhite:0. alpha: .65] retain];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncControls) name:@"updateUI" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncControlsColor) name:@"ParametersDidUpdateColorsNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePickerFromColors) name:@"ParametersDidUpdateColorsNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColorsFromPicker) name:@"ColorPickerDidUpdateNotification" object:nil];
    }
    return self;
}

- (void)dealloc
{
	[helpVC release];
	[infoVC release];
	[musicVC release];
	[shareVC release];
	
	[typeSize release];
	[typeText release];
	[typeView release];
	
	[colorPicker release];
	[colorCircle1 release];
	[colorCircle2 release];
	[colorCircle3 release];
	[colorIndicator1 release];
	[colorIndicator2 release];
	[colorIndicator3 release];
	
	[load4 release];
	[load3 release];
	[load2 release];
	[load1 release];
	[save4 release];
	[save3 release];
	[save2 release];
	[save1 release];
	
	
	[settingsButton release];
	[colorsButton release];
	[textButton release];
	[loadSaveButton release];
	[shareButton release];
	[infoButton release];
	[musicButton release];
	
	[activeColor release];
	
	[logo release];
	[antigravityButton release];
	[playPauseButton release];
	
	[sizeSlider release];
	[sizeLabel release];
	[densitySlider release];
	[densityLabel release];
	[gravitySlider release];
	[gravityLabel release];
	
	[settingsView release];
	[colorView release];
	[loadSaveView release];
	
	[topBar release];
	[tabView release];
	[controlBar release];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self skinControls];
	[self syncControls];
	[self syncControlsColor];
	
	
	[tabView addSubview:settingsView];
	settingsButton.selected = YES;
	
	[self setHeight];
	
	// The assoicated UIKeyboardWillHideNotification is added and removed in switchTab:
	if (typeAuxView) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideTypeAuxView:) name:UIKeyboardWillHideNotification object:nil];
	}
	
	rowSkip = (typeSize.maximumValue - typeSize.minimumValue)-(typeSize.value - typeSize.minimumValue)+typeSize.minimumValue;
//	
//	[colorPicker addObserver:self
//				  forKeyPath:@"color"
//					 options:NSKeyValueObservingOptionNew
//					 context:NULL];
	Color currentColors[3];
	gGravilux->params()->getColors(currentColors);
	colorPicker.color = [UIColor colorWithRed:currentColors[0].r green:currentColors[0].g blue:currentColors[0].b alpha:1.];
	
	[self hideInterface];
}


- (void)viewDidUnload
{
	// The assoicated UIKeyboardWillHideNotification is added and removed in switchTab:
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[infoVC release];
	infoVC = nil;
	
	[musicVC release];
	musicVC = nil;
	[shareVC release];
	shareVC = nil;
	
	[colorPicker release];
	colorPicker = nil;
	[colorCircle1 release];
	colorCircle1 = nil;
	[colorCircle2 release];
	colorCircle2 = nil;
	[colorCircle3 release];
	colorCircle3 = nil;
	[colorIndicator1 release];
	colorIndicator1 = nil;
	[colorIndicator2 release];
	colorIndicator2 = nil;
	[colorIndicator3 release];
	colorIndicator3 = nil;
	
	[save1 release];
	save1 = nil;
	[save2 release];
	save2 = nil;
	[save3 release];
	save3 = nil;
	[save4 release];
	save4 = nil;
	[load1 release];
	load1 = nil;
	[load2 release];
	load2 = nil;
	[load3 release];
	load3 = nil;
	[load4 release];
	load4 = nil;
	
	[settingsButton release];
	settingsButton = nil;
	[colorsButton release];
	colorsButton = nil;
	[textButton release];
	textButton = nil;
	[loadSaveButton release];
	loadSaveButton = nil;
	[shareButton release];
	shareButton = nil;
	[infoButton release];
	infoButton = nil;
	[musicButton release];
	musicButton = nil;
	
	[activeColor release];
	activeColor = nil;
	
	[logo release];
	logo = nil;
	[antigravityButton release];
	antigravityButton = nil;
	[playPauseButton release];
	playPauseButton = nil;
	
	[sizeSlider release];
	sizeSlider = nil;
	[sizeLabel release];
	sizeLabel = nil;
	[densitySlider release];
	densitySlider = nil;
	[densityLabel release];
	densitySlider = nil;
	[gravitySlider release];
	gravitySlider = nil;
	[gravityLabel release];
	gravityLabel = nil;
	
	[settingsView release];
	settingsView = nil;
	[colorView release];
	colorView = nil;
	[loadSaveView release];
	loadSaveView = nil;
	
	[topBar release];
	topBar = nil;
	[tabView release];
	tabView = nil;
	[controlBar release];
	controlBar = nil;
	
	[typeView release];
	typeView = nil;
	[typeText release];
	typeText = nil;
	[typeSize release];
	typeSize = nil;
	
	if (typeAuxSize) {
		[typeAuxSize release];
		typeAuxSize = nil;
	}
	if (typeAuxText) {
		[typeAuxText release];
		typeAuxText = nil;
	}
	if (typeAuxView) {
		[typeAuxView release];
		typeAuxView = nil;
	}
	
	[infoVC release];
	infoVC = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[UIView animateWithDuration:duration animations:^{
		centerNavigation.frame = CGRectMake((centerNavigation.superview.frame.size.width - centerNavigation.frame.size.width) / 2., centerNavigation.frame.origin.y, centerNavigation.frame.size.width, centerNavigation.frame.size.height);
	} completion:nil];
}

//#pragma mark KVC
//- (void)observeValueForKeyPath:(NSString *)keyPath
//                      ofObject:(id)object
//                        change:(NSDictionary *)change
//                       context:(void *)context
//{
//    if ([keyPath isEqual:@"color"]) {
//		gGravilux->params()->setHeatColor(YES);
//		[self updateColorsFromPicker];
//    }
//}
#pragma mark UIResponder Methods
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	gGravilux->params()->setInteractionTime();
	ForceState * forceState = gGravilux->forceState();
	float gravity = gGravilux->params()->gravity();
	
	//  pass touches on to the experiance if not touching the UI
	for (UITouch *touch in touches) {
		if (!((!hidden && (CGRectContainsPoint(controlBar.bounds, [touch locationInView:controlBar])
							|| (topBar != nil && CGRectContainsPoint(topBar.bounds, [touch locationInView:topBar]))))
			|| (hidden && CGRectContainsPoint(logo.bounds, [touch locationInView:logo])))) {
			Force * f = new Force(touch);
			f->setStrength(gravity);
			// This is for tossing points:
//			f->setBoundaryMode(ForceBoundaryModeBounce);
//			f->enableVelocity(true);
//			f->setAcceleration(.9, .6);
			forceState->addForce(f);
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	
	gGravilux->params()->setInteractionTime();
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	
	gGravilux->params()->setInteractionTime();
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	
	gGravilux->params()->setInteractionTime();
}

#pragma mark - Delegate Methods
#pragma mark UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if ([string isEqualToString:@"\n"]) {
		[textField resignFirstResponder];
		return NO;
	}
	NSString * text = [(NSString*)textField.text stringByReplacingCharactersInRange:range withString:string];
	if ([[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
		gGravilux->resetGrains();
	} else {
		gGravilux->resetGrainsType(text, self.currentOrientation, rowSkip);
	}
	if ([textField isEqual:typeAuxText]) {
		typeText.text = text;
	}
	else if([textField isEqual:typeText]) {
		typeAuxText.text = text;
	}
	
	return true;
}

#pragma mark - Interface Builder Actions
#pragma mark Top-level UI Actions
- (IBAction)toggleInterface:(id)sender
{
//	[FlurryAnalytics logEvent:@"Toggle Menu"];
	[UIView animateWithDuration:TRANSITION_LENGTH_S animations:^{
		if (hidden) {
			[self showInterface];
		}
		else {
			[self hideInterface];
		}
	} completion:^(BOOL finished) {
		// Signal the animated button to stop rendering when hidden
		if (finished) {
			if ([[[tabView subviews] objectAtIndex:0] isEqual:musicVC.view]) {
				if (hidden) {
					[musicVC viewDidDisappear:YES];
				} else {
					[musicVC viewDidAppear:YES];
				}
			}
		}
	}];
}

- (IBAction)toggleAntigravity:(id)sender
{
//	[FlurryAnalytics logEvent:@"Toggle Antigravity"];
	gGravilux->params()->setAntigravity(!(gGravilux->params()->antigravity()));
	
	[self syncControls];
}

- (IBAction)togglePlayPause:(id)sender
{
	BOOL state = gGravilux->running();
	gGravilux->setRunning(!state);
	playPauseButton.selected = state;
}

- (IBAction)resetGrid:(id)sender
{
//	[FlurryAnalytics logEvent:@"Reset Grid"];
	gGravilux->resetGrains();
}

- (IBAction)resetAll:(id)sender
{
//	[FlurryAnalytics logEvent:@"Reset All"];
	gGravilux->resetGrains();
	gGravilux->params()->setDefaults(true);
	
	[self syncControls];
}

- (IBAction)switchTab:(id)sender
{
	// Reset all button states and then enable the touched one later
	loadSaveButton.selected = NO;
	colorsButton.selected = NO;
	settingsButton.selected = NO;
	musicButton.selected = NO;
	textButton.selected = NO;
	shareButton.selected = NO;
	
	UIView* target = nil;
	UIView* current = [[tabView subviews] objectAtIndex:0];
	if ([sender isEqual:loadSaveButton]) {
		target = loadSaveView;
		loadSaveButton.selected = YES;
//		[FlurryAnalytics logEvent:@"Opened Load/Save Panel"];
	} else if ([sender isEqual:colorsButton]) {
		target = colorView;
		colorsButton.selected = YES;
//		[FlurryAnalytics logEvent:@"Opened Color Panel"];
	} else if ([sender isEqual:settingsButton]) {
		target = settingsView;
		settingsButton.selected = YES;
//		[FlurryAnalytics logEvent:@"Opened Settings Panel"];
	} else if ([sender isEqual:musicButton]) {
		target = musicVC.view;
		musicButton.selected = YES;
//		[FlurryAnalytics logEvent:@"Opened Music Panel"];
	} else if ([sender isEqual:textButton]) {
		target = typeView;
		textButton.selected = YES;
//		[FlurryAnalytics logEvent:@"Opened Type Panel"];
	} else if ([sender isEqual:shareButton]) {
		target = shareVC.view;
		shareButton.selected = YES;
//		[FlurryAnalytics logEvent:@"Opened Share Panel"];
	}
	
	if (target && ![current isEqual:target]) {
		target.alpha = 0.;
		[tabView insertSubview:target atIndex:0];
		[UIView animateWithDuration:TRANSITION_LENGTH_S
						 animations:^{
							 target.alpha = 1.;
							 current.alpha = 0.;
							 [self setHeight];//:target.frame.size.height];
						 }
						 completion:^(BOOL finished){
							 if(finished) {
								 [current removeFromSuperview];
								 
								 // This tells the animating button to only render when visable
								 if([target isEqual:musicVC]) {
									 [musicVC viewDidAppear:YES];
								 }
							 }
						 }];
	}
	
	
	// Observe keyboard notifications when the type tool is active
	// (removing avoids displaying for keyboard in share tab)
	// The UIKeyboardWillHideNotification is registered in viewDidLoad: and is removed in viewDidUnload:
	if (typeAuxView) {
		if ([target isEqual:typeView]) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showTypeAuxView:) name:UIKeyboardWillShowNotification object:nil];
		} else {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
		}
	}
	
	// More simplified UI for iPhone
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ) {
		if ([target isEqual:typeView]) {			// Bring up the keyboard+auxview
			typeAuxView.hidden = NO;
			[typeAuxText becomeFirstResponder];
		} else if ([current isEqual:typeView]) {	// Hide the keyboard+auxview
			[typeAuxText resignFirstResponder];
		}
	}
	
	[self syncControls];
}

- (IBAction)info:(id)sender
{
//	[FlurryAnalytics logEvent:@"Info" timed:YES];
	
	infoVC.view.alpha = 0;
	[self.view addSubview:infoVC.view];
	infoVC.view.frame = self.view.frame;
	[UIView animateWithDuration:TRANSITION_LENGTH_S animations:^{
		infoVC.view.alpha = 1;
	} completion:nil];
}

- (IBAction)iap:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"presentProUpgrade" object:self];
}

- (IBAction)help:(id)sender
{
//	[FlurryAnalytics logEvent:@"Help" timed:YES];
	
	helpVC.view.alpha = 0;
	[self.view addSubview:helpVC.view];
	helpVC.view.frame = self.view.frame;
	[UIView animateWithDuration:TRANSITION_LENGTH_S animations:^{
		helpVC.view.alpha = 1;
	} completion:nil];
}

#pragma mark Settings UI Actions
- (IBAction)updateSetting:(id)sender {
	if ([sender isEqual:sizeSlider]) {
		gGravilux->params()->setStarSize(sizeSlider.value);
	} else if ([sender isEqual:densitySlider]) {
		int rowscols = (int)sqrtf(densitySlider.value);
		gGravilux->params()->setSize(rowscols, rowscols);
	} else if ([sender isEqual:gravitySlider]) {
		float fval = 1.0;
		
		// sender.value ranges from 1 - 100
		float normVal = gravitySlider.value / 100.0;
		// shift scale to allow more range at low end
		fval = powf(normVal, G_SLIDER_EXPONENT);
		fval *= MAX_GRAVITY;
		
		if (fval > 5) fval = roundf(fval);
		gGravilux->params()->setGravity(fval);
		gGravilux->forceState()->setGravity(fval);
	}
	
	[self syncControls];
}

- (IBAction)finishUpdatingSetting:(id)sender {
	if ([sender isEqual:sizeSlider]) {
//		[FlurryAnalytics logEvent:@"Change Grain Size"];
	} else if ([sender isEqual:densitySlider]) {
//		[FlurryAnalytics logEvent:@"Change Grain Count"];
	} else if ([sender isEqual:gravitySlider] ) {
//		[FlurryAnalytics logEvent:@"Change Gravity"];
	}
}

#pragma mark Color UI Actions
- (IBAction)toggleColor:(UIButton *)sender
{
//	[FlurryAnalytics logEvent:@"Toggle Color"];
	
	Parameters * p = gGravilux->params();
	BOOL isHeatEnabled = p->heatColor();
	
	p->setHeatColor(!isHeatEnabled);
	
	[self syncControlsColor];
}

- (IBAction)selectColor:(UIButton *)sender
{
	int selected = 1;
	if ([sender isEqual:colorCircle2]) {
		selected = 2;
	} else if ([sender isEqual:colorCircle3]) {
		selected = 3;
	}
//	[FlurryAnalytics logEvent:@"Switch Color Swatch" withParameters:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:selected] forKey:@"Swatch"]];
	
	colorIndicator1.hidden = (selected != 1);
	colorIndicator2.hidden = (selected != 2);
	colorIndicator3.hidden = (selected != 3);
	
	[self updatePickerFromColors];
	[self syncControlsColor];
}

- (IBAction)randomColor:(UIButton *)sender
{
//	[FlurryAnalytics logEvent:@"Random Colors"];
	
	Color randomColors[3];
	
	for (int i=0; i < 3; i++) {
		randomColors[i].r = (float) arc4random()/RAND_MAX;
		randomColors[i].g = (float) arc4random()/RAND_MAX;
		randomColors[i].b = (float) arc4random()/RAND_MAX;
	}
	
	gGravilux->params()->setColors(randomColors);
	gGravilux->params()->setHeatColor(YES);
	
	[self updatePickerFromColors];
	[self syncControlsColor];
}

- (IBAction)greyColor:(UIButton *)sender
{
//	[FlurryAnalytics logEvent:@"Grey Colors"];
	Color greyColors[3];
	
	greyColors[0].r = greyColors[0].g = greyColors[0].b = 0;
	greyColors[1].r = greyColors[1].g = greyColors[1].b = 0.5;
	greyColors[2].r = greyColors[2].g = greyColors[2].b = 1.0;
	
	gGravilux->params()->setColors(greyColors);
	gGravilux->params()->setHeatColor(YES);
	
	[self updatePickerFromColors];
	[self syncControlsColor];
}

#pragma mark Load/View UI Actions
- (IBAction)load:(id)sender
{
//	[FlurryAnalytics logEvent:@"Load"];
	Parameters * p = gGravilux->params();
	if([sender isEqual:load1]) {
		p->loadPreset(1, false);
	} else if([sender isEqual:load2]) {
		p->loadPreset(2, false);
	} else if([sender isEqual:load3]) {
		p->loadPreset(3, false);
	} else if([sender isEqual:load4]) {
		p->loadPreset(4, false);
	}
	
	[self syncControls];
	[self syncControlsColor];
	[self updatePickerFromColors];
}

- (IBAction)save:(id)sender
{
//	[FlurryAnalytics logEvent:@"Save"];
	Parameters * p = gGravilux->params();
	if([sender isEqual:save1]) {
		p->savePreset(1);
	} else if([sender isEqual:save2]) {
		p->savePreset(2);
	} else if([sender isEqual:save3]) {
		p->savePreset(3);
	} else if([sender isEqual:save4]) {
		p->savePreset(4);
	}
}

#pragma mark Type UI Actions
- (IBAction)resizeType:(id)sender
{
	if (![[typeText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
		if ([sender isKindOfClass:[UISlider class]]) {
			UISlider * slider = sender;
			if ([slider isEqual:typeSize]) {
				typeAuxSize.value = slider.value;
			}
			else if([slider isEqual:typeAuxSize]) {
				typeSize.value = slider.value;
			}
			
			int scaledValue = (slider.maximumValue - slider.minimumValue)-(slider.value - slider.minimumValue)+slider.minimumValue;
			if (rowSkip != scaledValue) {
				rowSkip = scaledValue;
				gGravilux->resetGrainsType(typeText.text, self.currentOrientation, rowSkip);
			}
		}
	}
}

#pragma mark - Private methods
- (void)hideInterface
{
	for (UIView * subView in controlBar.subviews) {
		if(![subView isEqual:logo])
			subView.alpha = 0.;
	}
	
	if(topBar != nil) {
		for (UIView * subView in topBar.subviews) {
			subView.alpha = 0.;
		}
		topBar.backgroundColor = [UIColor clearColor];
	}
	
	logo.selected = NO;
	
	controlBar.backgroundColor = [UIColor clearColor];
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		[self setHeight:44+24*2];//image height + top margin + bottom margin
	}
	hidden = YES;
}

- (void)showInterface
{
	for (UIView * subView in controlBar.subviews) {
		subView.alpha = 1.;
	}
	if(topBar != nil) {
		for (UIView * subView in topBar.subviews) {
			subView.alpha = 1.;
		}
		topBar.backgroundColor = activeColor;
	}
	logo.selected = YES;
	controlBar.backgroundColor = activeColor;
	[self setHeight];
	hidden = NO;
}

- (void) setHeight
{
	float height = ((UIView*)[tabView.subviews objectAtIndex:0]).bounds.size.height;
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		height = MAX(height, settingsView.frame.size.height);
	}
	[self setHeight:height];
}

- (void) setHeight:(int)height
{
	
	UIDevice* thisDevice = [UIDevice currentDevice];
	if(thisDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		// iPad
		controlBar.frame = CGRectMake(0,self.view.frame.size.height - height,controlBar.frame.size.width, height);
	} else if(thisDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		// iPhone
		int settingsViewYOffset = seperationLine.frame.origin.y + seperationLine.frame.size.height;
		topBar.frame = CGRectMake(0, 0, topBar.frame.size.width, height+settingsViewYOffset);
	}
}

- (void) skinControls
{
	UIImage * sliderImage = [UIImage imageNamed:@"settings_slider_line.png"];
	UIImage * handleImage = [UIImage imageNamed:@"settings_slider_handle.png"];
	NSArray * viewsToSkin = [settingsView subviews];
	if (typeSize) {
		viewsToSkin = [viewsToSkin arrayByAddingObject:typeSize];
	}
	if (typeAuxSize) {
		viewsToSkin = [viewsToSkin arrayByAddingObject:typeAuxSize];
	}
	for (UIView * subview in viewsToSkin) {
		if ([subview isKindOfClass:[UISlider class]]) {
			[(UISlider*)subview setThumbImage:handleImage forState:UIControlStateNormal];
			[(UISlider*)subview setMinimumTrackImage:sliderImage forState:UIControlStateNormal];
			[(UISlider*)subview setMaximumTrackImage:sliderImage forState:UIControlStateNormal];
		}
	}
	
	typeAuxView.hidden = YES;
	CGRect screenSize = [UIScreen mainScreen].bounds;
	typeAuxView.frame = CGRectMake(screenSize.origin.x, screenSize.origin.y + screenSize.size.height, typeAuxView.frame.size.width, typeAuxView.frame.size.height);
	
	sizeSlider.minimumValue = gGravilux->params()->minStarSize();
	sizeSlider.maximumValue = gGravilux->params()->maxStarSize();
	densitySlider.maximumValue = powf(gGravilux->params()->maxRows(),2.);
	
}

- (void) syncControls
{
	Parameters * p = gGravilux->params();
	p->savePreset(0);
	
	antigravityButton.selected = !p->antigravity();
	
	sizeSlider.value = p->starSize();
	sizeLabel.text = [NSString stringWithFormat:@"%00.2f", p->starSize()];
	
	densitySlider.value = p->rows()*p->cols();
	densityLabel.text = [NSString stringWithFormat:@"%5.d", p->rows()*p->cols()];
	
	gravitySlider.value = powf((p->gravity() / MAX_GRAVITY), .5) * 100.0;
	gravityLabel.text = [NSString stringWithFormat:@"%00.1f", (p->antigravity() ? -1 : 1) * p->gravity()];
	
	if (buttonScrollView) {
		buttonScrollView.contentSize = ((UIView*)[buttonScrollView.subviews objectAtIndex:0]).frame.size;
	}
}
- (void) syncControlsColor
{
	Parameters * p = gGravilux->params();
	p->savePreset(0);
	
	// Update the color picker if it has loaded
	if (colorPicker) {
		colorToggle.selected = p->heatColor();
		// Retreive current colors so we can replace the updated one and then set
		Color currentColors[3];
		p->getColors(currentColors);
		
		// Sync the UI circles
		colorCircle1.color = [UIColor colorWithRed:currentColors[0].r green:currentColors[0].g blue:currentColors[0].b alpha:1.];
		colorCircle2.color = [UIColor colorWithRed:currentColors[1].r green:currentColors[1].g blue:currentColors[1].b alpha:1.];
		colorCircle3.color = [UIColor colorWithRed:currentColors[2].r green:currentColors[2].g blue:currentColors[2].b alpha:1.];
	}
	
}

- (void)updatePickerFromColors
{
	if (colorPicker) {
		Color currentColors[3];
		gGravilux->params()->getColors(currentColors);
		
		int selectedCircle = 0;
		if (!colorIndicator2.hidden) { selectedCircle = 1; }
		else if (!colorIndicator3.hidden) { selectedCircle = 2; } 
		UIColor * colorToPass = [UIColor colorWithRed:currentColors[selectedCircle].r green:currentColors[selectedCircle].g blue:currentColors[selectedCircle].b alpha:1];
		[colorPicker setColor:colorToPass];
	}
}

- (void)updateColorsFromPicker
{
	// Retreive current colors so we can replace the updated one and then set
	Color currentColors[3];
	gGravilux->params()->getColors(currentColors);
	
	// Find the currently selected circle
	int selectedCircle;
	if (!colorIndicator1.hidden) {
		colorCircle1.color = colorPicker.color;
		selectedCircle = 0;
	} else if (!colorIndicator2.hidden) {
		colorCircle2.color = colorPicker.color;
		selectedCircle = 1;
	} else { // if (!colorIndicator3.hidden) 
		colorCircle3.color = colorPicker.color;
		selectedCircle = 2;
	} 
	
	// Extract the color from the picker
	const CGFloat* pickerComponents = CGColorGetComponents( colorPicker.color.CGColor );
	
	// Update the proper color
	currentColors[selectedCircle].r = pickerComponents[0];
	currentColors[selectedCircle].g = pickerComponents[1];
	currentColors[selectedCircle].b = pickerComponents[2];
	
	// Save the newly updated colors
	gGravilux->params()->setColors(currentColors);
	gGravilux->params()->setHeatColor(YES);
	[self syncControlsColor];
}

- (void)showTypeAuxView:(NSNotification *)notification
{
	UIViewAnimationCurve animationCurve;
	double duration;
	CGRect keyboardEndFrame, keyboardBeginFrame;
	[[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
	[[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
	[[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
	[[notification.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardBeginFrame];
	
	keyboardEndFrame = [self.view convertRect:keyboardEndFrame fromView:self.view.superview.superview];
	keyboardBeginFrame = [self.view convertRect:keyboardBeginFrame fromView:self.view.superview.superview];
	
	typeAuxView.hidden = NO;
	typeAuxView.alpha = 0.;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:duration];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:animationCurve];
	typeAuxView.alpha = 1.;
	typeAuxView.frame = CGRectMake(keyboardEndFrame.origin.x, keyboardEndFrame.origin.y - typeAuxView.frame.size.height, keyboardEndFrame.size.width, typeAuxView.frame.size.height);
	[UIView commitAnimations];
	
	[typeAuxText performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:duration];
/*	[UIView animateWithDuration:duration
						  delay:0.
						options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent
					 animations:^{
						 typeAuxView.alpha = 1.;
						 typeAuxView.frame = CGRectMake(keyboardEndFrame.origin.x, keyboardEndFrame.origin.y - typeAuxView.frame.size.height, keyboardEndFrame.size.width, typeAuxView.frame.size.height);
					 }
					 completion:^(BOOL finished) {
						 if (typeAuxText) {
							 [typeAuxText becomeFirstResponder];
						 }
					 }];*/
}

- (void)hideTypeAuxView:(NSNotification *)notification
{
	UIViewAnimationCurve animationCurve;
	double duration;
	CGRect keyboardEndFrame, keyboardBeginFrame;
	[[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
	[[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
	[[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
	[[notification.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardBeginFrame];
	
	keyboardEndFrame = [self.view convertRect:keyboardEndFrame fromView:self.view.superview.superview];
	keyboardBeginFrame = [self.view convertRect:keyboardBeginFrame fromView:self.view.superview.superview];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:duration];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:animationCurve];
	typeAuxView.alpha = 0.;
	typeAuxView.frame = CGRectMake(keyboardEndFrame.origin.x, keyboardEndFrame.origin.y, typeAuxView.frame.size.width, typeAuxView.frame.size.height);
	[UIView commitAnimations];
/*	[UIView animateWithDuration:duration
						  delay:0.
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 typeAuxView.alpha = 0.;
						 typeAuxView.frame = CGRectMake(keyboardEndFrame.origin.x, keyboardEndFrame.origin.y, typeAuxView.frame.size.width, typeAuxView.frame.size.height);
					 }
					 completion:^(BOOL finished){
						 typeAuxView.hidden = YES;
					 }];*/
}
@end
