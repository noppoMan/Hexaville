//
//  SwiftPMDumpPackage.swift
//  HexavillePackageDescription
//
//  Created by Yuki Takei on 2017/10/10.
//

import Foundation

public struct Product: Decodable {
    public let name: String
    public let productType: String
    public let targets: [String]
    
    public var isExecutable: Bool {
        return productType == "executable"
    }
    
    public var isLibrary: Bool {
        return productType == "library"
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case productType = "product_type"
        case targets
    }
}

public struct SwiftPMDumpPackage: Decodable {
    public let name: String
    public let products: [Product]
    
    public func findProduct(fromTargetName target: String) -> Product? {
        if let index = products.index(where: { $0.targets.contains(target) }) {
            return products[index]
        }
        return nil
    }
}
