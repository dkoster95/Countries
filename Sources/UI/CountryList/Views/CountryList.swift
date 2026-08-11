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
    private var viewModel: any CountryListViewModel
    
    public init(viewModel: CountryListViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            List(viewModel.cellModels) { cellModel in
                CountryCell(model: cellModel)
                    .onTapGesture {
                        print(cellModel.name)
                }
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
            .navigationTitle("Countries")
            .searchable(text: Binding(
                get: { viewModel.searchText },
                set: { viewModel.searchText = $0 }
            ), prompt: "Search Countries")
            .task(id: viewModel.searchText) {
                if !viewModel.searchText.isEmpty {
                    try? await Task.sleep(for: .milliseconds(300))
                }
                guard !Task.isCancelled else { return }
                await viewModel.reload()
            }
        }
    }
}

#Preview {
    CountryList(viewModel: CountryListViewModel2())
}
