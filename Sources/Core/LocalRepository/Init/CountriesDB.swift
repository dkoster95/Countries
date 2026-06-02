//
//  CountriesDB.swift
//  Countries
//
//  Created by Daniel Koster on 6/2/26.
//
import Foundation
import SwiftData

public func countriesModelContainer() throws -> ModelContainer {
    let schema = Schema(versionedSchema: CountriesSchemaV1.self)
    let config = ModelConfiguration(
        "ProductionStore",
        schema: schema,
        isStoredInMemoryOnly: true,
        allowsSave: true
    )
    let container = try ModelContainer(for: schema, configurations: [config])
    return container
}
