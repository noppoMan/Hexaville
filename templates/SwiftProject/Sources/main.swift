import Foundation
import HexavilleFramework

let app = HexavilleFramework()

let router = Router()

func requestDetail(for request: Request) throws -> Data {
    var header: [String: String] = [:]
    request.headers.forEach {
        header[$0.key.description] = $0.value
    }
    let json: [String: Any] = [
        "path": request.path ?? "/",
        "params": request.params ?? [:],
        "header": header
    ]
    return try JSONSerialization.data(withJSONObject: json, options: [])
}

app.use(RandomNumberGenerateMiddleware())

router.use(.get, "/") { request, context in
    let str = "<html><head><title>Hexaville</title></head><body>Welcome to Hexaville!</body></html>"
    return Response(headers: ["Content-Type": "text/html"], body: .buffer(str.data))
}

router.use(.get, "/hello") { request, context in
    return try Response(headers: ["Content-Type": "application/json"], body: .buffer(requestDetail(for: request)))
}

router.use(.get, "/hello/{id}") { request, context in
    return try Response(headers: ["Content-Type": "application/json"], body: .buffer(requestDetail(for: request)))
}

router.use(.post, "/hello/{id}") { request, context in
    return try Response(status: .created, headers: ["Content-Type": "application/json"], body: .buffer(requestDetail(for: request)))
}

app.use(router)

try app.run()
