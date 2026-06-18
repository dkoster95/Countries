//
//  SearchCountriesByNameTests.swift
//  Countries
//
//  Created by Daniel Koster on 6/18/26.


import Testing
import Foundation
import QuickHatchCore
import CountriesAPI
import PelicanProtocols
import QuickHatchAsync
import os
@testable import CountriesCore
import CountriesMock

@Suite("SearchCountriesByNameDataProvider Tests")
struct SearchCountriesByNameDataProviderTests {
    
    // MARK: - Test Context Coordinator
    private struct TestContext {
        let webAPI: MockAsyncCountryAPI
        let taskSerializer: MockTaskSerializer
        let sut: SearchCountriesByNameDataProvider
        
        init() {
            self.webAPI = MockAsyncCountryAPI()
            self.taskSerializer = MockTaskSerializer()
            self.sut = SearchCountriesByNameDataProvider(
                webAPI: webAPI,
                taskSerializer: taskSerializer
            )
        }
    }
    
    // MARK: - Test Cases

    @Test("Verify that execution channels seamlessly through the TaskSerializing engine with correct tracking ID context")
    func testTaskSerializerIntegrationParameters() async throws {
        let context = TestContext()
        
        _ = try await context.sut.execute("Uruguay")
        
        #expect(context.taskSerializer.executeCallCount == 1)
        #expect(context.taskSerializer.lastExecutedId == "search_countries_by_name")
    }
    
    @Test("When matching countries are found, map network responses to domain formats and return them strictly alphabetized")
    func testReturnsSortedMappedCountriesOnSuccessfulSearch() async throws {
        let context = TestContext()
        
        // Arrange unsorted items in the actor stub
        let unsortedResponses = [
            CountryResponse(name: "Uruguay"),
            CountryResponse(name: "Argentina"),
            CountryResponse(name: "Brazil")
        ]
        await context.webAPI.setStubbedFindByNameResult(unsortedResponses)
        
        // Act
        let result = try await context.sut.execute("South America")
        
        // Assert alphabetical sorting behavior transformation: Argentina -> Brazil -> Uruguay
        #expect(result.count == 3)
        #expect(result[0].name == "Argentina")
        #expect(result[1].name == "Brazil")
        #expect(result[2].name == "Uruguay")
        
        // Spy checking on argument forwarding logic tracking signatures
        let searchCount = await context.webAPI.findByNameCalledCount
        let queryQuery = await context.webAPI.lastFindByNameQuery
        #expect(searchCount == 1)
        #expect(queryQuery == "South America")
    }

    @Test("When network operation errors out, verify fault propagates up the execution stack safely")
    func testSearchFailurePropagatesErrorUpward() async throws {
        let context = TestContext()
        
        struct SearchNetworkError: Error, Equatable {}
        await context.webAPI.setShouldThrowError(SearchNetworkError())
        
        // Act & Assert
        await #expect(throws: SearchNetworkError.self) {
            try await context.sut.execute("ErrorTrigger")
        }
    }

    @Test("Verify task early cancellation hooks short-circuit query evaluation pathways prior to network execution transitions")
    func testTaskCancellationExitsExecutionGracefully() async throws {
        let context = TestContext()
        
        let cancellationTask = Task {
            try await context.sut.execute("Canada")
        }
        cancellationTask.cancel() // Invoke structural breakdown states
        
        await #expect(throws: CancellationError.self) {
            try await cancellationTask.value
        }
    }
}

// MARK: - Concurrent Actor Mutation Test Helpers
extension MockAsyncCountryAPI {
    func setStubbedFindByNameResult(_ values: [CountryResponse]) {
        self.stubbedFindByNameResult = values
    }
}

