import Foundation
import HexavilleFramework
import Dispatch

func requestDetail(for request: Request) throws -> Data {
    var header: [String: String] = [:]
    request.headers.forEach { name, value in
        header[name] = value
    }
    let json: [String: Any] = [
        "path": request.path ?? "/",
        "params": request.params ?? [:],
        "header": header
    ]
    return try JSONSerialization.data(withJSONObject: json, options: [])
}


#if os(Linux)
let _urlSessionShared = URLSession(configuration: URLSessionConfiguration(), delegate: nil, delegateQueue: nil)
extension URLSession {
    static var shared: URLSession {
        return _urlSessionShared
    }
}
#endif

extension URLSession {
    func resumeSync(with url: URL) throws -> Data {
        let semaphore = DispatchSemaphore(value: 0)
        var error: Error?
        var data: Data?
        
        let task = self.dataTask(with: url) { _data, response, _error in
            error = _error
            data = _data
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        if let error = error {
            throw error
        }
        return data!
    }
}

let app = HexavilleFramework()

var router = Router()

app.use(RandomNumberGenerateMiddleware())

let sessionMiddleware = SessionMiddleware(
    cookieAttribute: CookieAttribute(
        expiration: 3600,
        httpOnly: true,
        secure: false,
        domain: nil,
        path: nil
    ),
    store: SessionMemoryStore()
)

app.use(sessionMiddleware)

router.use(.GET, "/") { request, context in
    let html = "<html><head><title>Hexaville</title></head><body>Welcome to Hexaville!</body></html>"
    return Response(headers: ["Content-Type": "text/html"], body: html)
}

router.use(.GET, "/hello") { request, context in
    return try Response(headers: ["Content-Type": "application/json"], body: requestDetail(for: request))
}

router.use(.GET, "/hello/{id}") { request, context in
    return try Response(headers: ["Content-Type": "application/json"], body: requestDetail(for: request))
}

router.use(.POST, "/hello/{id}") { request, context in
    return try Response(status: .created, headers: ["Content-Type": "application/json"], body: requestDetail(for: request))
}

router.use(.GET, "/random_img") { request, context in
    let data = try URLSession.shared.resumeSync(with: URL(string: "http://lorempixel.com/400/200/")!)
    return Response(headers: ["Content-Type": "image/png"], body: data.base64EncodedData())
}

app.use(router)

app.catch { error in
    print(error)
    return Response(status: .internalServerError, body: "\(error)".data)
}

try app.run()

