//
//  main.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/17.
//
//

//
//  main.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/16.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import Foundation
import AWSSDKSwift
import Prorsum
import Core
import SwiftyJSON
import SwiftCLI
import Yaml

enum HexavilleError: Error {
    case missingRequiredParamInHexavillefile(String)
    case unsupportedService(String)
    case projectAlreadyCreated(String)
    case couldNotFindManifestFile(String)
    case pathIsNotForHexavillefile(String)
}

class GenerateProject: Command {
    let name = "generate"
    let shortDescription  = "Generate initial project"
    let projectName = Parameter()
    let dest = Key<String>("-o", "--dest", usage: "Destination for the project")
    
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
            
            try FileManager.default.copyFiles(from: "\(projectRoot)/templates/SwiftProject", to: out)
            let hashId = hashids.encode(randomNumber)!
            let bucketName = "hexaville-\(projectName.value.lowercased())-\(hashId)-bucket"
            
            try String(contentsOfFile: ymlPath)
                .replacingOccurrences(of: "{{appName}}", with: projectName.value)
                .replacingOccurrences(of: "{{bucketName}}", with: bucketName)
                .write(toFile: ymlPath, atomically: true, encoding: .utf8)
            
            try String(contentsOfFile: packageSwiftPath)
                .replacingOccurrences(of: "{{appName}}", with: projectName.value)
                .write(toFile: packageSwiftPath, atomically: true, encoding: .utf8)
            
        } catch {
            print(error)
            throw error
        }
    }
}

func loadHexavilleFile(hexavilleFilePath: String) throws -> Yaml {
    let ymlString = try String(contentsOfFile: hexavilleFilePath)
    return try Yaml.load(ymlString)
}

class RoutesCommand: Command {
    let name = "routes"
    let shortDescription  = "Show routes and endpoint for the API"
    let stage = Key<String>("--stage", usage: "Deployment Stage. default is staging")
    
    func execute() throws {
        do {
            let cwd = FileManager.default.currentDirectoryPath
            let ymlPath = cwd+"/Hexavillefile.yml"
            if !FileManager.default.fileExists(atPath: ymlPath) {
                throw HexavilleError.couldNotFindManifestFile(ymlPath)
            }
            
            let deploymentStage = DeploymentStage(string: stage.value ?? "staging")
            let cloudProvider = try HexavillefileLoader(fromHexavillefilePath: ymlPath).load()
            
            let launcher = Launcher(
                provider: cloudProvider,
                hexavilleApplicationPath: cwd,
                executableTarget: "\(cwd)".components(separatedBy: "/").last ?? "",
                configuration: Configuration(),
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
    let target = Parameter()
    let hexavillefilePath = Key<String>("-c", "--hexavillefile", usage: "Path for the Hexavillefile.yml")
    let stage = Key<String>("--stage", usage: "Deployment Stage. default is staging")
    
    func execute() throws {
        do {
            var hexavileApplicationPath = FileManager.default.currentDirectoryPath
            if let hexavillefilePath = hexavillefilePath.value {
                var splited = hexavillefilePath.components(separatedBy: "/")
                let last = splited.removeLast()
                if last != "Hexavillefile.yml" {
                    throw HexavilleError.pathIsNotForHexavillefile(hexavillefilePath)
                }
                hexavileApplicationPath = splited.joined(separator: "/")
            }
            
            let deploymentStage = DeploymentStage(string: stage.value ?? "staging")
            let yml = try loadHexavilleFile(hexavilleFilePath: hexavileApplicationPath+"/Hexavillefile.yml")
            let cloudProvider = try HexavillefileLoader(fromYaml: yml).load()
            
            let launcher = Launcher(
                provider: cloudProvider,
                hexavilleApplicationPath: hexavileApplicationPath,
                executableTarget: target.value,
                configuration: Configuration(yml: yml),
                deploymentStage: deploymentStage
            )
            try launcher.launch()
        } catch {
            print(error)
            throw error
        }
    }
}


CLI.setup(name: "hexaville")
CLI.register(commands: [GenerateProject(), Deploy(), RoutesCommand()])
_ = CLI.go()
