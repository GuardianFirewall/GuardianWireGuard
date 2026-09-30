// swift-tools-version:5.6
//
//  Package.swift
//  GRDWireGuardKit
//
//

import PackageDescription

let package = Package(
	name: "GRDWireGuardKit",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v13)
	],
	products: [
		.library(name: "GRDWireGuardKit", targets: ["GRDWireGuardKit"])
	],
	targets: [
		.binaryTarget(
			name: "GRDWireGuardKit",
			url:"https://github.com/GuardianFirewall/GuardianWireGuard/releases/download/1.1.0/GRDWireGuardKit.xcframework.zip",
			checksum: "2d7f0937fe893ead9d2865e9326e8f3c2e41104f191330714290ed24cd429a6a"
		)
	]
)
