//
//  AsyncImageViewModel.swift
//  Countries
//
//  Created by Daniel Koster on 3/8/26.
//
import Foundation

@MainActor
public protocol AsyncImageViewModelable: Sendable {
    var data: Data? { get set }
    func reload() async throws
}

@Observable
public class AsyncImageViewModel: AsyncImageViewModelable {
    public var data: Data?
    @ObservationIgnored private let url: String
    @ObservationIgnored private let dataProvider: any ImageDataProvider
    
    public init(data: Data? = nil, dataProvider: any ImageDataProvider, url: String) {
        self.data = data
        self.dataProvider = dataProvider
        self.url = url
    }
    
    public func reload() async throws {
        let imageData = try await dataProvider.execute(url)
        self.data = imageData
    }
}
