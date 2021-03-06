//
//  POSViewController.m
//  POSsystem
//
//  Created by Andrew Charkin on 2/27/13.
//  Copyright (c) 2013 POS. All rights reserved.
//

#import "POSViewController.h"
#import "POSCategoryViewController.h"
#import "POSSubCategoryViewController.h"
#import "POSProductViewController.h"
#import "POSProductDetailViewController.h"
#import "POSGalleryViewController.h"
#import "POSCartViewController.h"
#import "POSConstants.h"
#import "POSAnimations.h"
#import "POSFragmentDelegate.h"
#import "POSTableViewCell.h"

@interface POSViewController ()
@property (strong, nonatomic) POSCategoryViewController * categoryViewController;
@property (strong, nonatomic) POSSubCategoryViewController * subCategoryViewController;
@property (strong, nonatomic) POSProductViewController * productViewController;
@property (strong, nonatomic) POSProductDetailViewController * productDetailViewController;
@property (strong, nonatomic) POSGalleryViewController * galleryViewController;
@property (strong, nonatomic) POSCartViewController * cartViewController;

@property (strong, nonatomic) POSNavigationBar * navigationBar;
@property (nonatomic, strong) UIPanGestureRecognizer* panGestureRecognizer;
@property (nonatomic, strong) UIViewController* panSlidingViewController;

//type: NSMutableDictionary[NSString, NSString]
@property (nonatomic, strong) NSDictionary* nilifyDictionary;

-(UIViewController *) setupViewController: (Class) classToSetup;

-(void) handlePanFrom: (UIPanGestureRecognizer *)recognizer;

@end

@implementation POSViewController

#pragma mark - setters/getters
-(NSDictionary *) nilifyDictionary {
    if(_nilifyDictionary) return _nilifyDictionary;
    _nilifyDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"categoryViewController",NSStringFromClass([POSCategoryViewController class]), @"subCategoryViewController", NSStringFromClass([POSSubCategoryViewController class]), @"productViewController", NSStringFromClass([POSProductViewController class]), @"productDetailViewController", NSStringFromClass([POSProductDetailViewController class]), @"cartViewController", NSStringFromClass([POSCartViewController class]),@"galleryViewController", NSStringFromClass([POSGalleryViewController class]), nil];
    return _nilifyDictionary;
}

-(POSNavigationBar *) navigationBar{
    if(_navigationBar) return _navigationBar;
    _navigationBar = [[POSNavigationBar alloc] initWithDefaultTitle:self.categoryViewController.title];
    _navigationBar.delegate = self;
    
    _navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
    return _navigationBar;
}

@synthesize controllerStack = _controllerStack;
-(NSMutableArray *) controllerStack {
    if(_controllerStack) return _controllerStack;
    _controllerStack = [[NSMutableArray alloc] init];
    return _controllerStack;
}

#pragma mark - setup methods
-(UIViewController *) setupViewController: (Class) classToSetup {
    UIViewController * controller = [[classToSetup alloc] init];
    [self addChildViewController:controller];
    if(self.cartViewController){
        [self.view insertSubview:controller.view belowSubview:self.cartViewController.view];
    } else {
        [self.view addSubview:controller.view];
    }
    
    controller.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self setValue:controller forKey:[self.nilifyDictionary objectForKey:NSStringFromClass(classToSetup)]];
    ((id<POSFragmentDelegate>)controller).coordinatorDelegate = self;
    
    return controller;
}

#pragma mark - nilifier method
-(void) nilifyViewController: (UIViewController *) viewController {
    [viewController removeFromParentViewController];
    [viewController.view removeFromSuperview];
    
    //sets the property to nil
    //don't know if this will actually call arc's dealloc
    if(viewController)
        [self setValue:nil forKey:[self.nilifyDictionary objectForKey:NSStringFromClass([viewController class])]];
}

#pragma mark - view methods
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupViewController:[POSCategoryViewController class]];
    self.categoryViewController.title = @"Categories";
    
    [self.view addSubview:self.navigationBar];
    [self addToControllerStack:self.categoryViewController];

    ADD_CONSTRAINT(self.view, self.categoryViewController.view, NSLayoutAttributeLeading, NSLayoutRelationEqual, self.view, NSLayoutAttributeLeading, 1.f, 0);
    ADD_CONSTRAINT(self.view, self.categoryViewController.view, NSLayoutAttributeTop, NSLayoutRelationEqual, self.navigationBar, NSLayoutAttributeBottom, 1.f, 0);
    ADD_CONSTRAINT(self.view, self.categoryViewController.view, NSLayoutAttributeWidth, NSLayoutRelationEqual, self.view, NSLayoutAttributeWidth, 1.f, 0);
    ADD_CONSTRAINT(self.view, self.categoryViewController.view, NSLayoutAttributeBottom, NSLayoutRelationEqual, self.view, NSLayoutAttributeBottom, 1.f, 0);

    ADD_CONSTRAINT(self.view, self.navigationBar, NSLayoutAttributeLeading, NSLayoutRelationEqual, self.view, NSLayoutAttributeLeading, 1.f, 0.f);
    ADD_CONSTRAINT(self.view, self.navigationBar, NSLayoutAttributeTop, NSLayoutRelationEqual, self.view, NSLayoutAttributeTop, 1.f, 0.f);
    ADD_CONSTRAINT(self.view, self.navigationBar, NSLayoutAttributeWidth, NSLayoutRelationEqual, self.view, NSLayoutAttributeWidth, 1.f, 0.f);
    ADD_CONSTRAINT(self.view, self.navigationBar, NSLayoutAttributeHeight, NSLayoutRelationEqual, self.navigationBar, NSLayoutAttributeHeight, 0.f, NAVIGATION_BAR_HEIGHT);
}

- (void) viewDidAppear:(BOOL)animated {
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [self.view addGestureRecognizer:self.panGestureRecognizer];
}

-(void) handlePanFrom: (UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:recognizer.view];
    CGPoint velocity = [recognizer velocityInView:recognizer.view];
    
    //sliding from right to left is ignored
    if(translation.x <= 0) return;
    
    UIViewController *currentController = [self getViewControllerFromStackAtIndex: [self.controllerStack count] - 1 ];
    
    if(!currentController || [currentController isKindOfClass:[POSCategoryViewController class]]) {
        return;
    } else if ([currentController isKindOfClass:[POSSubCategoryViewController class]]) {
        if([self.categoryViewController parentViewController] == nil){
            [self setupViewController:[POSCategoryViewController class]];
            self.categoryViewController.title = @"Categories";
        }
        self.panSlidingViewController = self.categoryViewController;
        
        CGFloat width = 1.f;
        if(self.cartViewController){
            width = .75f;
        }
        ADD_CONSTRAINT(self.view, self.panSlidingViewController.view, NSLayoutAttributeTrailing, NSLayoutRelationEqual, currentController.view, NSLayoutAttributeLeading, 1.f, 0);
        ADD_CONSTRAINT(self.view, self.panSlidingViewController.view, NSLayoutAttributeTop, NSLayoutRelationEqual, currentController.view, NSLayoutAttributeTop, 1.f, 0);
        ADD_CONSTRAINT(self.view, self.panSlidingViewController.view, NSLayoutAttributeWidth, NSLayoutRelationEqual, self.view, NSLayoutAttributeWidth, width, 0);
        ADD_CONSTRAINT(self.view, self.panSlidingViewController.view, NSLayoutAttributeBottom, NSLayoutRelationEqual, currentController.view, NSLayoutAttributeBottom, 1.f, 0);
        [self.view layoutIfNeeded];

    } else if ([currentController isKindOfClass:[POSProductViewController class]]){
        if([self.subCategoryViewController parentViewController] == nil){
            [self setupViewController:[POSSubCategoryViewController class]];
            self.subCategoryViewController.title = @"Sub Categories";
        }
        self.panSlidingViewController = self.subCategoryViewController;
        
        CGFloat width = 1.f;
        if(self.cartViewController){
            width = .75f;
        }
        
        ADD_CONSTRAINT(self.view, self.panSlidingViewController.view, NSLayoutAttributeTrailing, NSLayoutRelationEqual, currentController.view, NSLayoutAttributeLeading, 1.f, 0);
        ADD_CONSTRAINT(self.view, self.panSlidingViewController.view, NSLayoutAttributeTop, NSLayoutRelationEqual, currentController.view, NSLayoutAttributeTop, 1.f, 0);
        ADD_CONSTRAINT(self.view, self.panSlidingViewController.view, NSLayoutAttributeWidth, NSLayoutRelationEqual, self.view, NSLayoutAttributeWidth, width, 0);
        ADD_CONSTRAINT(self.view, self.panSlidingViewController.view, NSLayoutAttributeBottom, NSLayoutRelationEqual, currentController.view, NSLayoutAttributeBottom, 1.f, 0);
        [self.view layoutIfNeeded];
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged && currentController){
        for (NSLayoutConstraint *c in self.view.constraints) {
            if(c.firstItem == currentController.view && c.firstAttribute == NSLayoutAttributeLeading){
                [self.view removeConstraint:c];
            }
        }
        ADD_CONSTRAINT(self.view, currentController.view, NSLayoutAttributeLeading, NSLayoutRelationEqual, self.view, NSLayoutAttributeLeading, 1.f, translation.x);
    } else if (recognizer.state == UIGestureRecognizerStateEnded && currentController){
        CGFloat width = self.view.frame.size.width;
        
        //if past the midpoint, go back in stack
        if(ABS(translation.x) > width/2 || velocity.x > 1000.0f){
            [self.navigationBar popControllerPreAnimation:nil];
            [self.view layoutIfNeeded];
            
            [UIView animateWithDuration:.4
                                  delay:0
                                options: UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 for (NSLayoutConstraint *c in self.view.constraints) {
                                     if(c.firstItem == currentController.view && c.firstAttribute == NSLayoutAttributeLeading){
                                         [self.view removeConstraint:c];
                                     }
                                 }
                                 
                                 [self.navigationBar popControllerDuringAnimation];
                                 
                                 ADD_CONSTRAINT(self.view, self.panSlidingViewController.view, NSLayoutAttributeLeading, NSLayoutRelationEqual, self.view, NSLayoutAttributeLeading, 1.f, 0.f);
                                 [self.view layoutIfNeeded];
                                 
                                 
                             } completion:^(BOOL finished) {
                                 for (NSLayoutConstraint *c in self.view.constraints) {
                                     if(c.firstItem == self.panSlidingViewController.view) [self.view removeConstraint:c];
                                 }
                                 CGFloat width = 1.f;
                                 if(self.cartViewController){
                                     width = .75f;
                                 }
                                 
                                 ADD_CONSTRAINT(self.view, self.panSlidingViewController.view, NSLayoutAttributeLeading, NSLayoutRelationEqual, self.view, NSLayoutAttributeLeading, 1.f, 0.f);
                                 ADD_CONSTRAINT(self.view, self.panSlidingViewController.view, NSLayoutAttributeWidth, NSLayoutRelationEqual, self.view, NSLayoutAttributeWidth, width, 0.f);
                                 ADD_CONSTRAINT(self.view, self.panSlidingViewController.view, NSLayoutAttributeTop, NSLayoutRelationEqual, self.navigationBar, NSLayoutAttributeBottom, 1.f, 0.f);
                                 ADD_CONSTRAINT(self.view, self.panSlidingViewController.view, NSLayoutAttributeBottom, NSLayoutRelationEqual, self.view, NSLayoutAttributeBottom, 1.f, 0.f);
                                 
                                 [self nilifyViewController:currentController];
                                 [self.navigationBar popControllerPostAnimation];
                                 
                                 [self nilifyViewController:self.productDetailViewController];
                                 
                                 [self.controllerStack removeObjectAtIndex:self.controllerStack.count -1];
                             }];

        } else {
            //slide failed, return to original
            [UIView animateWithDuration:.4
                                  delay:0
                                options: UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 for (NSLayoutConstraint *c in self.view.constraints) {
                                     if(c.firstItem == currentController.view && c.firstAttribute == NSLayoutAttributeLeading) [self.view removeConstraint:c];
                                 }
                                 
                                 ADD_CONSTRAINT(self.view, currentController.view, NSLayoutAttributeLeading, NSLayoutRelationEqual, self.view, NSLayoutAttributeLeading, 1.f, 0.f);
                                 [self.view layoutIfNeeded];

                             } completion:^(BOOL finished) {
                                 [self nilifyViewController:self.panSlidingViewController];
                             }];
        }
    }

}

#pragma mark - POSCoordinatorDelegate
-(void) categoryClicked:(NSString *) title {
    [self setupViewController:[POSSubCategoryViewController class]];
    CGFloat width = 1.f;
    if(self.cartViewController){
        width = .75f;
    }
    
    [POSAnimations animate:[NSArray arrayWithObjects:self.subCategoryViewController.view, nil]
           withPercentages:[NSArray arrayWithObjects:[NSNumber numberWithFloat:width], nil]
                    inView:self.view
   appearRightToLeftofView:self.categoryViewController.view
    during:^{
        [self.navigationBar pushControllerDuringAnimation];
    } after:^{
        ADD_CONSTRAINT(self.view, self.subCategoryViewController.view, NSLayoutAttributeTop, NSLayoutRelationEqual, self.navigationBar, NSLayoutAttributeBottom, 1.f, 0);
        ADD_CONSTRAINT(self.view, self.subCategoryViewController.view, NSLayoutAttributeBottom, NSLayoutRelationEqual, self.view, NSLayoutAttributeBottom, 1.f, 0);
        [self.navigationBar pushControllerPostAnimation:title];
        [self nilifyViewController:self.categoryViewController];
        [self addToControllerStack:self.subCategoryViewController];
    }];
}

-(void) subCategoryClicked:(NSString *) title {
    [self setupViewController:[POSProductViewController class]];
    [self setupViewController:[POSProductDetailViewController class]];
    CGFloat width = .75f;
    if(self.cartViewController){
        width = .5f;
    }
    
    [POSAnimations animate:[NSArray arrayWithObjects:self.productViewController.view, self.productDetailViewController.view, nil]
           withPercentages:[NSArray arrayWithObjects:[NSNumber numberWithFloat:.25f], [NSNumber numberWithFloat:width], nil]
                    inView:self.view
   appearRightToLeftofView:self.subCategoryViewController.view
    during:^{
        [self.navigationBar pushControllerDuringAnimation];
    } after:^{
        ADD_CONSTRAINT(self.view, self.productViewController.view, NSLayoutAttributeTop, NSLayoutRelationEqual, self.navigationBar, NSLayoutAttributeBottom, 1.f, 0);
        ADD_CONSTRAINT(self.view, self.productViewController.view, NSLayoutAttributeBottom, NSLayoutRelationEqual, self.view, NSLayoutAttributeBottom, 1.f, 0);
        
        [self.navigationBar pushControllerPostAnimation:title];
        
        [self nilifyViewController:self.subCategoryViewController];
        
        [self addToControllerStack:self.productViewController];
    }];
}

-(void) detailImageClicked: (UIButton *) button {
    self.galleryViewController = [[POSGalleryViewController alloc] init];
    [self.view addSubview:self.galleryViewController.view];
    [self addChildViewController:self.galleryViewController];
    self.galleryViewController.coordinatorDelegate = self;
    self.galleryViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    ADD_CONSTRAINT(self.view, self.galleryViewController.view, NSLayoutAttributeLeading, NSLayoutRelationEqual, self.productDetailViewController.imageView, NSLayoutAttributeLeading, 1.f, 0);
    ADD_CONSTRAINT(self.view, self.galleryViewController.view, NSLayoutAttributeTop, NSLayoutRelationEqual, self.productDetailViewController.imageView, NSLayoutAttributeTop, 1.f, 0);
    ADD_CONSTRAINT(self.view, self.galleryViewController.view, NSLayoutAttributeBottom, NSLayoutRelationEqual, self.productDetailViewController.imageView, NSLayoutAttributeBottom, 1.f, 0);
    ADD_CONSTRAINT(self.view, self.galleryViewController.view, NSLayoutAttributeTrailing, NSLayoutRelationEqual, self.productDetailViewController.imageView, NSLayoutAttributeTrailing, 1.f, 0);
    [self.view layoutIfNeeded];
    
    [UIView animateWithDuration:.4f
                          delay:0
                        options: UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         for (NSLayoutConstraint *c in self.view.constraints) {
                             if(c.firstItem == self.galleryViewController.view) [self.view removeConstraint:c];
                         }
                         
                         ADD_CONSTRAINT(self.view, self.galleryViewController.view, NSLayoutAttributeTop, NSLayoutRelationEqual, self.view, NSLayoutAttributeTop, 1.f, 0);
                         ADD_CONSTRAINT(self.view, self.galleryViewController.view, NSLayoutAttributeBottom, NSLayoutRelationEqual, self.view, NSLayoutAttributeBottom, 1.f, 0);
                         ADD_CONSTRAINT(self.view, self.galleryViewController.view, NSLayoutAttributeTrailing, NSLayoutRelationEqual, self.view, NSLayoutAttributeTrailing, 1.f, 0);
                         ADD_CONSTRAINT(self.view, self.galleryViewController.view, NSLayoutAttributeLeading, NSLayoutRelationEqual, self.view, NSLayoutAttributeLeading, 1.f, 0);
                         
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         [self.view removeGestureRecognizer:self.panGestureRecognizer];
                     }];
}

-(void) detailImageCloseClicked: (UIButton *) button {
    [UIView animateWithDuration:.4f
                          delay:0
                        options: UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         for (NSLayoutConstraint *c in self.view.constraints) {
                             if(c.firstItem == self.galleryViewController.view) [self.view removeConstraint:c];
                         }
                         
                         ADD_CONSTRAINT(self.view, self.galleryViewController.view, NSLayoutAttributeLeading, NSLayoutRelationEqual, self.productDetailViewController.imageView, NSLayoutAttributeLeading, 1.f, 0);
                         ADD_CONSTRAINT(self.view, self.galleryViewController.view, NSLayoutAttributeTop, NSLayoutRelationEqual, self.productDetailViewController.imageView, NSLayoutAttributeTop, 1.f, 0);
                         ADD_CONSTRAINT(self.view, self.galleryViewController.view, NSLayoutAttributeBottom, NSLayoutRelationEqual, self.productDetailViewController.imageView, NSLayoutAttributeBottom, 1.f, 0);
                         ADD_CONSTRAINT(self.view, self.galleryViewController.view, NSLayoutAttributeTrailing, NSLayoutRelationEqual, self.productDetailViewController.imageView, NSLayoutAttributeTrailing, 1.f, 0);
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         [self.galleryViewController removeFromParentViewController];
                         [self.galleryViewController.view removeFromSuperview];
                         
                         self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
                         [self.view addGestureRecognizer:self.panGestureRecognizer];
                     }];
    
}

#pragma mark - POSNavigationBarDelegate
-(void) addToControllerStack: (UIViewController *) controller {
    [self.controllerStack addObject:NSStringFromClass([controller class])];
}

-(UIViewController *) getViewControllerFromStackAtIndex: (NSUInteger) index {
    NSString *className = [self.controllerStack objectAtIndex:index];
    
    if([className isEqualToString:NSStringFromClass([POSCategoryViewController class])] && [self.categoryViewController parentViewController]){
        return self.categoryViewController;
    } else if([className isEqualToString:NSStringFromClass([POSSubCategoryViewController class])] && [self.subCategoryViewController parentViewController]) {
        return self.subCategoryViewController;
    } else if([className isEqualToString:NSStringFromClass([POSProductViewController class])] && [self.productViewController parentViewController]) {
        return self.productViewController;
    } else if([className isEqualToString:NSStringFromClass([POSProductDetailViewController class])] && [self.productDetailViewController parentViewController]) {
        return self.productDetailViewController;
    } else {
        return [self setupViewController: NSClassFromString(className)];
    }
}

-(void) navigationBarPopViewController: (UIButton *) button {
    NSInteger controllerIndex = [self.navigationBar popControllerPreAnimation: button];
    UIViewController *controllerToLoad = [self getViewControllerFromStackAtIndex: controllerIndex ];
    UIViewController *currentController = [self getViewControllerFromStackAtIndex: [self.controllerStack count] - 1 ];
    CGFloat width = 1.f;
    if(self.cartViewController){
        width = .75f;
    }
    
    [POSAnimations animate:[NSArray arrayWithObjects:controllerToLoad.view, nil]
           withPercentages:[NSArray arrayWithObjects:[NSNumber numberWithFloat:width], nil]
                    inView:self.view
   appearLefttoRightofView:currentController.view
                    during:^{
                        [self.navigationBar popControllerDuringAnimation];
                    } after:^{
                        ADD_CONSTRAINT(self.view, controllerToLoad.view, NSLayoutAttributeTop, NSLayoutRelationEqual, self.navigationBar, NSLayoutAttributeBottom, 1.f, 0);
                        ADD_CONSTRAINT(self.view, controllerToLoad.view, NSLayoutAttributeBottom, NSLayoutRelationEqual, self.view, NSLayoutAttributeBottom, 1.f, 0);
                        [self.navigationBar popControllerPostAnimation];
                        
                        for(NSUInteger i=controllerIndex+1; i<self.controllerStack.count; i++){
                            [self nilifyViewController:[self getViewControllerFromStackAtIndex:i]];
                        }
                        [self.controllerStack removeObjectsInRange:NSMakeRange(controllerIndex+1, self.controllerStack.count-controllerIndex-1)];
                        [self nilifyViewController: self.productDetailViewController];
                    }];
}

-(void) cartButtonClicked: (UIButton *) button {
    button.selected = !button.selected;
    self.navigationBar.userButton.selected = NO;
    self.navigationBar.scannerButton.selected = NO;
    
    if([button isSelected]) {
        [self setupViewController:[POSCartViewController class]];
        self.cartViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
        ADD_CONSTRAINT(self.view, self.cartViewController.view, NSLayoutAttributeTop, NSLayoutRelationEqual, self.navigationBar, NSLayoutAttributeBottom, 1.f, 0.f);
        ADD_CONSTRAINT(self.view, self.cartViewController.view, NSLayoutAttributeLeading, NSLayoutRelationEqual, self.view, NSLayoutAttributeTrailing, 1.f, 0.f);
        ADD_CONSTRAINT(self.view, self.cartViewController.view, NSLayoutAttributeWidth, NSLayoutRelationEqual, self.view, NSLayoutAttributeWidth, .25f, 0.f);
        ADD_CONSTRAINT(self.view, self.cartViewController.view, NSLayoutAttributeBottom, NSLayoutRelationEqual, self.view, NSLayoutAttributeBottom, 1.f, 0.f);
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:.4f
                              delay:0.f
                            options:UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             UIView *shiftingView;
                             CGFloat shiftingViewWidth;
                             for(NSLayoutConstraint *constraint in self.view.constraints){
                                 if(constraint.firstItem == self.cartViewController.view)
                                     [self.view removeConstraint:constraint];
                                 if(constraint.firstItem == self.categoryViewController.view && constraint.firstAttribute == NSLayoutAttributeWidth){
                                     shiftingView = self.categoryViewController.view;
                                     shiftingViewWidth = constraint.multiplier;
                                     [self.view removeConstraint:constraint];
                                 } else if (constraint.firstItem == self.subCategoryViewController.view && constraint.firstAttribute == NSLayoutAttributeWidth) {
                                     shiftingView = self.subCategoryViewController.view;
                                     shiftingViewWidth = constraint.multiplier;
                                     [self.view removeConstraint:constraint];
                                 } else if (constraint.firstItem == self.productDetailViewController.view && constraint.firstAttribute == NSLayoutAttributeWidth) {
                                     shiftingView = self.productDetailViewController.view;
                                     shiftingViewWidth = constraint.multiplier;
                                     [self.view removeConstraint:constraint];
                                 }
                             }
         
                             ADD_CONSTRAINT(self.view, self.cartViewController.view, NSLayoutAttributeTop, NSLayoutRelationEqual, self.navigationBar, NSLayoutAttributeBottom, 1.f, 0.f);
                             ADD_CONSTRAINT(self.view, self.cartViewController.view, NSLayoutAttributeTrailing, NSLayoutRelationEqual, self.view, NSLayoutAttributeTrailing, 1.f, 0.f);
                             ADD_CONSTRAINT(self.view, self.cartViewController.view, NSLayoutAttributeWidth, NSLayoutRelationEqual, self.view, NSLayoutAttributeWidth, .25f, 0.f);
                             ADD_CONSTRAINT(self.view, self.cartViewController.view, NSLayoutAttributeBottom, NSLayoutRelationEqual, self.view, NSLayoutAttributeBottom, 1.f, 0.f);
                             ADD_CONSTRAINT(self.view, shiftingView, NSLayoutAttributeWidth, NSLayoutRelationEqual, self.view, NSLayoutAttributeWidth, shiftingViewWidth-.25f, 0.f);
                             
                             if(self.categoryViewController)[self.categoryViewController.collectionView.collectionViewLayout invalidateLayout];
                             if(self.subCategoryViewController)[self.subCategoryViewController.collectionView.collectionViewLayout invalidateLayout];
                             [self.view layoutIfNeeded];
                         } completion:^(BOOL finished){}];
    } else {        
        [UIView animateWithDuration:.4f
                              delay:0.f
                            options:UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             UIView *boundView;
                             CGFloat boundViewWidthMultiplier;
                             for(NSLayoutConstraint *constraint in self.view.constraints){
                                 if(constraint.firstItem == self.cartViewController.view){
                                     [self.view removeConstraint:constraint];
                                 }
                                 if(constraint.firstItem == self.categoryViewController.view && constraint.firstAttribute == NSLayoutAttributeWidth){
                                     boundView = constraint.firstItem;
                                     boundViewWidthMultiplier = constraint.multiplier;
                                     [self.view removeConstraint:constraint];
                                 } else if (constraint.firstItem == self.subCategoryViewController.view && constraint.firstAttribute == NSLayoutAttributeWidth) {
                                     boundView = constraint.firstItem;
                                     boundViewWidthMultiplier = constraint.multiplier;
                                     [self.view removeConstraint:constraint];
                                 } else if (constraint.firstItem == self.productDetailViewController.view && constraint.firstAttribute == NSLayoutAttributeWidth) {
                                     boundView = constraint.firstItem;
                                     boundViewWidthMultiplier = constraint.multiplier;
                                     [self.view removeConstraint:constraint];
                                 }
                             }
                             
                             ADD_CONSTRAINT(self.view, self.cartViewController.view, NSLayoutAttributeTop, NSLayoutRelationEqual, self.navigationBar, NSLayoutAttributeBottom, 1.f, 0.f);
                             ADD_CONSTRAINT(self.view, self.cartViewController.view, NSLayoutAttributeLeading, NSLayoutRelationEqual, self.view, NSLayoutAttributeTrailing, 1.f, 0.f);
                             ADD_CONSTRAINT(self.view, self.cartViewController.view, NSLayoutAttributeWidth, NSLayoutRelationEqual, self.view, NSLayoutAttributeWidth, .25f, 0.f);
                             ADD_CONSTRAINT(self.view, self.cartViewController.view, NSLayoutAttributeBottom, NSLayoutRelationEqual, self.view, NSLayoutAttributeBottom, 1.f, 0.f);
                             
                             ADD_CONSTRAINT(self.view, boundView, NSLayoutAttributeWidth, NSLayoutRelationEqual, self.view, NSLayoutAttributeWidth, boundViewWidthMultiplier+.25, 0.f);
                             
                             if(self.categoryViewController) [self.categoryViewController.collectionView.collectionViewLayout invalidateLayout];
                             if(self.subCategoryViewController) [self.subCategoryViewController.collectionView.collectionViewLayout invalidateLayout];
                             [self.view layoutIfNeeded];
                         } completion:^(BOOL finished){
                             [self nilifyViewController:self.cartViewController];
                         }];
    }
}

-(void) userButtonClicked: (UIButton *) button {
    button.selected = !button.selected;
    self.navigationBar.cartButton.selected = NO;
    self.navigationBar.scannerButton.selected = NO;
}

-(void) scannerButtonClicked: (UIButton *) button {
    button.selected = !button.selected;
    self.navigationBar.userButton.selected = NO;
    self.navigationBar.cartButton.selected = NO;
}

@end
