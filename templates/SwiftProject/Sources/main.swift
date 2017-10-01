import Foundation
import HexavilleFramework

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


#if os(Linux)
let _urlSessionShared = URLSession(configuration: URLSessionConfiguration(), delegate: nil, delegateQueue: nil)
    extension URLSession {
        static var shared: URLSession {
            return _urlSessionShared
        }
    }
#endif

extension URLSession {
    func fetch(with url: URL) throws -> Data {
        let chan = Channel<(Error?, Data?)>.make(capacity: 1)
        
        let task = self.dataTask(with: url) { data, response, error in
            if let error = error {
                try! chan.send((error, nil))
                return
            }
            try! chan.send((nil, data))
        }
        
        task.resume()
        
        let (err, data) = try chan.receive()
        if let error = err {
            throw error
        }
        return data!
    }
}

let app = HexavilleFramework()

var router = Router()

app.use(RandomNumberGenerateMiddleware())

router.use(.get, "/") { request, context in
    let html = "<html><head><title>Hexaville</title></head><body>Welcome to Hexaville!</body></html>"
    return Response(headers: ["Content-Type": "text/html"], body: html)
}

router.use(.get, "/hello") { request, context in
    return try Response(headers: ["Content-Type": "application/json"], body: requestDetail(for: request))
}

router.use(.get, "/hello/:id") { request, context in
    return try Response(headers: ["Content-Type": "application/json"], body: requestDetail(for: request))
}

router.use(.post, "/hello/:id") { request, context in
    return try Response(status: .created, headers: ["Content-Type": "application/json"], body: requestDetail(for: request))
}

router.use(.get, "/random_img") { request, context in
    let data = try URLSession.shared.fetch(with: URL(string: "http://lorempixel.com/400/200/")!)
    return Response(headers: ["Content-Type": "image/png"], body: data.base64EncodedData())
}

app.use(router)

app.catch { error in
    print(error)
    return Response(status: .internalServerError, body: "\(error)".data)
}

try app.run()
