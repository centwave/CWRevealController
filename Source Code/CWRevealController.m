//
//  CWRevealController.m
//  CWRevealController
//
//  Created by Ku4n Cheang on 17/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//  Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php



#import "CWRevealController.h"
#import <QuartzCore/QuartzCore.h>

#define REVEAL_OFFSET_EDGE 270
#define REVEAL_OFFSET_FROM_EDGE 50
#define REVEAL_MAX_VELOCITY 1300
#define REVEAL_BUTTON_IMAGE_NAME @"ButtonMenu.png"

@implementation UIView (Reveal)

- (CGFloat)xMinEdge
{
  return self.frame.origin.x;
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/  

- (CGFloat)xMaxEdge
{
  return self.frame.origin.x + self.frame.size.width;
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (CGFloat)width
{
  return self.bounds.size.width;
}
@end

/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/  

@interface CWRevealController ()
@property (nonatomic, retain) UIView                 *rootView;
@property (nonatomic, assign) UIView                 *revealView;
@property (nonatomic) RootViewPosition               previousRootViewPos;
@property (nonatomic) RootViewPosition               currentRootViewPos;
@property (nonatomic, retain) UIViewController       *leftRevealController;
@property (nonatomic, retain) UIViewController       *rightRevealController;
@property (nonatomic, retain) CWNavigationController *navController;
@property (nonatomic, retain) UIPanGestureRecognizer *recognizer;
@property (nonatomic) BOOL                           allowRecognizerMoveLeft;
@property (nonatomic) BOOL                           allowRecognizerMoveRight;

- (void)concealAnimationInDirection:(RootViewPosition)direction withRebounce:(BOOL)flag;
- (void)revealAnimationInDirection:(RootViewPosition)direction withRebounce:(BOOL)flag;
- (void)setUpForNavController:(UIViewController *)controller;

@end

/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/ 

@implementation CWRevealController
@synthesize rootView                  = _rootView;
@synthesize revealView                = _revealView;
@synthesize leftRevealController      = _leftRevealController;
@synthesize rightRevealController     = _rightRevealController;
@synthesize navController             = _navController;
@synthesize previousRootViewPos       = _previousRootViewPos;
@synthesize currentRootViewPos        = _currentRootViewPos;
@synthesize recognizer                = _recognizer;
@synthesize allowRecognizerMoveLeft   = _allowRecognizerMoveLeft;
@synthesize allowRecognizerMoveRight  = _allowRecognizerMoveRight;
@synthesize leftButtonImageName       = _leftButtonImageName;
@synthesize rightButtonImageName      = _rightButtonImageName;

// attributes
@synthesize offsetEdge = _offsetEdge;
@synthesize duration = _duration;
@synthesize rebounce = _rebounce;

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (id)initWithRootController:(UIViewController *)rootViewController 
       rightRevealController:(UIViewController *)rightRevealController
{
  return [self initWithRootController:rootViewController
                 leftRevealController:nil rightRevealController:rightRevealController];
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (id)initWithRootController:(UINavigationController *)rootViewController 
        leftRevealController:(UIViewController *)leftRevealController{
  return [self initWithRootController:rootViewController 
                 leftRevealController:leftRevealController rightRevealController:nil];
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (id)initWithRootController:(UINavigationController *)rootViewController 
        leftRevealController:(UIViewController *)leftRevealController
       rightRevealController:(UIViewController *)rightRevealController {
  self = [super init];
  if (self) {
    self.view.bounds = [UIScreen mainScreen].bounds;
    self.view.backgroundColor = [UIColor whiteColor];
    //button image name
    self.leftButtonImageName = REVEAL_BUTTON_IMAGE_NAME;
    self.rightButtonImageName = REVEAL_BUTTON_IMAGE_NAME;
    
    self.allowRecognizerMoveLeft = NO;
    self.allowRecognizerMoveRight = NO;
    
    self.leftRevealController = leftRevealController;
    self.rightRevealController = rightRevealController;
    self.navController = [[[CWNavigationController alloc] initWithRootViewController:rootViewController] autorelease];
    
    //position initialize
    self.currentRootViewPos = RootViewCenter;
    self.previousRootViewPos = RootViewCenter;
    
    self.offsetEdge = REVEAL_OFFSET_EDGE;
    self.duration = 0.25;
    self.rebounce = YES;

  }
  return self;
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)dealloc {
  _revealView = nil;
  [_leftButtonImageName release];
  [_rightButtonImageName release];
  [_recognizer release];
  [_rootView release];
  [_leftRevealController release];
  [_rightRevealController release];
  [_navController release];
  [super dealloc];
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 
#pragma mark - View lifecycle

- (void)viewDidUnload
{
  [super viewDidUnload];
  self.rootView = nil;
  self.revealView = nil;
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // Return YES for supported orientations
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)setRootView:(UIView *)rootView
{
  if (_rootView.superview){
    [_rootView removeFromSuperview];
    [_rootView release];
  }
  _rootView = [rootView retain];
  
  //add shadow to rootView
  UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:_rootView.bounds];
	_rootView.layer.masksToBounds = NO;
	_rootView.layer.shadowColor = [UIColor blackColor].CGColor;
	_rootView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
	_rootView.layer.shadowOpacity = 1.0f;
	_rootView.layer.shadowRadius = 6.0f;
	_rootView.layer.shadowPath = shadowPath.CGPath;
  
  [self.view addSubview:_rootView];
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)setRevealView:(UIView *)revealView
{
  if (_revealView.superview){
    [_revealView removeFromSuperview];
    [_revealView release];
  }
  
  _revealView = [revealView retain];
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (UIView *)revealView
{
  if (self.currentRootViewPos == RootViewLeft  && _revealView != self.leftRevealController.view){
    _revealView = self.leftRevealController.view;
    _revealView.frame = self.view.bounds;
  }else if (self.currentRootViewPos == RootViewRight && _revealView != self.rightRevealController.view){
    _revealView = self.rightRevealController.view;
    _revealView.frame = self.view.bounds;
  }
  
  return _revealView;
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

-(void)setNavController:(CWNavigationController *)navController
{
  
  // put a pan gesture into the navigation bar
  if (_navController){
    [_navController.view removeFromSuperview];
    [_navController release];
  }
  
  _navController = [navController retain];
  _navController.delegate = self;
  
  //add pan guesture
  self.recognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self 
                                                            action:@selector(panGestureRecognizerDidTouched:)] autorelease];
  [_navController.navigationBar addGestureRecognizer:self.recognizer];
  
  //set up left bar item and right bar items
  [self setUpForNavController:_navController.topViewController];
  
  self.rootView = _navController.view;
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)setCurrentRootViewPos:(RootViewPosition)currentRootViewPos
{
  _currentRootViewPos = currentRootViewPos;
  [self.revealView removeFromSuperview];
  
  if ((currentRootViewPos == RootViewLeft) || (currentRootViewPos == RootViewRight)){
    // if the state of pos is left or right, add the reveal view below the rootview
    [self.view insertSubview:self.revealView belowSubview:self.rootView];
  }
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)setLeftRevealController:(UIViewController<CWRevealDelegate> *)leftRevealController
{
  if (_leftRevealController){
    [_leftRevealController.view removeFromSuperview];
    [_leftRevealController release];
  }
  
  _leftRevealController = [leftRevealController retain];
  
  if (_leftRevealController){
    
    if ([_leftRevealController respondsToSelector:@selector(shouldSetRevealController:)]){
      [_leftRevealController performSelector:@selector(shouldSetRevealController:) withObject:self];
    }

    self.allowRecognizerMoveLeft = YES;
    
    _leftRevealController.wantsFullScreenLayout = YES;
  }

}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)setRightRevealController:(UIViewController<CWRevealDelegate> *)rightRevealController
{
  if (_rightRevealController){
    [_rightRevealController.view removeFromSuperview];
    [_rightRevealController release];
  }
  
  _rightRevealController = [rightRevealController retain];
  
  if (_rightRevealController){
    
    if ([_rightRevealController respondsToSelector:@selector(shouldSetRevealController:)]){
      [_rightRevealController performSelector:@selector(shouldSetRevealController:) withObject:self];
    }
    
    self.allowRecognizerMoveRight = YES;
    
    _rightRevealController.wantsFullScreenLayout = YES;
  }

}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (UIViewController *)rootViewController
{
  return [self.navController.viewControllers objectAtIndex:0];
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (UIViewController *)topViewController
{
  return [self.navController topViewController];
}

/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/ 

#pragma mark -
#pragma mark private method

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)setUpForNavController:(UIViewController *)controller
{
  
  if (self.leftRevealController){
    
    // add a reveal button
    UIBarButtonItem *revealButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:self.leftButtonImageName]
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(triggerRevealAnimation:)];
    // give a tag for identification
    revealButton.tag = ButtonTouchFromLeft;
    
    controller.navigationItem.leftBarButtonItem = revealButton;
    
    [revealButton release]; 
  }
  
  if (self.rightRevealController){
    
    // add a reveal button
    UIBarButtonItem *revealButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:self.rightButtonImageName]
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(triggerRevealAnimation:)];
    // give a tag for identification 
    revealButton.tag = ButtonTouchFromRight;
    
    controller.navigationItem.rightBarButtonItem = revealButton;
    
    [revealButton release];
  }
  
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)ajustPosition
{
  // if it needs to be changed and assign the correct state for it.
  if (self.rootView.xMinEdge < 0){
    self.currentRootViewPos = RootViewRight;
  }else if (self.rootView.xMinEdge > 0){
    self.currentRootViewPos = RootViewLeft;
  }else{
    self.currentRootViewPos = RootViewCenter;
  }
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (BOOL)isStayInPosition{
  BOOL isStay;
  //check whether it was still in a same state if it has been moved.
  switch (self.currentRootViewPos) {
    case RootViewLeft:{
      isStay = (self.rootView.xMinEdge > 0)? YES : NO;
    }
      break;
    case RootViewRight:{
      isStay = (self.rootView.xMinEdge < 0)? YES : NO;
    }
      break;
    default:
      isStay = (CGRectEqualToRect(self.rootView.bounds, self.rootView.frame));
      break;
  }
  return isStay;
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (BOOL)isAtPosition
{
  CGRect targetBounds = CGRectZero;
  // check the rootview frame is at the target position. such as left target frame.
  switch (self.currentRootViewPos) {
    case RootViewCenter:
      targetBounds = self.rootView.bounds;
      break;
    case RootViewLeft:
      targetBounds = CGRectOffset(self.rootView.bounds, REVEAL_OFFSET_EDGE, 0);
      break;
    case RootViewRight:
      targetBounds = CGRectOffset(self.rootView.bounds, - REVEAL_OFFSET_EDGE, 0);
      break;
  }
  
  return CGRectEqualToRect(self.rootView.frame, targetBounds);
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (CGFloat)offsetFromEdge
{
  CGFloat offset = 0.0f;
  
  if (self.currentRootViewPos == RootViewLeft){
    if (self.previousRootViewPos == RootViewCenter){
      offset = self.rootView.xMinEdge;
    }else if (self.previousRootViewPos == RootViewLeft){
      offset = REVEAL_OFFSET_EDGE - self.rootView.xMinEdge;
    }
  }else {
    if (self.previousRootViewPos == RootViewCenter){
      offset = self.rootView.width - self.rootView.xMaxEdge;
    }else if (self.previousRootViewPos == RootViewRight){
      offset = self.rootView.xMaxEdge - (self.rootView.width - REVEAL_OFFSET_EDGE);
    }
  }

  return offset;
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)adjustPreviousPos
{
  CGFloat halfWidth = self.rootView.width / 2;
  
  if (self.previousRootViewPos == RootViewCenter){
    if (self.rootView.xMinEdge > halfWidth){
      self.previousRootViewPos = RootViewLeft;
    }else if (self.rootView.xMaxEdge < halfWidth){
      self.previousRootViewPos = RootViewRight;
    }
  }else if ((self.rootView.xMinEdge < halfWidth) || (self.rootView.xMaxEdge > halfWidth)){
    self.previousRootViewPos = RootViewCenter;
  }
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/  

- (void)panGestureRecognizerDidTouched:(UIPanGestureRecognizer *)gesture{
  
  CGFloat velocity = [gesture velocityInView:self.rootView].x;
  
  if ([gesture state] == UIGestureRecognizerStateBegan){
    if ( self.previousRootViewPos == RootViewCenter){
      self.currentRootViewPos = (velocity >0)? RootViewLeft: RootViewRight;
    }
  }
  
  if ((!self.allowRecognizerMoveLeft && self.currentRootViewPos == RootViewLeft) || 
      (!self.allowRecognizerMoveRight && self.currentRootViewPos == RootViewRight)){
    return;
  }
  
  if ([gesture state] == UIGestureRecognizerStateEnded){
    // if the velocity of gesture recognizer is larger than the maximum velocity, then trigger animation
    if (velocity > REVEAL_MAX_VELOCITY || fabs(velocity) > REVEAL_MAX_VELOCITY){
      
      if ((self.currentRootViewPos == RootViewLeft && velocity > 0) ||
          (self.currentRootViewPos == RootViewRight && velocity < 0))
      {
      
        [self revealAnimationInDirection:self.currentRootViewPos withRebounce:YES];
      
      }else if ((self.currentRootViewPos == RootViewLeft && velocity <= 0) ||
                (self.currentRootViewPos == RootViewRight && velocity >= 0))
      {
      
        [self concealAnimationInDirection:self.currentRootViewPos withRebounce:YES];
      
      }

      
    }else if (![self isAtPosition]){
      
      // if the gesture state is end and its velocity is under limit, then check the distance between the edge
      // of rootView and reveal view.
      if (((self.previousRootViewPos == RootViewCenter) && ([self offsetFromEdge] > REVEAL_OFFSET_FROM_EDGE))
          || ((self.previousRootViewPos != RootViewCenter) && ([self offsetFromEdge] <= REVEAL_OFFSET_FROM_EDGE)))
      {
        [self revealAnimationInDirection:self.currentRootViewPos withRebounce:YES];
      }else if (((self.previousRootViewPos != RootViewCenter) && ([self offsetFromEdge] > REVEAL_OFFSET_FROM_EDGE))
          || ((self.previousRootViewPos == RootViewCenter) && ([self offsetFromEdge] <= REVEAL_OFFSET_FROM_EDGE)))
      {
        [self concealAnimationInDirection:self.currentRootViewPos withRebounce:YES];
      }
    }
    return;
  }
  
  // if the pan is dragging slowly
  CGFloat offset = [gesture translationInView:self.rootView].x;
  
  if (self.currentRootViewPos == RootViewLeft && (self.rootView.xMinEdge >= REVEAL_OFFSET_EDGE) && velocity > 0){
    
    // it reach the target position and change the previous position state.
    self.previousRootViewPos = self.currentRootViewPos;
    // if it has been stay at the target position, then we would not been allowed it to move further.
    self.rootView.frame = CGRectOffset(self.rootView.bounds, REVEAL_OFFSET_EDGE, 0);
  
  }else if (self.currentRootViewPos == RootViewRight && (self.rootView.xMinEdge <= - REVEAL_OFFSET_EDGE) && velocity < 0){
    
    // it reach the target position and change the previous position state.
    self.previousRootViewPos = self.currentRootViewPos;
    // if it has been stay at the target position, then we would not been allowed it to move further.
    self.rootView.frame = CGRectOffset(self.rootView.bounds, - REVEAL_OFFSET_EDGE, 0);
    
  }else {
    
    //if it is move, then changing the frame origin
    if (self.previousRootViewPos == RootViewCenter){
      //start from center case
      if ((!self.allowRecognizerMoveLeft && offset > 0) || (!self.allowRecognizerMoveRight && offset < 0)){
        return;
      }
      
      self.rootView.frame = CGRectOffset(self.rootView.bounds, offset, 0);
      
    }else if (self.previousRootViewPos == RootViewLeft){
      //start from left case
      self.rootView.frame = CGRectOffset(self.rootView.bounds, offset + REVEAL_OFFSET_EDGE, 0);
    }else{
      //start from right case
      self.rootView.frame = CGRectOffset(self.rootView.bounds, offset - REVEAL_OFFSET_EDGE, 0);
    }
    
    // to check whether it needs to be changed its position.
    if (![self isStayInPosition]){
      [self ajustPosition];
    }
    
  }
  
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)concealAnimationInDirection:(RootViewPosition)direction withRebounce:(BOOL)flag
{
  BOOL isLeftButton = (direction == ButtonTouchFromLeft) ? YES : NO;
  CGFloat step = (isLeftButton)? -1 : 1;
  CGFloat rebounce = (self.showRebounceEffect && flag)? 1: 0;
  
  [UIView animateWithDuration:self.duration delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
    self.rootView.frame = CGRectOffset(self.rootView.bounds, 15 * step * rebounce, 0);
  } completion:^(BOOL finished) {
    if (self.showRebounceEffect && flag){
      [UIView animateWithDuration:self.duration / 2 delay:0 options:UIViewAnimationCurveEaseIn animations:^{
        self.rootView.frame = self.rootView.bounds;
      } completion:^(BOOL finished) {
        // change the root view position
        self.previousRootViewPos = RootViewCenter;
        self.currentRootViewPos = RootViewCenter;
      }];
      
    }else {
      // change the root view position
      self.previousRootViewPos = RootViewCenter;
      self.currentRootViewPos = RootViewCenter;
    }
  }];

}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)revealAnimationInDirection:(RootViewPosition)direction withRebounce:(BOOL)flag
{
  BOOL isLeftButton = (direction == ButtonTouchFromLeft) ? YES : NO;
  CGFloat step = (isLeftButton)? 1 : -1;
  CGFloat rebounce = (self.showRebounceEffect && flag)? 1: 0;
  
  // change the root view position
  self.currentRootViewPos = (isLeftButton)? RootViewLeft : RootViewRight;
  self.previousRootViewPos = self.currentRootViewPos;
  
  [UIView animateWithDuration:self.duration delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
    self.rootView.frame = CGRectOffset(self.rootView.bounds, ( self.offsetEdge + 15 * rebounce) * step , 0);
  } completion:^(BOOL finished) {
    if (self.showRebounceEffect && flag){
      [UIView animateWithDuration:self.duration / 2 delay:0 options:UIViewAnimationCurveEaseIn animations:^{
        self.rootView.frame = CGRectOffset(self.rootView.bounds, self.offsetEdge * step, 0);
      } completion:^(BOOL finished) {
        
      }];
    }
  }];
  
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 
     
- (void)triggerRevealAnimation:(id)sender
{
  UIBarButtonItem *button = sender; 
  if (self.currentRootViewPos == RootViewCenter){
    [self revealAnimationInDirection:button.tag withRebounce:NO];
  }else if (self.currentRootViewPos == RootViewRight || self.currentRootViewPos == RootViewLeft){
    [self concealAnimationInDirection:button.tag withRebounce:NO];
  }
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)popToRootViewAndConcealRootView
{
  [self.navController popToRootViewControllerAnimated:NO];
  // release the previous root view controller 
  [self concealAnimationInDirection:self.currentRootViewPos withRebounce:NO];
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)pushToNavController:(UIViewController *)controller animated:(BOOL)animated
{
  [self setUpForNavController:controller];
  
  [self.navController replaceRootViewControllerByViewController:controller shouldShow:NO];
  
  if (animated){
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationCurveEaseIn animations:^{
      self.rootView.frame = CGRectOffset(self.rootView.bounds, self.rootView.width + 30, 0);
    } completion:^(BOOL finished) {
      [self popToRootViewAndConcealRootView];
    }];
  }else{
    [self popToRootViewAndConcealRootView];
  }
  
}

/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/ 

#pragma mark -
#pragma mark UINavigationController delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  if ([viewController conformsToProtocol:@protocol(CWRevealDelegate)]){
    
    // if the left or right viewcontroller need to interact with root controller then 
    // it should set up the connection.
    if ([viewController respondsToSelector:@selector(DidHandleWithRevealController:)]){
       [viewController performSelector:@selector(DidHandleWithRevealController:) withObject:self];
     }
       
    // if it wants to keep right button 
    if ([viewController respondsToSelector:@selector(shouldKeepRightRevealButton)]){
      if ([viewController performSelector:@selector(shouldKeepRightRevealButton)]){
        // add a reveal button
        UIBarButtonItem *revealButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ButtonMenu.png"]
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(triggerRevealAnimation:)];
        // give a tag for identification 
        revealButton.tag = ButtonTouchFromRight;
        
        viewController.navigationItem.rightBarButtonItem= revealButton;
        
        [revealButton release];

      }
    }
  }
  if (viewController.navigationItem.rightBarButtonItem.action == @selector(triggerRevealAnimation:)){
    self.allowRecognizerMoveRight = YES;
  }else{
    self.allowRecognizerMoveRight = NO;
  }
  if (viewController.navigationItem.leftBarButtonItem.action == @selector(triggerRevealAnimation:)){
    self.allowRecognizerMoveLeft = YES;
  }else{
    self.allowRecognizerMoveLeft = NO;
  }
  
  if (!self.allowRecognizerMoveLeft && !self.allowRecognizerMoveRight){
    self.recognizer.enabled = NO;
  }else{
    self.recognizer.enabled = YES;
  }
  
  if (self.currentRootViewPos == RootViewRight){
    self.rootView.frame = CGRectOffset(self.rootView.bounds, self.rootView.width, 0);
  }
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (BOOL)navigationController:(CWNavigationController *)navigationController shouldAnimatedPushViewController:(UIViewController *)controller
{
  if (self.currentRootViewPos == RootViewRight){
    return NO;
  }
  return YES;
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  if (self.currentRootViewPos == RootViewRight){
    [UIView animateWithDuration:0.3 animations:^{
      self.revealView.frame = CGRectOffset(self.revealView.frame, -self.revealView.width, 0);
      self.rootView.frame = self.rootView.bounds;
    } completion:^(BOOL finished) {
      self.revealView.frame = self.revealView.bounds;
      self.previousRootViewPos = RootViewCenter;
      self.currentRootViewPos = RootViewCenter;
    }];
  }
}

@end



