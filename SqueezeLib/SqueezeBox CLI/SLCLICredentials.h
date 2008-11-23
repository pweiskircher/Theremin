//
//  SLCLICredentials.h
//  SqueezeLib
//
//  Created by Patrik Weiskircher on 14.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#if !defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE 
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif


@interface SLCLICredentials : NSObject {
	NSString *_username;
	NSString *_password;
}
+ (id) cliCredentialsWithUsername:(NSString *)aUsername andPassword:(NSString *)aPassword;
- (id) initWithUsername:(NSString *)aUsername andPassword:(NSString *)aPassword;

- (NSString *) username;
- (NSString *) password;
@end
