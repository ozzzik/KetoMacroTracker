//
//  DatabaseSettingsView.swift
//  Keto Macro Tracker
//
//  View for configuring food database and country selection
//

import SwiftUI

struct DatabaseSettingsView: View {
    @StateObject private var settingsManager = AppSettingsManager.shared
    private let openFoodFactsAPI = OpenFoodFactsAPI()
    @Environment(\.dismiss) var dismiss
    
    @State private var searchUSDA: Bool
    @State private var searchOFF: Bool
    @State private var preferredCountry: OpenFoodFactsCountry
    @State private var additionalCountries: [OpenFoodFactsCountry]
    @State private var showDatabaseSource: Bool
    @State private var maxSearchResults: Int
    
    init() {
        let manager = AppSettingsManager.shared
        _searchUSDA = State(initialValue: manager.settings.searchUSDADatabase)
        _searchOFF = State(initialValue: manager.settings.searchOpenFoodFacts)
        _preferredCountry = State(initialValue: manager.getPreferredCountry())
        _additionalCountries = State(initialValue: manager.settings.additionalCountries.compactMap { OpenFoodFactsCountry(rawValue: $0) })
        _showDatabaseSource = State(initialValue: manager.settings.showDatabaseSource)
        _maxSearchResults = State(initialValue: manager.settings.maxSearchResults)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Database Selection Section
                Section(header: Text("Food Databases")) {
                    Toggle("Search USDA Database", isOn: $searchUSDA)
                        .onChange(of: searchUSDA) {
                            settingsManager.updateSearchPreferences(searchUSDA: searchUSDA, searchOFF: searchOFF)
                        }
                    
                    Toggle("Search OpenFoodFacts", isOn: $searchOFF)
                        .onChange(of: searchOFF) {
                            settingsManager.updateSearchPreferences(searchUSDA: searchUSDA, searchOFF: searchOFF)
                        }
                    
                    if !searchUSDA && !searchOFF {
                        Text("⚠️ At least one database must be enabled")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                // Country Selection Section
                if searchOFF {
                    Section(header: Text("Country Selection"), 
                           footer: Text("OpenFoodFacts searches country-specific databases. Select your country for better results with local products.")) {
                        
                        Picker("Preferred Country", selection: $preferredCountry) {
                            ForEach(OpenFoodFactsCountry.allCases, id: \.self) { country in
                                Text(country.displayName)
                                    .tag(country)
                            }
                        }
                        .onChange(of: preferredCountry) {
                            settingsManager.updatePreferredCountry(preferredCountry)
                            openFoodFactsAPI.refreshCountriesFromSettings()
                        }
                        
                        // Additional Countries
                        if !additionalCountries.isEmpty {
                            ForEach(additionalCountries, id: \.self) { country in
                                HStack {
                                    Text(country.displayName)
                                    Spacer()
                                    Button("Remove") {
                                        additionalCountries.removeAll { $0 == country }
                                        settingsManager.removeCountry(country)
                                        openFoodFactsAPI.refreshCountriesFromSettings()
                                    }
                                    .foregroundColor(.red)
                                    .font(.caption)
                                }
                            }
                        }
                        
                        // Add Country Button
                        NavigationLink("Add Additional Country") {
                            AddCountryView(
                                currentCountries: [preferredCountry] + additionalCountries,
                                onAdd: { country in
                                    additionalCountries.append(country)
                                    settingsManager.addCountry(country)
                                    openFoodFactsAPI.refreshCountriesFromSettings()
                                }
                            )
                        }
                    }
                }
                
                // Search Settings Section
                Section(header: Text("Search Settings")) {
                    Toggle("Show Database Source", isOn: $showDatabaseSource)
                        .onChange(of: showDatabaseSource) {
                            settingsManager.toggleShowDatabaseSource()
                        }
                    
                    Stepper("Max Results: \(maxSearchResults)", value: $maxSearchResults, in: 10...50, step: 5)
                        .onChange(of: maxSearchResults) {
                            settingsManager.updateMaxSearchResults(maxSearchResults)
                        }
                }
                
                // Info Section
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("USDA Database")
                            .font(.headline)
                        Text("Comprehensive nutrition data for raw ingredients and generic foods. Best for whole foods and cooking ingredients.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text("OpenFoodFacts")
                            .font(.headline)
                        Text("Community-driven database with barcode scanning. Best for packaged and branded products. Country selection improves results for local products.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Database Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Country View
struct AddCountryView: View {
    let currentCountries: [OpenFoodFactsCountry]
    let onAdd: (OpenFoodFactsCountry) -> Void
    @Environment(\.dismiss) var dismiss
    
    var availableCountries: [OpenFoodFactsCountry] {
        OpenFoodFactsCountry.allCases.filter { !currentCountries.contains($0) }
    }
    
    var body: some View {
        List {
            ForEach(availableCountries, id: \.self) { country in
                Button(action: {
                    onAdd(country)
                    dismiss()
                }) {
                    HStack {
                        Text(country.displayName)
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle("Add Country")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DatabaseSettingsView()
}

