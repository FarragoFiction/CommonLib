import "package:CommonLib/Logging.dart";

class JsonHandler {
    static Logger _logger = new Logger("JsonHandler");

    Map<String, dynamic> data;

    JsonHandler(Map<String, dynamic> this.data);

    T getValue<T>(String location, [T fallback = null]) {
        List<String> tags = location.split(".");
        dynamic object = data;

        for (int level = 0; level < tags.length; level++) {
            String tag = tags[level];

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
                int pos = int.parse(tag, onError: (String tag) => -1);
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
        // ignore: always_specify_types
        var value = this.getValue(location);

        if (value != null && value is List<dynamic>) {
            List<T> list = <T>[];

            // ignore: always_specify_types
            for (var item in value) {
                if (item is T) {
                    list.add(item);
                }
            }

            return list;
        }
        return null;
    }
}
