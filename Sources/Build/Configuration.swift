/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

public struct Configuration: Equatable {
    public enum Mode: String, Equatable {
        case normal
        case fuzz
    }
    public enum Optimization: String, Equatable {
        case debug
        case release
    }
    public let mode: Mode
    public let optimization: Optimization
    
    public init(mode: Mode, optimization: Optimization) {
        self.mode = mode
        self.optimization = optimization
    }
    public var dirname: String {
        return self.description
    }
}

extension Configuration {
    public static let normalDebug: Configuration = .init(mode: .normal, optimization: .debug)
    public static let normalRelease: Configuration = .init(mode: .normal, optimization: .release)
    public static let fuzzDebug: Configuration = .init(mode: .fuzz, optimization: .debug)
    public static let fuzzRelease: Configuration = .init(mode: .fuzz, optimization: .release)
}

extension Configuration: CustomStringConvertible {
    public var description: String {
        var desc = ""
        if mode == .fuzz {
            desc += "\(mode.rawValue)-"
        }
        desc += optimization.rawValue
        return desc
    }
}

extension Configuration {
    var clangActiveCompilationConditions: [String] {
        var compilationConditions = ["-DSWIFT_PACKAGE=1"]
        
        if optimization == .debug {
            compilationConditions += ["-DDEBUG=1"]
        }
        if mode == .fuzz {
            compilationConditions += ["-DFUZZER=1"]
        }
        
        return compilationConditions
    }
    var swiftActiveCompilationConditions: [String] {
        var compilationConditions = ["-DSWIFT_PACKAGE"]
        
        if optimization == .debug {
            compilationConditions += ["-DDEBUG"]
        }
        if mode == .fuzz {
            compilationConditions += ["-DFUZZER"]
        }
        
        return compilationConditions
    }
    
    var swiftOptimizationArguments: [String] {
        switch optimization {
        case .debug:
            return ["-Onone", "-g", "-enable-testing"]
        case .release:
            return ["-O"]
        }
    }
    
    /// Optimization arguments according to the build configuration.
    var clangOptimizationArguments: [String] {
        switch optimization {
        case .debug:
            return ["-g", "-O0"]
        case .release:
            return ["-O2"]
        }
    }
}
