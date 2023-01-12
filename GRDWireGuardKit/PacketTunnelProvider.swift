//
//  PacketTunnelProvider.swift
//  GuardianTunnel
//
//  Created by Constantin Jacob on 13.12.21.
//

import os
import Foundation
import NetworkExtension

// Note from CJ 2023-01-12
// Added our own error type here to properly
// reflect the keychain being blocked by the XPC
// connection on macOS and never recovering
enum GRDWireGuardKitError: String, Error {
	case internalError
	case xpcKeychainAccessBlocked
}

@objc open class GRDPacketTunnelProvider : NEPacketTunnelProvider {
	var keychainAccessPending: Bool = false
	
	private lazy var adapter: WireGuardAdapter = {
		return WireGuardAdapter(with: self) { logLevel, message in
			wg_log(logLevel.osLogLevel, message: message)
		}
	}()
	
	public override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
// Note from CJ 2023-01-12
// This little hack below appears to be required on macOS 
// to allow all actions to complete properly before attempting 
// to start the tunnel and establish a connection		
#if os(macOS)
		var count: Int = 0
		while keychainAccessPending == true {
			if count > 25 {
				completionHandler(GRDWireGuardKitError.xpcKeychainAccessBlocked)
				return
			}
			
			NSLog("[WARNING] XPC keychain access still pending, count: \(count)! Sleeping for 0.1s")
			Thread.sleep(forTimeInterval: 0.1)
			count += 1
		}
		NSLog("[WARNING] XPC keychain access no longer pending. Attempting to starting the tunnel")
#endif
		
		let dictionary  = Bundle.main.infoDictionary!
        let bundleId    = Bundle.main.bundleIdentifier!
		let version     = dictionary["CFBundleShortVersionString"] as! String
		let build       = dictionary["CFBundleVersion"] as! String
		NSLog("[WARNING] Attempting to start the WireGuard PTP: '\(bundleId)' version: '\(version) (\(build))'")
		
        let activationAttemptId = options?["activationAttemptId"] as? String
		NSLog("[WARNING] Attempting to start the VPN with activation attempt id: " + (activationAttemptId == nil ? "no id present. Starting via the OS": "app"))
		
		NSLog("[WARNING] Trying to setup protocol configuration")
        
		#if os(macOS)
		// Note from CJ 2022-03-16:
		// This little workaround is required for macOS app distributed via Developer Id
		// since System Extension Network Extensions can't access keychain items created by the
		// host app, while Network Extensions on iOS are distributed as an App Extension which can
		// access keychain items created by the host app.
		// See func handleAppMessage() in this class to see how the WireGuard config is passed to the
		// SYSEX NE via the IPC handler provided by the NEPacketTunnelProvider class
        let wireGuardConfig = GRDKeychain.loadWGQuickConfig(bundleId: bundleId)
        if wireGuardConfig == "" {
            completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            return
        }
        
		guard let tunnelConfiguration = grdTunnelConfig(config: wireGuardConfig, named: nil) else {
			NSLog("[ERROR] Saved wg-quick protocol is invalid")
			completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
			return
		}
		
		#else
		guard let tunnelProviderProtocol = self.protocolConfiguration as? NETunnelProviderProtocol,
			  let tunnelConfiguration = tunnelProviderProtocol.asTunnelConfiguration() else {
                  NSLog("[ERROR] Saved wg-quick protocol is invalid")
			completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
			return
		}
		#endif

		NSLog("[WARNING] Trying to start the adapter")
		// Start the tunnel
		adapter.start(tunnelConfiguration: tunnelConfiguration) { adapterError in
			guard let adapterError = adapterError else {
				let interfaceName = self.adapter.interfaceName ?? "unknown"
				NSLog("[WARNING] Tunnel interface is \(interfaceName)")

				completionHandler(nil)
				return
			}

			switch adapterError {
			case .cannotLocateTunnelFileDescriptor:
				NSLog("[ERROR] Starting tunnel failed: could not determine file descriptor")
				completionHandler(PacketTunnelProviderError.couldNotDetermineFileDescriptor)

			case .dnsResolution(let dnsErrors):
				let hostnamesWithDnsResolutionFailure = dnsErrors.map { $0.address }
					.joined(separator: ", ")
				NSLog("[ERROR] DNS resolution failed for the following hostnames: \(hostnamesWithDnsResolutionFailure)")
				completionHandler(PacketTunnelProviderError.dnsResolutionFailure)

			case .setNetworkSettings(let error):
				NSLog("[ERROR] Starting tunnel failed with setTunnelNetworkSettings returning \(error.localizedDescription)")
				completionHandler(PacketTunnelProviderError.couldNotSetNetworkSettings)

			case .startWireGuardBackend(let errorCode):
				NSLog("[ERROR] Starting tunnel failed with wgTurnOn returning \(errorCode)")
				completionHandler(PacketTunnelProviderError.couldNotStartBackend)

			case .invalidState:
				// Must never happen
				fatalError()
			}
		}
	}
	
	public func grdTunnelConfig(config: String? = nil, named: String? = nil) -> TunnelConfiguration? {
		return try? TunnelConfiguration(fromWgQuickConfig: config!, called: named)
	}
	
	public override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
		NSLog("[WARNING] Stopping tunnel");

		adapter.stop { error in
			if let error = error {
				NSLog("[ERROR] Failed to stop WireGuard adapter: \(error.localizedDescription)")
			}
			completionHandler()

			#if os(macOS)
			// HACK: This is a filthy hack to work around Apple bug 32073323 (dup'd by us as 47526107).
			// Remove it when they finally fix this upstream and the fix has been rolled out to
			// sufficient quantities of users.
			exit(0)
			#endif
		}
	}

	public struct PTPMessage: Decodable {
		enum CodingKeys: String, CodingKey {
			case wireGuardConfig = "wg-quick-config"
		}
		let wireGuardConfig: String?
	}
	
	public override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
		guard let completionHandler = completionHandler else { return }

		NSLog("[WARNING] Setting XPC keychain access pending to true")
		keychainAccessPending = true
		
		// Note from CJ 2022-03-16:
		// Due to limitations on macOS System Extension Network Extensions
		// can't access keychain items created by the host app.
		// I would prefer to pass the WireGuard config via the launch options sent to
		// startTunnel() but those are sometimes ommitted for some strange reason.
		// The WireGuard config is therefore passed through the IPC handlers here
		// which appear to work very reliably
		let message: PTPMessage = try! JSONDecoder().decode(PTPMessage.self, from:messageData)
		if message.wireGuardConfig != nil {
            NSLog("[INFO] Saving WireGuard config received via IPC message")
			let success = GRDKeychain.saveWGQuickConfig(bundleId: Bundle.main.bundleIdentifier!, wgQuickConfig: message.wireGuardConfig!)
			if success == false {
				NSLog("[ERROR] Failed to save WireGuard config")
			}
            
			NSLog("[WARNING] Setting XPC keychain access pending to false")
			keychainAccessPending = false
			completionHandler(nil)
			return
		}
		
		if messageData.count == 1 && messageData[0] == 0 {
			adapter.getRuntimeConfiguration { settings in
				var data: Data?
				if let settings = settings {
					data = settings.data(using: .utf8)!
				}
				completionHandler(data)
			}
			
		} else {
			completionHandler(nil)
		}
	}
}

extension WireGuardLogLevel {
	var osLogLevel: OSLogType {
		switch self {
		case .verbose:
			return .debug
		case .error:
			return .error
		}
	}
}
