//
//  MusicLibraryController.m
//  YoutubeSearch
//
//  Created by An Nguyen on 12/27/17.
//  Copyright © 2017 An Nguyen. All rights reserved.
//

#import "MusicLibraryController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "MultimediaPlayerView.h"
#import "DeviceMediaModel.h"
#import <AVKit/AVKit.h>
#import "AudioTableViewCell.h"
#import "UIAlertView+BlocksKit.h"
#import "UIActionSheet+BlocksKit.h"
#import "NSObject+Block.h"
#import <ISMessages.h>
#import "AppSession.h"
#import "ControllerServices.h"
#import "AppDefine.h"
#import "RootTabBarController.h"
#import "AudioSplitController.h"

#import "Reachability.h"
#import "AppDelegate.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "UICKeyChainStore.h"
#import <Crashlytics/Crashlytics.h>
#import "PupUpViewController.h"
#define PurcheseProductID @"com.rainsic.fullversion"
#define myAppDelegate (AppDelegate *)[[UIApplication sharedApplication] delegate]


@interface MusicLibraryController ()<UITableViewDelegate, UITableViewDataSource, AudioTableViewCellDelegate>{
    
    AVAudioFramePosition lengthSongSamples;
    float sampleRateSong;
    float lengthSongSeconds;
    float startInSongSeconds;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;


@property (nonatomic) NSMutableArray<DeviceMediaModel *>* datasources;

//
//@property AVAudioEngine *audioEngine;
//@property AVAudioPlayerNode* audioPlayerNode;
//@property AVAudioFile *audioFile;
//@property AVAudioUnitTimePitch *changePitchEffect;
//@property AVAudioUnitEQ *equalizer;
//@property AVAudioEnvironmentNode *mixer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomCst;
@property (weak, nonatomic) IBOutlet GADBannerView *adBannerView;
@property BOOL isSeeking;

@end

@implementation MusicLibraryController

- (void)viewDidLoad {
    [super viewDidLoad];
   
   
    
//  [[Crashlytics sharedInstance] crash];
//    UITabBarController * tab = [[RootTabBarController alloc]init];
//    tab.tabBarItem.selectedImage =  [[UIImage imageNamed:@"favorite"]
//                                       imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//
//    tab.tabBarItem.image  = [[UIImage imageNamed:@"favorite"]
//                             imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    [self initTableView];
//    [self getLocalListSong];
//    [self checkPermissionForMusic];
    self.datasources = [ControllerServices getLocalListSong];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerAppearNotificationListener:)
                                                 name:PlayerAppearNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    self.adBannerView.rootViewController = self;
    [self.adBannerView loadRequest:[GADRequest request]];
    
    _BuyView.frame = self.view.frame;
    [self.view addSubview:_BuyView];
    [self.BuyView setHidden:YES];
    [self fetchAvailableProducts];
    [self validateReceiptForTransaction];
    self.btnBuy.layer.borderWidth = 2.0f;
    self.btnBuy.layer.borderColor = [UIColor blackColor].CGColor;
    self.btnRestore.layer.borderWidth = 2.0f;
    self.btnRestore.layer.borderColor = [UIColor blackColor].CGColor;
    
    
}


-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
   // ((RootTabBarController *)self.tabBarController).se
}

- (void) reachabilityChanged:(NSNotification *)note
{
//    Reachability* curReach = [note object];
//    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    
    [self.tableView reloadData];
}

- (void)checkPermissionForMusic {
    if (MPMediaLibrary.authorizationStatus != MPMediaLibraryAuthorizationStatusAuthorized) {
        [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status){
            switch (status) {
                    case MPMediaLibraryAuthorizationStatusNotDetermined: {
                        // not determined
                        break;
                    }
                    case MPMediaLibraryAuthorizationStatusRestricted: {
                        // restricted
                        break;
                    }
                    case MPMediaLibraryAuthorizationStatusDenied: {
                        // denied
                        break;
                    }
                    case MPMediaLibraryAuthorizationStatusAuthorized: {
                        self.datasources = [ControllerServices getLocalListSong];
                        break;
                    }
                default: {
                    break;
                }
            }
        }];
    } else {
        self.datasources = [ControllerServices getLocalListSong];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [AppSession sharedInstance].rootTabBarController.childTab = self;
    [[AppSession sharedInstance].rootTabBarController.audioController minimizeIfNeeded];
    
}

- (void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
     ((RootTabBarController *)self.tabBarController).searchBar.hidden = NO;
    [self.BuyView removeFromSuperview];
}

- (void)playerAppearNotificationListener:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:PlayerAppearNotification]){
        BOOL isNeedSpace = [notification.object boolValue];
        self.bottomCst.constant = isNeedSpace?120:0;
    }
}

#pragma mark - TableView
- (void)initTableView{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg"]];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return ([AppDefine sharedInstance].internetReachability.currentReachabilityStatus == NotReachable) ? 0 : self.datasources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    AudioTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.data = [self.datasources objectAtIndex:indexPath.row];
    cell.delegate = self;
    return cell;
}

- (void)dlgAudioTableViewCellPlay:(DeviceMediaModel*)data{
    [ControllerServices playAudio:data inList:self.datasources];
    [[AppSession sharedInstance].rootTabBarController showRewardedVideo];
}

- (void)dlgAudioTableViewCellAdd:(DeviceMediaModel*)data{
    // Old Action Sheet
  /*  UIActionSheet *actionSheet = [UIActionSheet bk_actionSheetWithTitle:@"Menu Action"];
    
    [actionSheet bk_addButtonWithTitle:@"Add To Playlist" handler:^{
        [AppSession sharedInstance].lastSelectVideo = data;
        [AppSession sharedInstance].rootTabBarController.selectedIndex = 2;
    }];
    
    [actionSheet bk_addButtonWithTitle:@"Add To Favorites" handler:^{
        [[AppSession sharedInstance] addFavorite:data];
    }];
    
    [actionSheet bk_setCancelButtonWithTitle:@"Cancel" handler:^{
        
    }];
    [actionSheet showInView:self.view];*/
    // Old Action Sheet
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *addToPlaylist = [UIAlertAction
                                    actionWithTitle:@"Add To Playlist"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction *action){
                                        NSLog(@"Add To Playlist");
                            [AppSession sharedInstance].lastSelectVideo = data;
                            [AppSession sharedInstance].rootTabBarController.selectedIndex = 2;
                                        
                                    }];
    [addToPlaylist setValue:[[UIImage imageNamed:@"ic_playlist_white"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [alertController addAction:addToPlaylist];
    
    
    UIAlertAction *AddToFavorites = [UIAlertAction
                             actionWithTitle:@"Add To Favorites"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction *action) {
                                 NSLog(@"Add To Favorites");
                             [[AppSession sharedInstance] addFavorite:data];
                             }];
    [AddToFavorites setValue:[[UIImage imageNamed:@"ic_favorite_white"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [alertController addAction:AddToFavorites];
    
    UIAlertAction *cutAudio = [UIAlertAction
                                    actionWithTitle:@"Cut Audio"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction *action){
                                        NSLog(@"Cut Audio");
                                        [self onCutAudio:data];
                                    }];
    [cutAudio setValue:[[UIImage imageNamed:@"ic_scissor"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [alertController addAction:cutAudio];
    
    UIAlertAction *Cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction *action) {
                                 NSLog(@"Cancel");
                                 
                             }];
    [alertController addAction:Cancel];
    
    
    alertController.view.tintColor = [UIColor whiteColor];
    UIView *subView = alertController.view.subviews.firstObject;
    
    UIView *alertContentView = subView.subviews.firstObject;
    for (UIView *subSubView in alertContentView.subviews) {
        subSubView.backgroundColor = [UIColor colorWithRed:83/255.0f green:133/255.0f blue:140/255.0f alpha:1.0f];
    }
    alertContentView.layer.cornerRadius = 5;
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)onCutAudio:(DeviceMediaModel*)data {
    AudioSplitController* next = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"AudioSplitController"];
    next.data = data;
    //[self.audioControl pause];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:next];
    [[AppSession sharedInstance].rootTabBarController presentViewController:nav animated:true completion:nil];
}


// In APP PURCHESE

-(void)fetchAvailableProducts {
    NSSet *productIdentifiers = [NSSet
                                 setWithObjects:PurcheseProductID,nil];
    productsRequest = [[SKProductsRequest alloc]
                       initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
}

- (BOOL)canMakePurchases {
    return [SKPaymentQueue canMakePayments];
}

- (void)purchaseMyProduct:(SKProduct*)product {
    if ([self canMakePurchases]) {
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:
                                  @"Purchases are disabled in your device" message:nil delegate:
                                  self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alertView show];
    }
}
-(IBAction)purchase:(id)sender {
    [self purchaseMyProduct:[validProducts objectAtIndex:0]];
   // purchaseButton.enabled = NO;
}

#pragma mark StoreKit Delegate

-(void)paymentQueue:(SKPaymentQueue *)queue
updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"Purchasing");
                break;
                
            case SKPaymentTransactionStatePurchased:
                if ([transaction.payment.productIdentifier
                     isEqualToString:PurcheseProductID]) {
                    NSLog(@"Purchased ");
                    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:
                                              @"Purchase is completed succesfully" message:nil delegate:
                                              self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                    [alertView show];
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                NSLog(@"Restored ");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                NSLog(@"Purchase failed ");
                break;
            default:
                break;
        }
    }
}
-(void)productsRequest:(SKProductsRequest *)request
    didReceiveResponse:(SKProductsResponse *)response {
    SKProduct *validProduct = nil;
    int count = [response.products count];
    
    if (count>0) {
        validProducts = response.products;
        validProduct = [response.products objectAtIndex:0];
        
        if ([validProduct.productIdentifier
             isEqualToString:PurcheseProductID]) {
//            NSLog(@"validProduct.localizedTitle",validProduct.localizedTitle);
//            NSLog(@"validProduct.localizedDescription",validProduct.localizedDescription);
//            NSLog(@"validProduct.price",validProduct.price);;
           /* [productTitleLabel setText:[NSString stringWithFormat:
                                        @"Product Title: %@",validProduct.localizedTitle]];
            [productDescriptionLabel setText:[NSString stringWithFormat:
                                              @"Product Desc: %@",validProduct.localizedDescription]];
            [productPriceLabel setText:[NSString stringWithFormat:
                                        @"Product Price: %@",validProduct.price]];*/
        }
    } else {
        UIAlertView *tmp = [[UIAlertView alloc]
                            initWithTitle:@"Not Available"
                            message:@"No products to purchase"
                            delegate:self
                            cancelButtonTitle:nil
                            otherButtonTitles:@"Ok", nil];
        [tmp show];
    }
    
   // [activityIndicatorView stopAnimating];
   // purchaseButton.hidden = NO;
}
- (IBAction)Restore:(UIButton *)sender {
    [self validateReceiptForTransaction];
    [[SKPaymentQueue defaultQueue]restoreCompletedTransactions];
}

-(void)validateReceiptForTransaction
{
    /* Load the receipt from the app bundle. */
    
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
    
    if (!receipt) {
        /* No local receipt -- handle the error. */
         NSLog(@"No local receipt");
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.isShowAdd = YES;
        [self.BuyView setHidden:NO];
        [self.adBannerView setHidden:NO];
        ((RootTabBarController *)self.tabBarController).searchBar.hidden = YES;
        return;
        
    }
  
    NSError *error;
    
    NSDictionary *requestContents = @{
                                      @"receipt-data": [receipt base64EncodedStringWithOptions:0],
                                       @"password" : @"cd3197da6fa847aa9733125a125dbd62"
                                      };
    
    NSLog(@"requestContents %@",requestContents);
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents
                                                          options:0
                                                            error:&error];
    
    if (!requestData) {
        /* ... Handle error ... */
    }
    // Create a POST request with the receipt data.
   // NSURL *storeURL = [NSURL URLWithString:@"https://buy.itunes.apple.com/verifyReceipt"];
    NSURL *storeURL = [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
    
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];
    
    /* Make a connection to the iTunes Store on a background queue. */
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:storeRequest queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               if (connectionError) {
                                   
                                   /* ... Handle error ... */
                                   
                               } else {
                                   
                                   NSError *error;
                                   NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                   NSDictionary * dic_1 = [jsonResponse valueForKey:@"receipt"];
                                     NSArray * dic_2 = [dic_1 valueForKey:@"in_app"];
                                   NSDictionary * dic_3  = dic_2[0];
                                   NSString * product_id = [dic_3 valueForKey:@"product_id"];
                                   NSLog(@"product_id %@",product_id);
                                   if ([product_id isEqualToString:@"com.rainsic.fullversion"]){
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                           appDelegate.isShowAdd = NO;
                                          [self.BuyView setHidden:YES];
                                          [self.adBannerView setHidden:YES];
                                           ((RootTabBarController *)self.tabBarController).searchBar.hidden = NO;
                                       });
                                      
                                   }
                                   
                                   if (!jsonResponse) {
                                   
                                   }
                                   
                                   /* ... Send a response back to the device ... */
                               }
                           }];
}

- (IBAction)btnClose:(UIButton *)sender {
    [self.BuyView removeFromSuperview];
    ((RootTabBarController *)self.tabBarController).searchBar.hidden = NO;
}


//- (void)completeTransaction:(SKPaymentTransaction *)transaction {
//    NSLog(@"completeTransaction...");
//
//    [self validateReceiptForTransaction];
//    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
//}
//
//- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
//    NSLog(@"restoreTransaction...");
//
//    [self validateReceiptForTransaction];
//    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
//}



//- (void)searchString:(NSString *)search{
//    self.datasources = [NSMutableArray new];
//    for (DeviceMediaModel *obj in self.allSources) {
//        NSString* nameTerm = [obj.localName lowercaseString];
//        if ([nameTerm containsString:search] || [search containsString:nameTerm]) {
//            [self.datasources addObject:obj];
//        }
//    }
//    [self.tableView reloadData];
//}
//
//- (void)cancelSearch{
//    self.datasources = [NSMutableArray arrayWithArray:self.allSources];
//    [self.tableView reloadData];
//}

/*
 
 - (UIImage *)imageFromVideoURL{
 
 UIImage *image = nil;
 AVAsset *asset = [[AVURLAsset alloc] initWithURL:self.videoURL options:nil];;
 AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
 imageGenerator.appliesPreferredTrackTransform = YES;
 
 // calc midpoint time of video
 Float64 durationSeconds = CMTimeGetSeconds([asset duration]);
 CMTime midpoint = CMTimeMakeWithSeconds(durationSeconds/2.0, 600);
 
 // get the image from
 NSError *error = nil;
 CMTime actualTime;
 CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:midpoint actualTime:&actualTime error:&error];
 
 if (halfWayImage != NULL)
 {
 // cgimage to uiimage
 image = [[UIImage alloc] initWithCGImage:halfWayImage];
 [self.dic setValue:image forKey:@"ImageThumbnail"];//kImage
 NSLog(@"Values of dictonary==>%@", self.dic);
 NSLog(@"Videos Are:%@",self.videoURLArray);
 CGImageRelease(halfWayImage);
 }
 return image;
 }
 
- (void)playSampleAudio:(DeviceMediaModel*)obj{
    [self playAudioUrl:obj.localURL];
}
- (void)playAudioUrl:(NSURL*)url{
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"noo" ofType:@"mp3"];
    NSError *err;
    NSURL* mp3Url = url;//[NSURL fileURLWithPath:filePath];
    self.audioEngine = [[AVAudioEngine alloc] init];
    self.audioFile = [[AVAudioFile alloc] initForReading:mp3Url error:&err];
    NSLog(@"Audio Leng %lld", self.audioFile.length);
    NSLog(@"Audio sampleRate %f", self.audioFile.fileFormat.sampleRate);
    NSLog(@"Audio duration %f", self.audioFile.length/(double)self.audioFile.fileFormat.sampleRate);
    
    AVAudioSession*session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    
    self.audioPlayerNode = [[AVAudioPlayerNode alloc]init];
    //    [self.audioPlayerNode addObserver:self forKeyPath:@"playing" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.audioEngine attachNode:self.audioPlayerNode];
    
    self.changePitchEffect = [[AVAudioUnitTimePitch alloc]init];
    self.changePitchEffect.pitch = 500;
    [self.audioEngine attachNode:self.changePitchEffect];
    
    
    self.equalizer = [[AVAudioUnitEQ alloc] initWithNumberOfBands:10];
    [self.audioEngine attachNode:self.equalizer];
    [self applyEQPop];
    
    [self.audioEngine connect:self.audioPlayerNode to:self.equalizer format:nil];
    [self.audioEngine connect:self.equalizer to:self.changePitchEffect format:nil];
    [self.audioEngine connect:self.changePitchEffect to:self.audioEngine.outputNode format:nil];
    
    [self.audioPlayerNode scheduleFile:self.audioFile atTime:nil completionHandler:nil];
    [self.audioEngine startAndReturnError:nil];
    
    lengthSongSamples = self.audioFile.length;
    AVAudioFormat *songFormat = self.audioFile.processingFormat;
    sampleRateSong = songFormat.sampleRate;
    lengthSongSeconds = lengthSongSamples/sampleRateSong;
    [self.audioPlayerNode play];
}
- (void)applyEQPop{
    NSArray*gains = @[@(0),@(3),@(6),@(5),@(3.3),@(-0.5),@(-0.7),@(-2.6),@(-4),@(-3.8)];
    [self applyEQ:gains type:AVAudioUnitEQFilterTypeParametric];
}
- (void)applyEQ:(NSArray*)gains type:(AVAudioUnitEQFilterType)type{
    NSArray<AVAudioUnitEQFilterParameters *> *bands = self.equalizer.bands;
    NSArray*freqs = @[@(31),@(62),@(125),@(250),@(500),@(1000),@(2000),@(4000),@(8000),@(16000)];
    
    for (NSUInteger i = 0; i < bands.count; i++) {
        AVAudioUnitEQFilterParameters *band = bands[i];
        band.frequency  = [freqs[i] floatValue];
        band.gain       = [gains[i] floatValue];
        band.bypass     = false;
        band.filterType = type;
    }
 
 NSDictionary *requestContents = @{
 @"receipt-data":@"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",
 @"password" : @"cd3197da6fa847aa9733125a125dbd62"
 };
 
}
 */
@end
