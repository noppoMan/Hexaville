//
//  main.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/17.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import Foundation
import Prorsum
import SwiftyJSON
import SwiftCLI
import Yaml
import HexavilleCore

enum HexavilleError: Error {
    case projectAlreadyCreated(String)
    case couldNotFindManifestFile(String)
    case couldNotFindHexavillefile(String)
    case unsupportedSwiftToolsVersion(String)
}

private func transformToAbsolutePath(_ path: String) -> String {
    func isRelative(_ path: String) -> Bool {
        return path.first != "/"
    }
    
    if isRelative(path) {
        return "\(FileManager.default.currentDirectoryPath)/\(path)"
    }
    
    return path
}

class GenerateProject: Command {
    let name = "generate"
    let shortDescription  = "Generate initial project"
    let projectName = Parameter()
    let swiftToolVersion = Key<String>("--swift-tools-version", description: "Major Swift Tool Version for this project. default is 4.0")
    let dest = Key<String>("-o", "--dest", description: "Destination for the project")
    
    private func resolveSwiftVersion() throws -> SwiftVersionContainer {
        guard let version = swiftToolVersion.value else {
            // default is 4.0
            return Configuration.SwiftConfiguration.defaultVersion
        }
        
        let swiftVersion = try SwiftVersionContainer(string: version)
        
        if (Configuration.SwiftConfiguration.supportedVersionsRange ~= swiftVersion.asCompareableVersion().major) == false {
            throw HexavilleError.unsupportedSwiftToolsVersion(version)
        }
        
        return swiftVersion
    }
    
    private func createBucketName(from projectName: String, hashId: String) -> String {
        let prefix = "hexaville-"
        let suffix = "-\(hashId)-bucket"
        
        let bucketNameMaxLength = 63
        let maxLength = bucketNameMaxLength - (prefix + suffix).characters.count
        
        let allowedCharacters = Set("abcdefghijklmnopqrstuvwxyz1234567890-".characters)
        let sanitizedCharacters = projectName
            .lowercased()
            .characters
            .filter { allowedCharacters.contains($0) }
            .prefix(maxLength)
        
        let sanitizedName = String(sanitizedCharacters)
        
        return prefix + sanitizedName + suffix
    }
    
    func execute() throws {
        do {
            let out = (dest.value ?? FileManager.default.currentDirectoryPath) + "/\(projectName.value)"
            let packageSwiftPath = out+"/Package.swift"
            let ymlPath = out+"/Hexavillefile.yml"
            
            if FileManager.default.fileExists(atPath: packageSwiftPath) {
                throw HexavilleError.projectAlreadyCreated(out)
            }
            let hashids = Hashids(salt: UUID().uuidString)
            
            #if os(Linux)
                srandom(UInt32(time(nil)))
                let randomNumber = Int(UInt32(random() % 10000))
            #else
                let randomNumber = Int(arc4random_uniform(9999))
            #endif
            
            let swiftVersion = try resolveSwiftVersion()
            
            try FileManager.default.copyFiles(from: "\(Finder.findTemplatePath(for: "/SwiftProject/Base"))", to: out)
            try FileManager.default.copyFiles(from: "\(Finder.findTemplatePath(for: "/SwiftProject/Swift\(swiftVersion.asCompareableVersion().major)"))", to: out)
            try FileManager.default.copyFiles(from: "\(Finder.findTemplatePath(for: "/SwiftProject/Sources"))", to: "\(out)/Sources/\(projectName.value)")
            
            let hashId = hashids.encode(randomNumber)!
            
            let bucketName = createBucketName(from: projectName.value, hashId: hashId)
            
            try String(contentsOfFile: ymlPath, encoding: .utf8)
                .replacingOccurrences(of: "{{appName}}", with: projectName.value)
                .replacingOccurrences(of: "{{bucketName}}", with: bucketName)
                .replacingOccurrences(of: "{{swiftVersion}}", with: swiftVersion.versionString)
                .write(toFile: ymlPath, atomically: true, encoding: .utf8)
            
            try String(contentsOfFile: packageSwiftPath, encoding: .utf8)
                .replacingOccurrences(of: "{{appName}}", with: projectName.value)
                .replacingOccurrences(of: "{{appNameLower}}", with: projectName.value.lowercased())
                .write(toFile: packageSwiftPath, atomically: true, encoding: .utf8)
            
        } catch {
            print(error)
            throw error
        }
    }
}

func loadHexavilleFile(hexavilleFilePath: String) throws -> Yaml {
    let ymlString = try String(contentsOfFile: hexavilleFilePath, encoding: .utf8)
    return try Yaml.load(ymlString)
}

class RoutesCommand: Command {
    let name = "routes"
    let shortDescription  = "Show routes and endpoint for the API"
    let stage = Key<String>("--stage", description: "Deployment Stage. default is staging")
    
    func execute() throws {
        do {
            let cwd = FileManager.default.currentDirectoryPath
            let ymlPath = cwd+"/Hexavillefile.yml"
            if !FileManager.default.fileExists(atPath: ymlPath) {
                throw HexavilleError.couldNotFindManifestFile(ymlPath)
            }
            
            let deploymentStage = DeploymentStage(string: stage.value ?? "staging")
            let config = try HexavillefileLoader(fromHexavillefilePath: ymlPath).load()
            
            let launcher = Launcher(
                hexavilleApplicationPath: cwd,
                executable: "\(cwd)".components(separatedBy: "/").last ?? "",
                configuration: config,
                deploymentStage: deploymentStage
            )
            try launcher.showRoutes()
        } catch {
            print(error)
            throw error
        }
    }
}

class Deploy: Command {
    let name = "deploy"
    let shortDescription  = "Deploy your application to the specified cloud provider"
    let executableName = Parameter()
    let hexavillefilePath = Key<String>("-c", "--hexavillefile", description: "Path for the Hexavillefile.yml")
    let stage = Key<String>("--stage", description: "Deployment Stage. default is staging")
    
    func execute() throws {
        do {
            var hexavileApplicationPath = FileManager.default.currentDirectoryPath
            var hexavilleFileYAML = "Hexavillefile.yml"
            if var hexavillefilePath = hexavillefilePath.value {
                hexavillefilePath = transformToAbsolutePath(hexavillefilePath)
                if !FileManager.default.fileExists(atPath: hexavillefilePath) {
                    throw HexavilleError.couldNotFindHexavillefile(hexavillefilePath)
                }
                var splited = hexavillefilePath.components(separatedBy: "/")
                hexavilleFileYAML = splited.removeLast()
                hexavileApplicationPath = splited.joined(separator: "/")
            }
            
            var environment: [String: String] = [:]
            do {
                environment = try DotEnvParser.parse(fromFile: hexavileApplicationPath+"/.env")
            } catch {
                print(".env was not found")
            }
            
            let deploymentStage = DeploymentStage(string: stage.value ?? "staging")
            let yml = try loadHexavilleFile(hexavilleFilePath: "\(hexavileApplicationPath)/\(hexavilleFileYAML)")
            
            print("Hexavillefile: \(hexavileApplicationPath)/\(hexavilleFileYAML)")
            
            let config = try HexavillefileLoader(fromYaml: yml).load(withEnvironment: environment)
            
            let launcher = Launcher(
                hexavilleApplicationPath: hexavileApplicationPath,
                executable: executableName.value,
                configuration: config,
                deploymentStage: deploymentStage
            )
            try launcher.launch()
        } catch {
            fatalError("\(error)")
        }
    }
}

func detectVersion() -> String {
    if let path = try? Finder.findPath(childDir: "/.hexaville-version"), let version = try? String(contentsOfFile: path, encoding: .utf8) {
        return version.components(separatedBy: "\n").first ?? "Unknown"
    }
    
    return "Unknown"
}

// SIGINT handling
SignalHandler.shared.trap(with: .int) {
    defer {
        exit(SignalHandler.Signal.int.rawValue)
    }
    SignalEventEmitter.shared.emit(with: .int)
}

let hexavilleCLI = CLI(name: "hexaville", version: detectVersion())
hexavilleCLI.commands = [GenerateProject(), Deploy(), RoutesCommand()]
_ = hexavilleCLI.go()
