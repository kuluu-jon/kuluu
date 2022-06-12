//
//  SCNGeometry+Vertices.swift
//  kuluu
//
//  Created by jon on 6/10/22.
//

import SceneKit

extension SCNGeometry {

    /**
     Get the vertices (3d points coordinates) of the geometry.
     
     - returns: An array of SCNVector3 containing the vertices of the geometry.
     */
    func vertices() -> [SCNVector3]? {

        let sources = self.sources(for: .vertex)

        guard let source  = sources.first else {return nil}

        let stride = source.dataStride / source.bytesPerComponent
        let offset = source.dataOffset / source.bytesPerComponent
        let vectorCount = source.vectorCount

        return source.data.withUnsafeBytes { dataBytes in
            let buffer: UnsafePointer<Float> = dataBytes.baseAddress!.assumingMemoryBound(to: Float.self)
            var result = [SCNVector3]()
            for i in 0...vectorCount - 1 {
                let start = i * stride + offset
                let x = buffer[start]
                let y = buffer[start + 1]
                let z = buffer[start + 2]
                result.append(SCNVector3(x, y, z))
            }
            return result

        }

    }
}
