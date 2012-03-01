//
//  CWRevealController.h
//  CWRevealController
//
//  Created by Ku4n Cheang on 17/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//  Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php

#import <UIKit/UIKit.h>
#import "CWNavigationController.h"

typedef enum {
  RootViewLeft,
  RootViewRight,
  RootViewCenter
}RootViewPosition;

typedef enum {
  ButtonTouchFromLeft,
  ButtonTouchFromRight
}ButtonTouchPosition;

@protocol CWRevealDelegate;


@interface UIView (Reveal)
- (CGFloat)xMinEdge;
- (CGFloat)xMaxEdge;
- (CGFloat)width;
@end

@interface CWRevealController : UIViewController<CWNavigationControllerDelegate>{
  
@package
  UIView *_rootView;
  UIView *_revealView;
  UIPanGestureRecognizer *_recognizer;
}

//customize attribute
@property (nonatomic) CGFloat                           offsetEdge;
@property (nonatomic) CGFloat                           duration;
@property (nonatomic, getter = showRebounceEffect) BOOL rebounce;
@property (nonatomic, copy) NSString *                  leftButtonImageName;
@property (nonatomic, copy) NSString *                  rightButtonImageName;

@property (nonatomic, readonly) UIViewController *      rootViewController;
@property (nonatomic, readonly) UIViewController *      topViewController;

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (id)initWithRootController:(UIViewController *)rootViewController rightRevealController:(UIViewController *)rightRevealController;

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (id)initWithRootController:(UIViewController *)rootViewController leftRevealController:(UIViewController *)leftRevealController;

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (id)initWithRootController:(UIViewController *)rootViewController leftRevealController:(UIViewController *)leftRevealController
       rightRevealController:(UIViewController *)rightRevealController;

/*-----------------------------------------------------------------------------------------------------------------------------------*/ 

- (void)pushToNavController:(UIViewController *)controller animated:(BOOL)animated;

@end

/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/ 

@protocol CWRevealDelegate <NSObject>

@optional
- (void)DidHandleWithRevealController:(CWRevealController *)revealController;
- (BOOL)shouldKeepRightRevealButton;

@end