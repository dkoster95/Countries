//
//  AsyncImageViewModel.swift
//  Countries
//
//  Created by Daniel Koster on 3/8/26.
//
import Foundation
import QuickHatchCore

@MainActor
public protocol AsyncImageViewModelable: Sendable {
    var data: Data? { get set }
    func reload() async throws
}

@Observable
public class AsyncImageViewModel: AsyncImageViewModelable {
    public var data: Data?
    @ObservationIgnored private let url: String
    @ObservationIgnored private let dataProvider: any FindImageDataProvidable
    
    public init(data: Data? = nil, dataProvider: any FindImageDataProvidable, url: String) {
        self.data = data
        self.dataProvider = dataProvider
        self.url = url
        Task {
            try await reload()
        }
    }
    
    public func reload() async throws {
        do {
            let imageData = try await dataProvider.execute(url)
            self.data = imageData
        } catch let error {
            // Empty Image
        }
    }
}
