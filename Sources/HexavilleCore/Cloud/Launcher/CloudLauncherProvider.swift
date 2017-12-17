//
//  CloudServiceProvider.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/17.
//
//

import Foundation

public enum CloudLauncherProvider {
    case aws(AWSLauncherProvider) //lambda+api-gateway
    
    var appName: String {
        switch self {
        case .aws(let provider):
            return provider.appName
        }
    }
}
