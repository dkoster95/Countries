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
import QuickHatchCore

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

public protocol FindAllCountriesDataProvidable: DataProvider<String, [Country]> {}

public typealias FindAllCountriesRepository = AsyncReadableRepository<Country> & AsyncBatchRepository<Country>

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
    
    public func execute(_ input: String) async throws -> [Country] {
        if input.isEmpty {
            logger.debug("\(Thread.current) - no input, finding all countries")
            let repository = repositoryFactory.make()
            logger.debug("\(Thread.current) - repository created")
            let savedCountries = await repository.find()
            if !savedCountries.isEmpty {
                logger.debug("\(Thread.current) - returning saved countries")
                return savedCountries.sorted { $0.name < $1.name }
            }
            let response = try await webAPI.find()
            let transformedResponse = response.compactMap { $0.asCountry }
            logger.info("\(transformedResponse.count) valid countries mapped")
            try await repository.add(elements: transformedResponse)
            logger.debug("\(Thread.current) - added all elements")
            return transformedResponse.sorted { $0.name < $1.name }
        }
        // validate the input
        logger.info("\(Thread.current)Searching countries by Input: \(input)")
        return try await webAPI.find(byName: input)
            .compactMap { $0.asCountry }
            .sorted { $0.name < $1.name }
        //validate the output
    }
}
