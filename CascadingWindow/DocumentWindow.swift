//
//  DocumentWindow.swift
//  CascadingWindow
//
//  Created by usagimaru on 2022/11/03.
//

import Cocoa

class DocumentWindow: NSWindow {
	
	var topLeft: NSPoint {
		NSPoint(x: frame.minX, y: frame.maxY)
	}
	
	/// Stop NSWindowDelegate notifications in setFrame()
	var disablePostingNotificationsWhenFrameSetting: Bool = true
	
	override func setFrame(_ frameRect: NSRect, display flag: Bool) {
		if disablePostingNotificationsWhenFrameSetting && !self.inLiveResize {
			let delegate = self.delegate
			self.delegate = nil
			super.setFrame(frameRect, display: flag)
			self.delegate = delegate
		}
		else {
			super.setFrame(frameRect, display: flag)
		}
	}

}
