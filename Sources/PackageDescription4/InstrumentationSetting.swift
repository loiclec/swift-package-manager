/*
 This source file is part of the Swift.org open source project
 
 Copyright (c) 2018 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception
 
 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
 */

public struct InstrumentationSetting: Codable {
    public enum Kind: String, Codable {
        case coverage
    }
    
    let kind: Kind
    let targets: [String]
    let configuration: BuildConfiguration
    
    public init(kind: Kind, targets: [String], configuration: BuildConfiguration) {
        self.kind = kind
        self.targets = targets
        self.configuration = configuration
    }
    
    public static func coverage(forTargets targets: [String], configuration: BuildConfiguration) -> InstrumentationSetting {
        return InstrumentationSetting(kind: .coverage, targets: targets, configuration: configuration)
    }
}
