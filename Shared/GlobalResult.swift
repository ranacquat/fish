// This file was generated by json2swift. https://github.com/ijoshsmith/json2swift

import Foundation

//
// MARK: - Data Model
//
struct GlobalResult: CreatableFromJSON {
    let extractedValues: ExtractedValues
    let globalResult: String
    let scoring: Scoring
    let validations: [Validations]
    init(extractedValues: ExtractedValues, globalResult: String, scoring: Scoring, validations: [Validations]) {
        self.extractedValues = extractedValues
        self.globalResult = globalResult
        self.scoring = scoring
        self.validations = validations
    }
    init?(json: [String: Any]) {
        guard let extractedValues = ExtractedValues(json: json, key: "extractedValues") else { return nil }
        guard let globalResult = json["globalResult"] as? String else { return nil }
        guard let scoring = Scoring(json: json, key: "scoring") else { return nil }
        guard let validations = Validations.createRequiredInstances(from: json, arrayKey: "validations") else { return nil }
        self.init(extractedValues: extractedValues, globalResult: globalResult, scoring: scoring, validations: validations)
    }
    struct ExtractedValues: CreatableFromJSON { 
        let accountDetails: AccountDetails
        let bankDetails: BankDetails
        let ownerDetails: OwnerDetails
        init(accountDetails: AccountDetails, bankDetails: BankDetails, ownerDetails: OwnerDetails) {
            self.accountDetails = accountDetails
            self.bankDetails = bankDetails
            self.ownerDetails = ownerDetails
        }
        init?(json: [String: Any]) {
            guard let accountDetails = AccountDetails(json: json, key: "accountDetails") else { return nil }
            guard let bankDetails = BankDetails(json: json, key: "bankDetails") else { return nil }
            guard let ownerDetails = OwnerDetails(json: json, key: "ownerDetails") else { return nil }
            self.init(accountDetails: accountDetails, bankDetails: bankDetails, ownerDetails: ownerDetails)
        }
        struct AccountDetails: CreatableFromJSON { // TODO: Rename this struct
            let accountKey: String
            let accountNumber: String
            let bankCode: String
            let bic: String
            let branchCode: String
            let iban: String
            init(accountKey: String, accountNumber: String, bankCode: String, bic: String, branchCode: String, iban: String) {
                self.accountKey = accountKey
                self.accountNumber = accountNumber
                self.bankCode = bankCode
                self.bic = bic
                self.branchCode = branchCode
                self.iban = iban
            }
            init?(json: [String: Any]) {
                guard let accountKey = json["accountKey"] as? String else { return nil }
                guard let accountNumber = json["accountNumber"] as? String else { return nil }
                guard let bankCode = json["bankCode"] as? String else { return nil }
                guard let bic = json["bic"] as? String else { return nil }
                guard let branchCode = json["branchCode"] as? String else { return nil }
                guard let iban = json["iban"] as? String else { return nil }
                self.init(accountKey: accountKey, accountNumber: accountNumber, bankCode: bankCode, bic: bic, branchCode: branchCode, iban: iban)
            }
        }
        struct BankDetails: CreatableFromJSON {
            let address: String
            let ibanCountryCode: String
            let name: String
            init(address: String, ibanCountryCode: String, name: String) {
                self.address = address
                self.ibanCountryCode = ibanCountryCode
                self.name = name
            }
            init?(json: [String: Any]) {
                guard let address = json["address"] as? String else { return nil }
                guard let ibanCountryCode = json["ibanCountryCode"] as? String else { return nil }
                guard let name = json["name"] as? String else { return nil }
                self.init(address: address, ibanCountryCode: ibanCountryCode, name: name)
            }
        }
        struct OwnerDetails: CreatableFromJSON {
            let address: Any?
            let extraInfos: [Any?]
            let name: Any?
            init(address: Any?, extraInfos: [Any?], name: Any?) {
                self.address = address
                self.extraInfos = extraInfos
                self.name = name
            }
            init?(json: [String: Any]) {
                guard let extraInfos = json["extraInfos"] as? [Any?] else { return nil }
                let address = json["address"] as? [Any?]
                let name = json["name"] as? [Any?]
                self.init(address: address, extraInfos: extraInfos, name: name)
            }
        }
    }
    struct Scoring: CreatableFromJSON {
        let confidenceIndex: Int
        init(confidenceIndex: Int) {
            self.confidenceIndex = confidenceIndex
        }
        init?(json: [String: Any]) {
            guard let confidenceIndex = json["confidenceIndex"] as? Int else { return nil }
            self.init(confidenceIndex: confidenceIndex)
        }
    }
    struct Validations: CreatableFromJSON {
        let elements: [Elements]
        let result: String
        let title: String
        init(elements: [Elements], result: String, title: String) {
            self.elements = elements
            self.result = result
            self.title = title
        }
        init?(json: [String: Any]) {
            guard let elements = Elements.createRequiredInstances(from: json, arrayKey: "elements") else { return nil }
            guard let result = json["result"] as? String else { return nil }
            guard let title = json["title"] as? String else { return nil }
            self.init(elements: elements, result: result, title: title)
        }
        struct Elements: CreatableFromJSON {
            let identifier: String
            let message: String
            let result: String
            let title: String
            init(identifier: String, message: String, result: String, title: String) {
                self.identifier = identifier
                self.message = message
                self.result = result
                self.title = title
            }
            init?(json: [String: Any]) {
                guard let identifier = json["identifier"] as? String else { return nil }
                guard let message = json["message"] as? String else { return nil }
                guard let result = json["result"] as? String else { return nil }
                guard let title = json["title"] as? String else { return nil }
                self.init(identifier: identifier, message: message, result: result, title: title)
            }
        }
    }
}

//
// MARK: - JSON Utilities
//
/// Adopted by a type that can be instantiated from JSON data.
protocol CreatableFromJSON {
    /// Attempts to configure a new instance of the conforming type with values from a JSON dictionary.
    init?(json: [String: Any])
}

extension CreatableFromJSON {
    /// Attempts to configure a new instance using a JSON dictionary selected by the `key` argument.
    init?(json: [String: Any], key: String) {
        guard let jsonDictionary = json[key] as? [String: Any] else { return nil }
        self.init(json: jsonDictionary)
    }

    /// Attempts to produce an array of instances of the conforming type based on an array in the JSON dictionary.
    /// - Returns: `nil` if the JSON array is missing or if there is an invalid/null element in the JSON array.
    static func createRequiredInstances(from json: [String: Any], arrayKey: String) -> [Self]? {
        guard let jsonDictionaries = json[arrayKey] as? [[String: Any]] else { return nil }
        var array = [Self]()
        for jsonDictionary in jsonDictionaries {
            guard let instance = Self.init(json: jsonDictionary) else { return nil }
            array.append(instance)
        }
        return array
    }

    /// Attempts to produce an array of instances of the conforming type, or `nil`, based on an array in the JSON dictionary.
    /// - Returns: `nil` if the JSON array is missing, or an array with `nil` for each invalid/null element in the JSON array.
    static func createOptionalInstances(from json: [String: Any], arrayKey: String) -> [Self?]? {
        guard let array = json[arrayKey] as? [Any] else { return nil }
        return array.map { item in
            if let jsonDictionary = item as? [String: Any] {
                return Self.init(json: jsonDictionary)
            }
            else {
                return nil
            }
        }
    }
}

extension Date {
    // Date parsing is serialized on a dedicated queue because DateFormatter is not thread-safe.
    private static let parsingQueue = DispatchQueue(label: "JSONDateParsing")
    private static var formatterCache = [String: DateFormatter]()
    private static func dateFormatter(with format: String) -> DateFormatter {
        if let formatter = formatterCache[format] { return formatter }
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatterCache[format] = formatter
        return formatter
    }

    static func parse(string: String, format: String) -> Date? {
        var date: Date?
        parsingQueue.sync {
            let formatter = dateFormatter(with: format)
            date = formatter.date(from: string)
        }
        return date
    }

    init?(json: [String: Any], key: String, format: String) {
        guard let string = json[key] as? String else { return nil }
        guard let date = Date.parse(string: string, format: format) else { return nil }
        self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate)
    }
}

extension URL {
    init?(json: [String: Any], key: String) {
        guard let string = json[key] as? String else { return nil }
        self.init(string: string)
    }
}

extension Double {
    init?(json: [String: Any], key: String) {
        // Explicitly unboxing the number allows an integer to be converted to a double,
        // which is needed when a JSON attribute value can have either representation.
        guard let nsNumber = json[key] as? NSNumber else { return nil }
        self.init(_: nsNumber.doubleValue)
    }
}

extension Array where Element: NSNumber {
    // Convert integers to doubles, for example [1, 2.0] becomes [1.0, 2.0]
    // This is necessary because ([1, 2.0] as? [Double]) yields nil.
    func toDoubleArray() -> [Double] {
        return map { $0.doubleValue }
    }
}

extension Array where Element: CustomStringConvertible {
    func toDateArray(withFormat format: String) -> [Date]? {
        var dateArray = [Date]()
        for string in self {
            guard let date = Date.parse(string: String(describing: string), format: format) else { return nil }
            dateArray.append(date)
        }
        return dateArray
    }

    func toURLArray() -> [URL]? {
        var urlArray = [URL]()
        for string in self {
           guard let url = URL(string: String(describing: string)) else { return nil }
           urlArray.append(url)
        }
        return urlArray
    }
}

extension Array where Element: Any {
    func toOptionalValueArray<Value>() -> [Value?] {
        return map { ($0 is NSNull) ? nil : ($0 as? Value) }
    }

    func toOptionalDateArray(withFormat format: String) -> [Date?] {
        return map { item in
            guard let string = item as? String else { return nil }
            return Date.parse(string: string, format: format)
        }
    }

    func toOptionalDoubleArray() -> [Double?] {
        return map { item in
            guard let nsNumber = item as? NSNumber else { return nil }
            return nsNumber.doubleValue
        }
    }

    func toOptionalURLArray() -> [URL?] {
        return map { item in
            guard let string = item as? String else { return nil }
            return URL(string: string)
        }
    }
}
