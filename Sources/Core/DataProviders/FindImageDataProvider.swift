//
//  FindImageDataProvider.swift
//  Countries
//
//  Created by Daniel Koster on 3/8/26.
//
import Foundation
import CountriesAPI

public protocol FindImageDataProvidable: DataProvider<String, Data>: Sendable {}


public struct FindImageDataProvider: FindImageDataProvidable {
    
}
