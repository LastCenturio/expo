// Copyright 2015-present 650 Industries. All rights reserved.

import Foundation
import UIKit

class DevMenuTouchInterceptor {
  static fileprivate let recognizer: DevMenuGestureRecognizer = DevMenuGestureRecognizer()

  /**
   User defaults key under which the current state is saved.
   */
  static let userDefaultsKey = "EXDevMenuTouchGestureEnabled"

  /**
   Returns bool value whether touch interceptor is currently installed.
   */
  static var isInstalled: Bool = false {
    willSet {
      if isInstalled != newValue {
        // Capture touch gesture from any window by swizzling default implementation from UIWindow.
        swizzle()

        // Make sure recognizer is enabled/disabled accordingly.
        recognizer.isEnabled = newValue

        // Update value in user defaults.
        UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
      }
    }
  }

  static func initialize() {
    UserDefaults.standard.register(defaults: [
      userDefaultsKey : true
    ])
    isInstalled = UserDefaults.standard.bool(forKey: userDefaultsKey)
  }

  static private func swizzle() {
    DevMenuUtils.swizzle(
      selector: #selector(getter: UIWindow.gestureRecognizers),
      withSelector: #selector(getter: UIWindow.EXDevMenu_gestureRecognizers),
      forClass: UIWindow.self
    )
  }
}

// We swizzle the method for `UIWindow`, but we have to extend entire `UIView` (superclass of `UIWindow`).
// Otherwise we would get "unrecognized selector" runtime crash as internal `UITransitionView` calls this property on `UIView` pointer.
extension UIView {
  @objc open var EXDevMenu_gestureRecognizers: [UIGestureRecognizer]? {
    // Just for thread safety, someone may uninstall the interceptor in the meantime and we would fall into recursive loop.
    if !DevMenuTouchInterceptor.isInstalled {
      return self.gestureRecognizers
    }

    // Check for the case where singleton instance of gesture recognizer is not created yet or is attached to different window.
    let recognizer = DevMenuTouchInterceptor.recognizer
    if recognizer.view != self {
      // Remove it from the window it's attached to.
      recognizer.view?.removeGestureRecognizer(recognizer)

      // Attach to this window.
      self.addGestureRecognizer(recognizer)
    }

    // `EXDevMenu_gestureRecognizers` implementation has been swizzled with `gestureRecognizers` - it might be confusing that we call it recursively, but we don't.
    return self.EXDevMenu_gestureRecognizers
  }
}
