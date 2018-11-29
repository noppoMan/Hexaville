//
//  Endpoints.swift
//  APIGateway
//
//  Created by Yuki Takei on 2018/11/30.
//

import Foundation

public struct AWSEndpoints {
    let s3Endpoint: String?
    let lambdaEndpoint: String?
    let apiGatewayEndpoint: String?
    
    init(s3Endpoint: String? = nil, lambdaEndpoint: String? = nil, apiGatewayEndpoint: String) {
        self.s3Endpoint = s3Endpoint
        self.lambdaEndpoint = lambdaEndpoint
        self.apiGatewayEndpoint = apiGatewayEndpoint
    }
}
