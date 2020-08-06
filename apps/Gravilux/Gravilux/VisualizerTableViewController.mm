//
//  VisualizerTableViewController.m
//  Gravilux
//
//  Created by Colin Roache on 10/31/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "VisualizerTableViewController.h"
#include "Gravilux.h"
#include "Visualizer.h"

@interface VisualizerTableViewController (Private)
- (void) updateUI;
@end

@implementation VisualizerTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
	
    if (self) {
		self.tableView.delegate = self;
		self.tableView.dataSource = self;
    }
	
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	self.view.layer.shouldRasterize = YES;
	
	self.view.layer.rasterizationScale = [UIScreen mainScreen].scale;
	
	trackMinImage = [UIImage imageNamed:@"slider_min.png"];
	trackMaxImage = [UIImage imageNamed:@"slider_max.png"];
	if ([trackMinImage respondsToSelector:@selector(resizableImageWithCapInsets)]) {
		trackMinImage = [trackMinImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 19, 0, 19)];
		trackMaxImage = [trackMaxImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 19, 0, 19)];
	} else {
		trackMinImage = [trackMinImage stretchableImageWithLeftCapWidth:19 topCapHeight:0];
		trackMaxImage = [trackMaxImage stretchableImageWithLeftCapWidth:19 topCapHeight:0];
	}
	
	thumbImages = [NSArray array];
	for (int i = 0; i < gGravilux->visualizer()->nEmitters(); i++) {
		UIImage * thumb = [[UIImage imageNamed:[NSString stringWithFormat:@"vis_handle_%i.png", i+1]] retain];
		thumbImages = [thumbImages arrayByAddingObject:thumb];
	}
	[thumbImages retain];
	
	self.tableView.transform = CGAffineTransformMakeRotation(-M_PI_2);
	self.tableView.bounds = CGRectMake(self.tableView.bounds.origin.x, self.tableView.bounds.origin.y, self.tableView.bounds.size.height, self.tableView.bounds.size.width);
	[self.tableView layoutSubviews];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI) name:@"updateUIVisualizerLevels" object:nil];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"updateUIVisualizerLevels"];
	
	if (trackMinImage) {
		[trackMinImage release];
	}
	if (trackMaxImage) {
		[trackMaxImage release];
	}
	
	for (UIImage* thumb in thumbImages) {
		[thumb release];
	}
	[thumbImages release];
	
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return (NSInteger)1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return (NSInteger)gGravilux->visualizer()->nEmitters();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"emitter";
    static NSString *cellNib = @"VisualizerTableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {	
		NSArray *loadedXib = [[NSBundle mainBundle] loadNibNamed:cellNib
														   owner:self 
														 options:nil];
		for (id object in loadedXib) {
			if ([object isKindOfClass:[UITableViewCell class]]) {
				cell = (UITableViewCell *)object;
				break;
			}
		}
    }
    
    // Configure the cell...
	int emitterIndex = [indexPath indexAtPosition:1];
    cell.tag = emitterIndex;	// tag with the table index
	for(UIView * subview in ((UIView*)[cell.subviews objectAtIndex:0]).subviews) {
		if([subview isKindOfClass:[UISlider class]]) {
			((UISlider*)subview).value = 
			gGravilux->visualizer()->emitterStrength(emitterIndex);
			UIImage* thumb = [thumbImages objectAtIndex:[indexPath indexAtPosition:1]];
			[(UISlider*)subview setThumbImage: thumb forState:UIControlStateNormal];
			[(UISlider*)subview setThumbImage: thumb forState:UIControlStateHighlighted];
			[(UISlider*)subview setMinimumTrackImage:trackMinImage forState:UIControlStateNormal];
			[(UISlider*)subview setMaximumTrackImage:trackMaxImage forState:UIControlStateNormal];
		}
	}
	
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
}

#pragma mark - IB actions

- (IBAction)adjustEmitter:(id)sender
{
	if (!gGravilux->visualizer()->running())
		return;
	
	if ([sender isKindOfClass:[UISlider class]]) {
		NSUInteger index = ((UIView*)sender).superview.superview.tag;
		if (index != NSNotFound) {
			gGravilux->visualizer()->setEmitterStrength(index, ((UISlider*)sender).value);
		}
	}
}

#pragma mark - Private Methods

- (void)updateUI
{
	[self.tableView reloadData];
}
@end
