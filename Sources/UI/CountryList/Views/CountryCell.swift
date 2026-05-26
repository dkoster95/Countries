//
//  CountryCell.swift
//  Countries
//
//  Created by Daniel Koster on 5/11/26.
//
import Foundation
import SwiftUI

struct CountryCell: View {
    private let model: CountryCellModel
    
    init(model: CountryCellModel) {
        self.model = model
    }
    
    @ViewBuilder var image: some View {
        AsyncImageV2(viewModel: model.imageViewModel) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            ProgressView()
        }
        .frame(width: 60, height: 40)
    }
    
    @ViewBuilder var textSection: some View {
        VStack(alignment: .leading) {
            Text(model.name).font(Font.title)
            Text(model.detail).font(Font.headline).foregroundStyle(Color.gray)
        }
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            image
            textSection
        }
    }
}
