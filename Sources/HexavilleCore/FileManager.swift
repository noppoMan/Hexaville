//
//  FileManager.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/19.
//
//

import Foundation

enum FileManagerError: Error {
    case couldNotMakeDirectory(String)
}

extension FileManager {
    public func copyFiles(from: String, to dest: String, excludes: [String] = []) throws {
        guard let enumerator = FileManager.default.enumerator(atPath: from) else { return }
        let r = Process.exec("mkdir", ["-p", dest])
        if r.terminationStatus != 0 {
            throw FileManagerError.couldNotMakeDirectory(dest)
        }

        for item in enumerator {
            guard let item = item as? String else { continue }

            let fullTargetPath = from+"/"+item
            let attributes = try FileManager.default.attributesOfItem(atPath: fullTargetPath)

            if let fileType = attributes[FileAttributeKey.type] as? Foundation.FileAttributeType {
                let fullDestinationPath = dest+"/"+item
                switch fileType {
                case FileAttributeType.typeDirectory:
                    _ = try FileManager.default.createDirectory(
                        atPath: fullDestinationPath,
                        withIntermediateDirectories: true,
                        attributes: [:]
                    )
                    print("created \(fullDestinationPath)")

                case FileAttributeType.typeRegular:
                    try Data(contentsOf: URL(string: "file://\(fullTargetPath)")!)
                        .write(to: URL(string: "file://\(fullDestinationPath)")!)
                    print("created \(fullDestinationPath)")
                    
                default:
                    break
                }
            }
        }
    }
}
