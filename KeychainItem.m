//
//  KeychainItem.m
//  NekoLogic
//
//  Created by Cory Leach on 9/2/10.
//  Copyright 2010 Cory R. Leach. All rights reserved.
//

#import "KeychainItem.h"

@interface KeychainItem (PrivateMethods)

- (void)writeToKeychain;
- (NSMutableDictionary*) dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary*) secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;

@end

@implementation KeychainItem

@synthesize keychainDictionary;

- (id) init {
	NSAssert(NO,@"Must init KeychainItem with account and service name");
	return nil;
	
}

- (id) initWithAccountName:(NSString*)account serviceName:(NSString*)service {

	if ( (self = [super init]) == nil ) {
		return self;
	}
	
	//Init
	OSStatus keychainErr = noErr;
	// Set up the keychain search dictionary:
	genericPasswordQuery = [[NSMutableDictionary alloc] init];
	// This keychain item is a generic password.
	[genericPasswordQuery setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	[genericPasswordQuery setObject:account forKey:(id)kSecAttrAccount];
	[genericPasswordQuery setObject:service forKey:(id)kSecAttrService];
	
	// Return the attributes of the first match only:
	[genericPasswordQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	
	// Return the attributes of the keychain item (the password is
	//  acquired in the secItemFormatToDictionary: method):
	[genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
	
	//Initialize the dictionary used to hold return data from the keychain:
	NSMutableDictionary *outDictionary = nil;
	
	// If the keychain item exists, return the attributes of the item: 
	keychainErr = SecItemCopyMatching((CFDictionaryRef)genericPasswordQuery,(CFTypeRef *)&outDictionary);
	
	if (keychainErr == noErr) {
		
		// Convert the data dictionary into the format used by the view controller:
		self.keychainDictionary = [self secItemFormatToDictionary:outDictionary];
		
	} else if (keychainErr == errSecItemNotFound) {
				
		// Put default values into the keychain if no matching
		// keychain item is found:
		self.keychainDictionary = nil;
		[self resetKeychainItem];
				
	} else {
				
		// Any other error is unexpected.
		NSAssert(NO, @"Serious error.\n");
		
	}
	
	[outDictionary release];
	
	
	return self;
	
}

- (void) dealloc {
	
	self.keychainDictionary = nil;
	[genericPasswordQuery release];
	genericPasswordQuery = nil;
	
	[super dealloc];
	
}

+ (KeychainItem*) keychainItemWithAccoundName:(NSString*)anAccount serviceName:(NSString*)aService {
	
	return [[[KeychainItem alloc] initWithAccountName:anAccount serviceName:aService] autorelease];
	
}

- (void) setSecret:(NSString*)newSecret {

	if ( newSecret == nil ) {
		[keychainDictionary removeObjectForKey:(id)kSecValueData];
		//Delete Keychain Data
		[self resetKeychainItem];
		return;
	}
	
	id oldSecret = [keychainDictionary objectForKey:(id)kSecValueData];
	
	if ( ![oldSecret isEqual:newSecret] ) {
		[keychainDictionary setObject:newSecret forKey:(id)kSecValueData];
		[self writeToKeychain];
	}
	
}

- (NSString*) secret {

	return [keychainDictionary objectForKey:(id)kSecValueData];

}

- (void) setAccount:(NSString*)newAccount {
	
	if ( newAccount == nil ) {
		NSLog(@"Attempted to set account to nil!");
		return;
	}
	
	NSString* oldAccount = [keychainDictionary objectForKey:(id)kSecAttrAccount];
	
	if ( ![oldAccount isEqual:newAccount] ) {
		[keychainDictionary setObject:newAccount forKey:(id)kSecAttrAccount];
		[self writeToKeychain];
	}
	
}

- (NSString*) account {
	
	return [keychainDictionary objectForKey:(id)kSecAttrAccount];
	
}

- (void) setService:(NSString*)newService {
	
	if ( newService == nil ) {
		NSLog(@"Attempted to set service to nil!");
		return;
	}
	
	NSString* oldService = [keychainDictionary objectForKey:(id)kSecAttrService];
	
	if ( ![oldService isEqual:newService] ) {
		[keychainDictionary setObject:newService forKey:(id)kSecAttrService];
		[self writeToKeychain];
	}
	
}

- (NSString*) service {
	
	return [keychainDictionary objectForKey:(id)kSecAttrService];
	
}


- (void)writeToKeychain {
	
	if ( self.secret == nil ) {
		//There is no secret to write to the keychain
		return;
	}
	
    NSDictionary *attributes = NULL;
    NSMutableDictionary *updateItem = NULL;
	
	OSStatus error = SecItemCopyMatching((CFDictionaryRef)genericPasswordQuery,(CFTypeRef *)&attributes);
	
    // If the keychain item already exists, modify it:
    if ( error == noErr) {
		
        // First, get the attributes returned from the keychain and add them to the
        // dictionary that controls the update:
        updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
		
        // Second, get the class value from the generic password query dictionary and
        // add it to the updateItem dictionary:
        [updateItem setObject:[genericPasswordQuery objectForKey:(id)kSecClass] forKey:(id)kSecClass];
		
        // Finally, set up the dictionary that contains new values for the attributes:
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:keychainDictionary];
        //Remove the class--it's not a keychain attribute:
        [tempCheck removeObjectForKey:(id)kSecClass];
		
		// You can update only a single keychain item at a time.
		error = SecItemUpdate((CFDictionaryRef)updateItem,(CFDictionaryRef)tempCheck);
		
        NSAssert(error == noErr,@"Couldn't update the Keychain Item." );
		
	} else {
		
		// No previous item found; add the new item.		
		NSMutableDictionary* temp = [self dictionaryToSecItemFormat:keychainDictionary];
		
		//Creating a new record so set a label, just make it equal to service
		[temp setObject:[temp objectForKey:(id)kSecAttrService] forKey:(id)kSecAttrLabel];
		
		// No pointer to the newly-added items is needed, so pass NULL for the second parameter:
		error = SecItemAdd((CFDictionaryRef)temp,NULL);
		
		if ( error != noErr ) {
			NSAssert(NO, @"Couldn't add the Keychain Item." );
		}
		
	}
	
}

// Reset the values in the keychain item, or create a new item if it
// doesn't already exist:
- (void)resetKeychainItem {
	
    if ( !keychainDictionary ) {
		
		//Allocate the keychainDictionary dictionary if it doesn't exist yet.
        keychainDictionary = [[NSMutableDictionary alloc] init];
		
	} else if ( keychainDictionary ) {
		
		// Format the data in the keychainDictionary dictionary into the format needed for a query
		//  and put it into tmpDictionary:
        NSMutableDictionary *tmpDictionary = [self dictionaryToSecItemFormat:keychainDictionary];
		
		// Delete the keychain item in preparation for resetting the values:
        NSAssert(SecItemDelete((CFDictionaryRef)tmpDictionary) == noErr,@"Problem deleting current keychain item." );
		
	}
	
    // Default generic data for Keychain Item:
	[keychainDictionary removeAllObjects];
	[keychainDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    [keychainDictionary setObject:[genericPasswordQuery objectForKey:(id)kSecAttrAccount] forKey:(id)kSecAttrAccount];
    [keychainDictionary setObject:[genericPasswordQuery objectForKey:(id)kSecAttrService] forKey:(id)kSecAttrService];
	
}

// Implement the dictionaryToSecItemFormat: method, which takes the attributes that
//   you want to add to the keychain item and sets up a dictionary in the format
//  needed by Keychain Services:
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert {
	
    // This method must be called with a properly populated dictionary
    // containing all the right key/value pairs for a keychain item search.
	
    // Create the return dictionary:
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
	
    // Convert the password NSString to NSData to fit the API paradigm:
    NSString *passwordString = [dictionaryToConvert objectForKey:(id)kSecValueData];
    [returnDictionary setObject:[passwordString dataUsingEncoding:NSUTF8StringEncoding] forKey:(id)kSecValueData];
    
	return returnDictionary;
	
}

// Implement the secItemFormatToDictionary: method, which takes the attribute dictionary
//  obtained from the keychain item, acquires the password from the keychain, and
//  adds it to the attribute dictionary:
- (NSMutableDictionary*) secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert {
	
    // This method must be called with a properly populated dictionary
    // containing all the right key/value pairs for the keychain item.
	
    // Create a return dictionary populated with the attributes:
    NSMutableDictionary* returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
	
    // To acquire the password data from the keychain item,
    // first add the search key and class attribute required to obtain the password:
    [returnDictionary setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [returnDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	
    // Then call Keychain Services to get the password:
    NSData *passwordData = NULL;
    OSStatus keychainError = noErr; //
    keychainError = SecItemCopyMatching((CFDictionaryRef)returnDictionary,(CFTypeRef *)&passwordData);
	
    if (keychainError == noErr) {
		
        // Remove the kSecReturnData key; we don't need it anymore:
        [returnDictionary removeObjectForKey:(id)kSecReturnData];
		
        // Convert the password to an NSString and add it to the return dictionary:
        NSString *password = [[[NSString alloc] initWithBytes:[passwordData bytes] length:[passwordData length] encoding:NSUTF8StringEncoding] autorelease];
        [returnDictionary setObject:password forKey:(id)kSecValueData];
		
	}
    // Don't do anything if nothing is found.
    else if (keychainError == errSecItemNotFound) {
		NSAssert(NO, @"Nothing was found in the keychain.");
    }
    // Any other error is unexpected.
    else {
        NSAssert(NO, @"Serious error.");
    }
	
    [passwordData release];
	
    return returnDictionary;
	
}

@end
