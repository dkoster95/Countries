//
//  AsyncImage.swift
//  Countries
//
//  Created by Daniel Koster on 5/9/26.
//
import Foundation
import SwiftUI

extension Image {
    init?(data: Data) {
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return nil }
        self = Image(uiImage: uiImage)
        #elseif canImport(AppKit)
        guard let nsImage = NSImage(data: data) else { return nil }
        self = Image(nsImage: nsImage)
        #else
        return nil
        #endif
    }
}

@MainActor
public struct AsyncImageV2<Content: View, Placeholder: View>: View {
    @State var viewModel: AsyncImageViewModelable
    let imageModifiers: ((Image) -> Content)?
    let placeholder: () -> Placeholder
    
    public init(viewModel: AsyncImageViewModelable,
         imageModifiers: ((Image) -> Content)? = nil,
         @ViewBuilder placeholder:  @escaping () -> Placeholder) {
        self.viewModel = viewModel
        self.imageModifiers = imageModifiers
        self.placeholder = placeholder
    }
    
    public var body: some View {
        if let imageData = viewModel.data,
           let image = Image(data: imageData) {
            if let modifiers = imageModifiers {
                modifiers(image)
            } else {
                image
            }
        } else {
            placeholder()
        }
    }
}
