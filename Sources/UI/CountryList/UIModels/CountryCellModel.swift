//
//  UIModels.swift
//  Countries
//
//  Created by Daniel Koster on 2/5/26.
//
import Foundation
import CountriesCore

public struct CountryCellModel: Identifiable, Sendable {
    public var id: String { name }
    let name: String
    let detail: String
    let image: String
}



public protocol ImageDataProvider: DataProvider<String, Data>, Sendable {}


