//
//  LoadViewController.mm
//
//  Copyright 2010 Scott Snibbe. All rights reserved.
//

#import "LoadViewController.h"
#include "BubbleHarp.h"
#include "Parameters.h"

#import "ImageBrowserView.h"

@implementation LoadViewController

@synthesize loadButton, deleteButton;
@synthesize scrollView = _scrollView;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
 // Custom initialization
 }
 return self;
 }
 */


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	_scrollView.delegate = _scrollView;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
	 selector:@selector(updateUI) name:@"UpdateLoadUI" object:nil];
	
//	CGSize screenSize = [[UIScreen mainScreen] bounds].size;
	
	[self cacheFilesToLoad];
	[_scrollView viewWillAppear:animated];
	[self updateUI];
}

- (void)viewWillDisappear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"UpdateLoadUI" object:nil];
}

- (void)cacheFilesToLoad
{
	NSString *images_dir;
	NSArray *files;
	NSURL *url;
	NSMutableArray *urls;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	images_dir = [paths objectAtIndex:0];
	
	files = [[NSFileManager defaultManager]
			 contentsOfDirectoryAtPath:images_dir error:nil];
	urls = [NSMutableArray array];
	
	for (NSString *file in files)
    {
		if ([file hasSuffix:BH_FILE_SUFFIX]) {
			url = [NSURL fileURLWithPath:
				   [images_dir stringByAppendingPathComponent:file]];
			[urls addObject:url];
		}
    }
	
	self.scrollView.fileURLs = urls;
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (IS_IPAD || interfaceOrientation == UIInterfaceOrientationPortrait)
		return YES;
	else 
		return NO;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}



- (void)updateUI {
	NSString *loadFilename = [_scrollView selectedViewFilename];
	
	if (loadFilename) {
		loadButton.enabled = true;
		deleteButton.enabled = true;
	} else {
		loadButton.enabled = false;
		deleteButton.enabled = false;
	}
}

- (IBAction)loadAction:(id)sender
{
	// load
	NSURL *loadURL = [_scrollView selectedViewFileURL];
	if (loadURL) gBubbleHarp->loadFromURL(loadURL);
	
	gBubbleHarp->setRunning(true);	
	
	[self dismissModalViewControllerAnimated:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ResetTimer" object:nil]; // turn on auto-hide timer for UI
}

- (IBAction)deleteAction:(id)sender
{
	[_scrollView deleteSelectedItem];
}

- (IBAction)cancelAction:(id)sender
{
	gBubbleHarp->setRunning(true);

	[self dismissModalViewControllerAnimated:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ResetTimer" object:nil]; // turn on auto-hide timer for UI
}

@end
