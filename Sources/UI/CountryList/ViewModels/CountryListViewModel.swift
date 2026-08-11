//
//  CountryListViewModel.swift
//  Countries
//
//  Created by Daniel Koster on 2/6/26.
//
import Foundation
import CountriesCore
import CountriesAPI
import Combine
import OSLog
import PelicanRepositories

@MainActor
public protocol CountryListViewModel: Sendable, Observable, AnyObject {
    var cellModels: [CountryCellModel] { get set }
    var searchText: String { get set }
    func reload() async
}

@Observable
public class CountryListViewModel1: CountryListViewModel {
    
    public var searchText: String = ""
    public var cellModels: [CountryCellModel] = []
    @ObservationIgnored
    private let dataProvider: (any FindCountriesDataProvidable)
    @ObservationIgnored
    private let logger = Logger(subsystem: "Countries.UI", category: "CountryList")
    @ObservationIgnored
    private let cellModelFactory: CountryCellModelFactory
    
    public init(dataProvider: (any FindCountriesDataProvidable),
                cellModelFactory: CountryCellModelFactory) {
        self.dataProvider = dataProvider
        self.cellModelFactory = cellModelFactory
    }
    
    public func reload() async {
        logger.debug("\(Thread.current) Reloading countries")
        guard !Task.isCancelled else { return }
        if let countries = try? await dataProvider.execute(searchText) {
            logger.debug("\(Thread.current) - \(countries.count) Countries found, proceeding to map into cellModels")
            let cellModelsMapped = countries.map { cellModelFactory.make(country: $0) }
            cellModels = cellModelsMapped
            
        }
    }
}
