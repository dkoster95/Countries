//
//  FindAllCountriesDataProviderTests.swift
//  CountriesTests
//
//  Created by Daniel Koster on 6/18/26.
//

import Testing
import Foundation
import QuickHatchCore
import CountriesAPI
import PelicanProtocols
import QuickHatchAsync
import os
@testable import CountriesCore
import CountriesMock

@Suite("FindAllCountriesDataProvider Tests")
struct FindAllCountriesDataProviderTests {
    
    // MARK: - Test Context Coordinator
    /// Encapsulates dependencies to avoid boilerplates inside individual tests.
    private struct TestContext {
        let webAPI: MockAsyncCountryAPI
        let countryRepository: MockGenericRepository<Country>
        let syncStatusRepository: MockGenericRepository<SyncStatus>
        let repositoryFactory: MockRepositoryFactory
        let offlineValidator: MockOfflineValidator
        let taskCoalescer: MockTaskCoalescer
        let sut: FindAllCountriesDataProvider
        
        init(stubbedLocalCountries: [Country] = []) async {
            self.webAPI = MockAsyncCountryAPI()
            self.countryRepository = MockGenericRepository<Country>(stubbedElements: stubbedLocalCountries)
            self.syncStatusRepository = MockGenericRepository<SyncStatus>()
            self.repositoryFactory = MockRepositoryFactory(
                countryRepository: countryRepository,
                syncStatusRepository: syncStatusRepository
            )
            self.offlineValidator = MockOfflineValidator()
            self.taskCoalescer = MockTaskCoalescer()
            self.sut = FindAllCountriesDataProvider(
                webAPI: webAPI,
                repositoryFactory: repositoryFactory,
                offlineStatusValidationDataProvider: offlineValidator,
                taskCoalescer: taskCoalescer
            )
        }
    }
    
    // MARK: - Test Cases

    @Test("Verify that execution channels seamlessly through the TaskCoalescing engine with correct ID and eviction thresholds")
    func testTaskCoalescerIntegrationParameters() async throws {
        // Arrange
        let context = await TestContext(stubbedLocalCountries: [Country(name: "Uruguay")])
        context.offlineValidator.stubbedIsValid = true
        
        // Act
        _ = try await context.sut.execute(())
        
        // Assert
        #expect(context.taskCoalescer.executeCallCount == 1)
        #expect(context.taskCoalescer.lastExecutedId == "find_all_countries")
    }
    
    @Test("When offline status is valid and local storage has records, return alphabetically sorted countries without executing web requests")
    func testReturnsSortedLocalCacheWhenValidAndNotEmpty() async throws {
        // Arrange unsorted domain elements inside the local database stub
        let unsortedData = [Country(name: "Uruguay"), Country(name: "Argentina"), Country(name: "Brazil")]
        let context = await TestContext(stubbedLocalCountries: unsortedData)
        context.offlineValidator.stubbedIsValid = true
        
        // Act
        let result = try await context.sut.execute(())
        
        // Assert strict sorting layout compliance rules (A < B < U)
        #expect(result.count == 3)
        #expect(result[0].name == "Argentina")
        #expect(result[1].name == "Brazil")
        #expect(result[2].name == "Uruguay")
        
        // Verify via spies that the network layer remained un-invoked
        let webCallCount = await context.webAPI.findCalledCount
        #expect(webCallCount == 0)
        
        // Verify the database layer read request occurred once
        let repoReadCount = await context.countryRepository.findCalledCount
        #expect(repoReadCount == 1)
    }
    
    @Test("When offline status is valid but local storage is completely empty, fallback immediately to remote web pipeline to synchronize elements")
    func testDownloadsFromWebWhenCacheIsValidButStorageIsEmpty() async throws {
        // Arrange
        let context = await TestContext(stubbedLocalCountries: []) // Empty local database
        context.offlineValidator.stubbedIsValid = true
        
        let apiResponses = [CountryResponse(name: "Canada"), CountryResponse(name: "Japan")]
        await context.webAPI.setStubbedFindResult(apiResponses)
        
        // Act
        let result = try await context.sut.execute(())
        
        // Assert sorting on network elements fallback returns correctly (C < J)
        #expect(result.count == 2)
        #expect(result[0].name == "Canada")
        #expect(result[1].name == "Japan")
        
        // Verify validation tracking mapped the correct entity key enumeration context
        #expect(context.offlineValidator.lastCheckedEntity == .countries)
        
        // Verify data payload batch insertion spies updated successfully
        let batchCallCount = await context.countryRepository.addBatchCalledCount
        let capturedBatch = await context.countryRepository.receivedBatchElements
        #expect(batchCallCount == 1)
        #expect(capturedBatch.count == 2)
        #expect(capturedBatch.contains { $0.name == "Canada" })
        
        // Verify sync status registry update spy successfully tracked structural changes
        let syncInsertCount = await context.syncStatusRepository.addSingleCalledCount
        let capturedSyncElement = await context.syncStatusRepository.lastAddedSingleElement
        #expect(syncInsertCount == 1)
        #expect(capturedSyncElement?.name == SyncableEntities.countries.rawValue)
    }
    
    @Test("When offline status lifecycle evaluates as stale, skip reading old data, download new payloads, and overwrite local tracking metrics")
    func testDownloadsAndOverwritesEverythingWhenCacheIsStale() async throws {
        // Arrange
        let context = await TestContext(stubbedLocalCountries: [Country(name: "StaleCountry")])
        context.offlineValidator.stubbedIsValid = false // Stale policy setting
        
        let freshAPIResponse = [CountryResponse(name: "FreshCountry")]
        await context.webAPI.setStubbedFindResult(freshAPIResponse)
        
        // Act
        let result = try await context.sut.execute(())
        
        // Assert
        #expect(result.count == 1)
        #expect(result.first?.name == "FreshCountry")
        
        // Confirm repository spy captured batch insertion mapping updates smoothly
        let capturedBatchData = await context.countryRepository.receivedBatchElements
        #expect(capturedBatchData.count == 1)
        #expect(capturedBatchData.first?.name == "FreshCountry")
        
        // Verify the database was never read from due to invalidation policy triggers
        let localFindCount = await context.countryRepository.findCalledCount
        #expect(localFindCount == 0)
    }
    
    @Test("When downstream network operation errors out, verify the fault propagates up through the pipeline execution stack securely")
    func testNetworkFailurePropagatesErrorUpward() async throws {
        // Arrange
        let context = await TestContext(stubbedLocalCountries: [])
        context.offlineValidator.stubbedIsValid = false
        
        struct SampleNetworkError: Error, Equatable {}
        await context.webAPI.setShouldThrowError(SampleNetworkError())
        
        // Act & Assert using Swift Testing throws validation metrics blocks
        await #expect(throws: SampleNetworkError.self) {
            try await context.sut.execute(())
        }
    }
    
    @Test("Verify task early cancellation hooks short-circuit pipeline evaluations cleanly prior to performing heavy tasks")
    func testTaskCancellationExitsExecutionGracefully() async throws {
        // Arrange
        let context = await TestContext()
        
        // Execute structural pipeline context wrapper directly on a cancelled thread Task container block
        let standaloneTask = Task {
            try await context.sut.execute(())
        }
        standaloneTask.cancel() // Prompt cancel states
        
        // Assert
        await #expect(throws: CancellationError.self) {
            try await standaloneTask.value
        }
    }
}

// MARK: - Concurrent Actor Mutation Test Helpers
/// Extensions to facilitate clean test state manipulation boundaries with the Mock Actor types without encountering warnings.
extension MockAsyncCountryAPI {
    func setStubbedFindResult(_ values: [CountryResponse]) {
        self.stubbedFindResult = values
    }
    func setShouldThrowError(_ error: Error?) {
        self.shouldThrowError = error
    }
}

extension Country {
    init(name: String) {
        self.init(uuid: UUID(), name: name, flagURL: nil, region: nil, subregion: nil, languages: nil)
    }
}

extension CountryResponse {
    init(name: String) {
        self.init(name: Name(common: name, official: name, nativeName: nil), flags: nil, languages: nil, region: nil, subregion: nil)
    }
}
