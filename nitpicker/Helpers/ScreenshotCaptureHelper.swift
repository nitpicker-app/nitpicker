//
//  ScreenshotCaptureHelper.swift
//  nitpicker
//
//  Created by Vishnu R on 20/11/25.
//

import Cocoa
import ScreenCaptureKit

class ScreenshotCaptureHelper {
    
    /// Captures a screenshot of the active screen (the screen containing the frontmost window)
    /// - Returns: PNG image data of the captured screen, or nil if capture fails
    static func captureActiveScreen() async -> Data? {
        print("ScreenshotCaptureHelper: Starting active screen capture")
        
        // Check for screen recording permissions
        guard await checkScreenRecordingPermission() else {
            print("ScreenshotCaptureHelper: ⚠️ Screen recording permission not granted")
            return nil
        }
        
        do {
            // Get all available content (windows and displays)
            let availableContent = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )
            
            // Find the active screen (the one with the frontmost window)
            guard let activeDisplay = findActiveDisplay(from: availableContent) else {
                print("ScreenshotCaptureHelper: ⚠️ Could not determine active display")
                return nil
            }
            
            print("ScreenshotCaptureHelper: Capturing display: \(activeDisplay.displayID)")
            
            // Create a content filter for the display
            let filter = SCContentFilter(display: activeDisplay, excludingWindows: [])
            
            // Configure the screenshot
            let config = SCStreamConfiguration()
            config.width = activeDisplay.width
            config.height = activeDisplay.height
            config.scalesToFit = true
            config.showsCursor = false
            
            // Capture the screenshot
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            
            // Convert CGImage to PNG data
            guard let pngData = convertCGImageToPNG(image) else {
                print("ScreenshotCaptureHelper: ⚠️ Failed to convert image to PNG")
                return nil
            }
            
            print("ScreenshotCaptureHelper: ✓ Successfully captured screenshot (\(pngData.count) bytes)")
            
            // Save the screenshot to Documents/nitpicker folder
            saveScreenshot(pngData)
            
            return pngData
            
        } catch {
            print("ScreenshotCaptureHelper: ⚠️ Error capturing screenshot: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Finds the active display by looking for the frontmost window
    private static func findActiveDisplay(from content: SCShareableContent) -> SCDisplay? {
        // Get the frontmost window (the one the user is currently interacting with)
        let windows = content.windows
        
        // Try to find the frontmost application's window
        if let frontmostApp = NSWorkspace.shared.frontmostApplication,
           let frontWindow = windows.first(where: { window in
               window.owningApplication?.bundleIdentifier == frontmostApp.bundleIdentifier
           }) {
            // Find the display that contains this window
            // Check which display's bounds intersect with the window frame
            let windowCenter = CGPoint(
                x: frontWindow.frame.midX,
                y: frontWindow.frame.midY
            )
            
            // Find display containing the center of the window
            for display in content.displays {
                // Get the actual screen bounds for this display
                if let screen = NSScreen.screens.first(where: { screen in
                    screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID == display.displayID
                }) {
                    // Convert window center to screen coordinates
                    if screen.frame.contains(windowCenter) {
                        print("ScreenshotCaptureHelper: Found window on display \(display.displayID)")
                        return display
                    }
                }
            }
            
            print("ScreenshotCaptureHelper: Could not match window to specific display, using first available")
        }
        
        // Fallback: return the main display
        print("ScreenshotCaptureHelper: Using main display as fallback")
        return content.displays.first { display in
            display.displayID == CGMainDisplayID()
        }
    }
    
    /// Checks if the app has screen recording permission
    private static func checkScreenRecordingPermission() async -> Bool {
        if #available(macOS 11.0, *) {
            do {
                // Attempting to get shareable content will trigger the permission prompt if needed
                _ = try await SCShareableContent.excludingDesktopWindows(
                    false,
                    onScreenWindowsOnly: true
                )
                return true
            } catch {
                print("ScreenshotCaptureHelper: Screen recording permission error: \(error.localizedDescription)")
                return false
            }
        }
        return true
    }
    
    /// Converts a CGImage to PNG data
    private static func convertCGImageToPNG(_ cgImage: CGImage) -> Data? {
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmapImage.representation(using: .png, properties: [:])
    }
    
    /// Captures a screenshot and returns it as a base64-encoded string suitable for OpenAI API
    static func captureActiveScreenAsBase64() async -> String? {
        guard let pngData = await captureActiveScreen() else {
            return nil
        }
        
        return pngData.base64EncodedString()
    }
    
    /// Saves screenshot data to Documents/nitpicker folder
    private static func saveScreenshot(_ data: Data) {
        // Get the user's home directory
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        
        // Create path to Documents/nitpicker
        let nitpickerFolder = homeDirectory
            .appendingPathComponent("Documents")
            .appendingPathComponent("nitpicker")
        
        do {
            // Create the nitpicker directory if it doesn't exist
            try FileManager.default.createDirectory(at: nitpickerFolder, withIntermediateDirectories: true, attributes: nil)
            
            // Create filename with timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            let filename = "screenshot_\(timestamp).png"
            
            let fileURL = nitpickerFolder.appendingPathComponent(filename)
            
            // Write the data to file
            try data.write(to: fileURL)
            print("ScreenshotCaptureHelper: ✓ Screenshot saved to: \(fileURL.path)")
            
        } catch {
            print("ScreenshotCaptureHelper: ⚠️ Error saving screenshot: \(error.localizedDescription)")
        }
    }
}
