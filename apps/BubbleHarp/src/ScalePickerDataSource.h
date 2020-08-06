/*
     File: ScalePickerDataSource.h
 
	(c) 2010 Scott Snibbe
 
 */

#include "Parameters.h"

@interface ScalePickerDataSource : NSObject <UIPickerViewDataSource, UIPickerViewDelegate>
{
	NSArray	*customPickerArray;
}

@property (nonatomic) NSArray *customPickerArray;

@end
