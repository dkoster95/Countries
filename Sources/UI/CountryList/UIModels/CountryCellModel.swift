//
//  UIModels.swift
//  Countries
//
//  Created by Daniel Koster on 2/5/26.
//
import Foundation
import CountriesCore

public struct CountryCellModel: Identifiable, Sendable {
    public var id: String { name }
    let name: String
    let detail: String
    let image: String
}

@MainActor
public protocol AsyncImageViewModelable: Sendable {
    var data: Data? { get set }
    func reload() async throws
}

public protocol ImageDataProvider: DataProvider<String, Data>, Sendable {}

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
