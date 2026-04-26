import Foundation
import CoreLocation

struct Split: Identifiable {
    let id = UUID()
    let kmIndex: Int          // 1-based km marker
    let durationSeconds: Double
    let elevationGainMetres: Double

    var paceSecondsPerKm: Double { durationSeconds }
    var formattedPace: String {
        let total = Int(paceSecondsPerKm.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d/km", m, s)
    }
}

enum RunMetrics {
    /// Bucket the route into `count` evenly-distance-spaced pace samples (sec/km).
    static func paceBuckets(from locations: [CLLocation], count: Int = 32) -> [Double] {
        guard locations.count >= 2 else { return [] }

        // Cumulative distance & time arrays.
        var cumDist: [Double] = [0]
        var cumTime: [Double] = [0]
        for i in 1..<locations.count {
            let d = locations[i].distance(from: locations[i-1])
            let t = locations[i].timestamp.timeIntervalSince(locations[i-1].timestamp)
            cumDist.append(cumDist.last! + d)
            cumTime.append(cumTime.last! + max(t, 0))
        }
        let totalDist = cumDist.last ?? 0
        guard totalDist > 0, count > 0 else { return [] }

        let bucketSize = totalDist / Double(count)
        var result: [Double] = []
        result.reserveCapacity(count)

        for i in 0..<count {
            let dStart = Double(i) * bucketSize
            let dEnd = Double(i + 1) * bucketSize
            let tStart = interpolate(target: dStart, xs: cumDist, ys: cumTime)
            let tEnd = interpolate(target: dEnd, xs: cumDist, ys: cumTime)
            let dt = max(tEnd - tStart, 0.001)
            // sec / km
            let pace = dt / (bucketSize / 1000.0)
            result.append(pace)
        }
        return result
    }

    static func splits(from locations: [CLLocation]) -> [Split] {
        guard locations.count >= 2 else { return [] }
        var splits: [Split] = []
        var lastKmIndex = 0
        var lastTimestamp = locations.first!.timestamp
        var lastAltitude = locations.first!.altitude
        var elevAccum = 0.0
        var cumDist = 0.0

        for i in 1..<locations.count {
            cumDist += locations[i].distance(from: locations[i-1])
            let dAlt = locations[i].altitude - lastAltitude
            if dAlt > 0 { elevAccum += dAlt }
            lastAltitude = locations[i].altitude

            let kmCount = Int(cumDist / 1000.0)
            if kmCount > lastKmIndex {
                let kmIdx = kmCount
                let dt = locations[i].timestamp.timeIntervalSince(lastTimestamp)
                splits.append(Split(kmIndex: kmIdx, durationSeconds: dt, elevationGainMetres: elevAccum))
                lastKmIndex = kmIdx
                lastTimestamp = locations[i].timestamp
                elevAccum = 0
            }
        }
        return splits
    }

    /// Elevation in metres sampled along the route, normalised by index for plotting.
    static func elevationProfile(from locations: [CLLocation], count: Int = 64) -> [Double] {
        guard locations.count >= 2 else { return [] }
        let step = max(1, locations.count / count)
        return stride(from: 0, to: locations.count, by: step).map { locations[$0].altitude }
    }

    private static func interpolate(target: Double, xs: [Double], ys: [Double]) -> Double {
        guard !xs.isEmpty else { return 0 }
        if target <= xs.first! { return ys.first! }
        if target >= xs.last! { return ys.last! }
        // binary search would be nicer but linear is fine for hundreds of points
        for i in 1..<xs.count {
            if xs[i] >= target {
                let span = xs[i] - xs[i-1]
                if span <= 0 { return ys[i] }
                let frac = (target - xs[i-1]) / span
                return ys[i-1] + frac * (ys[i] - ys[i-1])
            }
        }
        return ys.last!
    }
}
