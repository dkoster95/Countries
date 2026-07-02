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
    func make() -> any AsyncPredicableReadableRepository<CountryEntity, Country>
}

public struct SearchCountriesByNameDataProvider: SearchCountriesDataProvidable {
    private let webAPI: AsyncCountryAPI
    private let logger = Logger(subsystem: "Countries.Core", category: "SearchCountriesByNameDataProvider")
    private let taskSerializer: TaskSerializing
    private let repositoryFactory: SearchCountriesRepositoryFactorizable
    
    public init(webAPI: AsyncCountryAPI,
                taskSerializer: TaskSerializing,
                repositoryFactory: SearchCountriesRepositoryFactorizable) {
        self.webAPI = webAPI
        self.taskSerializer = taskSerializer
        self.repositoryFactory = repositoryFactory
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
                logger.error("Error thrown by API \(error)")
                return await findLocally(input: input)
            }
        }
    }
    
    private func findLocally(input: String) async -> [Country] {
        let repository = repositoryFactory.make()
        logger.debug("Filtering countries in DB by name")
        let predicate = CountryQueries().search(byName: input)
        let sortDescriptor = SortDescriptor(\CountryEntity.name)
        let results = await repository.find(predicate: predicate, sortBy: sortDescriptor)
        logger.debug("found results in DB")
        return results
    }
}
