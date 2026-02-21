//
//  FindAllCountries.swift
//  Countries
//
//  Created by Daniel Koster on 2/5/26.
//

import Foundation
import CountriesAPI
import QHValidator
import SwiftData
import os

class DataProviderThing {
    let repo: Repo<SuperModel>
    
    init(repo: Repo<SuperModel>) {
        self.repo = repo
    }
}

protocol SaveRepo {
    func save(element: Data)
}
//
//@ModelActor actor SaveRepoSwiftData: SaveRepo {
//    nonisolated func save(element: Data) {
//        <#code#>
//    }
//}

@Model
class SuperModel {
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

class Repo<T: PersistentModel> {
    let modelContainer: ModelContext
    
    init(modelContainer: ModelContext) {
        self.modelContainer = modelContainer
    }
    
    func save(element: T) {
        modelContainer.insert(element)
    }
}

public protocol DataProvider<Input, Result>: Sendable {
    associatedtype Input: Sendable
    associatedtype Result: Sendable
    func execute(_ input: Input) async throws -> Result
}

public protocol FindAllCountriesDataProvidable: DataProvider<String, [CountryResponse]> {}

public struct FindAllCountriesDataProvider: FindAllCountriesDataProvidable, @unchecked Sendable {
    private let webAPI: AsyncCountryAPI
    private let logger = Logger(subsystem: "CountriesCore", category: "FindAllCountriesDataProvider")
    
    public init(webAPI: AsyncCountryAPI) {
        self.webAPI = webAPI
    }
    
    public func execute(_ input: String) async throws -> [CountriesAPI.CountryResponse] {
        if input.isEmpty {
            logger.debug("\(Thread.current) - no input, finding all countries")
            return try await webAPI.findAll()
        }
        // validate the input
        logger.info("\(Thread.current)Searching countries by Input: \(input)")
        return try await webAPI.findAll(byName: input)
        //validate the output
    }
}
