// Copyright 2015-present 650 Industries. All rights reserved.

import Foundation

class DevMenuUtils {
  /**
   Swizzles implementations of given selectors.
   */
  static func swizzle(selector selectorA: Selector, withSelector selectorB: Selector, forClass: AnyClass) {
    if let methodA = class_getInstanceMethod(forClass, selectorA),
      let methodB = class_getInstanceMethod(forClass, selectorB) {
      method_exchangeImplementations(methodA, methodB)
    }
  }
}
