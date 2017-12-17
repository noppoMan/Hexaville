// This file is port of https://github.com/aciidb0mb3r/Spawn

import Foundation

#if os(OSX)
    import Darwin.C
#else
    import Glibc
#endif

public enum SpawnError: Error {
    case couldNotOpenPipe
    case couldNotSpawn
    case terminatedWithStatus(Int32)
}

public typealias OutputClosure = (String) -> Void

public final class Spawn {
    
    /// The arguments to be executed.
    let args: [String]
    
    /// Closure to be executed when there is
    /// some data on stdout/stderr streams.
    private var output: OutputClosure?
    
    /// The PID of the child process.
    private(set) var pid: pid_t = 0
    
    /// The TID of the thread which will read streams.
    #if os(OSX)
    private(set) var tid: pthread_t? = nil
    private var childFDActions: posix_spawn_file_actions_t? = nil
    #else
    private(set) var tid = pthread_t()
    private var childFDActions = posix_spawn_file_actions_t()
    #endif
    
    private let process = "/bin/sh"
    private var outputPipe: [Int32] = [-1, -1]
    
    public init(args: [String], environment: [String: String] = ProcessInfo.processInfo.environment ,  output: OutputClosure? = nil) throws {
        (self.args, self.output)  = (args, output)
        
        if pipe(&outputPipe) < 0 {
            throw SpawnError.couldNotOpenPipe
        }
        
        posix_spawn_file_actions_init(&childFDActions)
        posix_spawn_file_actions_adddup2(&childFDActions, outputPipe[1], 1)
        posix_spawn_file_actions_adddup2(&childFDActions, outputPipe[1], 2)
        posix_spawn_file_actions_addclose(&childFDActions, outputPipe[0])
        posix_spawn_file_actions_addclose(&childFDActions, outputPipe[1])
        
        let argv: [UnsafeMutablePointer<CChar>?] = args.map{ $0.withCString(strdup) }
        defer { for case let arg? in argv { free(arg) } }
        
        let envs = environment.map({ "\($0.key)=\($0.value)" })
        let envp: [UnsafeMutablePointer<CChar>?] = envs.map { $0.withCString(strdup) }
        
        if posix_spawn(&pid, argv[0], &childFDActions, nil, argv + [nil], envp + [nil]) < 0 {
            throw SpawnError.couldNotSpawn
        }
        watchStreams()
        
        var status: Int32 = 0
        #if os(Linux)
            pthread_join(tid, nil)
        #else
            if let tid = tid {
                pthread_join(tid, nil)
            }
        #endif
        
        waitpid(pid, &status, 0)
        if status != 0 {
            throw SpawnError.terminatedWithStatus(status)
        }
    }
    
    struct ThreadInfo {
        let outputPipe: UnsafeMutablePointer<Int32>
        let output: OutputClosure?
    }
    var threadInfo: ThreadInfo!
    
    func watchStreams() {
        threadInfo = ThreadInfo(outputPipe: &outputPipe, output: output)
        pthread_create(&tid, nil, { x in
            #if os(Linux)
            guard let x = x else { return nil }
            #endif
            let threadInfo = x.assumingMemoryBound(to: ThreadInfo.self).pointee
            let outputPipe = threadInfo.outputPipe
            close(outputPipe[1])
            let bufferSize: size_t = 1024 * 8
            let dynamicBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            while true {
                let amtRead = read(outputPipe[0], dynamicBuffer, bufferSize)
                if amtRead <= 0 { break }
                let array = Array(UnsafeBufferPointer(start: dynamicBuffer, count: amtRead))
                let tmp = array  + [UInt8(0)]
                tmp.withUnsafeBufferPointer { ptr in
                    let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                    threadInfo.output?(str)
                }
            }
            dynamicBuffer.deallocate(capacity: bufferSize)
            return nil
        }, &threadInfo)
    }
}
