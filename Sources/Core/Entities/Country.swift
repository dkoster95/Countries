//
//  Country.swift
//  Countries
//
//  Created by Daniel Koster on 5/29/26.
//
import Foundation

public struct Country: Sendable, Equatable {
    public let uuid: UUID
    public let name: String
    public let flagURL: String?
    public let region: String?
    public let subregion: String?
    public let languages: String?
    
    public init(uuid: UUID, name: String, flagURL: String?, region: String?, subregion: String?, languages: String?) {
        self.uuid = uuid
        self.name = name
        self.flagURL = flagURL
        self.region = region
        self.subregion = subregion
        self.languages = languages
    }
}
