//
//  CountriesFactory.swift
//  Countries
//
//  Created by Daniel Koster on 6/11/26.
//
import Foundation
import CountriesCore
import PelicanProtocols
import PelicanRepositories
import SwiftData

public struct FindAllCountriesRepositoryFactory: FindAllCountriesRepositoryFactorizable {
    private let modelContainer: ModelContainer
    
    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    public func make() -> any FindAllCountriesRepository {
        return SwiftDataRepository<Country>(modelContainer: modelContainer)
    }
    
    public func makeSyncStatus() -> any SyncStatusRepository {
        return SwiftDataRepository<SyncStatus>(modelContainer: modelContainer)
    }
}

public struct OfflineValidationRepositoryFactory<Entity: PersistenModelConvertible>: OfflineStatusValidationRepositoryFactorizable {
    private let modelContainer: ModelContainer
    
    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    public func make() -> any PelicanProtocols.AsyncDeleteableRepository<Entity> where Entity : Equatable, Entity : Sendable {
        return SwiftDataRepository<Entity>(modelContainer: modelContainer)
    }
    
    public func makeSyncStatus() -> any CountriesCore.SyncStatusRepository {
        return SwiftDataRepository<SyncStatus>(modelContainer: modelContainer)
    }
}

public struct FindCountriesDataProviderFactory: FindCountriesDataProviderFactorizable {
    private let findAll: any FindAllCountriesDataProvidable
    private let search: any SearchCountriesDataProvidable
    
    init(findAll: any FindAllCountriesDataProvidable,
         search: any SearchCountriesDataProvidable) {
        self.findAll = findAll
        self.search = search
    }
    
    public func makeFindAll() -> any CountriesCore.FindAllCountriesDataProvidable {
        findAll
    }
    
    public func makeSearch() -> any CountriesCore.SearchCountriesDataProvidable {
        search
    }
    
    
}
