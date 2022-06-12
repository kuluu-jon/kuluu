//
//  main.swift
//  noesis-scene-generator
//
//  Created by jon on 6/9/22.
//

import Foundation
import CollectionConcurrencyKit

@main
struct CLI {
    static func main() async throws {
        let args = CommandLine.arguments
        let fm = FileManager.default
        var path: String = fm.currentDirectoryPath
        print("original cwd", path)
        if let pathArgIndex = args.firstIndex(of: "-path") ?? args.firstIndex(of: "-p") {
            let pathIndex = pathArgIndex.advanced(by: 1)
            if args.indices.contains(pathIndex) {
                guard fm.changeCurrentDirectoryPath(args[pathIndex]) else {
                    fatalError("failed to change dir to dats")
                }
                path = args[pathIndex]
            }
        }
        print("cwd", fm.currentDirectoryPath)
        guard fm.fileExists(atPath: "Info/ZoneINFO.json") else {
            fatalError("no Info/ZoneINFO.json to parse")
        }
        guard let url = URL(string: "file://" + fm.currentDirectoryPath)?.appendingPathComponent("Info", isDirectory: true).appendingPathComponent("ZoneINFO.json") else {
            fatalError("no Info/ZoneINFO.json to parse")
        }
        do {
            let zoneInfoJsonData = try Data(contentsOf: url, options: [])
            let jsonDecoder = JSONDecoder()
            print("ZoneINFO.json data length: ", zoneInfoJsonData.count)
            
            let zoneInfo: ZoneInfoContainer = try jsonDecoder.decode(ZoneInfoContainer.self, from: zoneInfoJsonData)
            let zones = zoneInfo.zoneInfo
            print(zones)
            
            if let pathArgIndex = args.firstIndex(of: "-out") ?? args.firstIndex(of: "-o") {
                let pathIndex = pathArgIndex.advanced(by: 1)
                if args.indices.contains(pathIndex) {
                    guard fm.changeCurrentDirectoryPath(args[pathIndex]) else {
                        fatalError("failed to change dir to .noesis output path. does the directory exist?")
                    }
                }
            }
            
            let noesisZones = await zones
                .concurrentCompactMap { $0.noesisScene }
            
            await noesisZones.concurrentForEach { tuple in
                let (noesisScene, id) = tuple
                guard let data = noesisScene.data(using: .utf8) else {
                    fatalError()
                }
                guard let outUrl = URL(string: "file://" + fm.currentDirectoryPath)?.appendingPathComponent("\(id).noesis") else {
                    fatalError("could not create file for \(id).noesis")
                }
                do {
                    try data.write(to: outUrl)
                    print("wrote \(id).noesis")
                } catch {
                    fatalError(error.localizedDescription)
                }
            }
        } catch {
            fatalError("could not read ZoneINFO.json: \(error.localizedDescription)")
        }
    }
}
