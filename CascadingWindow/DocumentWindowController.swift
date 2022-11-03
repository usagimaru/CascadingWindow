//
//  DocumentWindowController.swift
//  CascadingWindow
//
//  Created by usagimaru on 2022/11/03.
//
//  References:
//  https://github.com/jessegrosjean/window.autosaveName/blob/master/Test/WindowController.m
//  https://github.com/coteditor/CotEditor/blob/f9c140ab08fd6acd24ebe65fd01420f29ba367fd/CotEditor/Sources/DocumentWindowController.swift
//  https://stackoverflow.com/questions/35827239/document-based-app-autosave-with-storyboards/43726191#43726191

import Cocoa

class DocumentWindowController: NSWindowController, NSWindowDelegate {
	
	/// To true, discard the last window frame info from the UserDefaults when all document windows are closed.
	var discardWindowFrameAutosaveWhenLastWindowClosed = false
	/// To true, set the first window position to center of the screen.
	var centerWindowPositionWhenFirstWindowOpening = false
	
	private var windowFrameSavingAllowed = false
	private var windowFrameAutosaveName_alt: String = "Document"
	
	private static var previousTopLeft: NSPoint?
	
	
	// MARK: -
	
	override func windowWillLoad() {
		super.windowWillLoad()
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		
		/* Do not touch these because window positioning is so buggy for some reaason.
		 self.windowFrameAutosaveName = …
		 self.shouldCascadeWindows = …
		 */
		
		resetWindowFrame()
		
		self.windowFrameSavingAllowed = true
		self.window?.delegate = self
	}
	
	/// Restore window frame as descriptor
	private func persistableWindowFrameDescriptor() -> NSWindow.PersistableFrameDescriptor? {
		UserDefaults.standard.string(forKey: "NSWindow Frame \(self.windowFrameAutosaveName_alt)")
	}
	
	private func resetWindowFrame() {
		// NSWindowController.windowFrameAutosaveName を使わずにカスケーディングとフレーム保存を実現する
		
		guard let window = self.window as? DocumentWindow, let screen = window.screen
		else { return }
		
		if AppDelegate.sharedDocumentController.allDocumentWindows().count == 0 {
			// [First Window]
			
			if let windowFrameDesc = persistableWindowFrameDescriptor() {
				// Restore window frame if auto saved
				window.setFrame(from: windowFrameDesc)
				
				if self.centerWindowPositionWhenFirstWindowOpening {
					// Centering position
					window.center()
				}
			}
			else {
				// Set initial window size and centering
				let scale_w = 0.75
				let scale_h = 0.75
				let screenSize = screen.visibleFrame.size
				let size = NSSize(width: CGFloat(Int(screenSize.width * scale_w)),
								  height: CGFloat(Int(screenSize.height * scale_h)))
				window.setContentSize(size)
				window.center()
			}
			
			Self.previousTopLeft = window.topLeft
		}
		else {
			// [Other Windows]
			
			// Restore window frame
			window.setFrameUsingName(self.windowFrameAutosaveName_alt)
			
			// Cascade and set position
			let topLeft = window.topLeft
			let nextTopLeft = window.cascadeTopLeft(from: Self.previousTopLeft ?? topLeft)
			window.setFrameTopLeftPoint(nextTopLeft)
			
			Self.previousTopLeft = nextTopLeft
		}
	}
	
	
	// MARK: - NSWindowDelegate
	
	func windowDidBecomeMain(_ notification: Notification) {
		guard self.isWindowLoaded,
			  let window = self.window as? DocumentWindow,
			  (notification.object as? DocumentWindow) == window,
			  self.windowFrameSavingAllowed else
		{ return }
		
		window.saveFrame(usingName: self.windowFrameAutosaveName_alt)
	}
	
	func windowDidBecomeKey(_ notification: Notification) {
		guard self.isWindowLoaded,
			  let window = self.window as? DocumentWindow,
			  (notification.object as? DocumentWindow) == window,
			  self.windowFrameSavingAllowed else
		{ return }
		
		Self.previousTopLeft = window.topLeft
	}
	
	func windowDidResize(_ notification: Notification) {
		guard self.isWindowLoaded,
			  let window = self.window as? DocumentWindow,
			  (notification.object as? DocumentWindow) == window,
			  self.windowFrameSavingAllowed else
		{ return }
		
		window.saveFrame(usingName: self.windowFrameAutosaveName_alt)
		Self.previousTopLeft = window.topLeft
	}
	
	func windowDidMove(_ notification: Notification) {
		guard self.isWindowLoaded,
			  let window = self.window as? DocumentWindow,
			  (notification.object as? DocumentWindow) == window,
			  window.isKeyWindow,
			  self.windowFrameSavingAllowed else
		{ return }
		
		window.saveFrame(usingName: self.windowFrameAutosaveName_alt)
		
		if window.isMainWindow {
			Self.previousTopLeft = window.topLeft
		}
	}
	
	func windowWillClose(_ notification: Notification) {
		if self.discardWindowFrameAutosaveWhenLastWindowClosed,
		   (notification.object as? DocumentWindow) == self.window,
		   AppDelegate.sharedDocumentController.allDocumentWindows().count == 1 {
			DocumentWindow.removeFrame(usingName: self.windowFrameAutosaveName_alt)
		}
	}
	
}
