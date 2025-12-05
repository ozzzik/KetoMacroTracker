# Figma Template Setup Instructions

## 🚀 **Quick Start - Copy This Template**

### **Step 1: Create New Figma File**
1. Open Figma
2. Click "New Design File"
3. Name it "Keto Macro Tracker"

### **Step 2: Set Up iPhone Frame**
1. Click the Frame tool (F)
2. Select "iPhone 14 Pro" (393x852px)
3. Position it in center of canvas

### **Step 3: Add Color Styles**
Go to **Design** → **Color Styles** and add these:

```
Primary Green: #33B366
Accent Orange: #E69933
Protein Red: #E64D4D
Carbs Blue: #4D9BE6
Fat Yellow: #E6B84D
Calories Purple: #9B4DE6
Background Light: #FFFFFF
Background Dark: #1C1C1E
Text Light: #000000
Text Dark: #FFFFFF
```

### **Step 4: Add Text Styles**
Go to **Design** → **Text Styles** and add these:

```
Large Title: SF Pro Rounded, 34pt, Bold
Title: SF Pro Rounded, 28pt, Bold
Headline: SF Pro Rounded, 17pt, Semibold
Body: SF Pro Rounded, 17pt, Regular
Caption: SF Pro Rounded, 12pt, Regular
```

### **Step 5: Create Basic Components**

#### **Macro Circle Component:**
1. Draw circle (120x120px)
2. Stroke: 8px, color from macro colors
3. Fill: Transparent
4. Add text: "Protein" (bottom)
5. Right-click → "Create Component"

#### **Food Card Component:**
1. Draw rectangle (350x80px)
2. Corner radius: 12px
3. Fill: Background color
4. Add shadow: 0px 2px 8px rgba(0,0,0,0.1)
5. Right-click → "Create Component"

#### **Progress Bar Component:**
1. Draw rectangle (350x8px)
2. Corner radius: 4px
3. Fill: Macro color
4. Right-click → "Create Component"

#### **Button Component:**
1. Draw rectangle (120x44px)
2. Corner radius: 12px
3. Fill: Primary green
4. Add text: "Add Food" (white)
5. Right-click → "Create Component"

### **Step 6: Create Today View**

1. **Header Section:**
   - Add text: "Today" (Large Title style)
   - Add text: "September 27, 2024" (Caption style)
   - Add Button component: "Add Food"

2. **Macro Circles:**
   - Add 4 Macro Circle components
   - Arrange in 2x2 grid
   - Label: Protein, Net Carbs, Fat, Calories
   - Use appropriate colors

3. **Progress Section:**
   - Add text: "Daily Progress" (Title style)
   - Add 4 Progress Bar components
   - Label each with macro name and values

4. **Food List:**
   - Add text: "Today's Food" (Title style)
   - Add Food Card components
   - Show sample food items

### **Step 7: Add SF Symbols**

1. **Download SF Symbols** (if you haven't)
2. **Copy symbol names** from our guide
3. **Add text elements** with symbol names
4. **Apply colors** from your palette

**Common Symbols:**
- `fork.knife` - Food
- `magnifyingglass` - Search
- `person.circle` - Profile
- `chart.line.uptrend.xyaxis` - History
- `plus` - Add
- `heart.fill` - Health

### **Step 8: Export Assets**

1. **Select components** you want to export
2. **Right-click** → "Export"
3. **Choose format**: PNG
4. **Choose sizes**: 1x, 2x, 3x
5. **Export** to your project folder

### **Step 9: Import to Xcode**

1. **Open Xcode project**
2. **Drag exported images** to Assets.xcassets
3. **Use in SwiftUI** with Image() views
4. **Apply colors** from DesignSystem.swift

## 💡 **Pro Tips:**

1. **Use Auto Layout** for responsive design
2. **Create Variants** for light/dark mode
3. **Name Layers** clearly
4. **Group Related Elements**
5. **Test on Device** with Figma Mirror

## 🎯 **What You'll Have:**

- Professional-looking mockups
- Consistent design system
- Reusable components
- Exportable assets
- Clear design direction

## 🚀 **Next Steps:**

1. Follow these instructions
2. Create your mockups
3. Export assets
4. Import to Xcode
5. Use with our DesignSystem.swift

This will give you a solid foundation for your app's visual design! 🎨


