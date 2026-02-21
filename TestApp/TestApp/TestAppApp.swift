//
//  TestAppApp.swift
//  TestApp
//
//  Created by Daniel Koster on 2/6/26.
//

import SwiftUI
import CountriesContainers
import CountriesAPI
import Countries

@MainActor
public class Dependencies {
    static let aquarium = try! Containers.UI.prod(environment: GenericHostEnvironment(headers: [:], baseURL: "https://restcountries.com/v3.1"))
}


@main
struct TestAppApp: App {
    var body: some Scene {
        WindowGroup {
            let view: CountryList = try! Dependencies.aquarium.resolve()
            return view
        }
    }
}
