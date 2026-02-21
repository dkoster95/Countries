//
//  CountryList.swift
//  Countries
//
//  Created by Daniel Koster on 2/5/26.
//

import SwiftUI
import Foundation

@Observable
public class CountryListViewModel2: CountryListViewModel {
    public var searchText: String = ""
    
    public var cellModels: [CountryCellModel] = []
    public func reload() {
        
    }
}

public struct CountryList: View {
    @State private var viewModel: CountryListViewModel
    
    public init(viewModel: CountryListViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            List(viewModel.cellModels) { cellModel in
                CountryCell(model: cellModel)
            }
            .listStyle(.inset)
            .refreshable {
                await viewModel.reload()
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: {
                          // action to perform when the button is tapped
                        print("filter")
                        }) {
                            Image(systemName: "line.3.horizontal.decrease")
                        }
                      

                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search Countries")
            .navigationTitle("Countries")
            .task {
                await viewModel.reload()
            }
        }
    }
}

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

struct CountryCell: View {
    private let model: CountryCellModel
    
    init(model: CountryCellModel) {
        self.model = model
    }
    
    public var body: some View {
        HStack(spacing: 16) {
//            Image(model.image, bundle: .module)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 60, height: 40)
            AsyncImage(url: URL(string:model.image), scale: 1.0) { image in
                image
                    .resizable()
                    .scaledToFit()
                    // Add modifiers to the image itself
            } placeholder: {
                ProgressView() // Show a spinner while loading
            }
//                .resizable()
//                .scaledToFit()
                .frame(width: 60, height: 40)
            VStack(alignment: .leading) {
                Text(model.name).font(Font.title)
                Text(model.detail).font(Font.headline).foregroundStyle(Color.gray)
            }
        }
    }
}

#Preview {
    CountryList(viewModel: CountryListViewModel2())
}
