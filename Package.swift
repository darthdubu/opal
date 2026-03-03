// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Opal",
    platforms: [.macOS(.v14)],
    products: [
        .executable(
            name: "Opal",
            targets: ["Opal"]
        ),
    ],
    dependencies: [
        .package(path: "../sunshine")
    ],
    targets: [
        .executableTarget(
            name: "Opal",
            dependencies: ["OpalCore", .product(name: "AutoUpdate", package: "sunshine")],
            path: "Sources/OpalNext"
        ),
        .target(
            name: "OpalCore",
            dependencies: ["Copal"],
            path: "Sources/OpalNextCore",
            linkerSettings: [
                .unsafeFlags([
                    "-L../target/release",
                    "-lopal_ffi",
                ])
            ]
        ),
        .systemLibrary(
            name: "Copal",
            path: "Sources/Copal"
        ),
    ]
)
