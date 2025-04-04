import Foundation

// Phone number formatting utility 
class PhoneFormatterService {
    static func format(_ phoneNumber: String?) -> String? {
        guard let phone = phoneNumber, !phone.isEmpty else { return nil }
        
        // Clean the input - remove all non-numeric characters
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // If fewer than 7 digits, return original
        if digits.count < 7 {
            return phone
        }
        
        // Format based on length
        switch digits.count {
        case 7: // Just local number DDD.DDDD
            let index3 = digits.index(digits.startIndex, offsetBy: 3)
            return digits[..<index3] + "." + digits[index3...]
            
        case 10: // US number without country code (areacode.prefix.line)
            let index3 = digits.index(digits.startIndex, offsetBy: 3)
            let index6 = digits.index(digits.startIndex, offsetBy: 6)
            return digits[..<index3] + "." + digits[index3..<index6] + "." + digits[index6...]
            
        case 11...: // International with country code
            var formattedNumber = ""
            
            // Country code (1-3 digits)
            let countryCodeEndIndex = min(3, digits.count - 7)
            let countryCodeIndex = digits.index(digits.startIndex, offsetBy: countryCodeEndIndex)
            formattedNumber += digits[..<countryCodeIndex] + "."
            
            // City code (2-3 digits)
            let cityCodeLength = min(3, digits.count - countryCodeEndIndex - 4)
            let cityCodeEndIndex = countryCodeEndIndex + cityCodeLength
            let cityCodeEndIdx = digits.index(digits.startIndex, offsetBy: cityCodeEndIndex)
            formattedNumber += digits[digits.index(digits.startIndex, offsetBy: countryCodeEndIndex)..<cityCodeEndIdx] + "."
            
            // Remaining digits split into DDD.DDDD format
            let remainingDigits = digits[cityCodeEndIdx...]
            if remainingDigits.count > 4 {
                let splitIndex = remainingDigits.index(remainingDigits.startIndex, offsetBy: remainingDigits.count - 4)
                formattedNumber += remainingDigits[..<splitIndex] + "." + remainingDigits[splitIndex...]
            } else {
                formattedNumber += remainingDigits
            }
            
            return formattedNumber
            
        default: // 8-9 digits, city code + local
            // Try to separate into city code and local number
            let cityCodeLength = digits.count - 7
            let cityCodeIndex = digits.index(digits.startIndex, offsetBy: cityCodeLength)
            let localStart = digits[cityCodeIndex...]
            let index3 = localStart.index(localStart.startIndex, offsetBy: 3)
            return digits[..<cityCodeIndex] + "." + localStart[..<index3] + "." + localStart[index3...]
        }
    }
}