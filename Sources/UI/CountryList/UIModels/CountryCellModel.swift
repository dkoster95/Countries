//
//  UIModels.swift
//  Countries
//
//  Created by Daniel Koster on 2/5/26.
//
import Foundation
import CountriesCore
import QuickHatchUI

public struct CountryCellModel: Identifiable, Sendable {
    public var id: String { name }
    let name: String
    let detail: String
    let imageViewModel: any AsyncImageViewModelable
    
    public init(name: String, detail: String, imageViewModel: any AsyncImageViewModelable) {
        self.name = name
        self.detail = detail
        self.imageViewModel = imageViewModel
    }
}
