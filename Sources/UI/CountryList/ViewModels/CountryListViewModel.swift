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

@MainActor
public protocol CountryListViewModel: Sendable {
    var cellModels: [CountryCellModel] { get set }
    var searchText: String { get set }
    func reload() async
}

@Observable
public class CountryListViewModel1: CountryListViewModel {
    public var searchText: String = "" {
        didSet {
            searchInputSubject.send(searchText)
        }
    }
    public var cellModels: [CountryCellModel] = []
    @ObservationIgnored
    private let dataProvider: (any FindAllCountriesDataProvidable)
    @ObservationIgnored
    private let searchInputSubject = PassthroughSubject<String, Never>()
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "CountriesUI", category: "CountryList")
    
    public init(dataProvider: (any FindAllCountriesDataProvidable)) {
        self.dataProvider = dataProvider
        configureSearch()
    }
    
    private func configureSearch() {
        searchInputSubject
                    .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
                    .sink { [weak self] debouncedQuery in
                        guard let self = self else { return }
                        print("Debounced query: \(self.searchText)")
                        Task {
                            try await reload()
                        }
                    }
                    .store(in: &cancellables)
    }
    
    public func reload() async {
        logger.debug("\(Thread.current) Reloading countries")
        if let countries = try? await dataProvider.execute(searchText) {
            logger.debug("\(Thread.current) - \(countries.count) Countries found, proceeding to map into cellModels")
            let cellModelsMapped = countries.map { CountryCellModel(name: $0.name?.common ?? "",
                                                                    detail: ($0.subregion ?? "") + ", " + ($0.region ?? ""),
                                                                    image: $0.flags?.png ?? "") }
            
            cellModels = cellModelsMapped
            
        }
    }
    
//
//    private func loadCellModels() {
//        Task { [weak self] in
//            if let countries = try await self?.dataProvider.execute("") {
//                let cellModelsMapped = countries.map { CountryCellModel(name: $0.name?.official ?? "",
//                                                                        detail: ($0.subregion ?? "") + ", " + ($0.region ?? ""),
//                                                                        image: $0.flags?.png ?? "") }
//                    self?.cellModels = cellModelsMapped
//            }
//        }
//    }
    
//    private func map(country: CountryResponse) -> CountryCellModel {
//        CountryCellModel(name: country.name?.official ?? "",
//                         detail: (country.subregion ?? "") + ", " + (country.region ?? ""),
//                         image: country.flags?.png ?? "")
//    }
}
