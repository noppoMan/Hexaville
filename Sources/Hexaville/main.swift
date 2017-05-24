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
            try FileManager.default.copyFiles(from: "\(projectRoot)/templates/SwiftProject", to: out)
            
            try String(contentsOfFile: ymlPath)
                .replacingOccurrences(of: "{{appName}}", with: projectName.value)
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

func loadProvider(config: Yaml) throws -> CloudLauncherProvider {
    guard let service = config["service"].string else {
        throw HexavilleError.missingRequiredParamInHexavillefile("service")
    }
    
    guard let appName = config["name"].string else {
        throw HexavilleError.missingRequiredParamInHexavillefile("name")
    }
    
    let cloudProvider: CloudLauncherProvider
    
    switch service {
    case "aws":
        var cred: Credential?
        
        if let accessKey = config["aws"]["credential"]["access_key_id"].string, let secretKey = config["aws"]["credential"]["secret_access_key"].string {
            cred = Credential(
                accessKeyId: accessKey,
                secretAccessKey: secretKey
            )
        }
        
        let lambdaCodeConfig = AWSLauncherProvider.LambdaCodeConfig(
            role: config["aws"]["lambda"]["role"].string ?? "",
            timeout: config["aws"]["lambda"]["timout"].int ?? 10
        )
        
        var region: Region?
        if let reg = config["aws"]["region"].string {
            region = Region(rawValue: reg)
        }
        
        let provider = AWSLauncherProvider(
            appName: appName,
            credential: cred,
            region: region,
            lambdaCodeConfig: lambdaCodeConfig
        )
        
        cloudProvider = .aws(provider)
        
    default:
        throw HexavilleError.unsupportedService(service)
    }

    return cloudProvider
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
            let yml = try loadHexavilleFile(hexavilleFilePath: ymlPath)
            let cloudProvider = try loadProvider(config: yml)
            
            let launcher = Launcher(
                provider: cloudProvider,
                hexavilleApplicationPath: cwd,
                executableTarget: "\(cwd)".components(separatedBy: "/").last ?? "",
                buildConfiguration: BuildConfiguration(),
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
            let cloudProvider = try loadProvider(config: yml)
            
            let launcher = Launcher(
                provider: cloudProvider,
                hexavilleApplicationPath: hexavileApplicationPath,
                executableTarget: target.value,
                buildConfiguration: BuildConfiguration(yml: yml),
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
