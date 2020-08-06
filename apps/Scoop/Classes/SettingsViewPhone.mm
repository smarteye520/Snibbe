//
//  SettingsViewPhone.m
//  Scoop
//
//  Created by Graham McDermott on 4/12/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import "SettingsViewPhone.h"
#import "BeatListController.h"
#import "InfoViewPhone.h"
#import "ScoopDefs.h"
#import "ScoopUtils.h"
#import "UIViewControllerBeatPurchase.h"
#import "ScoopBeat.h"
#import "SettingsManager.h"

@interface SettingsViewPhone()

- (void) onDone;
- (void) onInfo;
- (void) updateTempoImage: (float) tempo;
- (void) updateTempoLabel: (float) tempo;

// BeatSetNavDelegate methods
-(void) navigateToBeatSetViewAtIndex: (int) iIndex;

@end

@implementation SettingsViewPhone

@synthesize beatSetIDDelegate_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        self.title = @"Beats";
        
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
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

    
    
  
    // do a custom image for our info button
    UIImage *imageButton = [UIImage imageNamed: @"info_button_phone.png" ];
    
    UIButton *info = [UIButton buttonWithType:UIButtonTypeCustom];  
    [info setImage:imageButton forState:UIControlStateNormal ];    
    info.frame = CGRectMake(0, 0, imageButton.size.width, imageButton.size.height );
    
    [info addTarget:self action:@selector(onInfo) forControlEvents:UIControlEventTouchUpInside];    
    UIBarButtonItem *infoBarButton = [[UIBarButtonItem alloc] initWithCustomView: info];                                       
    
    self.navigationItem.leftBarButtonItem = infoBarButton;            
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDone) ];

    [infoBarButton release];
    
    [self.view addSubview: blController_.view ];    
    blController_.beatSetIDDelegate_ = beatSetIDDelegate_;
    blController_.beatSetNavDelegate_ = self;
    
    //float navBarHeight = 44.0f;
    blController_.view.frame = CGRectMake(0, BEAT_TABLE_CELL_HEIGHT/2.0f, 320, BEAT_SELECT_VIEW_PURCHASED_HEIGHT );
    
    
    [self.view setBackgroundColor: [UIColor colorWithRed: 232.0f/255 green:239.0f/255 blue:243.0f/255 alpha:1.0f ]];
    
    CGRect tableBGRect = CGRectMake( blController_.view.frame.origin.x - 1, blController_.view.frame.origin.y - 1, blController_.view.frame.size.width + 2, blController_.view.frame.size.height + 1);
    
    
    labelTableBG_.frame = tableBGRect;
    
    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated
{

    float normTtempo = [beatSetIDDelegate_ getNormalizedTempo];        
    float tempo = normTtempo * (MAX_BPM - MIN_BPM ) + MIN_BPM;
    
    [sliderTempo_ setValue: tempo];
    [self onTempoValueChanged: sliderTempo_];
    
    [blController_ viewWillAppear:animated];
    
    labelTableBG_.hidden = [SettingsManager manager].purchasedBeatSet1_;
    
    
    
    [super viewWillAppear:animated];
}



- (void)viewDidAppear:(BOOL)animated
{
    [blController_ viewDidAppear:animated];
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [blController_ viewWillDisappear:animated];
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [blController_ viewDidDisappear:animated];
    [super viewDidDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


//
//
- (IBAction) onTempoValueChanged: (id) sender
{
    UISlider *slider = sender;    
    [self updateTempoLabel: [slider value]];
    
    //[self updateTempoImage: [slider value]];
    
    float normalizedTempo = ([slider value] - MIN_BPM) / (float) (MAX_BPM - MIN_BPM );
    [beatSetIDDelegate_ onTempoChanged: normalizedTempo];
    
}

////////////////////////////////////////////////
// private implementation
////////////////////////////////////////////////

//
//
- (void) onDone
{
        
    [self dismissModalViewControllerAnimated:YES];
    
}

//
//
- (void) onInfo
{    
    
    InfoViewPhone *info = [[InfoViewPhone alloc] initWithNibName:@"InfoViewPhone" bundle:nil];        
    
    info.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:info animated:true];
    
    [info release];
}


//
//
- (void) updateTempoImage: (float) tempo
{

    tempo = MIN( tempo, MAX_BPM );
    tempo = MAX( tempo, MIN_BPM );
    
    int offset = ROUNDINT (tempo - MIN_BPM);
    
 
    
    NSString *imgName = [NSString stringWithFormat:@"tempo_phone_000%02d@2x.png", offset ];
    [imageViewTempo_ setImage: [ UIImage imageNamed: imgName]];
    
    
}
 

//
//
- (void) updateTempoLabel: (float) tempo
{
 
    NSString *bpm = [NSString stringWithFormat:@"%d", (int) ROUNDINT( tempo ) ];    
    labelBPM_.text = bpm;        
 
}


//
//
-(void) navigateToBeatSetViewAtIndex: (int) iIndex
{
    UIViewControllerBeatPurchase *purchaseController = [[UIViewControllerBeatPurchase alloc] initWithNibName:@"UIViewControllerBeatPurchase" bundle:nil];                
    NSString * bgImageName = [NSString stringWithFormat: @"beat_bg_iphone_0%d.png", iIndex ];
    
    ScoopLibrary& lib = ScoopLibrary::Library();
    ScoopBeatSet * selectedBS = lib.beatSetAt( iIndex );
    purchaseController.title = [NSString stringWithUTF8String: selectedBS->getName()];
    
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:purchaseController animated:YES];
    
    [purchaseController setImageName: bgImageName];
    [purchaseController setCopy: [NSString stringWithUTF8String: selectedBS->getDescription()] ];
    [purchaseController release];

}


 
@end
