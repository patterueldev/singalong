import Foundation

extension Foundation.Bundle {
    static let module: Bundle = {
        let mainPath = Bundle.main.bundleURL.appendingPathComponent("SingalongPlayer_SingalongPlayer.bundle").path
        let buildPath = "/Users/pat/Projects/PAT/singalong/apps/singalong-player-apple/.build/index-build/arm64-apple-macosx/debug/SingalongPlayer_SingalongPlayer.bundle"

        let preferredBundle = Bundle(path: mainPath)

        guard let bundle = preferredBundle ?? Bundle(path: buildPath) else {
            // Users can write a function called fatalError themselves, we should be resilient against that.
            Swift.fatalError("could not load resource bundle: from \(mainPath) or \(buildPath)")
        }

        return bundle
    }()
}