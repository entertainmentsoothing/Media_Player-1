//
//  MusicLibraryController.h
//  YoutubeSearch
//
//  Created by An Nguyen on 12/27/17.
//  Copyright © 2017 An Nguyen. All rights reserved.
//

#import "ChildTabViewController.h"
#import <StoreKit/StoreKit.h>

@interface MusicLibraryController : ChildTabViewController<
SKProductsRequestDelegate,SKPaymentTransactionObserver>{
    SKProductsRequest *productsRequest;
    NSArray *validProducts;
    
}

- (void)fetchAvailableProducts;
- (BOOL)canMakePurchases;
- (void)purchaseMyProduct:(SKProduct*)product;
- (IBAction)purchase:(id)sender;
@property (strong, nonatomic) IBOutlet UIView *BuyView;
@property (weak, nonatomic) IBOutlet UIButton *btnBuy;
@property (weak, nonatomic) IBOutlet UIButton *btnRestore;

@end
