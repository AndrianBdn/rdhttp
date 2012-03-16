//
//  RDHTTPAppDelegate.h
//  RDHTTP
//
//  Created by Andrian Budantsov on 26.11.11.
//  Copyright (c) 2011 Readdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDHTTP.h"

@interface RDHTTPAppDelegate : UIResponder <UIApplicationDelegate, RDHTTPThreadProviderAppDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
