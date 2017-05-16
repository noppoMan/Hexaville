//
//  VagrantBuildEnvironmentProvider.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/22.
//
//

import Foundation

//let copiedDirectoryName = "_hexaville_app"

//enum VagrantBuildEnvironmentProviderError: Error {
//    case projectRootPathIsInvalid
//    case swiftBuildFaild
//}

//struct VagrantBuildEnvironmentProvider: SwiftBuildEnvironmentProvider {
//    var swiftDownloadURL = "https://swift.org/builds/swift-3.1-release/ubuntu1404/swift-3.1-RELEASE/swift-3.1-RELEASE-ubuntu14.04.tar.gz"

//    let image = "ubuntu/trusty64"
//
//    let home = "/home/vagrant"
//
//    let vagrantExecutablePath: String
//
//    init(vagrantExecutablePath: String = "/usr/local/bin/vagrant") {
//        self.vagrantExecutablePath = vagrantExecutablePath
//    }
//
//    func vagrant(_ cmd: String, _ arguments: [String] = []) -> Proc {
//        var arguments = arguments
//        arguments.insert(cmd, at: 0)
//        return Proc(vagrantExecutablePath, arguments)
//    }
//
//    func vagrantRemote(_ cmd: String) -> Proc {
//        return Proc(vagrantExecutablePath, ["ssh", "-c", cmd])
//    }
//
//    func vagrantRemoteFileExists(path: String) ->  Bool{
//        print(path)
//        let proc = Proc(vagrantExecutablePath, ["ssh", "-c", "ls \(path)"])
//        return proc.terminationStatus == 0
//    }
//
//    /// build swift on ubuntu
//    func build(swiftDownloadURL: String, hexavilleApplicationPath: String) throws -> BuildResult {
//        let paths = swiftDownloadURL.components(separatedBy: "/")
//        let swiftZipFile = paths[paths.count-1]
//        let swiftFile = swiftZipFile.components(separatedBy: ".tar.gz")[0]
//
//        _ = vagrant("init \(image)")
//
//        print("Updating Vagrantfile...")
//        let vagrantfile = try String.init(contentsOfFile: projectRoot+"/templates/Vagrantfile", encoding: .utf8)
//
//        try vagrantfile.write(
//            toFile: hexavilleApplicationPath+"/Vagrantfile",
//            atomically: true,
//            encoding: .utf8
//        )
//
//        print("syncing files.......")
//        try copyFiles(to: hexavilleApplicationPath)
//
//        _ = vagrant("up")
//        _ = vagrant("reload")
//
//        _ = vagrantRemote("sudo apt-get update")
//        _ = vagrantRemote("sudo apt-get install -y clang libicu-dev uuid-dev git")
//
//        // Download swift
//        if !vagrantRemoteFileExists(path: home+"/"+swiftZipFile) {
//            _ = vagrantRemote("wget \(swiftDownloadURL)")
//        } else {
//            print("\(swiftZipFile) is already existed. Skip to download")
//        }
//
//        // Extract tar.gz
//        if !vagrantRemoteFileExists(path: home+"/"+swiftFile) {
//            _ = vagrantRemote("tar -zxf \(swiftZipFile)")
//        } else {
//            print("\(swiftFile) is already existed. Skip to extract")
//        }
//
//        let swift = "\(home)/\(swiftFile)/usr/bin/swift"
//
//        // Check swift version
//        _ = vagrantRemote("\(swift) --version")
//
//        // Build application
//        let buildResult = vagrantRemote("\(swift) build --chdir \(home)/hexaville_app")
//        if buildResult.terminationStatus != 0 {
//            throw VagrantBuildEnvironmentProviderError.swiftBuildFaild
//        }
//
//        return BuildResult(destination: hexavilleApplicationPath+"/"+copiedDirectoryName)
//    }
//}
