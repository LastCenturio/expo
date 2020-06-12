// Copyright 2015-present 650 Industries. All rights reserved.

import UIKit

class DevMenuViewController: UIViewController {
  static let JavaScriptDidLoadNotification = Notification.Name("RCTJavaScriptDidLoadNotification")

  private let manager: DevMenuManager
  private var reactRootView: RCTRootView?
  private var hasCalledJSLoadedNotification: Bool = false

  init(manager: DevMenuManager) {
    self.manager = manager

    super.init(nibName: nil, bundle: nil)
    edgesForExtendedLayout = UIRectEdge.init(rawValue: 0)
    extendedLayoutIncludesOpaqueBars = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()
    maybeRebuildRootView()
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    reactRootView?.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    maybeRebuildRootView()
    forceRootViewToRenderHack()
    reactRootView?.becomeFirstResponder()
  }

  override var shouldAutorotate: Bool {
    get {
      return true
    }
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    get {
      return UIInterfaceOrientationMask.portrait
    }
  }

  override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
    get {
      return UIInterfaceOrientation.portrait
    }
  }

  // MARK: private

  private func initialProps() -> Dictionary<String, Any> {
    return [
      "enableDevelopmentTools": true,
      "showOnboardingView": false,
      "devMenuItems": manager.serializedDevMenuItems(),
      "appInfo": manager.currentAppInfo() ?? NSNull(),
      "uuid": UUID.init().uuidString
    ]
  }

  private func forceRootViewToRenderHack() {
    if !hasCalledJSLoadedNotification, let bridge = manager.appInstance?.bridge {
      let notification = Notification(name: DevMenuViewController.JavaScriptDidLoadNotification, object: nil, userInfo: ["bridge": bridge])

      reactRootView?.javaScriptDidLoad(notification)
      hasCalledJSLoadedNotification = true
    }
  }

  private func maybeRebuildRootView() {
    guard let bridge = manager.appInstance?.bridge else {
      return
    }
    if reactRootView == nil || reactRootView?.bridge != bridge {
      if reactRootView != nil {
        reactRootView?.removeFromSuperview()
        reactRootView = nil
      }
      hasCalledJSLoadedNotification = false
      reactRootView = RCTRootView.init(bridge: bridge, moduleName: "main", initialProperties: initialProps())
      reactRootView?.frame = view.bounds
      reactRootView?.backgroundColor = UIColor.clear

      if isViewLoaded, let reactRootView = reactRootView {
        view.addSubview(reactRootView)
        view.setNeedsLayout()
      }
    }
  }
}
