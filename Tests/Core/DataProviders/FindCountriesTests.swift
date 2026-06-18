//
//  FindCountriesTests.swift
//  Countries
//
//  Created by Daniel Koster on 6/18/26.
//
//
//  FindCountriesDataProviderTests.swift
//  CountriesTests
//
//  Created by Daniel Koster on 6/18/26.
//

import Testing
import Foundation
import PelicanProtocols
@testable import CountriesCore
import CountriesMock

@Suite("FindCountriesDataProvider Routing Logic Tests")
struct FindCountriesDataProviderTests {
    
    // MARK: - Test Context Helper
    private struct TestContext {
        let factory: MockFindCountriesDataProviderFactory
        let sut: FindCountriesDataProvider
        
        init() {
            self.factory = MockFindCountriesDataProviderFactory()
            self.sut = FindCountriesDataProvider(dataProviderFactory: factory)
        }
    }
    
    // MARK: - Test Cases

    @Test("When input string parameter is empty, route execution flow directly to FindAll provider pipeline")
    func testRoutesToFindAllWhenInputIsEmpty() async throws {
        // Arrange
        let context = TestContext()
        let expectedCountries = [Country(name: "Argentina"), Country(name: "Uruguay")]
        context.factory.mockFindAll.stubSuccess(expectedCountries)
        
        // Act
        let result = try await context.sut.execute("")
        
        // Assert
        #expect(result.count == 2)
        #expect(result.first?.name == "Argentina")
        
        // Spy Assertions
        #expect(context.factory.mockFindAll.executeCalledCount == 1)
        #expect(context.factory.mockSearch.executeCalledCount == 0)
    }
    
    @Test("When input string parameter is populated, forward parameter token and route execution to Search provider pipeline")
    func testRoutesToSearchWhenInputIsNotEmpty() async throws {
        // Arrange
        let context = TestContext()
        let expectedCountries = [Country(name: "Brazil")]
        context.factory.mockSearch.stubSuccess(expectedCountries)
        
        // Act
        let result = try await context.sut.execute("Braz")
        
        // Assert
        #expect(result.count == 1)
        #expect(result.first?.name == "Brazil")
        
        // Spy Assertions
        #expect(context.factory.mockSearch.executeCalledCount == 1)
        #expect(context.factory.mockSearch.lastExecutedInput == "Braz")
        #expect(context.factory.mockFindAll.executeCalledCount == 0)
    }
}

