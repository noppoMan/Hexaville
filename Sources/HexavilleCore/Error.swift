//
//  Error.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/29.
//
//

import Foundation

enum HexavilleCoreError: Error {
    case missingRequiredParamInHexavillefile(String)
    case unsupportedService(String)
    case couldNotFindTemplate(in: [String])
}
