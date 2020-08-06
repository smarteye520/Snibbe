//
//  BeatListController.m
//  Scoop
//
//  Created by Graham McDermott on 4/12/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import "BeatListController.h"
#import "ScoopUtils.h"
#import "ScoopDefs.h"
#import "ScoopBeat.h"
#import "UIViewControllerBeatPurchase.h"
#import "SettingsManager.h"
#import "SnibbeStore.h"

////////////////////////////////////
// private interface
////////////////////////////////////

@interface BeatListController()

-(bool) beatSetAtIndexIsUnlocked: (int) iIndex;

-(void) storeTransactionFailed: (NSNotification *) notification;
-(void) storeTransactionSucceeded: (NSNotification *) notification;

-(void) refreshNotifications;

@end




@implementation BeatListController

////////////////////////////////////
// public implementation
////////////////////////////////////



@synthesize beatSetIDDelegate_;
@synthesize selectedSetIndex_;
@synthesize beatSetNavDelegate_;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
        // Custom initialization
        beatSetIDDelegate_ = nil;
              
        self.title = @"Select Beat Set";        
        selectedSetIndex_ = 0;

        [self refreshNotifications];
        
                
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    self.tableView.scrollEnabled = NO; 
    self.beatSetNavDelegate_ = nil;
    

    //self.tableView.style = UITableViewStyleGrouped;
             
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    int popAdjust = 0;
    bool bPurchased = [SettingsManager manager].purchasedBeatSet1_;
    
    if ( gbIsIPad && bPurchased )
    {
        //popAdjust = -1; // avoid last white line
    }
    
    
    [self.tableView setBackgroundColor:UIColor.clearColor]; // Make the table view transparent
    
    
    CGSize size = CGSizeMake( 320, BEAT_SELECT_VIEW_PURCHASED_HEIGHT + popAdjust);
    self.contentSizeForViewInPopover = size;    
    
    self.view.frame = CGRectMake( self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, size.height) ;
    
    self.tableView.separatorStyle = (bPurchased ? UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine);
    
    [self.tableView reloadData];
    
    [self refreshNotifications];
    
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

//
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return BEAT_TABLE_CELL_HEIGHT;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    ScoopLibrary& lib = ScoopLibrary::Library();
    return lib.numBeatSets();    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    int iIndex = indexPath.row;
    bool bUnlocked = [self beatSetAtIndexIsUnlocked: iIndex];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    
    ScoopLibrary& lib = ScoopLibrary::Library();
    ScoopBeatSet *bs = lib.beatSetAt( indexPath.row );
    if ( bs )
    {    
        cell.textLabel.text = [NSString stringWithUTF8String: bs->getName() ];        
        
        cell.textLabel.textColor = [UIColor darkGrayColor];        
        cell.textLabel.backgroundColor = (bUnlocked ? [UIColor clearColor] : [UIColor whiteColor] );        
        
    }
    
    
    if ( indexPath.row == selectedSetIndex_ )
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UIImage *bgImage = nil;
    
    if ( !bUnlocked )
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        
        bgImage = [UIImage imageNamed: @"beat_strip_white.png" ];
    }
    else
    {
        // add the bg image                
        bgImage = [UIImage imageNamed: [NSString stringWithFormat: @"beat_strip_0%d.png", iIndex] ];
        
            
    }
    
    if ( bgImage )
    {
        
        UIImageView *imageViewBG = [[UIImageView alloc] initWithImage: bgImage];        
        cell.backgroundView = imageViewBG;
        [imageViewBG release];
    }
    
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{   
    
    ScoopLibrary& lib = ScoopLibrary::Library();
    
    int iIndex = indexPath.row;
    bool bUnlocked = [self beatSetAtIndexIsUnlocked: iIndex];
    ScoopBeatSet * selectedBS = lib.beatSetAt( iIndex );
    
    
    if ( selectedBS )
    {
        
        // todo - is the selection an in-app purchase? $
        
        if ( !bUnlocked )
        {
            
            if ( beatSetNavDelegate_ )
            {
                // we handle this at another level (iPhone)
                [ beatSetNavDelegate_ navigateToBeatSetViewAtIndex: iIndex];
            }
            else
            {
                // we handle this here (iPad)
            
                UIViewControllerBeatPurchase *purchaseController = [[UIViewControllerBeatPurchase alloc] initWithNibName:@"UIViewControllerBeatPurchase" bundle:nil];                
                NSString * bgImageName = [NSString stringWithFormat: @"beat_bg_0%d.png", iIndex ];                
                purchaseController.title = [NSString stringWithUTF8String: selectedBS->getName()];
                
                
                // Pass the selected object to the new view controller.
                [self.navigationController pushViewController:purchaseController animated:YES];
                
                [purchaseController setImageName: bgImageName];
                [purchaseController setCopy: [NSString stringWithUTF8String: selectedBS->getDescription()] ];
                [purchaseController release];
            }
            
            
        }
        else
        {
            // select the beat set and dismiss
            
            if ( beatSetIDDelegate_ )
            {
                [beatSetIDDelegate_ onBeatSetIDSelected: selectedBS->getUID()];
            }
            
            bool bAllUnlocked = [SettingsManager manager].purchasedBeatSet1_;
            
            for ( int i = 0; i < [self.tableView numberOfRowsInSection: 0]; ++i )
            {
                UITableViewCell *cell = [tableView cellForRowAtIndexPath: [NSIndexPath indexPathForRow:i inSection:0]];
                cell.accessoryType = i == iIndex ? UITableViewCellAccessoryCheckmark : (bAllUnlocked ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator);      
            }
            
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            
        }        
        
    }
    
}


///////////////////////////////////////////////////////
// private implementation
///////////////////////////////////////////////////////

//
//
-(bool) beatSetAtIndexIsUnlocked: (int) iIndex
{
    return ( iIndex == 0 ||
            [SettingsManager manager].purchasedBeatSet1_ );
}

//
//
-(void) storeTransactionFailed: (NSNotification *) notification
{        
    [self.tableView reloadData];
}


//
//
-(void) storeTransactionSucceeded: (NSNotification *) notification
{        
    [self.tableView reloadData];
}

//
//
-(void) refreshNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeTransactionFailed:) 
                                                 name:kInAppPurchaseManagerTransactionFailedNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeTransactionSucceeded:) 
                                                 name:kInAppPurchaseManagerTransactionSucceededNotification object:nil];
}

@end
