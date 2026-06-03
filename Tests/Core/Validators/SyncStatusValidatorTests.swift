//
//  SyncStatusValidatorTests.swift
//  Countries
//
//  Created by Daniel Koster on 6/3/26.
//
import Testing
import Foundation
import CountriesCore // Replace with your actual target name

@Suite("Countries Expiration Sync Status Validator Tests")
struct CountriesExpirationSyncStatusValidatorTests {
    
    // SUT (System Under Test) can be instantiated directly for each test run
    private let sut = CountriesExpirationSyncStatusValidator()
    
    // MARK: - Success Cases
    
    @Test("Validates true when a sync status is brand new")
    func isValidWithJustCreatedSyncStatus() {
        // Given
        let currentSyncStatus = SyncStatus(name: "countries", createdAt: Date())
        
        // When
        let result = sut.isValid(syncStatus: currentSyncStatus)
        
        // Then
        #expect(result == true)
    }
    
    @Test("Validates true when a sync status is just under the 12-hour limit")
    func isValidWithSyncStatusExactlyUnderTwelveHours() {
        // Given - 11 hours and 59 minutes ago
        let elevenHoursAgo = Calendar.current.date(byAdding: .minute, value: -719, to: Date())!
        let validSyncStatus = SyncStatus(name: "countries", createdAt: elevenHoursAgo)
        
        // When
        let result = sut.isValid(syncStatus: validSyncStatus)
        
        // Then
        #expect(result == true)
    }
    
    // MARK: - Failure Cases
    
    @Test("Validates false when a sync status is just over the 12-hour limit")
    func isValidWithSyncStatusExactlyOverTwelveHours() {
        // Given - 12 hours and 1 minute ago
        let twelveHoursAndOneMinuteAgo = Calendar.current.date(byAdding: .minute, value: -721, to: Date())!
        let expiredSyncStatus = SyncStatus(name: "countries", createdAt: twelveHoursAndOneMinuteAgo)
        
        // When
        let result = sut.isValid(syncStatus: expiredSyncStatus)
        
        // Then
        #expect(result == false)
    }
    
    @Test("Validates false when a sync status is several days old")
    func isValidWithSyncStatusDaysOld() {
        // Given - 3 days ago
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let expiredSyncStatus = SyncStatus(name: "countries", createdAt: threeDaysAgo)
        
        // When
        let result = sut.isValid(syncStatus: expiredSyncStatus)
        
        // Then
        #expect(result == false)
    }
    
    // MARK: - Parameterized Optimization (Bonus)
    
    // Swift Testing lets you pass multiple values into a single test function
    // to verify different variations of expiration timelines cleanly.
    @Test("Validates correctly across multiple expiration time offsets", arguments: [
        (-5, true),    // 5 hours ago -> Valid
        (-11, true),   // 11 hours ago -> Valid
        (-13, false),  // 13 hours ago -> Expired
        (-24, false)   // 24 hours ago -> Expired
    ])
    func isValidWithVariousTimeOffsets(hoursOffset: Int, expectedResult: Bool) {
        // Given
        let targetDate = Calendar.current.date(byAdding: .hour, value: hoursOffset, to: Date())!
        let syncStatus = SyncStatus(name: "countries", createdAt: targetDate)
        
        // When
        let result = sut.isValid(syncStatus: syncStatus)
        
        // Then
        #expect(result == expectedResult)
    }
}
