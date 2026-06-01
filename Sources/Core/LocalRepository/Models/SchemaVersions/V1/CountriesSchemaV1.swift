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
        [CountryEntity.self, SyncStatusEntity.self]
    }
}

/*
 enum AppMigrationPlan: SchemaMigrationPlan {
     static var schemas: [any VersionedSchema.Type] {
         [SchemaV1.self, SchemaV2.self, SchemaV3.self] // All versions in order
     }

     static var stages: [MigrationStage] {
         [migrateV1toV2, migrateV2toV3] // The steps to get to the latest
     }

     static let migrateV1toV2 = MigrationStage.lightweight(
         fromVersion: SchemaV1.self,
         toVersion: SchemaV2.self
     )

     static let migrateV2toV3 = MigrationStage.lightweight(
         fromVersion: SchemaV2.self,
         toVersion: SchemaV3.self
     )
 }

 */
