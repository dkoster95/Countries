//
//  CountryResponse+MapperTests.swift
//  Countries
//
//  Created by Daniel Koster on 6/3/26.
//
import Testing
import Foundation
@testable import CountriesCore
import CountriesAPI

@Suite("Country Response Extension Tests")
struct CountryResponseExtensionTests {
    
    // MARK: - languagesString Tests
    
    @Test("languagesString returns empty string when languages dictionary is nil")
    func languagesStringWithNilLanguages() {
        // Given
        let response = CountryResponse(name: nil, flags: nil, languages: nil, region: nil, subregion: nil)
        
        // Then
        #expect(response.languagesString == "")
    }
    
    @Test("languagesString returns empty string when languages dictionary is empty")
    func languagesStringWithEmptyLanguages() {
        // Given
        let response = CountryResponse(name: nil, flags: nil, languages: [:], region: nil, subregion: nil)
        
        // Then
        #expect(response.languagesString == "")
    }
    
    @Test("languagesString formats a single language correctly")
    func languagesStringWithSingleLanguage() {
        // Given
        let response = CountryResponse(
            name: nil,
            flags: nil,
            languages: ["spa": "Spanish"],
            region: nil,
            subregion: nil
        )
        
        // Then
        #expect(response.languagesString == "spa:Spanish")
    }
    
    @Test("languagesString converts multiple languages sorted or joined cleanly with semicolons")
    func languagesStringWithMultipleLanguages() {
        // Given
        let response = CountryResponse(
            name: nil,
            flags: nil,
            languages: ["eng": "English", "fra": "French"],
            region: nil,
            subregion: nil
        )
        
        // When
        let result = response.languagesString
        
        // Then
        // Dictionary iteration order is non-deterministic in Swift, so we verify both possible valid string outputs
        let validOutputs = ["eng:English;fra:French", "fra:French;eng:English"]
        #expect(validOutputs.contains(result))
    }
    
    // MARK: - asCountry Mapping Tests
    
    @Test("asCountry returns nil when the common name is missing")
    func asCountryReturnsNilWhenCommonNameIsNil() {
        // Given
        let nameWithNoCommon = Name(common: nil, official: "Official Name", nativeName: nil)
        let response = CountryResponse(name: nameWithNoCommon, flags: nil, languages: nil, region: nil, subregion: nil)
        
        // Then
        #expect(response.asCountry == nil)
    }
    
    @Test("asCountry returns nil when the entire name container is missing")
    func asCountryReturnsNilWhenNameContainerIsNil() {
        // Given
        let response = CountryResponse(name: nil, flags: nil, languages: nil, region: nil, subregion: nil)
        
        // Then
        #expect(response.asCountry == nil)
    }
    
    @Test("asCountry maps all properties successfully when a common name exists")
    func asCountryMapsAllPropertiesSuccessfully() throws {
        // Given
        let nameContainer = Name(common: "Uruguay", official: "Oriental Republic of Uruguay", nativeName: nil)
        let flagsContainer = Flags(png: "https://example.com", svg: nil, alt: nil)
        let response = CountryResponse(
            name: nameContainer,
            flags: flagsContainer,
            languages: ["spa": "Spanish"],
            region: "Americas",
            subregion: "South America"
        )
        
        // When
        let country = response.asCountry
        
        // Then
        let unwrappedCountry = try #require(country) // Halts test early if country mapping failed and returned nil
        
        #expect(unwrappedCountry.name == "Uruguay")
        #expect(unwrappedCountry.flagURL == "https://example.com")
        #expect(unwrappedCountry.region == "Americas")
        #expect(unwrappedCountry.subregion == "South America")
        #expect(unwrappedCountry.languages == "spa:Spanish")
        #expect(unwrappedCountry.uuid != UUID(uuidString: "00000000-0000-0000-0000-000000000000")) // Verifies a real UUID was assigned
    }
}
