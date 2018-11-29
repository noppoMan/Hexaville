//
//  main.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/16.
//
//

import Foundation
import SwiftyJSON

public enum DeploymentStage {
    case staging
    case production
    case other(String)
    
    public init(string: String) {
        switch string {
        case DeploymentStage.staging.stringValue:
            self = .staging
        case DeploymentStage.production.stringValue:
            self = .production
        default:
            self = .other(string)
        }
    }
    
    public var stringValue: String {
        switch self {
        case .staging:
            return "staging"
        case .production:
            return "production"
        case .other(let stage):
            return stage
        }
    }
}

public enum LauncherError: Error {
    case swiftBuildFailed
    case cloudNotGenerateRoutingManifest
    case couldNotFindRootResource
    case missingRequiredParam(String)
}

public struct Routes {
    let endpoint: String
    let routes: [Route]
}

public struct Route {
    let method: [String]
    let resource: String
}

struct DeployResult {
    let endpoint: String
}

public class Launcher {
    
    let provider: CloudLauncherProvider
    
    let hexavilleApplicationPath: String
    
    let deploymentStage: DeploymentStage
    
    let configuration: HexavilleFile
    
    public init(hexavilleApplicationPath: String, configuration: HexavilleFile, deploymentStage: DeploymentStage = .staging, environment: [String: String] = [:]) {
        self.provider = configuration.createProvider(withEnvironment: environment)
        self.hexavilleApplicationPath = hexavilleApplicationPath
        self.configuration = configuration
        self.deploymentStage = deploymentStage
    }
    
    public func showRoutes() throws {
        switch provider {
        case .aws(let launcher):
            let routes = try launcher.routes(deploymentStage: deploymentStage)
            print("Endpoint: \(routes.endpoint)")
            print("Routes:")
            for route in routes.routes {
                for method in route.method {
                    print("  \(method)    \(route.resource)")
                }
            }
        }
    }
    
    public func launch(debug: Bool = false, shouldDiscardCache: Bool = false) throws {
        switch provider {
        case .aws(let provider):
            try launchFor(aws: provider)
        }
    }
    
    private func swiftExecutablePath() -> String {
        if let home = ProcessInfo.processInfo.environment["SWIFT_HOME"] {
            return "\(home)/usr/bin/swift"
        }
        return "swift"
    }
    
    private func buildSwift() throws -> BuildResult {
        let builder = SwiftBuilder(version: configuration.swift.version)
        return try builder.build(
            config: configuration,
            hexavilleApplicationPath: hexavilleApplicationPath,
            executable: configuration.executableTarget
        )
    }
    
    private func launchFor(aws provider: AWSLauncherProvider) throws {
        print("Start to build swift...")
        let result = try buildSwift()
        print("Build swift done.")
        
        let deployResult = try provider.deploy(
            deploymentStage: deploymentStage,
            buildResult: result,
            hexavilleApplicationPath: hexavilleApplicationPath,
            executable: configuration.executableTarget
        )
        
        print("######################################################")
        print("Information")
        print("")
        print("ApplicationName: \(provider.appName)")
        print("Endpoint: \(deployResult.endpoint)")
        print("Stage: \(deploymentStage.stringValue)")
        print("")
        print("######################################################")
        
        print("All Done.")
    }
}


extension HexavilleFile {
    func createProvider(withEnvironment environemnt: [String: String]) -> CloudLauncherProvider {
        switch provider {
        case .aws(let config):
            let provider = AWSLauncherProvider(
                appName: self.appName,
                credential: config.awsSDKSwiftCredential,
                region: config.awsSDKSwiftRegion,
                endpoints: nil,
                lambdaCodeConfig: config.lambda,
                environment: environemnt
            )
            return .aws(provider)
        }
    }
}
