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
    private let findAllDataProvider: any FindAllCountriesDataProvidable
    private let searchDataProvider: any SearchCountriesDataProvidable
    
    public init(dataProviderFactory: FindCountriesDataProviderFactorizable) {
        self.findAllDataProvider = dataProviderFactory.makeFindAll()
        self.searchDataProvider = dataProviderFactory.makeSearch()
    }
    
    public func execute(_ input: String) async throws -> Array<Country> {
        if input.isEmpty {
            return try await findAllDataProvider.execute(())
        }
        return try await searchDataProvider.execute(input)
    }
    
    
}
