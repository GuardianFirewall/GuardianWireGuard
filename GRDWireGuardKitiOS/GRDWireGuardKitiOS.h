//
//  GRDWireGuardKit.h
//  GRDWireGuardKit
//
//  Created by Constantin Jacob on 23.11.22.
//

#import <Foundation/Foundation.h>

//! Project version number for GRDWireGuardKit.
FOUNDATION_EXPORT double GRDWireGuardKitVersionNumber;

//! Project version string for GRDWireGuardKit.
FOUNDATION_EXPORT const unsigned char GRDWireGuardKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <GRDWireGuardKit/PublicHeader.h>


// Note from CJ 2022-11-23
// The required headers from the WireGuard project to make GRDWireGuardKit
// self contained and portable have the imported specifically in the way it is done below
// and all the headers need to be publically exposed in GRDWireGuardKit so that the 
// importing app can use them
#import "GRDWireGuardKitiOS/WireGuardKitC.h"
#import <GRDWireGuardKitiOS/wireguard.h>
#import <GRDWireGuardKitiOS/ringlogger.h>
#import <GRDWireGuardKitiOS/key.h>
#import <GRDWireGuardKitiOS/x25519.h>
