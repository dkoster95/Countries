//
//  SearchCountriesByName.swift
//  Countries
//
//  Created by Daniel Koster on 6/9/26.
//
import Foundation
import QuickHatchCore
import CountriesAPI
import QuickHatchAsync
import PelicanProtocols
import os

public protocol SearchCountriesDataProvidable: DataProvider<String, [Country]> {}

public protocol SearchCountriesRepositoryFactorizable: Sendable {
    func make() -> any SearchCountriesRepository
}

public typealias SearchCountriesRepository = AsyncPredicableReadableRepository<CountryEntity, Country> & Sendable

public struct SearchCountriesByNameDataProvider: SearchCountriesDataProvidable {
    private let webAPI: AsyncCountryAPI
    private let logger = Logger(subsystem: "Countries.Core", category: "SearchCountriesByNameDataProvider")
    private let taskSerializer: TaskSerializing
    private let countryRepository: any SearchCountriesRepository
    
    public init(webAPI: AsyncCountryAPI,
                taskSerializer: TaskSerializing,
                repositoryFactory: SearchCountriesRepositoryFactorizable) {
        self.webAPI = webAPI
        self.taskSerializer = taskSerializer
        self.countryRepository = repositoryFactory.make()
    }
    
    public func execute(_ input: String) async throws -> [Country] {
        return try await taskSerializer.execute(id: "search_countries_by_name") {
            try Task.checkCancellation()
            // validate the input
            logger.info("\(Thread.current)Searching countries by Input: \(input)")
            do {
                let countries = try await webAPI.find(byName: input)
                    .compactMap { $0.asCountry }
                    .sorted { $0.name < $1.name }
                return countries
                //validate the output
            } catch let error {
                if error is CancellationError {
                    logger.debug("Search network call for '\(input)' was cancelled. Exiting cleanly.")
                    throw error
                }
                logger.error("Error thrown by API \(error)")
                return await findLocally(input: input)
            }
        }
    }
    
    private func findLocally(input: String) async -> [Country] {
        guard !Task.isCancelled else { return [] }
        logger.debug("Filtering countries in DB by name")
        let predicate = CountryQueries().search(byName: input)
        let sortDescriptor = SortDescriptor(\CountryEntity.name)
        let results = await countryRepository.find(predicate: predicate, sortBy: sortDescriptor)
        logger.debug("found results in DB")
        return results
    }
}
