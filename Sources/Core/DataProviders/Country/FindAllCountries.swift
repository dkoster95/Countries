//
//  FindAllCountries.swift
//  Countries
//
//  Created by Daniel Koster on 6/11/26.
//
import Foundation
import QuickHatchCore
import CountriesAPI
import PelicanProtocols
import os
import QuickHatchAsync

public protocol FindAllCountriesDataProvidable: DataProvider<Void, [Country]> {}

public typealias FindAllCountriesRepository = AsyncReadableRepository<Country> & AsyncBatchRepository<Country> & AsyncDeleteableRepository<Country> & Sendable
public typealias SyncStatusRepository = AsyncReadableRepository<SyncStatus> & AsyncInsertableRepository<SyncStatus> & AsyncDeleteableRepository<SyncStatus> & Sendable

public protocol FindAllCountriesRepositoryFactorizable: Sendable {
    func make() -> any FindAllCountriesRepository
    func makeSyncStatus() -> any SyncStatusRepository
}


public struct FindAllCountriesDataProvider: FindAllCountriesDataProvidable, Sendable {
    private let webAPI: AsyncCountryAPI
    private let logger = Logger(subsystem: "Countries.Core", category: "FindAllCountriesDataProvider")
    private let offlineStatusValidationDataProvider: any OfflineStatusValidationDataProvidable
    private let taskCoalescer: TaskCoalescing
    private let countryRepository: any FindAllCountriesRepository
    private let syncStatusRepository: any SyncStatusRepository
    
    public init(webAPI: AsyncCountryAPI,
                repositoryFactory: FindAllCountriesRepositoryFactorizable,
                offlineStatusValidationDataProvider: any OfflineStatusValidationDataProvidable,
                taskCoalescer: TaskCoalescing) {
        self.webAPI = webAPI
        self.offlineStatusValidationDataProvider = offlineStatusValidationDataProvider
        self.taskCoalescer = taskCoalescer
        self.countryRepository = repositoryFactory.make()
        self.syncStatusRepository = repositoryFactory.makeSyncStatus()
    }
    
    public func execute(_ input: Void) async throws -> [Country] {
        try Task.checkCancellation()
        return try await taskCoalescer.execute(id: "find_all_countries", evictionTimeout: .seconds(30)) {
            return try await findAll()
        }
    }
    
    private func isOfflineStatusValid() async throws -> Bool {
        return try await offlineStatusValidationDataProvider.execute(SyncableEntities.countries)
    }
    
    private func findAll() async throws -> [Country] {
        try Task.checkCancellation()
        logger.debug("\(Thread.current) - finding all countries")
        
        logger.debug("\(Thread.current) - repository created")
        logger.info("Finding sync status for \(SyncableEntities.countries.rawValue)")
        if try await isOfflineStatusValid() {
                let savedCountries = await countryRepository.find()
                if !savedCountries.isEmpty {
                    logger.debug("\(Thread.current) - returning saved countries")
                    return savedCountries.sorted { $0.name < $1.name }
                }
        }
        try Task.checkCancellation()
        logger.debug("\(Thread.current) - No data saved, downloading all countries")
        let response = try await webAPI.find()
        logger.debug("\(response.count) - Country responses downloaded")
        let transformedResponse = response.compactMap { $0.asCountry }
        logger.info("\(transformedResponse.count) valid countries detected")
        try await countryRepository.add(elements: transformedResponse)
        logger.debug("\(Thread.current) - added all elements")
        let syncStatus = SyncStatus(name: SyncableEntities.countries.rawValue)
        _ = try await syncStatusRepository.add(element: syncStatus)
        logger.info("Sync status updated")
        return transformedResponse.sorted { $0.name < $1.name }
    }
}
