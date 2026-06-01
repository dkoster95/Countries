//
//  UpdateStatus.swift
//  Countries
//
//  Created by Daniel Koster on 6/1/26.
//
import Foundation
import SwiftData

extension CountriesSchemaV1 {
    @Model
    public class SyncStatusEntity {
        @Attribute(.unique) var uuid: UUID
        @Attribute(.unique) var name: String
        var createdAt: Date
        
        init(uuid: UUID = UUID(),
             name: String,
             createdAt: Date = Date()) {
            self.uuid = uuid
            self.name = name
            self.createdAt = createdAt
        }
    }
}
