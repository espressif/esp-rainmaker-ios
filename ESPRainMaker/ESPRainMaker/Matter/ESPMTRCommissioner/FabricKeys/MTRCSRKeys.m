/**
 *    Copyright (c) 2022 Project CHIP Authors
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

#import "MTRCSRKeys.h"
#import <Security/SecKey.h>

@interface MTRCSRKeys ()
@property (readonly) SecKeyRef privateKey;
@property (readonly) SecKeyRef publicKey;
@end

@implementation MTRCSRKeys

@synthesize publicKey = _publicKey, privateKey = _privateKey, ipk = _ipk;

static const NSString * MTRIPKKeyChainLabel = @"matter-tool.nodeopcerts.IPK:0";
static const NSString * MTRCAKeyChainLabel = @"matter-tool.nodeopcerts.CA:0";

// MARK: UTILITY METHODS

- (NSData *)publicKeyData
{
    return (__bridge_transfer NSData *) SecKeyCopyExternalRepresentation([self publicKey], nil);
}

- (instancetype)initWithGroupId:(NSString *) grpId
{
    if (!(self = [super init])) {
        return nil;
    }

    // Generate an IPK.  For now, hardcoded to 16 bytes until the
    // framework exposes this constant.
    const size_t ipk_size = 16;
    NSString * ipkKey = [NSString stringWithFormat:@"%@.%@", MTRIPKKeyChainLabel, grpId];
    NSMutableData * ipkData = [[NSUserDefaults standardUserDefaults] dataForKey:ipkKey];
    if (ipkData == nil) {
        ipkData = [NSMutableData dataWithLength:ipk_size];
        [[NSUserDefaults standardUserDefaults] setValue:ipkData forKey:ipkKey];
    }
    
    if (ipkData == nil) {
        return nil;
    }

    _ipk = ipkData;
    
    _publicKey = [MTRCSRKeys loadCAPublicKeyWithGroupId:grpId];
    _privateKey = [MTRCSRKeys loadCAPrivateKeyWithGroupId:grpId];
    
    if (_publicKey != nil && _privateKey != nil) {
        return self;
    }

    // Generate a keypair.  For now harcoded to 256 bits until the framework exposes this constant.
    const size_t keySizeInBits = 256;
    CFErrorRef error = NULL;
    const NSDictionary * keygenParams = @{
        (__bridge NSString *) kSecAttrKeyClass : (__bridge NSString *) kSecAttrKeyClassPrivate,
        (__bridge NSString *) kSecAttrKeyType : (__bridge NSNumber *) kSecAttrKeyTypeECSECPrimeRandom,
        (__bridge NSString *) kSecAttrKeySizeInBits : @(keySizeInBits),
        (__bridge NSString *) kSecAttrIsPermanent : @(NO)
    };

    SecKeyRef encodedPrivateKey = SecKeyCreateRandomKey((__bridge CFDictionaryRef) keygenParams, &error);
    if (error) {
        NSLog(@"Failed to generate private key");
        return nil;
    }
    SecKeyRef encodedPublicKey = SecKeyCopyPublicKey(encodedPrivateKey);
    
    _publicKey = [MTRCSRKeys setPublicKeyInKeychain:encodedPublicKey withGroupId:grpId];
    _privateKey = [MTRCSRKeys setPrivateKeyInKeychain:encodedPrivateKey withGroupId:grpId];

    return self;
}

- (NSData *)signMessageECDSA_DER:(NSData *)message
{
    CFErrorRef error = NULL;
    CFDataRef outData
        = SecKeyCreateSignature(_privateKey, kSecKeyAlgorithmECDSASignatureMessageX962SHA256, (__bridge CFDataRef) message, &error);

    if (error != noErr) {
        NSLog(@"Failed to sign cert: %@", (__bridge NSError *) error);
    }
    return (__bridge_transfer NSData *) outData;
}

// MARK: PRIVATE KEY SPECIFIC METHODS
- (SecKeyRef) getPublicKeyForGroupId:(NSString *)grpId {
    return _publicKey;
}

- (NSData * _Nullable) getPublicKeyDataForGroupId:(NSString *) grpId {
    return (__bridge_transfer NSData *) SecKeyCopyExternalRepresentation(_publicKey, nil);;
}

+ (NSDictionary *)privateKeyCreationParams
{
    // For now harcoded to 256 bits until the framework exposes this constant.
    const size_t keySizeInBits = 256;

    return @{
        (__bridge NSString *) kSecAttrKeyClass : (__bridge NSString *) kSecAttrKeyClassPrivate,
        (__bridge NSString *) kSecAttrKeyType : (__bridge NSNumber *) kSecAttrKeyTypeECSECPrimeRandom,
        (__bridge NSString *) kSecAttrKeySizeInBits : @(keySizeInBits),
        (__bridge NSString *) kSecAttrIsPermanent : @(NO)
    };
}

/// Private key params with group id
/// - Parameter groupId: group id
+ (NSDictionary *)privateKeyParamsWithGroupId:(NSString *)groupId
{
    NSString * finalKeyLabel = [[NSString alloc] initWithFormat:@"%@.%@",MTRCAKeyChainLabel, groupId];
    return @{
        (__bridge NSString *) kSecClass : (__bridge NSString *) kSecClassKey,
        (__bridge NSString *) kSecAttrApplicationLabel : finalKeyLabel,
        (__bridge NSString *) kSecAttrKeyClass : (__bridge NSString *) kSecAttrKeyClassPrivate,
        (__bridge NSString *) kSecAttrKeyType : (__bridge NSNumber *) kSecAttrKeyTypeECSECPrimeRandom,
    };
}

/// Save private key in keychain
/// - Parameters:
///   - encodedPrivateKey: encoded private key
///   - grpId: group id
+(SecKeyRef)setPrivateKeyInKeychain:(SecKeyRef) encodedPrivateKey withGroupId:(NSString *)grpId {
    CFErrorRef privKeyError = NULL;
    NSData * keyData = (__bridge_transfer NSData *) SecKeyCopyExternalRepresentation(encodedPrivateKey, &privKeyError);
    if (privKeyError) {
        NSLog(@"Could not get key external representation: %@", (__bridge NSError *) privKeyError);
        CFRelease(encodedPrivateKey);
        return NULL;
    }
    NSMutableDictionary * query = [[NSMutableDictionary alloc] initWithDictionary:[MTRCSRKeys privateKeyParamsWithGroupId:grpId]];
    query[(__bridge NSString *) kSecValueData] = [keyData base64EncodedDataWithOptions:0];
    OSStatus privKeyAddStatus = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
    if (privKeyAddStatus != errSecSuccess) {
        NSLog(@"Failed to store private key : %d", privKeyAddStatus);
        CFRelease(encodedPrivateKey);
        return NULL;
    }
    return [MTRCSRKeys loadCAPrivateKeyWithGroupId:grpId];
}

/// Load private key from keychain
/// - Parameter grpId: group id
+ (SecKeyRef)loadCAPrivateKeyWithGroupId:(NSString *)grpId {
    NSMutableDictionary * query = [[NSMutableDictionary alloc] initWithDictionary:[MTRCSRKeys privateKeyParamsWithGroupId:grpId]];
    query[(__bridge NSString *) kSecReturnData] = @(YES);

    // The CFDataRef we get from SecItemCopyMatching allocates its buffer in a
    // way that zeroes it when deallocated.
    CFDataRef keyDataRef;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) query, (CFTypeRef *) &keyDataRef);
    if (status != errSecSuccess || keyDataRef == nil) {
        NSLog(@"Did not find CA key in the keychain");
        return NULL;
    }

    NSLog(@"Found an existing CA key in the keychain");
    NSData * encodedKey = CFBridgingRelease(keyDataRef);

    NSData * keyData = [[NSData alloc] initWithBase64EncodedData:encodedKey options:0];
    if (keyData == nil) {
        NSLog(@"Could not base64-decode CA key");
        return NULL;
    }

    CFErrorRef error = NULL;
    SecKeyRef key = SecKeyCreateWithData(
        (__bridge CFDataRef) keyData, (__bridge CFDictionaryRef)[MTRCSRKeys privateKeyCreationParams], &error);
    if (error) {
        NSLog(@"Could not reconstruct private key %@", (__bridge NSError *) error);
        return NULL;
    }

    return key;
}

// MARK: PUBLIC KEY SPECIFIC METHODS
- (SecKeyRef) getPrivateKeyForGroupId:(NSString *) grpId {
    return _privateKey;
}

- (NSData * _Nullable) getPrivateKeyDataForGroupId:(NSString *) grpId {
    return (__bridge_transfer NSData *) SecKeyCopyExternalRepresentation(_privateKey, nil);
}

+ (NSDictionary *)publicKeyCreationParams
{
    // For now harcoded to 256 bits until the framework exposes this constant.
    const size_t keySizeInBits = 256;

    return @{
        (__bridge NSString *) kSecAttrKeyClass : (__bridge NSString *) kSecAttrKeyClassPublic,
        (__bridge NSString *) kSecAttrKeyType : (__bridge NSNumber *) kSecAttrKeyTypeECSECPrimeRandom,
        (__bridge NSString *) kSecAttrKeySizeInBits : @(keySizeInBits),
        (__bridge NSString *) kSecAttrIsPermanent : @(NO)
    };
}

/// Private key params with group id
/// - Parameter groupId: group id
+ (NSDictionary *)publicKeyParamsWithGroupId:(NSString *)groupId
{
    NSString * finalKeyLabel = [[NSString alloc] initWithFormat:@"%@.%@",MTRCAKeyChainLabel, groupId];
    return @{
        (__bridge NSString *) kSecClass : (__bridge NSString *) kSecClassKey,
        (__bridge NSString *) kSecAttrApplicationLabel : finalKeyLabel,
        (__bridge NSString *) kSecAttrKeyClass : (__bridge NSString *) kSecAttrKeyClassPublic,
        (__bridge NSString *) kSecAttrKeyType : (__bridge NSNumber *) kSecAttrKeyTypeECSECPrimeRandom,
    };
}

/// Save public key in keychain
/// - Parameters:
///   - encodedPrivateKey: encoded private key
///   - grpId: group id
+(SecKeyRef)setPublicKeyInKeychain:(SecKeyRef) encodedPublicKey withGroupId:(NSString *)grpId {
    CFErrorRef privKeyError = NULL;
    NSData * keyData = (__bridge_transfer NSData *) SecKeyCopyExternalRepresentation(encodedPublicKey, &privKeyError);
    if (privKeyError) {
        NSLog(@"Could not get key external representation: %@", (__bridge NSError *) privKeyError);
        CFRelease(encodedPublicKey);
        return NULL;
    }
    NSMutableDictionary * query = [[NSMutableDictionary alloc] initWithDictionary:[MTRCSRKeys publicKeyParamsWithGroupId:grpId]];
    query[(__bridge NSString *) kSecValueData] = [keyData base64EncodedDataWithOptions:0];
    OSStatus privKeyAddStatus = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
    if (privKeyAddStatus != errSecSuccess) {
        NSLog(@"Failed to store private key : %d", privKeyAddStatus);
        CFRelease(encodedPublicKey);
        return NULL;
    }
    return [MTRCSRKeys loadCAPublicKeyWithGroupId:grpId];
}

/// Load private key from keychain
/// - Parameter grpId: group id
+ (SecKeyRef)loadCAPublicKeyWithGroupId:(NSString *)grpId {
    NSMutableDictionary * query = [[NSMutableDictionary alloc] initWithDictionary:[MTRCSRKeys publicKeyParamsWithGroupId:grpId]];
    query[(__bridge NSString *) kSecReturnData] = @(YES);

    // The CFDataRef we get from SecItemCopyMatching allocates its buffer in a
    // way that zeroes it when deallocated.
    CFDataRef keyDataRef;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) query, (CFTypeRef *) &keyDataRef);
    if (status != errSecSuccess || keyDataRef == nil) {
        NSLog(@"Did not find CA key in the keychain");
        return NULL;
    }

    NSLog(@"Found an existing CA key in the keychain");
    NSData * encodedKey = CFBridgingRelease(keyDataRef);

    NSData * keyData = [[NSData alloc] initWithBase64EncodedData:encodedKey options:0];
    if (keyData == nil) {
        NSLog(@"Could not base64-decode CA key");
        return NULL;
    }

    CFErrorRef error = NULL;
    SecKeyRef key = SecKeyCreateWithData(
        (__bridge CFDataRef) keyData, (__bridge CFDictionaryRef)[MTRCSRKeys publicKeyCreationParams], &error);
    if (error) {
        NSLog(@"Could not reconstruct private key %@", (__bridge NSError *) error);
        return NULL;
    }

    return key;
}

- (void)dealloc
{
    if (_publicKey) {
        CFRelease(_publicKey);
    }

    if (_privateKey) {
        CFRelease(_privateKey);
    }
}
@end
