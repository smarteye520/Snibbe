//
//  HelpViewController.m
//  Gravilux
//
//  Created by Colin Roache on 11/29/11.
//  Copyright (c) 2011 Scott Snibbe Studio. All rights reserved.
//

#import "HelpViewController.h"
#import "FlurryAnalytics.h"

@implementation HelpViewController
@synthesize scrollView;
@synthesize imageView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    // Do any additional setup after loading the view from its nib.
	scrollView.contentSize = imageView.image.size;
//	imageView.frame = CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y, imageView.frame.size.width, imageView.image.size.height);
}

- (void)viewDidUnload
{
	[self setImageView:nil];
	[self setScrollView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)dismiss:(id)sender {
	[FlurryAnalytics endTimedEvent:@"Help" withParameters:nil];
	[UIView animateWithDuration:.3f animations:^{
		self.view.alpha = 0;
	} completion:^(BOOL finished) {
		if (finished) {
			[self.view removeFromSuperview];
		}
	}];
}
- (void)dealloc {
	[imageView release];
	[scrollView release];
	[super dealloc];
}
@end
