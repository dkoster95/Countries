//
//  CountryQueries.swift
//  Countries
//
//  Created by Daniel Koster on 6/26/26.
//
import Foundation

public struct CountryQueries {
    func search(byName: String) -> Predicate<CountryEntity> {
        #Predicate<CountryEntity> { country in
            country.name.localizedStandardContains(byName)
        }
    }
}
