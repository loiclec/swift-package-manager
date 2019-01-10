/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2018 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

public enum BuildConfiguration: Equatable {
    case debug
    case release
    indirect case custom(name: String, base: BuildConfiguration?)
}

extension BuildConfiguration: RawRepresentable, Codable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        let components = rawValue.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
        switch components.count {
        case 0:
            return nil
        case 1:
            switch components.first! {
            case "debug"  : self = .debug
            case "release": self = .release
            default       : return nil
            }
        case 2:
            let fst = components.first!
            guard
                fst != "debug",
                fst != "release"
            else {
                return nil
            }
            self = .custom(name: String(fst), base: BuildConfiguration(rawValue: String(components[1])))
        default:
            fatalError()
        }
    }
    
    public var rawValue: String {
        switch self {
        case .debug: return "debug"
        case .release: return "release"
        case .custom(name: let name, base: let base):
            if let base = base {
                return name + "-" + base.rawValue
            } else {
                return name
            }
        }
    }
}

extension BuildConfiguration: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)!
    }
}

extension BuildConfiguration {
    
    public func refines(_ configuration: BuildConfiguration) -> Bool {
        guard self != configuration else {
            return true
        }
        switch self {
        case .debug, .release:
            return false
        case .custom(name: _, base: let base?):
            return base.refines(configuration)
        case .custom(name: _, base: nil):
            return false
        }
    }
}

/// A build setting condition.
public struct BuildSettingCondition: Encodable {

    private let platforms: [Platform]?
    private let config: BuildConfiguration?

    private init(platforms: [Platform]?, config: BuildConfiguration?) {
        self.platforms = platforms
        self.config = config
    }

    /// Create a build setting condition.
    ///
    /// At least one parameter is mandatory.
    public static func when(
        platforms: [Platform]? = nil,
        configuration: BuildConfiguration? = nil
    ) -> BuildSettingCondition {
        // FIXME: This should be an error not a precondition.
        precondition(!(platforms == nil && configuration == nil))
        return BuildSettingCondition(platforms: platforms, config: configuration)
    }
}

/// The underlying build setting data.
fileprivate struct BuildSettingData: Encodable {

    /// The name of the build setting.
    let name: String

    /// The value of the build setting.
    let value: [String]

    /// The condition at which the build setting should be applied.
    let condition: BuildSettingCondition?
}

/// A C-language build setting.
public struct CSetting: Encodable {
    private let data: BuildSettingData

    private init(name: String, value: [String], condition: BuildSettingCondition?) {
        self.data = BuildSettingData(name: name, value: value, condition: condition)
    }

    /// Provide a header search path relative to the target's root directory.
    ///
    /// The path must not escape the package boundary.
    public static func headerSearchPath(_ path: String, _ condition: BuildSettingCondition? = nil) -> CSetting {
        return CSetting(name: "headerSearchPath", value: [path], condition: condition)
    }

    /// Define macro to a value (or 1 if the value is omitted).
    public static func define(_ name: String, to value: String? = nil, _ condition: BuildSettingCondition? = nil) -> CSetting {
        var settingValue = name
        if let value = value {
            settingValue += "=" + value
        }
        return CSetting(name: "define", value: [settingValue], condition: condition)
    }

    /// Set the given unsafe flags.
    public static func unsafeFlags(_ flags: [String], _ condition: BuildSettingCondition? = nil) -> CSetting {
        return CSetting(name: "unsafeFlags", value: flags, condition: condition)
    }
}

/// A CXX-language build setting.
public struct CXXSetting: Encodable {
    private let data: BuildSettingData

    private init(name: String, value: [String], condition: BuildSettingCondition?) {
        self.data = BuildSettingData(name: name, value: value, condition: condition)
    }

    /// Provide a header search path relative to the target's root directory.
    ///
    /// The path must not escape the package boundary.
    public static func headerSearchPath(_ path: String, _ condition: BuildSettingCondition? = nil) -> CXXSetting {
        return CXXSetting(name: "headerSearchPath", value: [path], condition: condition)
    }

    /// Define macro to a value (or 1 if the value is omitted).
    public static func define(_ name: String, to value: String? = nil, _ condition: BuildSettingCondition? = nil) -> CXXSetting {
        var settingValue = name
        if let value = value {
            settingValue += "=" + value
        }
        return CXXSetting(name: "define", value: [settingValue], condition: condition)
    }

    /// Set the given unsafe flags.
    public static func unsafeFlags(_ flags: [String], _ condition: BuildSettingCondition? = nil) -> CXXSetting {
        return CXXSetting(name: "unsafeFlags", value: flags, condition: condition)
    }
}

/// A Swift language build setting.
public struct SwiftSetting: Encodable {
    private let data: BuildSettingData

    private init(name: String, value: [String], condition: BuildSettingCondition?) {
        self.data = BuildSettingData(name: name, value: value, condition: condition)
    }

    /// Marks the given conditional compilation flag as true.
    public static func define(_ name: String, _ condition: BuildSettingCondition? = nil) -> SwiftSetting {
        return SwiftSetting(name: "define", value: [name], condition: condition)
    }

    /// Set the given unsafe flags.
    public static func unsafeFlags(_ flags: [String], _ condition: BuildSettingCondition? = nil) -> SwiftSetting {
        return SwiftSetting(name: "unsafeFlags", value: flags, condition: condition)
    }
}

/// A linker build setting.
public struct LinkerSetting: Encodable {
    private let data: BuildSettingData

    private init(name: String, value: [String], condition: BuildSettingCondition?) {
        self.data = BuildSettingData(name: name, value: value, condition: condition)
    }

    /// Link a system library.
    public static func linkedLibrary(_ library: String, _ condition: BuildSettingCondition? = nil) -> LinkerSetting {
        return LinkerSetting(name: "linkedLibrary", value: [library], condition: condition)
    }

    /// Link a system framework.
    public static func linkedFramework(_ framework: String, _ condition: BuildSettingCondition? = nil) -> LinkerSetting {
        return LinkerSetting(name: "linkedFramework", value: [framework], condition: condition)
    }

    /// Set the given unsafe flags.
    public static func unsafeFlags(_ flags: [String], _ condition: BuildSettingCondition? = nil) -> LinkerSetting {
        return LinkerSetting(name: "unsafeFlags", value: flags, condition: condition)
    }
}
