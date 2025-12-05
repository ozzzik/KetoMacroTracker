import Foundation

struct FoodIconMapper {
    
    static func getIcon(for food: USDAFood) -> String {
        let description = food.description.lowercased()
        let foodCategory = food.foodCategory?.lowercased() ?? ""
        
        // Protein foods
        if description.contains("chicken") || description.contains("poultry") {
            return "🍗"
        } else if description.contains("beef") || description.contains("steak") || description.contains("burger") {
            return "🥩"
        } else if description.contains("pork") || description.contains("bacon") || description.contains("ham") {
            return "🥓"
        } else if description.contains("fish") || description.contains("salmon") || description.contains("tuna") || description.contains("cod") {
            return "🐟"
        } else if description.contains("shrimp") || description.contains("lobster") || description.contains("crab") {
            return "🦐"
        } else if description.contains("egg") {
            return "🥚"
        } else if description.contains("protein") || description.contains("whey") {
            return "💪"
        }
        
        // Dairy products
        else if description.contains("milk") {
            return "🥛"
        } else if description.contains("cheese") {
            return "🧀"
        } else if description.contains("butter") {
            return "🧈"
        } else if description.contains("yogurt") {
            return "🍶"
        } else if description.contains("cream") {
            return "🥛"
        }
        
        // Vegetables
        else if description.contains("broccoli") || description.contains("cauliflower") {
            return "🥦"
        } else if description.contains("spinach") || description.contains("lettuce") || description.contains("kale") {
            return "🥬"
        } else if description.contains("carrot") {
            return "🥕"
        } else if description.contains("tomato") {
            return "🍅"
        } else if description.contains("avocado") {
            return "🥑"
        } else if description.contains("pepper") {
            return "🫑"
        } else if description.contains("onion") {
            return "🧅"
        } else if description.contains("garlic") {
            return "🧄"
        } else if description.contains("cucumber") {
            return "🥒"
        } else if description.contains("mushroom") {
            return "🍄"
        }
        
        // Fruits
        else if description.contains("apple") {
            return "🍎"
        } else if description.contains("banana") {
            return "🍌"
        } else if description.contains("orange") || description.contains("citrus") {
            return "🍊"
        } else if description.contains("berry") || description.contains("blueberry") || description.contains("strawberry") {
            return "🫐"
        } else if description.contains("lemon") {
            return "🍋"
        } else if description.contains("grape") {
            return "🍇"
        }
        
        // Nuts and seeds
        else if description.contains("almond") {
            return "🥜"
        } else if description.contains("walnut") || description.contains("pecan") {
            return "🌰"
        } else if description.contains("peanut") {
            return "🥜"
        } else if description.contains("seed") || description.contains("chia") || description.contains("flax") {
            return "🌱"
        }
        
        // Grains and carbs
        else if description.contains("bread") || description.contains("toast") {
            return "🍞"
        } else if description.contains("rice") {
            return "🍚"
        } else if description.contains("pasta") || description.contains("noodle") {
            return "🍝"
        } else if description.contains("cereal") {
            return "🥣"
        } else if description.contains("oats") || description.contains("oatmeal") {
            return "🌾"
        }
        
        // Oils and fats
        else if description.contains("oil") || description.contains("olive oil") {
            return "🫒"
        } else if description.contains("coconut") {
            return "🥥"
        }
        
        // Beverages
        else if description.contains("coffee") {
            return "☕"
        } else if description.contains("tea") {
            return "🍵"
        } else if description.contains("water") {
            return "💧"
        } else if description.contains("juice") {
            return "🧃"
        } else if description.contains("soda") || description.contains("cola") {
            return "🥤"
        }
        
        // Snacks and treats
        else if description.contains("chocolate") {
            return "🍫"
        } else if description.contains("cookie") || description.contains("biscuit") {
            return "🍪"
        } else if description.contains("cake") || description.contains("dessert") {
            return "🎂"
        } else if description.contains("candy") || description.contains("sweet") {
            return "🍬"
        }
        
        // Supplements and powders
        else if description.contains("powder") || description.contains("supplement") {
            return "💊"
        }
        
        // Fallback based on food category
        else if foodCategory.contains("protein") || foodCategory.contains("meat") {
            return "🍗"
        } else if foodCategory.contains("dairy") {
            return "🥛"
        } else if foodCategory.contains("vegetable") {
            return "🥦"
        } else if foodCategory.contains("fruit") {
            return "🍎"
        } else if foodCategory.contains("grain") || foodCategory.contains("cereal") {
            return "🌾"
        } else if foodCategory.contains("beverage") || foodCategory.contains("drink") {
            return "🥤"
        }
        
        // Default fallback
        else {
            return "🍽️"
        }
    }
    
    static func getIcon(for quickAddItem: QuickAddItem) -> String {
        let name = quickAddItem.name.lowercased()
        let category = quickAddItem.category.lowercased()
        
        // Use the same logic but for QuickAddItem
        if name.contains("chicken") || name.contains("poultry") {
            return "🍗"
        } else if name.contains("beef") || name.contains("steak") {
            return "🥩"
        } else if name.contains("fish") || name.contains("salmon") {
            return "🐟"
        } else if name.contains("milk") {
            return "🥛"
        } else if name.contains("cheese") {
            return "🧀"
        } else if name.contains("egg") {
            return "🥚"
        } else if name.contains("protein") || name.contains("whey") {
            return "💪"
        } else if name.contains("almond") {
            return "🥜"
        } else if name.contains("avocado") {
            return "🥑"
        } else if name.contains("broccoli") || name.contains("cauliflower") {
            return "🥦"
        } else if name.contains("spinach") || name.contains("lettuce") {
            return "🥬"
        } else if name.contains("bread") {
            return "🍞"
        } else if name.contains("oil") {
            return "🫒"
        } else if name.contains("coffee") {
            return "☕"
        } else if name.contains("chocolate") {
            return "🍫"
        }
        
        // Category-based fallback
        else if category.contains("protein") {
            return "🍗"
        } else if category.contains("dairy") {
            return "🥛"
        } else if category.contains("vegetable") {
            return "🥦"
        } else if category.contains("fruit") {
            return "🍎"
        } else if category.contains("grain") {
            return "🌾"
        } else if category.contains("beverage") {
            return "🥤"
        }
        
        // Default
        else {
            return "🍽️"
        }
    }
}
