//
//  PersistentFile.swift
//  RSSBud
//
//  Created by Cay Zhang on 2020/12/2.
//

import SwiftUI
import Combine

final class PersistentFile: ObservableObject {

    let url: URL
    let defaultContentURL: URL
    
    var fileHandle: FileHandle!
    var source: DispatchSourceFileSystemObject!

    var content: String {
        get { _content }
        set { try? newValue.write(to: url, atomically: true, encoding: .utf8) }
    }
    
    var contentPublisher: AnyPublisher<String, Never> {
        $_content.eraseToAnyPublisher()
    }
    
    @Published var _content: String = ""
    
    init(url: URL, defaultContentURL: URL) throws {
        print("Persistent file: \(url)")
        self.url = url
        self.defaultContentURL = defaultContentURL
        try buildSource()
        try read()
    }
    
    func restoreDefaultIfNeeded() throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            if !FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path) {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            }
            try FileManager.default.copyItem(at: defaultContentURL, to: url)
        }
    }
    
    func buildSource() throws {
        try restoreDefaultIfNeeded()
        
        self.fileHandle = try FileHandle(forReadingFrom: url)
        
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileHandle.fileDescriptor,
            eventMask: .all,
            queue: DispatchQueue.global(qos: .userInitiated)
        )

        source.setEventHandler { [unowned self] in
            let event = self.source.data
            try? self.process(event: event)
        }

        source.setCancelHandler { [fileHandle] in
            try? fileHandle?.close()
        }
        
        source.activate()
    }

    deinit {
        source?.cancel()
    }

    func process(event: DispatchSource.FileSystemEvent) throws {
        print("Received event: \(source.data)")
        
        if event.contains(.delete) || event.contains(.rename) {
            source.cancel()
            
            if FileManager.default.fileExists(atPath: url.path) {
                try self.buildSource()
                try self.read()
            } else {
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) {
                    try? self.buildSource()
                    try? self.read()
                }
            }
            
        } else {
            try read()
        }
    }
    
    func read() throws {
        try fileHandle.seek(toOffset: 0)
        if let content = try fileHandle.readToEnd().flatMap({ String(data: $0, encoding: .utf8) }) {
            print("Read content (fileHandle): " + content.lazy.split(separator: "\n").prefix(5).joined(separator: "\n"))
            _content = content
        } else {
            let content = try String(contentsOf: url, encoding: .utf8)
            print("Read content (String.init): " + content.lazy.split(separator: "\n").prefix(5).joined(separator: "\n"))
            _content = content
        }
    }
}
