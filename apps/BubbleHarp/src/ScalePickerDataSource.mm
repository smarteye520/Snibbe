/*
     File: ScalePickerDataSource.m
	(c) 2010 Scott Snibbe
 
 */

#import "ScalePickerDataSource.h"
#import "ScaleView.h"

@implementation ScalePickerDataSource

@synthesize customPickerArray;

- (id)init
{
	// use predetermined frame size
	self = [super init];
	if (self)
	{
		// create the data source for this custom picker
		NSMutableArray *viewArray = [[NSMutableArray alloc] init];
		ScaleView *scaleView;
		//float *rgba;
		//CGColorSpaceRef rgbColorSpace = (CGColorSpaceRef)[(id)CGColorSpaceCreateDeviceRGB() autorelease];
		
		for (int i=0; i < Parameters::params().nScales(); i++) {
			scaleView = [[ScaleView alloc] initWithFrame:CGRectZero];
			scaleView.title = Parameters::params().scaleName(i);
			scaleView.scaleIndex = i;
			scaleView.color = Parameters::params().scaleColor(i);
			[viewArray addObject:scaleView];
		}

		self.customPickerArray = viewArray;
	}
	return self;
}



#pragma mark -
#pragma mark UIPickerViewDataSource

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	return [ScaleView viewWidth];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return [ScaleView viewHeight];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [customPickerArray count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}


#pragma mark -
#pragma mark UIPickerViewDelegate

// tell the picker which view to use for a given component and row, we have an array of views to show
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row
		  forComponent:(NSInteger)component reusingView:(UIView *)view
{
	return [customPickerArray objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	Parameters::params().setScaleIndex(row);
	//NSLog(@"picked %@, %d", Parameters::params().curScaleName(), Parameters::params().scaleIndex());
	gBubbleHarp->resetIdleTimer(YES);
}

@end
