import "package:build/build.dart";
import "package:yaml/yaml.dart";

import "filelistbuilder.dart";

Builder fileListBuilder(BuilderOptions options) {
    return new FileListBuilder(
        exclude: ((options.config["exclude"] as YamlList?)?.whereType<String>().toList()) ?? <String>[],
        enabled: (options.config["enabled"] as bool?) ?? false,
    );
}

PostProcessBuilder fileListCleanupBuilder(BuilderOptions options) {
    return new FileDeletingBuilder(
        <String>[FileListBuilder.extension],
        isEnabled: (options.config["enabled"] as bool?) ?? false,
    );
}