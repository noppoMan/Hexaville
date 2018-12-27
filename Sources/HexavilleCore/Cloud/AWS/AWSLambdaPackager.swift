//
//  AWSLambdaPackager.swift
//  APIGateway
//
//  Created by Yuki Takei on 2018/12/28.
//

import Foundation

public struct Package {
    public let destination: String
}

public enum AWSLambdaPackagerError: Error {
    case couldNotZipPackage
}

public struct AWSLambdaPackager {
    
    public init() {}
    
    private var lambdaPackageShellContent: String {
        var content = ""
        content += "#!/usr/bin/env sh"
        content += "\n"
        content += "cd $2"
        content += "\n"
        content += "zip $1 $3 byline.js index.js ./*.so ./*.so.* -r assets"
        return content
    }
    
    public func package(buildResult: BuildResult, hexavilleApplicationPath: String, executable: String) throws -> Package {
        let nodejsTemplatePath = try Finder.findTemplatePath(for: "/lambda/node.js")
    
        let workingDirectory = "\(hexavilleApplicationPath)/.hexaville"
        
        _ = Process.exec("mkdir", ["-p", workingDirectory])
        
        let pkgFileName = "\(workingDirectory)/lambda-package.zip"
        
        try String(contentsOfFile: "\(nodejsTemplatePath)/index.js", encoding: .utf8)
            .replacingOccurrences(of: "{{executablePath}}", with: executable)
            .write(toFile: buildResult.destination+"/index.js", atomically: true, encoding: .utf8)
        
        try String(contentsOfFile: "\(nodejsTemplatePath)/byline.js", encoding: .utf8)
            .write(toFile: buildResult.destination+"/byline.js", atomically: true, encoding: .utf8)
        
        let assetPath = hexavilleApplicationPath+"/assets"
        if FileManager.default.fileExists(atPath: assetPath) {
            _ = Process.exec("cp", ["-r", assetPath, "\(buildResult.destination)"])
        }
        
        let shellPath = "/tmp/build-lambda-package.sh"
        try lambdaPackageShellContent.write(toFile: shellPath, atomically: true, encoding: .utf8)
        let proc = Proc("/bin/sh", [shellPath, pkgFileName, buildResult.destination, executable])
        
        if proc.terminationStatus > 0 {
            throw AWSLambdaPackagerError.couldNotZipPackage
        }
        
        try FileManager.default.removeItem(atPath: shellPath)
        
        return Package(destination: pkgFileName)
    }
}
