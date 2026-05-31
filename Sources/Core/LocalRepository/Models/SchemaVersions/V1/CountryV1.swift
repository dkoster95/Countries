//
//  CountryV1.swift
//  Countries
//
//  Created by Daniel Koster on 5/29/26.
//
import Foundation
import SwiftData

extension CountriesSchemaV1 {
    @Model
    public class CountryEntity {
        @Attribute(.unique) var uuid: UUID
        @Attribute(.unique) var name: String
        var flagURL: String
        var createdAt: Date
        var languages: String
        var region: String
        var subregion: String
        
        init(uuid: UUID = UUID(),
             name: String,
             flagURL: String,
             createdAt: Date = Date(),
             languages: String,
             region: String,
             subregion: String) {
            self.uuid = uuid
            self.name = name
            self.flagURL = flagURL
            self.region = region
            self.subregion = subregion
            self.createdAt = createdAt
            self.languages = languages
        }
    }
}
