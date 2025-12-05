import SwiftUI

struct UnitSelectionView: View {
    @Environment(\.dismiss) var dismiss
    let food: USDAFood
    let onAdd: (USDAFood, Double, String) -> Void // food, amount, unit
    
    @State private var selectedUnit: String
    @State private var amount = "1.0"
    
    init(food: USDAFood, onAdd: @escaping (USDAFood, Double, String) -> Void) {
        self.food = food
        self.onAdd = onAdd
        // Initialize with food's serving unit if available, otherwise "servings"
        self._selectedUnit = State(initialValue: food.servingSizeUnit ?? "servings")
    }
    
    private let unitOptions = [
        ("servings", "Servings"),
        ("g", "Grams"),
        ("ml", "Milliliters"),
        ("l", "Liters"),
        ("cups", "Cups"),
        ("tbsp", "Tablespoons"),
        ("tsp", "Teaspoons"),
        ("oz", "Ounces"),
        ("lb", "Pounds")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
                // Food Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(food.description)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let brand = food.brandName {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Nutrition preview
                    HStack(spacing: 16) {
                        NutritionBadge(label: "Protein", value: food.protein, unit: "g", color: .green)
                        NutritionBadge(label: "Net Carbs", value: food.netCarbs, unit: "g", color: .orange)
                        NutritionBadge(label: "Fat", value: food.fat, unit: "g", color: .blue)
                        NutritionBadge(label: "Cal", value: food.calories, unit: "", color: .purple)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Amount Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount")
                        .font(.headline)
                    
                    HStack {
                        TextField("1.0", text: $amount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .onSubmit {
                                hideKeyboard()
                            }
                        
                        Text(unitOptions.first { $0.0 == selectedUnit }?.1 ?? selectedUnit)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Unit Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unit")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(unitOptions, id: \.0) { unit in
                            Button(action: {
                                selectedUnit = unit.0
                            }) {
                                Text(unit.1)
                                    .font(.subheadline)
                                    .foregroundColor(selectedUnit == unit.0 ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedUnit == unit.0 ? Color.blue : Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Add Button
                Button("Add to Food Log") {
                    if let amountValue = Double(amount), amountValue > 0 {
                        onAdd(food, amountValue, selectedUnit)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(Double(amount) == nil || Double(amount) ?? 0 <= 0)
            }
            .padding()
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
            )
    }
    
    // Helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


#Preview {
    UnitSelectionView(
        food: USDAFood(
            id: UUID(),
            fdcId: 123,
            description: "Sample Food",
            dataType: "Sample",
            foodNutrients: [],
            gtinUpc: nil,
            publishedDate: nil,
            brandOwner: nil,
            brandName: "Sample Brand",
            ingredients: nil,
            servingSize: 100,
            servingSizeUnit: "g",
            foodCategory: "Sample"
        ),
        onAdd: { _, _, _ in }
    )
}
