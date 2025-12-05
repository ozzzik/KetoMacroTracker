import SwiftUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var profileManager: ProfileManager
    let onSave: () -> Void
    
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var age: String = ""
    @State private var gender: String = ""
    @State private var activityLevel: String = ""
    @State private var goal: String = ""
    
    private let genders = ["Male", "Female"]
    private let activityLevels = ["Sedentary", "Lightly Active", "Moderately Active", "Very Active", "Extremely Active"]
    private let goals = ["Lose Fat", "Maintain Weight", "Gain Weight"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("lbs", text: $weight)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .onSubmit {
                                hideKeyboard()
                            }
                        Text("lbs")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("cm", text: $height)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .onSubmit {
                                hideKeyboard()
                            }
                        Text("cm")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("years", text: $age)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .onSubmit {
                                hideKeyboard()
                            }
                        Text("years")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Gender")
                        Spacer()
                        Picker("Gender", selection: $gender) {
                            ForEach(genders, id: \.self) { gender in
                                Text(gender).tag(gender)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section(header: Text("Activity Level")) {
                    Picker("Activity Level", selection: $activityLevel) {
                        ForEach(activityLevels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Goal")) {
                    Picker("Goal", selection: $goal) {
                        ForEach(goals, id: \.self) { goal in
                            Text(goal).tag(goal)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if canCalculateMacros {
                    Section(header: Text("Calculated Macro Goals")) {
                        let macroGoals = calculateMacroGoals()
                        
                        MacroPreviewRow(
                            title: "Protein",
                            value: "\(Int(macroGoals.protein))g",
                            color: .blue
                        )
                        
                        MacroPreviewRow(
                            title: "Net Carbs",
                            value: "\(Int(macroGoals.carbs))g",
                            color: .red
                        )
                        
                        MacroPreviewRow(
                            title: "Fat",
                            value: "\(Int(macroGoals.fat))g",
                            color: .orange
                        )
                        
                        MacroPreviewRow(
                            title: "Calories",
                            value: "\(Int(macroGoals.calories)) kcal",
                            color: .purple
                        )
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear {
                initializeFormFields()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                        onSave()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private func initializeFormFields() {
        let profile = profileManager.profile
        weight = String(format: "%.0f", profile.weight)
        height = String(format: "%.0f", profile.height)
        age = String(profile.age)
        gender = profile.gender
        activityLevel = profile.activityLevel
        goal = profile.goal
    }
    
    private func saveProfile() {
        guard let weightValue = Double(weight),
              let heightValue = Double(height),
              let ageValue = Int(age) else { return }
        
        profileManager.updateProfile(
            weight: weightValue,
            height: heightValue,
            age: ageValue,
            gender: gender,
            activityLevel: activityLevel,
            goal: goal
        )
    }
    
    private var canSave: Bool {
        !weight.isEmpty && !height.isEmpty && !age.isEmpty && !gender.isEmpty &&
        Double(weight) != nil && Double(height) != nil && Int(age) != nil
    }
    
    private var canCalculateMacros: Bool {
        canSave
    }
    
    private func calculateMacroGoals() -> (protein: Double, carbs: Double, fat: Double, calories: Double) {
        guard let weightValue = Double(weight),
              let heightValue = Double(height),
              let ageValue = Int(age) else {
            return (protein: 0, carbs: 25, fat: 0, calories: 0)
        }
        
        // Create a temporary profile to use the shared calculation function
        let tempProfile = UserProfile(
            weight: weightValue,
            height: heightValue,
            age: ageValue,
            gender: gender,
            activityLevel: activityLevel,
            goal: goal
        )
        
        // Use the shared macro calculation function which properly accounts for activity level
        // Explicitly call the global function from MacroCalculations
        let result = KetoMacroTracker.calculateMacroGoals(profile: tempProfile)
        return (protein: result.protein, carbs: result.carbs, fat: result.fat, calories: result.calories)
    }
    
    // Helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct MacroPreviewRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    EditProfileView(
        profileManager: ProfileManager.shared,
        onSave: {}
    )
}
