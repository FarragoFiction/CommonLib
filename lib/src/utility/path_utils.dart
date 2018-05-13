import 'dart:html';
import 'dart:math' as Math;
import 'package:CommonLib/src/logging/logger.dart';

abstract class PathUtils {
    static Logger logger = Logger.get("Path Utils", false);

    static Map<Uri, int> _pathdepth = <Uri, int>{};

    static int getSubDirectoryCount(Uri path) {
        String hereUrl = path.toString();
        int depth = _getDepthFromMeta(hereUrl);
        if (depth < 0) {
            logger.warn("Falling back to css path depth detection");
            depth = _getDepthFromCSS(hereUrl);
        }
        if (depth < 0) {
            logger.warn("Unable to determine relative path depth, assuming this page is on the relative root");
            return 0;
        }
        return depth;
    }

    static int _getDepthFromMeta(String hereUrl) {
        List<Element> meta = querySelectorAll("meta");
        for (Element e in meta) {
            if (e is MetaElement && e.name == "rootdepth") {
                logger.debug("is path meta: ${e.content}");
                return int.parse(e.content, onError: (String source) {
                    logger.warn("rootdepth meta element has invalid value (should be an int): ${e.content}");
                    return -1;
                });
            }
        }
        logger.warn("Didn't find rootdepth meta element");
        return -1;
    }

    static int _getDepthFromCSS(String hereUrl) {
        List<Element> links = querySelectorAll("link");
        for (Element e in links) {
            if (e is LinkElement && e.rel == "stylesheet") {
                logger.debug("is sheet: ${e.href}");
                int shorter = Math.min(hereUrl.length, e.href.length);
                for (int i=0; i<shorter; i++) {
                    if (!(hereUrl[i] == e.href[i])) {
                        String local = hereUrl.substring(i);
                        logger.debug("path: $local");
                        return local.split("/").length-1;
                    }
                    continue;
                }
            }
        }
        logger.warn("Didn't find a css link to derive relative path");
        return -1;
    }

    static String adjusted(String path) {
        return "${"../" * getPathDepth()}$path";
    }

    static int getPathDepth() {
        Uri path = Uri.base;
        if (!_pathdepth.containsKey(path)) {
            _pathdepth[path] = getSubDirectoryCount(path);
        }
        return _pathdepth[path];
    }
}
