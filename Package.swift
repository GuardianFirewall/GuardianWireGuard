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
			url:"https://github.com/GuardianFirewall/GuardianWireGuard/releases/download/1.0.0/GRDWireGuardKit.xcframework.zip",
			checksum: "5efc9d245b89d00ea7b6e802038a4603c23c2664056c63d0e95d883fc83e8c26"
		)
	]
)
