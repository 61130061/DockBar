//
//  AppDelegate.swift
//  DockBar
//
//  Created by Bastard.y on 12/12/2564 BE.
//

import Cocoa
import SQLite3

@main
class AppDelegate: NSObject, NSApplicationDelegate {

	var MessageStatus: NSStatusItem?
	var messBadge: Int32?

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Hide Dock Icon
		NSApp.setActivationPolicy(.accessory)
		
		// Get database path
		let userPath = runProcess("echo $(getconf DARWIN_USER_DIR)")!.components(separatedBy: .whitespacesAndNewlines)[0].components(separatedBy: "/").dropLast().joined(separator: "/")
		let notiPath = userPath + "/com.apple.notificationcenter/db2/db"
		
		messBadge = 0
		loadStatusItem(target: true)
		
		Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(UpdateMessageIcon(_:)), userInfo: notiPath, repeats: true)
	}
	
	@objc func OpenMessages() {
		runProcess("open -a Messages")
	}
	
	@discardableResult
	func runProcess(_ cmd: String) -> String? {
		let pipe = Pipe()
		let process = Process()
		process.launchPath = "/bin/sh"
		process.arguments = ["-c", String(format:"%@", cmd)]
		process.standardOutput = pipe
		let fileHandle = pipe.fileHandleForReading
		process.launch()
		
		return String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8)
	}
	
	func loadStatusItem(target: Bool) {
		MessageStatus = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
		if let StatusBar = MessageStatus?.button{
			StatusBar.image = #imageLiteral(resourceName: "message.fill")
			StatusBar.image?.size = NSSize(width: 18.0, height: 18.0)
			StatusBar.image?.isTemplate = target
		}
		
		let appSubmenu = NSMenu()
		appSubmenu.addItem(NSMenuItem(title: "Open Messages", action: #selector(OpenMessages), keyEquivalent: ""))
		appSubmenu.addItem(NSMenuItem.separator())
		appSubmenu.addItem(NSMenuItem(title: "Quit DockBar", action: #selector(NSApplication.shared.terminate(_:)), keyEquivalent: "q"))
		MessageStatus?.menu = appSubmenu

	}
	
	@objc func UpdateMessageIcon(_ params: Timer) {
		let badge = UpdateNotification(getStatementString: "SELECT * FROM app WHERE app_id = 4", path: params.userInfo as! String)
		
		if badge != messBadge {
			if badge > 0 && messBadge! == 0 {
				loadStatusItem(target: false)
			}
			else if badge == 0 && messBadge! > 0 {
				loadStatusItem(target: true)
			}
			messBadge = badge
		}
	}

	func UpdateNotification(getStatementString: String, path: String) -> Int32 {
		var getStatement: OpaquePointer?
		var db: OpaquePointer?
		
		if sqlite3_open(path, &db) == SQLITE_OK {
			print("OK")
		} else {
			return 0
		}
		
		if sqlite3_prepare_v2(db, getStatementString, -1, &getStatement, nil) == SQLITE_OK {
			if sqlite3_step(getStatement) == SQLITE_ROW {
				let appId = sqlite3_column_int(getStatement, 0)
				guard let getResultCol1 = sqlite3_column_text(getStatement, 1) else {
					print("Result is nil")
					return 0
				}
				let badge = sqlite3_column_int(getStatement, 2)
				let name = String(cString: getResultCol1)
				
				print("\(appId) | \(name) | \(badge)")
				
				sqlite3_finalize(getStatement)
				sqlite3_close(db)
				
				return badge
			}
		}
		return 0
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}


}

