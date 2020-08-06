//
//  SKProduct+LocalizedPrice.h
//  Scoop
//
//  Created by Graham McDermott on 4/15/11.
//  Copyright 2011 Scott Snibbe. All rights reserved.
//
//  based on code from : http://troybrant.net/blog/2010/01/in-app-purchases-a-full-walkthrough/
//
//  A category to help with localized price strings for in-app purchases

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface SKProduct (LocalizedPrice)

@property (nonatomic, readonly) NSString *localizedPrice;

@end




