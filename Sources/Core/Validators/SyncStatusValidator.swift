//
//  ExpirationPolicy.swift
//  Countries
//
//  Created by Daniel Koster on 6/1/26.
//

import Foundation
import QHValidator

public protocol SyncStatusValidator {
    func isValid(syncStatus: SyncStatus) -> Bool
}

private func isWithinLast12Hours(_ date: Date) -> Bool {
    // 12 hours converted to seconds (12 * 60 * 60)
    let twelveHoursAgo = Date().addingTimeInterval(-43200)
    let currentRange = twelveHoursAgo...Date()
    
    return currentRange.contains(date)
}

extension Validator where Input == SyncStatus {
    func createdWithinLast(hours: Int) -> Validator<SyncStatus> {
        return add { syncStatus in
            let timeInterval = -Double(hours * 60 * 60)
            let hoursAgo = Date().addingTimeInterval(timeInterval)
            let currentRange = hoursAgo...Date()
            return currentRange.contains(syncStatus.createdAt)
        }
    }
    
    func createdWithinLast(minutes: Int) -> Validator<SyncStatus> {
        return add { syncStatus in
            let timeInterval = -Double(minutes * 60)
            let minutesAgo = Date().addingTimeInterval(timeInterval)
            let currentRange = minutesAgo...Date()
            return currentRange.contains(syncStatus.createdAt)
        }
    }
    
    func createdWithinLast(seconds: Int) -> Validator<SyncStatus> {
        return add { syncStatus in
            let timeInterval = -Double(seconds)
            let secondsAgo = Date().addingTimeInterval(timeInterval)
            let currentRange = secondsAgo...Date()
            return currentRange.contains(syncStatus.createdAt)
        }
    }
}

public struct CountriesExpirationSyncStatusValidator: SyncStatusValidator {
    private let validator = Validator<SyncStatus>().createdWithinLast(hours: 12)
    
    public func isValid(syncStatus: SyncStatus) -> Bool {
        ((try? validator.validate(value: syncStatus)) != nil)
    }
}
