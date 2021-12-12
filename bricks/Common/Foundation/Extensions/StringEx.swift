//
//  StringEx.swift
//
//
//  Created by Ido Rabin on 17/05/2021.
//  Copyright © 2021 . All rights reserved.
//

import Cocoa

extension Sequence where Iterator.Element == String {
    func lowercased(with locale:Locale? = nil)->[String] {
        return self.map { (str) -> String in
            return str.lowercased(with: locale)
        }
    }
    
    func uppercased(with locale:Locale? = nil)->[String] {
        return self.map { (str) -> String in
            return str.uppercased(with: locale)
        }
    }
    func capitalized(with locale:Locale? = nil)->[String] {
        return self.map { (str) -> String in
            return str.capitalized(with: locale)
        }
    }
}

extension String {
    
    
    /// Return a substring from index (as int)
    ///
    /// - Parameter from: index int location of first charachter to return a substring from
    /// - Returns: a substring of the given sring from the given index and until the end of the string
    func substring(from: Int) -> String {
        if from <= 0 {
            return self
        }

        let start = index(startIndex, offsetBy: from)
        return String(self[start ..< endIndex])
    }
    
    
    /// Return a substring until index (as int)
    ///
    /// - Parameter to: index int location of last charachter to return a substring until (not included)
    /// - Returns: a substring of the given sring from the cahr at index 0 until the given index (not included)
    func substring(to: Int) -> String {
        let end = index(startIndex, offsetBy: Swift.min(to, endIndex.utf16Offset(in: self)))
        return String(self[startIndex ..< end])
    }
    
    
    /// Returns a new string where the charachters at indexes of the given rage were replaced.
    ///
    /// - Parameters:
    ///   - range: Int Range (CountableClosedRange)
    ///   - replacementString: string to insert instead of the given range of charachters
    /// - Returns: resulting manipulated string
    public func replacing(range: CountableClosedRange<Int>, with replacementString: String) -> String {
        let rng = NSRange(location: range.lowerBound, length: max(range.upperBound - range.lowerBound, 1))
        if let range = self.range(from: rng) {
            return self.replacingCharacters(in: range, with: replacementString)
        }
        preconditionFailure("String replacing(range: CountableClosedRange<Int> range out of bounds!")
    }
    
    public func replacing(range: CountableRange<Int>, with replacementString: String) -> String {
        let rng = NSRange(location: range.lowerBound, length: max(range.upperBound - range.lowerBound, 1))
        if let range = self.range(from: rng) {
            return self.replacingCharacters(in: range, with: replacementString)
        }
        preconditionFailure("String replacing(range: CountableRange<Int> range out of bounds!")
    }
    
    /// Replace occurance of any char from the given char set to a uniform, single string
    ///
    /// - Parameters:
    ///   - set: charachter set to replace
    ///   - with: string to replace the charachters with
    /// - Returns: a string where each charachter of the given set is replaed with the given string
    func replacingOccurrences(of set:CharacterSet, with:String) -> String {
        return self.components(separatedBy: set)
            .filter { !$0.isEmpty }
            .joined(separator: with)
    }
    
    func replacingOccurrences(of set:CharacterSet, withRandomCharsOutOf charsRange:String) -> String {
        var result : String = ""
        for i in 0..<self.count {
            if let char = self.substring(atIndex: i) {
                if char.trimmingCharacters(in: set).count == 0 {
                    let index = Int(arc4random() % UInt32(charsRange.count))
                    let randomChar = charsRange.substring(atIndex: index) ?? " "
                    result.append(randomChar)
                } else {
                    result.append(char)
                }
            }
        }
        return result
    }
    
    /// Replaces all occurences of given keys with their corresponding values
    /// Example: for the string "hello simon and good day. hello!" and the given dictionary ["hello":"goodbye", "good":"have a great"],
    /// The resulting string would be "goodbye simon and have a great day. googbye!"
    ///
    ///
    /// - Parameter keyValues: keys to be replaced by their values
    /// - Returns: a new string where all occurences of given keys are replaced with their corresponding values
    func replacingOccurrences(ofFromTo keyValues:[String:String]) -> String {
        var str = self
        for (key, value) in keyValues {
            str = str.replacingOccurrences(of: key, with: value)
        }
        return str
    }
    
    /// Validate if the string is a valid email address (uses a simple regex)
    ///
    /// - Returns: true when email is valid
    func isValidEmail()->Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
    
    /// Returns the domain of the email IF the string is a valid email address
    ///
    /// - Returns: email address domain or nil
    func emailDomain()->String?
    {
        if self.isValidEmail() {
            let components = self.components(separatedBy: "@").last?.components(separatedBy: ".")
            if let components = components {
                let sindex = components.endIndex.advanced(by: -2)
                return components[sindex]
            }
        }
        
        return nil
    }
    
    
    /// Will return a "fixed" url string if the string was close enough to a valid url
    func isValidPossibleURL()->String? {
        var vals = [self]
        if !self.hasPrefix("https://") {
            vals.append("https://\(self)")
        }
        if !self.hasPrefix("http://") {
            vals.append("http://\(self)")
        }
        for val in vals {
            if URL(string:val) != nil {
                return val
            }
        }
        
        return nil
    }
    
    
    /// Returns true is the string can be split into two valid names: first name and last name components
    /// Conditions are that the string ahs at least 2 chars on either side of a whitespae charachter
    ///
    /// - Returns: true
    func isValidFullName()->Bool {
        if self.count < 4 {return false}
        
        let comps = self.components(separatedBy: CharacterSet.whitespaces)
        if comps.count < 2 {return false}
        var count = 0
        for comp in comps {
            if comp.count > 1 {
                count += 1
            }
        }
        if count < 2 {return false}
        
        return true
    }
    
    
    /// Returns the string split into two parts if they are valid parts of a full name
    ///
    /// - Returns: first name and last name tuple when the name is valid
    func componentsAsFullName()->(givenName:String, familyName:String)? {
        if !isValidFullName() {
            return nil
        }
        
        let comps = self.components(separatedBy: CharacterSet.whitespaces)
        if comps.count < 2 {return nil}
        if comps.count == 3 {
            return (givenName:comps.first! + " " + comps[1], familyName:comps.last!)
        }
        return (givenName:comps.first!, familyName:comps.last!)
    }
    
    
    static func validPasswordMinLength()->Int {
        return 8
    }
    
    /// Return if a candidate string is a valid password
    /// Currently the password MUST be comprised of at least 8 chars, 1 uppercase, one digit
    ///
    /// - Returns: true when teh string is a valid password
    func isValidPassword()->Bool {
        
        // Examples: (pick and use)
        /*
         ^                         Start anchor
         (?=.*[A-Z].*[A-Z])        Ensure string has two uppercase letters.
         (?=.*[!@#$&*])            Ensure string has one special case letter.
         (?=.*[0-9].*[0-9])        Ensure string has two digits.
         (?=.*[a-z].*[a-z].*[a-z]) Ensure string has three lowercase letters.
         .{8}                      Ensure string is of length 8.
         $                         End anchor.
         */
        
        
        var isPassedAllTests = true
        // At least one uppercase, one digit, at least validPasswordMinLength chars length (up to 20)
        let regexes = ["^(?=.*\\d).{\(String.validPasswordMinLength()),}$", "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$"]
        for regex in regexes {
            let passTest = NSPredicate(format:"SELF MATCHES %@", regex)
            isPassedAllTests = isPassedAllTests && passTest.evaluate(with: self)
        }
        
        // Actual test:
        
        return isPassedAllTests
    }
    
    
    /// Will return the last path compoment of the string IF it can be split into a url, otherwise, will return the whole string
    ///
    /// - Returns: Either the last path component or the original string as a whole
    func lastPathComponent()->String {
        if let url = URL(string:self) {
            return url.lastPathComponent
        }
        return self
    }
    
    
    /// Pad the string from its left side only with a charachter to fill up to a given total length of the string. If the string is already that length or bigger, no change will take place
    ///
    /// - Parameters:
    ///   - toLength: the length up to which the string is to be padded from the left
    ///   - character: the charachter to repeat as the filler padding in the left side of the string.
    ///   - padIndex: the char index from the left to start padding at
    /// - Returns: a string padded from its left side with the given charachter
    func paddingLeft(toLength: Int, withPad character: Character) -> String {
        if toLength <= 0 {return self}
        
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(self.suffix(toLength))
        }
    }
    
    
    func paddingLeft(padCount: Int, withPad character: Character) -> String {
        if padCount <= 0 {return self}
        
        // let stringLength = self.count
        return String(repeatElement(character, count: padCount)) + self
    }
    
    /// Will create a string trimming only from its left side any charachter from the given set. When encountering the first charachter that is not part of the set, the trimming will stop.
    /// Example: for the string ".!? simon, that is great!", using CharacterSet.punctuationCharacters will return
    /// "simon, this is great!"
    ///
    /// - Parameter set: a charachter set to use for the trimming
    /// - Returns: a string with its left side trimmed from all the the charachters in the set
    func trimmingPrefixCharacters(in set: CharacterSet) -> String {
        if self.count == 0 {return self}

        for index in 1..<self.count {
            let substr = self.substring(to: index)
            if substr.trimmingCharacters(in: set).count > 0 {
                return self.substring(from: index - 1)
            }
        }
        
        return self
    }
    
    /// Will create a string trimming only from its right side any charachter from the given set. When encountering the first charachter that is not part of the set, the trimming will stop.
    /// Example: for the string "simon, is this great!?", using CharacterSet.punctuationCharacters will return
    /// "simon, is this great"
    ///
    /// - Parameter set: a charachter set to use for the trimming
    /// - Returns: a string with its right side trimmed from all the the charachters in the set
    func trimmingSuffixCharacters(in set: CharacterSet) -> String {
        if self.count == 0 {return self}
        
        for index in 1..<self.count {
            let substr = self.substring(from: self.count - index)
            if substr.trimmingCharacters(in: set).count > 0 {
                return self.substring(to: self.count - index + 1)
            }
        }
        
        return self
    }
    
    
    /// Trim a prefix string only if the prefix string is indeed at the beginning of the string
    /// NOTE: will trim the first min(self.count / 256) cosecutive repetitions of prefix
    /// - Parameter prefix: expected prefix
    /// - Returns: a new string without the expected prefix, or, the original string if it does not contain the given string as a prefix
    func trimmingPrefix(_ prefix: String) -> String {
        var loopLimit = min(self.count, 256)
        var str = self
        while str.hasPrefix(prefix) && loopLimit > 0 {
            str = str.substring(from: prefix.count)
            loopLimit -= 1
        }
        
        return str
    }
    
    /// Trim a suffix string only if the suffix string is indeed at the end of the string
    /// NOTE: will trim the first min(self.count / 256) cosecutive repetitions of suffix
    /// - Parameter suffix: expected suffix
    /// - Returns: a new string without the expected suffix, or, the original string if it does not contain the given string as a suffix
    func trimmingSuffix(_ suffix: String) -> String {
        var loopLimit = min(self.count, 256)
        var str = self
        while str.hasSuffix(suffix) && loopLimit > 0 {
            str = self.substring(to: self.count - suffix.count)
            loopLimit -= 1
        }
        
        return str
    }
    
    
    /// Returns true when the string contains ANY charachter in the given charachter set
    /// NOTE: not efficient, do not use with big strings
    /// - Parameter set:set of charachters to be found in the string
    /// - Returns:true when the string contains at least one charachter in the set.
    func contains(anyIn set:CharacterSet)->Bool {
        return self.replacingOccurrences(of: set, with: "").count < self.count
    }
    

    /// Returns true is this string contains any of the strings in the given array
    /// // Note: test order is according to array order, and will stop testing after first found item
    /// - Parameter items:items to look for in the string.
    func contains(anyOf items:[String])->Bool {
        for item in items {
            if self.contains(item) {
                return true
            }
        }
        return false
    }
    
    
    /// Returns true when the string contains all of the given items as substrings - notee - does not account for overlaps.
    /// - Parameter items: substrigs to find
    /// - Returns: true if contains all of the given substrings
    func contains(allOf items:[String])->Bool {
        for item in items {
            if !self.contains(item) {
                return false // on of the substrings is missing
            }
        }
        return true // contains all
    }
    
    
    /// Returns true when the string ENDS with the wanted expression
    /// adds to the regex a "$" at the end
    func hasSuffixMatching(_ regex:String, options:NSRegularExpression.Options = [])->Bool {
        let substr = self.substring(from: max(self.count - regex.count, 0))
        let complete = regex.hasSuffix("$") ? regex : (regex + "$")
        return substr.matchRanges(for: complete, options: options).count > 0
    }
    
    /// Returns true when the string STARTS with the wanted expression
    /// adds to the regex a "^" at the start
    func hasPrefixMatching(_ regex:String, options:NSRegularExpression.Options = [])->Bool {
        let substr = self // - all string
        let complete = regex.hasPrefix("^") ? regex : ("^" + regex)
        return substr.matchRanges(for: complete, options: options).count > 0
    }
    
    /// Will return a suffix with the given length or smaller, or an empty string
    /// - Parameter size: maximun length of suffix required
    func safeSuffix(size: Int) -> String {
        return substring(from: self.count - size)
    }
    
    /// Will return a prefix with the given length or smaller, or an empty string
    /// - Parameter size: maximun length of prefix required
    func safePrefix(size: Int) -> String {
        return substring(to: size)
    }

}

extension StaticString {
    
    /// Will return the last path compoment of the string IF it can be split into a url, otherwise, will return the whole string
    ///
    /// - Returns: Either the last path component or the original string as a whole
    func lastPathComponent()->String {
        return self.description.lastPathComponent()
    }
}

// NSRange / Range<String.Index> conversions

extension String {
    
    
    /// Returns an NSRange describing the whole length of the string (from start index to the last index)
    ///
    /// - Returns: NSRange for the whole string
    func nsRangeForWholeString() -> NSRange? {
        if let from = self.startIndex.samePosition(in: utf16) {
            if let to = self.endIndex.samePosition(in: utf16) {
                return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                               length: utf16.distance(from: from, to: to))
            }
        }
        
        return nil
    }
    
    
    /// Convert Range<String.Index> to NSRange
    ///
    /// - Parameter range: range in new swift <String.Index> type
    /// - Returns: NSRange in int, assuming .utf16 encoding
    func nsRange(from range: Range<String.Index>) -> NSRange? {
        if let from = range.lowerBound.samePosition(in: utf16) {
            if let to = range.upperBound.samePosition(in: utf16) {
                return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                               length: utf16.distance(from: from, to: to))
            }
        }
        
        return nil
    }

    /// Convert NSRange to new swift Range<String.Index>
    ///
    /// - Parameter range: NSrange to convert from
    /// - Returns: Range<String.Index>? assuming .utf16 encoding
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location + nsRange.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return nil }
        return from ..< to
    }
    
    
    /// Given a string with digits, will attempt to search for the first found range of the same consecutive digit sequence in the given string, ignoring other charachters
    /// Example: "+1(234) 563456".rangeOfDigits("3456") will return the range of (3,4) and the "34) 56" substring
    /// NOTE: Search is limited to max length of 100 either or the digits string or self string
    ///
    /// - Parameter digits: digit sequence to search for
    /// - Returns: range of the digit sequence in the string, including delimiting charachters which are not digits and the found substring, including the other charachters
    func rangesOfDigits(digits:String) -> [(range:Range<String.Index>,substring:String)]? {
        
        var results : [(range:Range<String.Index>,substring:String)]? = []
        
        let digitsStr : String = digits.replacingOccurrences(of: CharacterSet.decimalDigits.inverted, with: "")
        if digitsStr.count > 0 && digitsStr.count < 100 && self.count < 100 {
            do {
                let digits : [String] = digitsStr.map { String($0) }
                let regexPattern = "(" + digits.joined(separator: "\\D{0,2}") + ")"
                let regex = try NSRegularExpression(pattern: regexPattern, options: [])
                let regexResults = regex.matches(in: self, options: [], range: NSMakeRange(0, self.count)) as Array<NSTextCheckingResult>
                for regexResult in regexResults {
                    results?.append((range:self.range(from: regexResult.range)!, substring:self.substring(with: regexResult.range)!))
                    // DLog.misc.info("rangesOfDigits found:\(digitsStr) in \(self) at:\(regexResult.range)")
                }
            } catch let error as NSError {
                DLog.misc.warning("StringEx.rangesOfDigits excpetion in regex: \(error.description)")
            }
        }
        
        if results?.count == 0 {
            results = nil
        }
        
        return results
    }
    
    /// Returns a copy of the string which omits all charachters that are NOT decimal digits, thus the remainder string is ONLY digits.
    var keepingDigitsOnly : String {
        get {
            return self.replacingOccurrences(of: CharacterSet.decimalDigits.inverted, with: "")
        }
    }
    
    /// Returns the ratio (part out of 1) of digit chars from the count of all chars.
    func partOfDigits()->Float {
        guard self.count > 0 else {
            return 0
        }
        
        let cnt = Float(self.count)
        let digits = Float(self.keepingDigitsOnly.count)
        return digits / cnt
    }
    
    var isAllAlphaNumerics : Bool {
        return self.replacingOccurrences(of: .alphanumerics, with: "").count == 0
    }
    
    var isAllDigits : Bool {
        return self.keepingDigitsOnly.count == self.count
    }
    
    var isAllCharsUppercased : Bool {
        return self.uppercased() == self
    }
    
    var isAllCharsLowercased : Bool {
        return self.lowercased() == self
    }
    
    var isAllCharsAscii : Bool {
        for scalar in self.unicodeScalars {
            if !scalar.isASCII {
                return false
            }
        }
        return true
    }
    
    
    func matchRanges(for regex: String, options: NSRegularExpression.Options = []) -> [NSRange] {
        do {
            let text = self
            let regex = try NSRegularExpression(pattern: regex, options: options)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { $0.range }
        } catch let error {
            print("[StringEx] invalid regex: \(error.localizedDescription) \((error as NSError).debugDescription)")
            return []
        }
    }
    
    func matches(for regex: String, options: NSRegularExpression.Options = []) -> [String] {
        let text = self
        let ranges = self.matchRanges(for: regex, options:options)
        if ranges.count > 0 {
            return ranges.map { (text as NSString).substring(with: $0)}
        }
        
        return []
    }
}


extension String {
    
    func capitalizedFirstWord()->String {
        guard self.count > 0 else {
            return self
        }
        
        let comps = self.components(separatedBy: .whitespacesAndNewlines)
        if comps.count > 1 {
            return self.replacingOccurrences(of: comps[0], with: comps[0].capitalized)
        } else {
            return self.capitalized
        }
    }
    /// Substring for a string with a given NSRange
    ///
    /// - Parameter range: NSRange for the substring location, assuming utf16 encoding
    /// - Returns: the substring of the string or nil if NSRange is out of bounds
    public func substring(with range:NSRange)->String? {
        if range.location >= 0 && range.location + range.length <= self.count, let rng = self.range(from: range) {
            return String(self[rng])
        }
        return nil
    }
    
    public func substring(atIndex index:Int)->String? {
        return self.substring(with: NSRange(location:index, length:1))
    }
    
    public func split(atIndex index:Int)->[String]? {
        if index == 0 {
            return ["", self.substring(from: 1)]
        }
        
        if index == self.count - 1 {
            return [self.substring(upTo: max(self.count - 2, 0)), ""]
        }
        
        if index < self.count && index > 0 {
            return [self.substring(upTo: index), self.substring(from: index + 1)]
        }
        
        return nil
    }
    
    /// Safe substring
    ///
    /// - Parameter index: index to return a substring that is up to this index, or shorter if the string is shorter
    /// - Returns: either
    public func substring(upTo index:Int)->String {
        
        if index < 0 {
            return self.substring(from: max(Int(self.count) + index, 0))
        }
        
        guard
            let strIndex16 = utf16.index(utf16.startIndex, offsetBy: index, limitedBy: utf16.endIndex),
            let strIndex = strIndex16.samePosition(in: self)
            else {return self}
        if self.endIndex > strIndex {
            return String(self[self.startIndex..<strIndex])
        }
        return self
    }
    
    func substring(withIntRange r: Range<Int>) -> String {
        guard let astrIndex16 = utf16.index(utf16.startIndex, offsetBy: r.lowerBound, limitedBy: utf16.endIndex),
             let astrIndex = astrIndex16.samePosition(in: self) else {
                return ""
        }
        
        guard let bstrIndex16 = utf16.index(utf16.startIndex, offsetBy: r.lowerBound, limitedBy: utf16.endIndex),
            let bstrIndex = bstrIndex16.samePosition(in: self) else {
                return ""
        }
        
        // TODO: Resolve this:
        return String(self[astrIndex..<bstrIndex]) //(with: astrIndex..<bstrIndex)
    }
    
    public func substring(untilFirstOccuranceOf substr:String)->String? {
        
        let indices = self.indices(of: substr)
        if (indices.count > 0)
        {
            return self.substring(upTo: indices.first!)
        }
        
        return nil
    }
    
    /// Trim a string from either a prefix and / or suffix string
    ///
    /// - Parameter string: a string to trim either from the start or end of the string.
    /// - Returns: a new string with its prefix of suffix or both trimmed, or the original string if the given string is not a prefix nor a suffix
    public func trimming(string:String)->String {
        var result = self
        if self == string {
            return ""
        }
        if self.hasPrefix(string) {
            result = self.substring(from: string.count)
        }
        if self.hasSuffix(string) {
            result = self.substring(to: result.count - string.count)
        }
        return result
    }
    
    func indices(of occurrence: String) -> [Int] {
        var indices = [Int]()
        var position = startIndex
        while let range = range(of: occurrence, range: position..<endIndex) {
            let i = distance(from: startIndex,
                             to: range.lowerBound)
            indices.append(i)
            let offset = occurrence.distance(from: occurrence.startIndex,
                                             to: occurrence.endIndex) - 1
            guard let after = index(range.lowerBound,
                                    offsetBy: offset,
                                    limitedBy: endIndex) else {
                                        break
            }
            position = index(after: after)
        }
        return indices
    }
    
    func ranges(of searchString: String) -> [Range<String.Index>] {
        let _indices = indices(of: searchString)
        let count = searchString.count
        return _indices.map({ index(startIndex, offsetBy: $0)..<index(startIndex, offsetBy: $0+count) })
    }
    
    public func substrings(between prefix:String, suffix:String)->[String]? {
        var result : [String]? = []
        let ranges = self.ranges(of: prefix)
        ranges.forEachIndex { (index, range) in
            // DLog.misc.info("[StringEx] substrings:between:suffix: substr: \(self[range])")
            var endIndex = String.Index(utf16Offset: self.count - 1, in:self)
            if index + 1 < ranges.count - 1 {
                endIndex = ranges[index + 1].lowerBound
            }
            
            let part = self[range.lowerBound..<endIndex]
            if let suffixRange = part.range(of: suffix) {
                // DLog.misc.info("[StringEx] substrings:between:suffix: substr: Found range: from:\(range.upperBound) ro:\(suffixRange.lowerBound) whole:\(self[range.upperBound..<suffixRange.lowerBound])")
                result?.append(String(part[range.upperBound..<suffixRange.lowerBound]))
            }
        }
        
        return result
    }
    
    public func hasAnyOfPrefixes(_ prefixes : [String])->Bool {
        for prefix in prefixes {
            if self.hasPrefix(prefix) {
                return true
            }
        }
        return false
    }
    
    public func hasAnyOfSuffixes(_ suffixes : [String])->Bool {
        for suffix in suffixes {
            if self.hasSuffix(suffix) {
                return true
            }
        }
        return false
    }
    
    
    /// Returns a string with multiple successive whitespaces or newlines are condensed into a single space
    /// For example:
    /// "mY TEXT  123\n  \tnew"
    /// will codense into:
    /// "mY TEXT 123 new"
    /// - Returns: a condensed string
    func condenseWhitespacesAndNewlines() -> String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    /// Returns a string with multiple successive whitespaces are condensed to into single space
    /// For example:
    /// "mY TEXT  123\n  \tnew"
    /// will codense into:
    /// "mY TEXT 123\n \tnew"
    /// - Returns: a condensed string
    func condenseWhitespaces() -> String {
        let components = self.components(separatedBy: .whitespaces)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    
    /// tries to detect the direction of the best found language is the string
    func detectBestLanguage()->String? {
        guard self.count > 0 else {
            return nil
        }
        
        let substr = self.substring(upTo: 100)
        return CFStringTokenizerCopyBestStringLanguage(substr as CFString, CFRange(location: 0, length: substr.count )) as String?
    }
    
    /// tries to detect the direction of the best found language is the string
    func detectBestTextAlignment()->NSTextAlignment? {
        if let lang = self.detectBestLanguage() {
            let rtlLangs = ["ar", "he"]
            return lang.lowercased().contains(anyOf: rtlLangs) ? .right : .left
        }
        return nil
    }
}

extension String {
    init (memoryAddressOf object:AnyObject) {
        self.init(String(describing: Unmanaged<AnyObject>.passUnretained(object as AnyObject).toOpaque()))
    }
    
    init (memoryAddressOfOrNil object:AnyObject?) {
        guard let object = object else {
            self.init("<nil>")
            return
        }
        self.init(String(describing: Unmanaged<AnyObject>.passUnretained(object as AnyObject).toOpaque()))
    }
}

//extension String /* bounding rectangles */ {
//    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
//        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
//        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
//
//        return ceil(boundingBox.height)
//    }
//
//    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
//        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
//        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
//
//        return ceil(boundingBox.width)
//    }
//}

/*
extension String /*run command*/{
    func runAsCommand() -> String {
        let pipe = Pipe()
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", String(format:"%@", self)]
        task.standardOutput = pipe
        let file = pipe.fileHandleForReading
        task.launch()
        if let result = NSString(data: file.readDataToEndOfFile(), encoding: String.Encoding.utf8.rawValue) {
            return result as String
        }
        else {
            return "--- Error running command - Unable to initialize string from file data ---"
        }
    }
}*/
