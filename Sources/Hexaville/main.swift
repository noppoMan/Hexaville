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
import HexavilleCore

enum HexavilleError: Error {
    case projectAlreadyCreated(String)
    case couldNotFindManifestFile(String)
    case pathIsNotForHexavillefile(String)
    case couldNotFoundTemplateIn([String])
}

class GenerateProject: Command {
    let name = "generate"
    let shortDescription  = "Generate initial project"
    let projectName = Parameter()
    let dest = Key<String>("-o", "--dest", usage: "Destination for the project")
    
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
    
    func findSwiftProjectTemplatePath() throws -> String {
        let manager = FileManager.default
        var templatesPathCandidates: [String] = [manager.currentDirectoryPath]
        do {
            let execPath = ProcessInfo.processInfo.arguments[0]
            let dest = try manager.destinationOfSymbolicLink(atPath: execPath)+"/../"
            templatesPathCandidates.append(dest)
        } catch {}
        
        for path in templatesPathCandidates {
            let tplPath = path+"/templates/SwiftProject"
            if manager.fileExists(atPath: tplPath) {
                return tplPath
            }
        }
        
        throw HexavilleError.couldNotFoundTemplateIn(templatesPathCandidates)
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
            
            try FileManager.default.copyFiles(from: "\(findSwiftProjectTemplatePath())", to: out)
            let hashId = hashids.encode(randomNumber)!
            
            let bucketName = createBucketName(from: projectName.value, hashId: hashId)
                
            try String(contentsOfFile: ymlPath, encoding: .utf8)
                .replacingOccurrences(of: "{{appName}}", with: projectName.value)
                .replacingOccurrences(of: "{{bucketName}}", with: bucketName)
                .write(toFile: ymlPath, atomically: true, encoding: .utf8)
            
            try String(contentsOfFile: packageSwiftPath, encoding: .utf8)
                .replacingOccurrences(of: "{{appName}}", with: projectName.value)
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
    let stage = Key<String>("--stage", usage: "Deployment Stage. default is staging")
    
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
                executableTarget: "\(cwd)".components(separatedBy: "/").last ?? "",
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
            
            var environment: [String: String] = [:]
            do {
                environment = try DotEnvParser.parse(fromFile: hexavileApplicationPath+"/.env")
            } catch {
                print(".env was not found")
            }
            
            let deploymentStage = DeploymentStage(string: stage.value ?? "staging")
            let yml = try loadHexavilleFile(hexavilleFilePath: hexavileApplicationPath+"/Hexavillefile.yml")
            let config = try HexavillefileLoader(fromYaml: yml).load(withEnvironment: environment)
            
            let launcher = Launcher(
                hexavilleApplicationPath: hexavileApplicationPath,
                executableTarget: target.value,
                configuration: config,
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
