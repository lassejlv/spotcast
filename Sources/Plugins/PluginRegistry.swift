import Foundation
import SpotcastPluginKit

public enum PluginRegistry {
    public static let all: [any SpotcastPlugin] =
        QuickLinkPlugin.commands + [
            OpenURLPlugin(),
            NewFilePlugin(),
            EchoPlugin(),
        ]
}
