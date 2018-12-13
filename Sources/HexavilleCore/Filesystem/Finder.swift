//
//  HexavilleCore.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/06/21.
//
//

import Foundation

public struct Finder {
    
    private static var absoluteFilePathAtCompiling: String {
        return #file
            .split(separator: "/", omittingEmptySubsequences: false)
            .dropLast(3)
            .map { String($0) }
            .joined(separator: "/")
    }
    
    public static func findPath(childDir: String) throws -> String {
        let manager = FileManager.default
        
        let executablePath = ProcessInfo.processInfo.arguments[0]
        let hexavilleDevelopmentRoot = executablePath.components(separatedBy: ".build")[0]
        
        var templatesPathCandidates: [String] = [
            "\(hexavilleDevelopmentRoot)",
            NSHomeDirectory()+"/.hexaville"
        ]
        
        do {
            let execPath = ProcessInfo.processInfo.arguments[0]
            let dest = try manager.destinationOfSymbolicLink(atPath: execPath)+"/../"
            templatesPathCandidates.append(dest)
        } catch {}
        
        templatesPathCandidates = templatesPathCandidates.map({ $0+childDir })
        
        for path in templatesPathCandidates {
            if manager.fileExists(atPath: path) {
                return path
            }
        }
        
        // try to find file/directory in local compiled dir
        // This should not be append to templatesPathCandidates
        if manager.fileExists(atPath: absoluteFilePathAtCompiling+childDir) {
            return absoluteFilePathAtCompiling+childDir
        }
        
        throw HexavilleCoreError.couldNotFindFile(in: templatesPathCandidates)
    }
    
    public static func findTemplatePath(for childDir: String = "") throws -> String {
        return try findPath(childDir: "/templates"+childDir)
    }
    
    public static func findScriptPath(for name: String) throws -> String {
        return try findPath(childDir: "/Scripts/"+name)
    }
}
