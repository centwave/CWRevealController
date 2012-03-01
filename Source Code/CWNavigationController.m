//
//  CWNavigationController.m
//  CWRevealController
//
//  Created by Ku4n Cheang on 23/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CWNavigationController.h"

@implementation CWNavigationController
@synthesize delegate;

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
  self = [super initWithRootViewController:rootViewController];
  if (self){
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  }
  return self;
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)dealloc {
  self.delegate = nil;
  [super dealloc];
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

-(void)replaceRootViewControllerByViewController:(UIViewController *)viewController shouldShow:(BOOL)show{
  // release all viewcontroller retained by UInavigation Controller except rootview controller
  [self popToRootViewControllerAnimated:NO];
  
  //create a new stack array but start with a new controller
  NSMutableArray *newViewControllers = [[NSMutableArray alloc] initWithObjects:viewController, nil];
  
  //add it to new stack
  [newViewControllers addObjectsFromArray:self.viewControllers];
  
  //replace the stack of navigation controller
  self.viewControllers = [NSArray arrayWithArray:newViewControllers];
  
  [newViewControllers release];
  
  if (show){
    [self popViewControllerAnimated:NO];
  }
}

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{

  if ([self.delegate respondsToSelector:@selector(navigationController:shouldAnimatedPushViewController:)]){
    animated = [self.delegate navigationController:self shouldAnimatedPushViewController:viewController];
  }
  
  [super pushViewController:viewController animated:animated];
}

@end
