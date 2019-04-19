import "package:CommonLib/Logging.dart";

class JsonHandler {
    static final Logger _logger = new Logger("JsonHandler");

    Map<String, dynamic> data;

    JsonHandler(Map<String, dynamic> this.data);

    T getValue<T>(String location, [T fallback]) {
        final List<String> tags = location.split(".");
        dynamic object = data;

        for (int level = 0; level < tags.length; level++) {
            final String tag = tags[level];

            if (object is Map) {
                if (!object.containsKey(tag)) {
                    _logger.warn("Map ${tags.getRange(0, level).join(".")} does not contain key $tag, falling back.");
                    return fallback;
                }
                if (level == tags.length - 1) {
                    return object[tag];
                } else {
                    object = object[tag];
                }
            } else if (object is List) {
                final int pos = int.tryParse(tag) ?? -1;
                if (pos < 0 || pos >= object.length) {
                    _logger.warn("Attempted to index list ${tags.getRange(0, level).join(".")} with invalid int or out of range: $tag, falling back.");
                    return fallback;
                }
                if (level == tags.length - 1) {
                    return object[pos];
                } else {
                    object = object[pos];
                }
            } else {
                _logger.warn("Tag depth ${tags.length} exceeds object depth $level, falling back.");
                return fallback;
            }
        }

        return fallback;
    }

    List<T> getArray<T>(String location) {
        // ignore: always_specify_types, prefer_final_locals
        var value = this.getValue(location);

        if (value != null) {
            if (value is List<T>) {
                return value;
            } else if (value is List<dynamic>) {
                final List<T> list = <T>[];

                // ignore: always_specify_types
                for (final dynamic item in value) {
                    if (item is T) {
                        list.add(item);
                    }
                }

                return list;
            }
        }
        return null;
    }
}