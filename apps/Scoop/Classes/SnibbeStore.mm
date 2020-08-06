//
//  SnibbeStore.m
//  Scoop
//
//  Created by Graham McDermott on 4/15/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//

#import "SnibbeStore.h"
#import "SettingsManager.h"

// the app store in-app purchase product id



static SnibbeStore *theStore = nil; // singleton in-app purchase store



// private interface
@interface SnibbeStore ()

- (void) clear;

@end

@implementation SnibbeStore

//
//
+ (void) startup
{
    theStore = [[SnibbeStore alloc] init];
    [theStore loadStore];
    
}

//
//
+ (void) shutdown
{
    
    if ( theStore )
    {
        [theStore release];
        theStore = nil;
    }
}

//
//
+ (SnibbeStore *) store
{
    return theStore;
}

//
//
- (id) init
{
    
    if ( ( self = [super init] ) )
    {
        productsRequest_ = nil;
        upgradeProduct_ = nil;
        
    }
    
    return self;
}

//
//
- (void) dealloc
{
    [self clear];
    [super dealloc];
}

//
//
- (void) initiateProductsRequest
{
    [self clear];
    
    // here we populate the set with the products relevant to this store
    // We can modify this for other products as needed
    
    // initiate products request for Scoop!
    NSSet *productIdentifiers = [NSSet setWithObject:kInAppPurchaseBeatSet1ProductId ];
        
    
    
    productsRequest_ = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];    
    productsRequest_.delegate = self;
    
    [productsRequest_ start];
}


//
// call this method once on startup
- (void)loadStore
{
    // restarts any purchases if they were interrupted last time the app was open
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    [self initiateProductsRequest];
}


//
// call this before making a purchase
- (BOOL)canMakePurchases
{
    return [SKPaymentQueue canMakePayments];
}


// kick off the purchase transaction
//
- (void)purchaseProduct: (NSString *) productID
{
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:productID];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}






//
// saves a record of the transaction by storing the receipt to disk
//
- (void)recordTransaction:(SKPaymentTransaction *)transaction
{
    
    // do we need this?
    
//    if ([transaction.payment.productIdentifier isEqualToString:kInAppPurchaseUpgradeProductId])
//    {
//        // save the transaction receipt to disk
//        [[NSUserDefaults standardUserDefaults] setValue:transaction.transactionReceipt forKey:@"upgradeTransactionReceipt" ];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//    }
}


//
// enable features
//
- (void)provideContent:(NSString *)productId
{
    if ([productId isEqualToString: kInAppPurchaseBeatSet1ProductId])
    {        
        // scoop specific
        [SettingsManager manager].purchasedBeatSet1_ = true; 
    }
}



//
// removes the transaction from the queue and posts a notification with the transaction result
//
- (void)finishTransaction:(SKPaymentTransaction *)transaction wasSuccessful:(BOOL)wasSuccessful
{
    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:transaction, @"transaction" , nil];
    if (wasSuccessful)
    {
        // send out a notification that we’ve finished the transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionSucceededNotification object:self userInfo:userInfo];
    }
    else
    {
        // send out a notification for the failed transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionFailedNotification object:self userInfo:userInfo];
    }
}


//
// called when the transaction was successful
//
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    //[self recordTransaction:transaction];
    [self provideContent:transaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
}

//
// called when a transaction has been restored and and successfully completed
//
- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    //[self recordTransaction:transaction.originalTransaction];
    [self provideContent:transaction.originalTransaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
}

//
// called when a transaction has failed
//
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        // error!
        [self finishTransaction:transaction wasSuccessful:NO];
    }
    else
    {
        // this is fine, the user just cancelled, so don’t notify
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}


////////////////////////////////////////////
// SKPaymentTransactionObserver methods
////////////////////////////////////////////

//
// called when the transaction status is updated
//
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }
}








////////////////////////////////////////////
// SKProductsRequestDelegate methods
////////////////////////////////////////////

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *products = response.products;
    
    // here we're just dealing with a single product since that's all we're interested in
    // at the moment.  expand as needed.
    
    
    upgradeProduct_ = [products count] == 1 ? [[products objectAtIndex:0] retain] : nil;
    

    if (upgradeProduct_)
    {
        NSLog(@"Product title: %@" , upgradeProduct_.localizedTitle);
        NSLog(@"Product description: %@" , upgradeProduct_.localizedDescription);
        NSLog(@"Product price: %@" , upgradeProduct_.price);
        NSLog(@"Product id: %@" , upgradeProduct_.productIdentifier);
    }
    
    for (NSString *invalidProductId in response.invalidProductIdentifiers)
    {
        NSLog(@"Invalid product id: %@" , invalidProductId);
    }
    
    if ( productsRequest_ )
    {
        [productsRequest_ release];
        productsRequest_ = nil;
    }
    
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerProductsFetchedNotification object:self userInfo:nil];
}

////////////////////////////////////////////
// private implementation
////////////////////////////////////////////

//
//
- (void) clear
{
    if ( productsRequest_ )
    {
        [productsRequest_ release];
        productsRequest_ = nil;
    }

    if ( upgradeProduct_ )
    {
        [upgradeProduct_ release];
        upgradeProduct_ = nil;
    }
}


@end
