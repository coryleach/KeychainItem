//
//  KeychainItem.h
//  NekoLogic
//
//  Created by Cory Leach on 9/2/10.
//  Copyright 2010 Cory R. Leach. All rights reserved.
//
//	The body of this class largely a copy-paste of code from the
//  Apple developer resources. (KeychainWrappper from Keychain Services Tasks for iOS)
//
//	The basic idea is to store a 'secret' string (aka password) for a given 'service' and 'username'
//	The 'Service' and 'Username' behave as if a dictionary key for the secret.
//
//  ** MAY NOT BE COMPATIBLE WITH VERSIONS OF iOS Simulator OLDER THAN 4.0 **
//
//	Requires: Security.framework
//

#import <Foundation/Foundation.h>

@interface KeychainItem : NSObject {

	NSMutableDictionary* keychainDictionary;
	NSMutableDictionary* genericPasswordQuery;
	
}

@property (retain) NSMutableDictionary* keychainDictionary;
@property (nonatomic,retain) NSString* secret;
@property (nonatomic,retain) NSString* account;
@property (nonatomic,retain) NSString* service;

+ (KeychainItem*) keychainItemWithAccoundName:(NSString*)account serviceName:(NSString*)service;

//KeychainItem must be init with an account and service name. 
- (id) initWithAccountName:(NSString*)account serviceName:(NSString*)service;

//Resets the KeychainItem and deletes data from actual OS keychain item
- (void)resetKeychainItem;

@end
