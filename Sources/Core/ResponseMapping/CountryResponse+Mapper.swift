//
//  CountryResponse+Mapper.swift
//  Countries
//
//  Created by Daniel Koster on 5/29/26.
//

import Foundation
import CountriesAPI

extension CountryResponse {
    var languagesString: String {
        languages?.map { $0 + ":" + $1}.joined(separator: ";") ?? ""
    }
    
    var asCountry: Country? {
        guard let name = name?.common else { return nil }
        return Country(uuid: UUID(),
                       name: name,
                       flagURL: flags?.png,
                       region: region,
                       subregion: subregion,
                       languages: languagesString)
    }
}



public protocol DataMappable<Source> {
    associatedtype Source
    
    func map<Result>(_ from: Source) -> Result
}
