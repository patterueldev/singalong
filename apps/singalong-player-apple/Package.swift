// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SingalongPlayer",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16)
    ],
    targets: [
        .target(
            name: "SingalongPlayer",
            dependencies: [],
            path: "SingalongPlayer",
            sources: [
                "App",
                "Models",
                "Services",
                "Views"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
