//
//  SyncStatusConfig.swift
//  Countries
//
//  Created by Daniel Koster on 6/1/26.
//
import Foundation
import PelicanProtocols

extension SyncStatus: PersistenModelConvertible {
    public init(from: SyncStatusEntity) {
        self.init(uuid: from.uuid, name: from.name, createdAt: from.createdAt)
    }
    
    public func asEntity() -> SyncStatusEntity {
        SyncStatusEntity(uuid: uuid, name: name, createdAt: createdAt)
    }
    
    public func merge(into: SyncStatusEntity) {
        into.name = name
    }
    
    public var identifiablePredicate: Predicate<SyncStatusEntity> {
        let name = name
        return #Predicate { item in
            return item.name == name
        }
    }
    
    public typealias SwiftDataEntity = SyncStatusEntity
    
    
}
