#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

import Foundation
import SwiftyJSON
import SwiftCLI
import Yams
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
    let swiftToolVersion = Key<String>("--swift-tools-version", description: "Major Swift Tool Version for this project. default is 4.2")
    let dest = Key<String>("-o", "--dest", description: "Destination for the project")
    
    private func resolveSwiftVersion() throws -> SwiftVersion {
        guard let version = swiftToolVersion.value else {
            return Constant.defaultSwiftVersion
        }
        
        let swiftVersion = try SwiftVersion(string: version)
        
        if (Constant.supportedSwiftVersionsRange ~= swiftVersion.asCompareableVersion().major) == false {
            throw HexavilleError.unsupportedSwiftToolsVersion(version)
        }
        
        return swiftVersion
    }
    
    func execute() throws {
        do {
            let out = (dest.value ?? FileManager.default.currentDirectoryPath) + "/\(projectName.value)"
            let packageSwiftPath = out+"/Package.swift"
            let ymlPath = out+"/Hexavillefile.yml"
            let serverlessYmlPath = out+"/serverless.yml"
            
            if FileManager.default.fileExists(atPath: packageSwiftPath) {
                throw HexavilleError.projectAlreadyCreated(out)
            }
            
            let swiftVersion = try resolveSwiftVersion()
            
            try FileManager.default.copyFiles(from: "\(Finder.findTemplatePath(for: "/SwiftProject/Base"))", to: out)
            try FileManager.default.copyFiles(from: "\(Finder.findTemplatePath(for: "/SwiftProject/Swift\(swiftVersion.asCompareableVersion().major)"))", to: out)
            try FileManager.default.copyFiles(from: "\(Finder.findTemplatePath(for: "/SwiftProject/Sources"))", to: "\(out)/Sources/\(projectName.value)")
            
            try String(contentsOfFile: ymlPath, encoding: .utf8)
                .replacingOccurrences(of: "{{appName}}", with: projectName.value)
                .replacingOccurrences(of: "{{swiftVersion}}", with: swiftVersion.versionString)
                .write(toFile: ymlPath, atomically: true, encoding: .utf8)
            
            try String(contentsOfFile: packageSwiftPath, encoding: .utf8)
                .replacingOccurrences(of: "{{appName}}", with: projectName.value)
                .replacingOccurrences(of: "{{appNameLower}}", with: projectName.value.lowercased())
                .write(toFile: packageSwiftPath, atomically: true, encoding: .utf8)
            
            try String(contentsOfFile: serverlessYmlPath, encoding: .utf8)
                .replacingOccurrences(of: "{{appName}}", with: projectName.value.lowercased())
                .write(toFile: serverlessYmlPath, atomically: true, encoding: .utf8)
            
        } catch {
            print(error)
            throw error
        }
    }
}

func loadHexavilleFile(hexavilleFilePath: String) throws -> HexavilleFile {
    let ymlString = try String(contentsOfFile: hexavilleFilePath, encoding: .utf8)
    return try HexavilleFile.load(ymlString: ymlString)
}

class BuildCommand: Command {
    let name = "package"
    let shortDescription  = "build and packaging your hexaville application"
    let hexavillefilePath = Key<String>("-c", "--hexavillefile", description: "Path for the Hexavillefile.yml")
    
    func execute() throws {
        do {
            var hexavilleApplicationPath = FileManager.default.currentDirectoryPath
            var hexavilleFileYAML = "Hexavillefile.yml"
            if let hexavillefilePath = hexavillefilePath.value {
                hexavilleApplicationPath = transformToAbsolutePath(hexavillefilePath)
                if !FileManager.default.fileExists(atPath: hexavillefilePath) {
                    throw HexavilleError.couldNotFindHexavillefile(hexavillefilePath)
                }
                var splited = hexavillefilePath.components(separatedBy: "/")
                hexavilleFileYAML = splited.removeLast()
                hexavilleApplicationPath = splited.joined(separator: "/")
            }
            
            let config = try loadHexavilleFile(hexavilleFilePath: "\(hexavilleApplicationPath)/\(hexavilleFileYAML)")
            
            print("Hexavillefile: \(hexavilleApplicationPath)/\(hexavilleFileYAML)")
            
            let builder = SwiftBuilder(version: config.swift.version)
            let result = try builder.build(
                config: config,
                hexavilleApplicationPath: hexavilleApplicationPath,
                executable: config.executableTarget
            )
            
            let package = try AWSLambdaPackager().package(
                buildResult: result,
                hexavilleApplicationPath: hexavilleApplicationPath,
                executable: config.executableTarget
            )
            
            print("###########################################################################")
            print("Your application package was successfully created at \(package.destination)")
            print("next step.")
            print("")
            print("    sls deploy --stage staging or production")
            print("")
            print("guide: https://serverless.com/framework/docs/providers/aws/guide/deploying/")
            print("###########################################################################")
            
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
hexavilleCLI.commands = [GenerateProject(), BuildCommand()]
_ = hexavilleCLI.go()
