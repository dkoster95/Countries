//
//  FindAllCountriesByInput.swift
//  Countries
//
//  Created by Daniel Koster on 6/11/26.
//


import Foundation
import CountriesAPI
import QHValidator
import SwiftData
import os
import PelicanProtocols
import QuickHatchCore
import QuickHatchAsync

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

public protocol FindCountriesDataProvidable: DataProvider<String, [Country]> {}

public protocol FindCountriesDataProviderFactorizable: Sendable {
    func makeFindAll() -> any FindAllCountriesDataProvidable
    func makeSearch() -> any SearchCountriesDataProvidable
}

public struct FindCountriesDataProvider: FindCountriesDataProvidable {
    private let dataProviderFactory: FindCountriesDataProviderFactorizable
    
    public init(dataProviderFactory: FindCountriesDataProviderFactorizable) {
        self.dataProviderFactory = dataProviderFactory
    }
    
    public func execute(_ input: String) async throws -> Array<Country> {
        if input.isEmpty {
            return try await dataProviderFactory.makeFindAll().execute(())
        }
        return try await dataProviderFactory.makeSearch().execute(input)
    }
    
    
}


//public struct FindCountriesDataProvider: FindCountriesDataProvidable, Sendable {
//    private let webAPI: AsyncCountryAPI
//    private let logger = Logger(subsystem: "Countries.Core", category: "FindAllCountriesDataProvider")
//    private let repositoryFactory: FindAllCountriesRepositoryFactorizable
//    private let validator: SyncStatusValidator
//    
//    public init(webAPI: AsyncCountryAPI,
//                repositoryFactory: FindAllCountriesRepositoryFactorizable,
//                validator: SyncStatusValidator) {
//        self.webAPI = webAPI
//        self.repositoryFactory = repositoryFactory
//        self.validator = validator
//    }
//    
//    public func execute(_ input: String) async throws -> [Country] {
//        try Task.checkCancellation()
//        if input.isEmpty {
////            return try await TaskCoalescer.shared.execute(id: "findAllCountries") {
//                return try await findAll()
////            }
//        }
////        return try await TaskSerializer.shared.execute(id: "searchCountriesByName") {
//            return try await search(input: input)
////        }
//    }
//
//    
//    private func search(input: String) async throws -> [Country] {
//        try Task.checkCancellation()
//        // validate the input
//        logger.info("\(Thread.current)Searching countries by Input: \(input)")
//        return try await webAPI.find(byName: input)
//            .compactMap { $0.asCountry }
//            .sorted { $0.name < $1.name }
//        //validate the output
//    }
//    
//    private func findAll() async throws -> [Country] {
//        try Task.checkCancellation()
//        logger.debug("\(Thread.current) - finding all countries")
//        
//        let repository = repositoryFactory.make()
//        let syncStatusRepository = repositoryFactory.makeSyncStatus()
//        logger.debug("\(Thread.current) - repository created")
//        logger.info("Finding sync status for \(SyncableEntities.countries.rawValue)")
//        if let countriesSyncStatus = await syncStatusRepository.find (query: { $0.name == SyncableEntities.countries.rawValue }).first {
//            // check expiration date for sync status
//            logger.info("Sync status for \(SyncableEntities.countries.rawValue) found!")
//            if validator.isValid(syncStatus: countriesSyncStatus) {
//                let savedCountries = await repository.find()
//                if !savedCountries.isEmpty {
//                    logger.debug("\(Thread.current) - returning saved countries")
//                    return savedCountries.sorted { $0.name < $1.name }
//                }
//            } else {
//                logger.info("Storage expiration reached proceeding to remove all countries")
//                try await repository.deleteAll()
//                logger.info("All countries deleted")
//            }
//        }
//        try Task.checkCancellation()
//        logger.debug("\(Thread.current) - No data saved, downloading all countries")
//        let response = try await webAPI.find()
//        logger.debug("\(response.count) - Country responses downloaded")
//        let transformedResponse = response.compactMap { $0.asCountry }
//        logger.info("\(transformedResponse.count) valid countries detected")
//        try await repository.add(elements: transformedResponse)
//        logger.debug("\(Thread.current) - added all elements")
//        let syncStatus = SyncStatus(name: SyncableEntities.countries.rawValue)
//        _ = try await syncStatusRepository.add(element: syncStatus)
//        logger.info("Sync status updated")
//        return transformedResponse.sorted { $0.name < $1.name }
//    }
//}
//
