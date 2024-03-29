// Copyright 2023 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  FabricKeys.h
//  ESPRainmaker
//

#pragma once

#import <Foundation/Foundation.h>
#import <Matter/Matter.h>

/**
 * Management of the CA key and IPK for our fabric.
 */

NS_ASSUME_NONNULL_BEGIN

@interface FabricKeys : NSObject <MTRKeypair>

@property (readonly, nonatomic, strong) NSData * ipk;

- (instancetype)init;
- (instancetype)init:(NSData *) privateKey;
- (instancetype)initWithRootCACert:(NSData*) derData PrivateKey:(SecKeyRef) encodedPrivKey;
- (SecKeyRef)getPublicKey;
- (instancetype)initWithPublicKey:(SecKeyRef) encodedPubKey PrivateKey:(SecKeyRef) encodedPrivKey groupId:(NSString *) grpId;

/// Custom fabric commissioning utils
-(instancetype) initWithRootCACert:(NSData*) derData PrivateKey:(SecKeyRef) encodedPrivKey groupId:(NSString *) grpId;

@end

NS_ASSUME_NONNULL_END
