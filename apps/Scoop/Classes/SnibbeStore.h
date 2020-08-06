//
//  SnibbeStore.h
//  Scoop
//
//  Created by Graham McDermott on 4/15/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//
// based on code from : http://troybrant.net/blog/2010/01/in-app-purchases-a-full-walkthrough/

#import <Foundation/Foundation.h>

#import <StoreKit/StoreKit.h>

#define kInAppPurchaseBeatSet1ProductId @"com.snibbe.oscilloscoop.beatset1"

#define kInAppPurchaseManagerProductsFetchedNotification @"kInAppPurchaseManagerProductsFetchedNotification"
#define kInAppPurchaseManagerTransactionFailedNotification @"kInAppPurchaseManagerTransactionFailedNotification"
#define kInAppPurchaseManagerTransactionSucceededNotification @"kInAppPurchaseManagerTransactionSucceededNotification"



@interface SnibbeStore : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver> 
{    
    SKProduct *upgradeProduct_;    // the product we're intested in
    SKProductsRequest *productsRequest_;
}

+ (void) startup;
+ (void) shutdown;
+ (SnibbeStore *) store;

- (void) initiateProductsRequest;


- (void)loadStore;
- (BOOL)canMakePurchases;
- (void)purchaseProduct: (NSString *) productID;



- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response;
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;

@end




