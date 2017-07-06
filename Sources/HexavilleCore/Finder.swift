//
//  HexavilleCore.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/06/21.
//
//

import Foundation

public struct Finder {
    internal static func findPath(childDir: String) throws -> String {
        let manager = FileManager.default
        
        var templatesPathCandidates: [String] = []
        
        let paths = ProcessInfo.processInfo.arguments[0].split(separator: "/")
        if paths.count > 3 {
            let projectRoot = "/\(paths[0..<paths.count-3].joined(separator: "/"))"
            let relativePath = FileManager.default.currentDirectoryPath+projectRoot
            templatesPathCandidates.append(contentsOf: [projectRoot, relativePath])
        }
        
        templatesPathCandidates.append(contentsOf: [
            manager.currentDirectoryPath,
            NSHomeDirectory()+"/.hexaville"
        ])
        
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
        
        throw HexavilleCoreError.couldNotFindTemplate(in: templatesPathCandidates)
    }
    
    public static func findTemplatePath(for childDir: String = "") throws -> String {
        return try findPath(childDir: "/templates"+childDir)
    }
    
    public static func findScriptPath(for name: String) throws -> String {
        return try findPath(childDir: "/Scripts/"+name)
    }
}
