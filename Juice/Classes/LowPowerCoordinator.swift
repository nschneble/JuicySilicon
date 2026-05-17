//
//  LowPowerCoordinator.swift
//  Juice
//
//  Created by Brian Michel on 1/2/17.
//  Copyright © 2017 Brian Michel. All rights reserved.
//

import AppKit
import RxSwift
import UserNotifications

final class LowPowerCoordinator {
    private enum Constants {
        //TODO: Could probably make this a user preference
        static let lowPowerNotificationPercentage = 10
        static let lowPowerNotificationIdentifier = "com.bsm.macos.juice.low-power-notification"
    }
    private let powerSourceObservable: Observable<[PowerSource]>
    private let notificationCenter = UNUserNotificationCenter.current()
    private let disposeBag = DisposeBag()
    private var lastPowerState: PowerSourceState = .unknown
    private var notificationDelivered = false

    init(observable: Observable<[PowerSource]>) {
        powerSourceObservable = observable
        notificationCenter.requestAuthorization(options: [.alert]) { _, _ in }
    }

    func start() {
        powerSourceObservable.share(replay: 1).subscribe { (event) in
            switch event {
            case .next(let sources):
                guard let source = sources.first else { return }
                self.checkForNotificationDismissal(powerSource: source)
                self.checkForWarning(powerSource: source)
            case .error(let error):
                print("Error: \(error)")
            case .completed:
                break
            }
        }.disposed(by: disposeBag)
    }

    private func checkForNotificationDismissal(powerSource: PowerSource) {
        if lastPowerState == .battery && powerSource.state == .ac {
            clearDeliveredNotification()
        }
        lastPowerState = powerSource.state
    }

    private func checkForWarning(powerSource: PowerSource) {
        guard powerSource.chargedPercentage <= Constants.lowPowerNotificationPercentage,
              powerSource.state == .battery,
              !notificationDelivered else { return }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Low Power", comment: "Title of notification shown to user when their battery is very low.")
        content.body = NSLocalizedString("Your Mac will sleep soon unless plugged into a power outlet.", comment: "Body of notification shown to user when their battery is very low.")
        let request = UNNotificationRequest(
            identifier: Constants.lowPowerNotificationIdentifier,
            content: content,
            trigger: nil
        )
        notificationCenter.add(request) { _ in }
        notificationDelivered = true
    }

    private func clearDeliveredNotification() {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [Constants.lowPowerNotificationIdentifier])
        notificationDelivered = false
    }
}
