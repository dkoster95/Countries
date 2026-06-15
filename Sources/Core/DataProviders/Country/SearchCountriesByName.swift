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
import os

public protocol SearchCountriesDataProvidable: DataProvider<String, [Country]> {}

public struct SearchCountriesByNameDataProvider: SearchCountriesDataProvidable {
    private let webAPI: AsyncCountryAPI
    private let logger = Logger(subsystem: "Countries.Core", category: "SearchCountriesByNameDataProvider")
    private let taskSerializer: TaskSerializing
    
    public init(webAPI: AsyncCountryAPI, taskSerializer: TaskSerializing) {
        self.webAPI = webAPI
        self.taskSerializer = taskSerializer
    }
    
    public func execute(_ input: String) async throws -> [Country] {
        return try await taskSerializer.execute(id: "search_countries_by_name") {
            try Task.checkCancellation()
            // validate the input
            logger.info("\(Thread.current)Searching countries by Input: \(input)")
            return try await webAPI.find(byName: input)
                .compactMap { $0.asCountry }
                .sorted { $0.name < $1.name }
            //validate the output
        }
    }
    
}
