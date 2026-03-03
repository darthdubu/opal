import Foundation

let opalVersion = "1.3.3"

func readBundledSeashellBuildVersion() -> String {
    guard let resourceURL = Bundle.main.resourceURL else {
        return "unavailable"
    }

    let buildFile = resourceURL.appendingPathComponent("SeashellBuild.txt")
    guard let text = try? String(contentsOf: buildFile, encoding: .utf8) else {
        return "unavailable"
    }

    for line in text.split(separator: "\n") {
        let parts = line.split(separator: "=", maxSplits: 1)
        if parts.count == 2 {
            return String(parts[1])
        }
    }

    return "unavailable"
}
