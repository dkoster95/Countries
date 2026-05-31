//
//  CountriesSchemaV1.swift
//  Countries
//
//  Created by Daniel Koster on 5/29/26.
//
import Foundation
import SwiftData


public enum CountriesSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }
    public static var models: [any PersistentModel.Type] {
        [CountryEntity.self]
    }
}
