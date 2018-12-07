import Foundation
import Yams

public enum DecodingError: Error {
    case unresolvedKey
}

public struct HexavilleFile: Decodable {
    public let appName: String
    public let executableTarget: String
    public let provider: Provider
    public let docker: Docker?
    public let swift: Swift
    
    public static func load(ymlString: String) throws -> HexavilleFile {
        return try YAMLDecoder().decode(HexavilleFile.self, from: ymlString)
    }
}
