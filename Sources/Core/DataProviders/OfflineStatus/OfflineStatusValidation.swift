//
//  OfflineStatusValidation.swift
//  Countries
//
//  Created by Daniel Koster on 6/11/26.
//
import Foundation
import PelicanProtocols
import QuickHatchCore
import os

public protocol OfflineStatusValidationDataProvidable: DataProvider<SyncableEntities, Bool> {}
public typealias OfflineEntityRepository<Entity: Sendable & Equatable> = AsyncDeleteableRepository<Entity> & Sendable

public protocol OfflineStatusValidationRepositoryFactorizable<Entity>: Sendable {
    associatedtype Entity: Sendable & Equatable
    func make() -> any OfflineEntityRepository<Entity>
    func makeSyncStatus() -> any SyncStatusRepository
}

public struct OfflineStatusValidationDataProvider<Entity: Sendable & Equatable>: OfflineStatusValidationDataProvidable {
    private let repositoryFactory: any OfflineStatusValidationRepositoryFactorizable<Entity>
    private let validator: SyncStatusValidator
    private let logger = Logger(subsystem: "Countries.Core", category: "OfflineStatusValidationDataProvider")
    private let syncStatusRepository: any SyncStatusRepository
    private let entityRepository: any OfflineEntityRepository<Entity>
    
    public init(repositoryFactory: any OfflineStatusValidationRepositoryFactorizable<Entity>,
         validator: SyncStatusValidator) {
        self.repositoryFactory = repositoryFactory
        self.validator = validator
        self.syncStatusRepository = repositoryFactory.makeSyncStatus()
        self.entityRepository = repositoryFactory.make()
    }
    
    public func execute(_ input: SyncableEntities) async throws -> Bool {

        logger.info("Finding sync status for \(input.rawValue)")
        if let syncStatus = await syncStatusRepository.find (query: { $0.name == input.rawValue }).first {
            // check expiration date for sync status
            logger.info("Sync status for \(input.rawValue) found!")
            if validator.isValid(syncStatus: syncStatus) {
                return true
            } else {
                logger.info("Storage expiration reached proceeding to remove all records of \(Entity.self)")
                try await entityRepository.deleteAll()
                try await syncStatusRepository.delete(element: syncStatus)
                logger.info("Sync status for \(input.rawValue) deleted")
                logger.info("All records of type \(Entity.self) deleted")
                return false
            }
        }
        return false
    }
}
