//
//  SyncStatus.swift
//  Countries
//
//  Created by Daniel Koster on 6/1/26.
//
import Foundation

public struct SyncStatus: Sendable, Equatable {
    public let uuid: UUID
    public let name: String
    public let createdAt: Date
    
    public init(uuid: UUID, name: String, createdAt: Date) {
        self.uuid = uuid
        self.name = name
        self.createdAt = createdAt
    }
}
