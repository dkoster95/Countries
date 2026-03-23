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
import PelicanProtocols

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
public class EntityData {
    @Attribute(.unique) var uuid: UUID
    var createdAt: Date
    var updatedAt: Date
    var data: Data
    public init(data: Data) {
        uuid = UUID()
        createdAt = Date()
        updatedAt = Date()
        self.data = data
    }
}

public struct EntityDataTransformer<Item: Codable & Equatable & Sendable>: PersistenModelConvertible {
    let uuid: UUID
    let item: Item
    let createdAt: Date?
    let updatedAt: Date?
    
    public init (item: Item) {
        self.item = item
        self.uuid = UUID()
        createdAt = nil
        updatedAt = nil
    }
    
    public init(from: EntityData) {
        self.uuid = from.uuid
        self.item = try! JSONDecoder().decode(Item.self, from: from.data)
        self.createdAt = from.createdAt
        self.updatedAt = from.updatedAt
    }
    
    public func asEntity() -> EntityData {
        EntityData(data: try! JSONEncoder().encode(item))
    }
    
    public func merge(into: EntityData) {
        into.updatedAt = Date()
        into.data = try! JSONEncoder().encode(item)
    }
    
    public var identifiablePredicate: Predicate<EntityData> {
        let uuid = self.uuid
        return #Predicate { data in
            data.uuid == uuid
        }
    }
    
    public typealias SwiftDataEntity = EntityData
    
    
}

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

public typealias CountryResponseDataTransformer = EntityDataTransformer<CountryResponse>
public typealias FindAllCountriesRepository = AsyncReadableRepository<CountryResponseDataTransformer> &  AsyncBatchRepository<CountryResponseDataTransformer>

public protocol FindAllCountriesRepositoryFactorizable: Sendable {
    func make() -> any FindAllCountriesRepository
}


public struct FindAllCountriesDataProvider: FindAllCountriesDataProvidable, Sendable {
    private let webAPI: AsyncCountryAPI
    private let logger = Logger(subsystem: "CountriesCore", category: "FindAllCountriesDataProvider")
    private let repositoryFactory: FindAllCountriesRepositoryFactorizable
    
    public init(webAPI: AsyncCountryAPI,
                repositoryFactory: FindAllCountriesRepositoryFactorizable) {
        self.webAPI = webAPI
        self.repositoryFactory = repositoryFactory
    }
    
    public func execute(_ input: String) async throws -> [CountriesAPI.CountryResponse] {
        if input.isEmpty {
            logger.debug("\(Thread.current) - no input, finding all countries")
            let repository = repositoryFactory.make()
            logger.debug("\(Thread.current) - repository created")
            let savedCountries = await repository.find()
            if !savedCountries.isEmpty {
                logger.debug("\(Thread.current) - returning saved countries")
                return savedCountries.map { $0.item }
            }
            let response = try await webAPI.find()
            let transformedResponse = response.map { EntityDataTransformer(item: $0) }
            try await repository.add(elements: transformedResponse)
            logger.debug("\(Thread.current) - added all elements")
            return response
        }
        // validate the input
        logger.info("\(Thread.current)Searching countries by Input: \(input)")
        return try await webAPI.find(byName: input)
        //validate the output
    }
}
