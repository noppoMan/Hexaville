//
//  DockerBuildEnvironmentProvider.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/22.
//
//

import Foundation


enum DockerBuildEnvironmentProviderError: Error {
    case dockerIsNotFound
    case dockerBuildFailed
    case couldNotMakeSharedDir
}

extension DockerBuildEnvironmentProviderError: CustomStringConvertible {
    var description: String {
        switch self {
        case .dockerIsNotFound:
            return """
            [DockerBuildEnvironmentProviderError] Could not find 'docker' in your machine. Please install docker.
            
              See Official installation guides with 'open https://docs.docker.com/engine/installation'
            
            
            """

        case .dockerBuildFailed:
            return "[DockerBuildEnvironmentProviderError] docker build is failed with the above reason."
            
        case .couldNotMakeSharedDir:
            return "[DockerBuildEnvironmentProviderError] Could not make shared directory between Host machine and Docker. Please make sure permission of your working directory."
        }
    }
}

struct DockerBuildEnvironmentProvider: SwiftBuildEnvironmentProvider {
    
    var dockerExecutablePath: String {
        return ProcessInfo.processInfo.environment["DOCKER_PATH"] ?? "docker"
    }
    
    func build(config: Configuration, hexavilleApplicationPath: String, executable: String) throws -> BuildResult {
        
        print("\nDocker version")
        let dockerVersionResult = Process.exec("docker", ["version"])
        if dockerVersionResult.terminationStatus != 0 {
            throw DockerBuildEnvironmentProviderError.dockerIsNotFound
        }
        
        let templatePath = try Finder.findTemplatePath()
        let buildSwiftShellPath = try Finder.findScriptPath(for: "build-swift.sh")
        
        try String(contentsOfFile: buildSwiftShellPath, encoding: .utf8)
            .write(toFile: "\(hexavilleApplicationPath)/build-swift.sh", atomically: true, encoding: .utf8)
        
        let dest: String
        if config.forSwift.version.asCompareableVersion() > Version(major: 3, minor: 1) {
            dest = "/hexaville-app/.build/x86_64-unknown-linux"
        } else {
            dest = "/hexaville-app/.build"
        }
        
        try String(contentsOfFile: templatePath+"/Dockerfile", encoding: .utf8)
            .replacingOccurrences(of: "{{SWIFT_DOWNLOAD_URL}}", with: config.forSwift.version.downloadURLString)
            .replacingOccurrences(of: "{{SWIFTFILE}}", with: config.forSwift.version.fileName)
            .replacingOccurrences(of: "{{EXECUTABLE_NAME}}", with: executable)
            .replacingOccurrences(of: "{{DEST}}", with: dest)
            .write(
                toFile: hexavilleApplicationPath+"/Dockerfile",
                atomically: true,
                encoding: .utf8
        )
        
        try String(contentsOfFile: templatePath+"/.dockerignore", encoding: .utf8)
            .write(
                toFile: hexavilleApplicationPath+"/.dockerignore",
                atomically: true,
                encoding: .utf8
        )
        
        let tag = executable.lowercased()
        
        var opts = ["build", "-t", tag, "-f", "\(hexavilleApplicationPath)/Dockerfile", hexavilleApplicationPath]
        if config.forBuild.noCache {
            opts.insert("--no-cache", at: 1)
        }
        
        let buildResult = Process.exec(dockerExecutablePath, opts)
        if buildResult.terminationStatus != 0 {
            throw DockerBuildEnvironmentProviderError.dockerBuildFailed
        }
        
        let sharedDir = "\(hexavilleApplicationPath)/__docker_shared"
        let mkdirResult = Process.exec("mkdir", ["-p", sharedDir])
        if mkdirResult.terminationStatus != 0 {
            throw DockerBuildEnvironmentProviderError.couldNotMakeSharedDir
        }
        
        #if os(OSX)
            let dockerRunOpts = [
                "-e",
                "BUILD_CONFIGURATION=\(config.forSwift.build.configuration)",
                "-v",
                "\(sharedDir):\(dest)",
                "-it",
                tag
            ]
        #else
            guard let user = ProcessInfo.processInfo.environment["USER"] else {
                fatalError("$USER was not found in env")
            }
            
            let dockerRunOpts = [
                "-e",
                "BUILD_CONFIGURATION=\(config.forSwift.build.configuration)",
                "-e",
                "VOLUME_USER=\(user)",
                "-e",
                "VOLUME_GROUP=\(user)",
                "-v",
                "\(sharedDir):\(dest)",
                "-it",
                tag
            ]
        #endif
        
        _ = try Spawn(args: ["/usr/bin/env", "docker", "run"] + dockerRunOpts) {
            print($0, separator: "", terminator: "")
        }
        
        return BuildResult(destination: sharedDir+"/\(config.forSwift.build.configuration)", dockerTag: tag)
    }
}
