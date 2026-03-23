//
//  Injections.swift
//  Countries
//
//  Created by Daniel Koster on 2/5/26.
//
import Foundation
import Aquarium
import CountriesAPIContainers
import CountriesAPI
import os
import CountriesCore
import Countries
import PelicanRepositories
import SwiftData


public struct FindAllCountriesRepositoryFactory: FindAllCountriesRepositoryFactorizable {
    private let modelContainer: ModelContainer
    
    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    public func make() -> any FindAllCountriesRepository {
        return SwiftDataRepository<CountryResponseDataTransformer>(modelContainer: modelContainer)
    }
    
    
}

public struct Containers {
    public struct Core {
        public static func prod(environment: HostEnvironment) throws -> Aquarium {
            let aquarium = Aquarium(containers: [.simple: SimpleContainer(logger: AquariumLoggerDefault()),
                                                 .singleton: SingletonContainer(logger: AquariumLoggerDefault())],
                                    aquariums: [try CountriesAPIContainers.prod(environment: environment)],
                                    logger: AquariumLoggerDefault())
            try aquarium.register(dependencyType: ModelContainer.self,
                                  registration: { container in
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: EntityData.self, configurations: config)
                return container
            },
                                  with: .singleton)
            try aquarium.register(dependencyType: FindAllCountriesRepositoryFactorizable.self,
                                  registration: { container in
                return FindAllCountriesRepositoryFactory(modelContainer: try container.resolve())
            },
                                  with: .simple)
            try aquarium.register(dependencyType: (any FindAllCountriesDataProvidable).self,
                                  registration: { container in FindAllCountriesDataProvider(webAPI: try container.resolve(),
                                                                                            repositoryFactory: try container.resolve())},
                                  with: .simple)
            return aquarium
        }
    }
    
    public struct UI {
        @MainActor
        public static func prod(environment: HostEnvironment) throws -> Aquarium {
            let aquarium = Aquarium(containers: [.simple: SimpleContainer(logger: AquariumLoggerDefault())],
                                    aquariums: [try Containers.Core.prod(environment: environment)],
                                    logger: AquariumLoggerDefault())
            
            try aquarium.register(dependencyType: CountryListViewModel.self,
                              registration: { container in CountryListViewModel1(dataProvider: try container.resolve())},
                              with: .simple)
            
            try aquarium.register(dependencyType: CountryList.self,
                                  registration: { container in CountryList(viewModel: try container.resolve())},
                                  with: .simple)
            
            return aquarium
        }
    }
}

public struct AquariumLoggerDefault: AquariumLogger {
    let logger = Logger(subsystem: "CountriesAquarium", category: "Logger")
    public func debug(_ msg: String) {
        logger.debug("\(msg)")
    }
    
    public func info(_ msg: String) {
        logger.info("\(msg)")
    }
    
    public func error(_ msg: String) {
        logger.error("\(msg)")
    }
    
    public func trace(_ msg: String) {
        logger.trace("\(msg)")
    }
}
