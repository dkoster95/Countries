//
//  Mocks.swift
//  Countries
//
//  Created by Daniel Koster on 6/3/26.
//
import Foundation
import PelicanProtocols
import CountriesCore
import CountriesAPI

public final class MockSyncStatusValidator: SyncStatusValidator, @unchecked Sendable {
    
    // MARK: - Stub Configurations
    private var _stubbedIsValidResult: Bool = false
    public var stubbedIsValidResult: Bool {
        get { _stubbedIsValidResult }
        set { _stubbedIsValidResult = newValue }
    }
    
    // MARK: - Interaction Spies
    private var _isValidCalledCount = 0
    public var isValidCalledCount: Int {
        _isValidCalledCount
    }
    
    private var _lastValidatedSyncStatus: SyncStatus?
    public var lastValidatedSyncStatus: SyncStatus? {
        _lastValidatedSyncStatus
    }
    
    // MARK: - Initialization
    public init(stubbedIsValidResult: Bool = false) {
        self._stubbedIsValidResult = stubbedIsValidResult
    }
    
    // MARK: - SyncStatusValidator Protocol Method
    public func isValid(syncStatus: SyncStatus) -> Bool {
        _isValidCalledCount += 1
        _lastValidatedSyncStatus = syncStatus
        let result = _stubbedIsValidResult
        return result
    }

}


public actor MockAsyncCountryAPI: AsyncCountryAPI {
    // MARK: - Stub Configurations
    public var stubbedFindResult: [CountryResponse] = []
    public var stubbedFindByNameResult: [CountryResponse] = []
    public var stubbedFindByCodeResult: [CountryResponse] = []
    public var shouldThrowError: Error?
    
    // MARK: - Interaction Spies
    public private(set) var findCalledCount = 0
    
    public private(set) var findByNameCalledCount = 0
    public private(set) var lastFindByNameQuery: String?
    
    public private(set) var findByCodeCalledCount = 0
    public private(set) var lastFindByCodeQuery: String?
    
    public init(
        stubbedFindResult: [CountryResponse] = [],
        stubbedFindByNameResult: [CountryResponse] = [],
        stubbedFindByCodeResult: [CountryResponse] = [],
        shouldThrowError: Error? = nil
    ) {
        self.stubbedFindResult = stubbedFindResult
        self.stubbedFindByNameResult = stubbedFindByNameResult
        self.stubbedFindByCodeResult = stubbedFindByCodeResult
        self.shouldThrowError = shouldThrowError
    }
    
    // MARK: - AsyncCountryAPI Protocol Methods
    
    public func find() async throws -> [CountryResponse] {
        findCalledCount += 1
        if let error = shouldThrowError { throw error }
        return stubbedFindResult
    }
    
    public func find(byName name: String) async throws -> [CountryResponse] {
        findByNameCalledCount += 1
        lastFindByNameQuery = name
        if let error = shouldThrowError { throw error }
        return stubbedFindByNameResult
    }
    
    public func find(byCode code: String) async throws -> [CountryResponse] {
        findByCodeCalledCount += 1
        lastFindByCodeQuery = code
        if let error = shouldThrowError { throw error }
        return stubbedFindByCodeResult
    }
}

public struct MockRepositoryFactory: FindAllCountriesRepositoryFactorizable {
    public let countryRepository: MockGenericRepository<Country>
    public let syncStatusRepository: MockGenericRepository<SyncStatus>
    
    public init(
        countryRepository: MockGenericRepository<Country> = MockGenericRepository<Country>(),
        syncStatusRepository: MockGenericRepository<SyncStatus> = MockGenericRepository<SyncStatus>()
    ) {
        self.countryRepository = countryRepository
        self.syncStatusRepository = syncStatusRepository
    }
    
    // Satisfies your architecture's repository creation calls
    public func make() -> any CountriesCore.FindAllCountriesRepository {
        return countryRepository
    }
    
    public func makeSyncStatus() -> any CountriesCore.SyncStatusRepository {
        return syncStatusRepository
    }
}


public actor MockGenericRepository<Element: Equatable & Sendable>:
    AsyncReadableRepository,
    AsyncBatchRepository,
    AsyncDeleteableRepository,
    AsyncInsertableRepository,
    AsyncUpdatableRepository
{
    // MARK: - Stub Configurations
    public var stubbedElements: [Element] = []
    public var stubbedContainsResult: Bool = false
    public var stubbedInsertedElement: Element?
    public var stubbedUpdatedElement: Element?
    public var shouldThrowError: Error?
    
    // MARK: - Interaction Spies
    public private(set) var findCalledCount = 0
    public private(set) var containsCalledCount = 0
    public private(set) var lastContainsElement: Element?
    
    public private(set) var addBatchCalledCount = 0
    public private(set) var receivedBatchElements: [Element] = []
    
    public private(set) var deleteCalledCount = 0
    public private(set) var lastDeletedElement: Element?
    public private(set) var deleteAllCalledCount = 0
    
    public private(set) var addSingleCalledCount = 0
    public private(set) var lastAddedSingleElement: Element?
    
    public private(set) var updateCalledCount = 0
    public private(set) var lastUpdatedElement: Element?

    public init(
        stubbedElements: [Element] = [],
        stubbedContainsResult: Bool = false,
        shouldThrowError: Error? = nil
    ) {
        self.stubbedElements = stubbedElements
        self.stubbedContainsResult = stubbedContainsResult
        self.shouldThrowError = shouldThrowError
    }
    
    // MARK: - AsyncReadableRepository Protocol
    public func find(query: (@Sendable (Element) -> Bool)?) async -> [Element] {
        findCalledCount += 1
        if let query = query {
            return stubbedElements.filter(query)
        }
        return stubbedElements
    }
    
    public func contains(element: Element) async -> Bool {
        containsCalledCount += 1
        lastContainsElement = element
        return stubbedContainsResult
    }
    
    // MARK: - AsyncBatchRepository Protocol
    public func add(elements: [Element]) async throws {
        addBatchCalledCount += 1
        receivedBatchElements.append(contentsOf: elements)
        if let error = shouldThrowError { throw error }
    }
    
    // MARK: - AsyncDeleteableRepository Protocol
    public func delete(element: Element) async throws {
        deleteCalledCount += 1
        lastDeletedElement = element
        if let error = shouldThrowError { throw error }
    }
    
    public func deleteAll() async throws {
        deleteAllCalledCount += 1
        if let error = shouldThrowError { throw error }
    }
    
    // MARK: - AsyncInsertableRepository Protocol
    public func add(element: Element) async throws -> Element {
        addSingleCalledCount += 1
        lastAddedSingleElement = element
        if let error = shouldThrowError { throw error }
        return stubbedInsertedElement ?? element
    }
    
    // MARK: - AsyncUpdatableRepository Protocol
    public func update(element: Element) async throws -> Element {
        updateCalledCount += 1
        lastUpdatedElement = element
        if let error = shouldThrowError { throw error }
        return stubbedUpdatedElement ?? element
    }
}
