//
//  CountryResponseConfig.swift
//  Countries
//
//  Created by Daniel Koster on 5/29/26.
//
import Foundation
import PelicanProtocols

extension Country: PersistenModelConvertible {
    public init(from: CountryEntity) {
        self.init(uuid: from.uuid,
                  name: from.name,
                  flagURL: from.flagURL,
                  region: from.region,
                  subregion: from.subregion,
                  languages: from.languages)
    }
    
    public func asEntity() -> CountryEntity {
        CountryEntity(name: name,
                      flagURL: flagURL ?? "",
                      languages: languages ?? "",
                      region: region ?? "",
                      subregion: subregion ?? "")
    }
    
    public func merge(into: CountryEntity) {
        into.name = name
        into.flagURL = flagURL ?? ""
        into.languages = languages ?? ""
        into.region = region ?? ""
        into.subregion = subregion ?? ""
    }
    
    public var identifiablePredicate: Predicate<CountryEntity> {
        let name = name
        return #Predicate { element in
            element.name == name
        }
    }
    
    public typealias SwiftDataEntity = CountryEntity
    
}
