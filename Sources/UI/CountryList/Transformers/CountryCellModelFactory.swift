//
//  CountryCellModelFactory.swift
//  Countries
//
//  Created by Daniel Koster on 5/11/26.
//
import CountriesAPI
import Foundation
import CountriesCore
import QuickHatchCore
import QuickHatchUI

@MainActor
public protocol CountryCellModelFactory {
    func make(country: CountryResponse) -> CountryCellModel
}

public struct AquariumCountryCellModelFactory: CountryCellModelFactory {
    private let dataProvider: any FindImageDataProvidable
    
    public init(dataProvider: any FindImageDataProvidable) {
        self.dataProvider = dataProvider
    }
    
    public func make(country: CountriesAPI.CountryResponse) -> Countries.CountryCellModel {
        let imageViewModel = AsyncImageViewModel(dataProvider: dataProvider,
                                                 url: country.flags?.png ?? "")
        return CountryCellModel(name: country.name?.common ?? "",
                                detail: detailText(country: country),
                                imageViewModel: imageViewModel)
    }
    
    private func detailText(country: CountryResponse) -> String {
        let regions = [country.region, country.subregion].compactMap { $0 }.filter { !$0.isEmpty}
        return regions.joined(separator: ", ")
    }
}
