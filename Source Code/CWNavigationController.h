//
//  CWNavigationController.h
//  CWRevealController
//
//  Created by Ku4n Cheang on 23/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CWNavigationController;

@protocol CWNavigationControllerDelegate <UINavigationControllerDelegate>
@optional
- (BOOL)navigationController:(CWNavigationController *)navigationController shouldAnimatedPushViewController:(UIViewController *)controller;
@end

@interface CWNavigationController : UINavigationController{
}

@property (nonatomic, assign) id<CWNavigationControllerDelegate> delegate;

-(void)replaceRootViewControllerByViewController:(UIViewController *)viewController  shouldShow:(BOOL)show;
@end

