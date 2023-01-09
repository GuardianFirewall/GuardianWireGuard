//
//  GRDWireGuardKitmacOS.h
//  GRDWireGuardKitmacOS
//
//  Created by Constantin Jacob on 23.11.22.
//

#import <Foundation/Foundation.h>

//! Project version number for GRDWireGuardKitmacOS.
FOUNDATION_EXPORT double GRDWireGuardKitmacOSVersionNumber;

//! Project version string for GRDWireGuardKitmacOS.
FOUNDATION_EXPORT const unsigned char GRDWireGuardKitmacOSVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <GRDWireGuardKitmacOS/PublicHeader.h>


// Note from CJ 2022-11-23
// The required headers from the WireGuard project to make GRDWireGuardKit
// self contained and portable have the imported specifically in the way it is done below
// and all the headers need to be publically exposed in GRDWireGuardKit so that the 
// importing app can use them
#import "GRDWireGuardKitmacOS/WireGuardKitC.h"
#import <GRDWireGuardKitmacOS/wireguard.h>
#import <GRDWireGuardKitmacOS/ringlogger.h>
#import <GRDWireGuardKitmacOS/key.h>
#import <GRDWireGuardKitmacOS/x25519.h>
