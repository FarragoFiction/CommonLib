import "dart:async";
import "dart:convert";

import "package:build/build.dart";
import "package:glob/glob.dart";
import "package:path/path.dart" as p;

class FileListBuilder extends Builder {
    static const String extension = ".filelist";
    late final List<Glob> exclusionPaths;
    final bool enabled;

    FileListBuilder({List<String>? exclude, bool this.enabled = false}) : super() {
        exclude ??= <String>[];
        exclusionPaths = exclude.map((String s) => new Glob(s)).toList();
    }

    @override
    Map<String, List<String>> get buildExtensions {
        return const <String,List<String>>{
            extension: <String>[".json"]
        };
    }

    @override
    FutureOr<void> build(BuildStep buildStep) async {
        if (!enabled) { return null; }

        final AssetId listFile = buildStep.inputId;

        final String directory = p.split(p.dirname(listFile.path)).join("/");

        final Glob dirGlob = new Glob("$directory/**");

        final Map<String,AssetId> files = <String,AssetId>{};

        // populate map with files, keyed by path relative to dataDir
        await for (final AssetId input in buildStep.findAssets(dirGlob)) {

            // skip filelist files and anything which matches our exclusion map
            if (p.extension(input.path) == extension) {
                continue;
            } else if (exclusionPaths.any((Glob path) => path.matches(input.path))) {
                continue;
            }

            final String rel = p.split(p.relative(input.path, from: directory)).join("/");

            files[rel] = input;
        }

        final AssetId output = listFile.changeExtension(".json");

        await buildStep.writeAsString(output, jsonEncode(<String,dynamic>{ "files": files.keys.toList() }) );
    }
}