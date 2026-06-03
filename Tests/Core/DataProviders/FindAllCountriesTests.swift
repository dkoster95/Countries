//
//  FindAllCountriesTests.swift
//  Countries
//
//  Created by Daniel Koster on 6/3/26.
//
import Testing
import Foundation
import CountriesCore
import CountriesMock
import CountriesAPI

@Suite("Find All Countries Data Provider Tests")
struct FindAllCountriesDataProviderTests {
    
    // MARK: - Search Flow Tests
    
    @Test("execute() with non-empty input invokes search flow and returns sorted countries")
    func executeWithInputInvokesSearchFlow() async throws {
        // Arrange
        let stubbedResponses = [
            CountryResponse.makeStub(commonName: "Uruguay"),
            CountryResponse.makeStub(commonName: "Argentina")
        ]
        let mockAPI = MockAsyncCountryAPI(stubbedFindByNameResult: stubbedResponses)
        let mockFactory = MockRepositoryFactory()
        let mockValidator = MockSyncStatusValidator()
        
        let sut = FindAllCountriesDataProvider(
            webAPI: mockAPI,
            repositoryFactory: mockFactory,
            validator: mockValidator
        )
        
        // Act
        let result = try await sut.execute("Uru")
        
        // Assert
        let apiCallCount = await mockAPI.findByNameCalledCount
        let queryPassed = await mockAPI.lastFindByNameQuery
        
        #expect(apiCallCount == 1)
        #expect(queryPassed == "Uru")
        #expect(result.count == 2)
        #expect(result[0].name == "Argentina") // Sorted verification
        #expect(result[1].name == "Uruguay")
    }
    
    // MARK: - Empty Input / Cache Success Flow Tests
    
    @Test("execute() with empty input returns valid cached data without hitting web API")
    func executeWithValidCacheReturnsLocalData() async throws {
        // Arrange
        let savedStatus = SyncStatus(name: SyncableEntities.countries.rawValue)
        let savedCountries = [
            Country.makeStub(name: "Canada"),
            Country.makeStub(name: "Brazil")
        ]
        
        let countryRepo = MockGenericRepository<Country>(stubbedElements: savedCountries)
        let syncRepo = MockGenericRepository<SyncStatus>(stubbedElements: [savedStatus])
        let mockFactory = MockRepositoryFactory(countryRepository: countryRepo, syncStatusRepository: syncRepo)
        
        let mockAPI = MockAsyncCountryAPI()
        let mockValidator = MockSyncStatusValidator(stubbedIsValidResult: true)
        
        let sut = FindAllCountriesDataProvider(
            webAPI: mockAPI,
            repositoryFactory: mockFactory,
            validator: mockValidator
        )
        
        // Act
        let result = try await sut.execute("")
        
        // Assert
        let apiCallCount = await mockAPI.findCalledCount
        let countryFindCount = await countryRepo.findCalledCount
        let validatorCallCount = mockValidator.isValidCalledCount
        
        #expect(apiCallCount == 0) // Did not hit network
        #expect(validatorCallCount == 1)
        #expect(countryFindCount == 1)
        #expect(result.count == 2)
        #expect(result[0].name == "Brazil") // Sorted verification
    }
    
    // MARK: - Empty Input / Cache Expired Flow Tests
    
    @Test("execute() with empty input clears expired cache, pulls fresh data, and updates sync state")
    func executeWithExpiredCacheDeletesLocalAndRefreshes() async throws {
        // Arrange
        let expiredStatus = SyncStatus(name: SyncableEntities.countries.rawValue)
        
        let countryRepo = MockGenericRepository<Country>()
        let syncRepo = MockGenericRepository<SyncStatus>(stubbedElements: [expiredStatus])
        let mockFactory = MockRepositoryFactory(countryRepository: countryRepo, syncStatusRepository: syncRepo)
        
        let networkResponse = [CountryResponse.makeStub(commonName: "France")]
        let mockAPI = MockAsyncCountryAPI(stubbedFindResult: networkResponse)
        let mockValidator = MockSyncStatusValidator(stubbedIsValidResult: false) // Expired
        
        let sut = FindAllCountriesDataProvider(
            webAPI: mockAPI,
            repositoryFactory: mockFactory,
            validator: mockValidator
        )
        
        // Act
        let result = try await sut.execute("")
        
        // Assert
        let deleteCalledCount = await countryRepo.deleteAllCalledCount
        let apiCallCount = await mockAPI.findCalledCount
        let savedBatchCount = await countryRepo.addBatchCalledCount
        let updatedSyncCount = await syncRepo.addSingleCalledCount
        
        #expect(deleteCalledCount == 1) // Verified cache eviction
        #expect(apiCallCount == 1)      // Verified data refresh
        #expect(savedBatchCount == 1)   // Saved back to database
        #expect(updatedSyncCount == 1)  // Reset sync status timestamp
        #expect(result.count == 1)
        #expect(result.first?.name == "France")
    }
    
    @Test("execute() with empty input pulls from network when no previous sync status exists")
    func executeWithNoCacheFetchesFromNetwork() async throws {
        // Arrange
        let countryRepo = MockGenericRepository<Country>()
        let syncRepo = MockGenericRepository<SyncStatus>(stubbedElements: []) // No cache entry
        let mockFactory = MockRepositoryFactory(countryRepository: countryRepo, syncStatusRepository: syncRepo)
        
        let networkResponse = [CountryResponse.makeStub(commonName: "Japan")]
        let mockAPI = MockAsyncCountryAPI(stubbedFindResult: networkResponse)
        let mockValidator = MockSyncStatusValidator()
        
        let sut = FindAllCountriesDataProvider(
            webAPI: mockAPI,
            repositoryFactory: mockFactory,
            validator: mockValidator
        )
        
        // Act
        let result = try await sut.execute("")
        
        // Assert
        let validatorCallCount = mockValidator.isValidCalledCount
        let deleteCalledCount = await countryRepo.deleteAllCalledCount
        let apiCallCount = await mockAPI.findCalledCount
        
        #expect(validatorCallCount == 0) // Validator skipped since no status was found
        #expect(deleteCalledCount == 0)   // Nothing to delete
        #expect(apiCallCount == 1)        // Hit network directly
        #expect(result.first?.name == "Japan")
    }
    
    // MARK: - Cancellation Boundary Tests
    
    @Test("execute() throws CancellationError early if the caller task was cancelled")
    func executeHandlesCooperativeCancellation() async throws {
        // Arrange
        let mockAPI = MockAsyncCountryAPI()
        let mockFactory = MockRepositoryFactory()
        let mockValidator = MockSyncStatusValidator()
        
        let sut = FindAllCountriesDataProvider(
            webAPI: mockAPI,
            repositoryFactory: mockFactory,
            validator: mockValidator
        )
        
        // Act & Assert
        let task = Task {
            try await sut.execute("")
        }
        task.cancel()
        
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}


extension Country {
    /// Convenience initializer for tests to avoid passing every argument manually
    static func makeStub(
        uuid: UUID = UUID(),
        name: String,
        flagURL: String? = nil,
        region: String? = nil,
        subregion: String? = nil,
        languages: String? = nil
    ) -> Country {
        Country(
            uuid: uuid,
            name: name,
            flagURL: flagURL,
            region: region,
            subregion: subregion,
            languages: languages
        )
    }
}

extension CountryResponse {
    /// Convenience initializer for tests to quickly stub network payloads
    static func makeStub(
        commonName: String,
        pngFlag: String? = nil,
        languages: [String: String]? = nil,
        region: String? = nil,
        subregion: String? = nil
    ) -> CountryResponse {
        let nameContainer = Name(common: commonName, official: nil, nativeName: nil)
        let flagsContainer = Flags(png: pngFlag, svg: nil, alt: nil)
        
        return CountryResponse(
            name: nameContainer,
            flags: flagsContainer,
            languages: languages,
            region: region,
            subregion: subregion
        )
    }
}

