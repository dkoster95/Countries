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

#Preview {
    CountryList(viewModel: CountryListViewModel2())
}
