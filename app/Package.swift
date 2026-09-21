// swift-tools-version: 5.9
import PackageDescription

// TaskNxt — a free, local-only, native macOS menu bar to-do app.
//
// Split into two targets:
//  - TaskNxtCore: models, persistence, and all app state/business logic.
//    No SwiftUI dependency, so it builds and tests cleanly with any Swift
//    toolchain (verified in CI/sandboxes that lack a full, license-accepted
//    Xcode install).
//  - TaskNxt: the executable app — SwiftUI views, the menu bar shell
//    (AppDelegate/NSStatusItem/NSPopover), and the @main entry point.
//    Depends on TaskNxtCore.
//
// The Info.plist is embedded into the TaskNxt binary via linker flags so
// the app behaves as a proper menu-bar-only (LSUIElement) app when run
// directly. This structure can be imported into an .xcodeproj later
// without changes to the source layout.
let package = Package(
    name: "TaskNxt",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "TaskNxtCore",
            path: "Sources/TaskNxtCore"
        ),
        .executableTarget(
            name: "TaskNxt",
            dependencies: ["TaskNxtCore"],
            path: "Sources/TaskNxt",
            exclude: [
                "App/Info.plist",
                "App/TaskNxt.entitlements"
            ],
            resources: [
                .copy("../../Resources/Assets.xcassets")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/TaskNxt/App/Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "TaskNxtTests",
            dependencies: ["TaskNxtCore"],
            path: "Tests/TaskNxtTests"
        )
    ]
)
