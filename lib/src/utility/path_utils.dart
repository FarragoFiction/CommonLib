import 'dart:html';
import 'dart:math' as Math;
import 'package:CommonLib/src/logging/logger.dart';

abstract class PathUtils {
    static const String _tagName = "rootdepth";
    static Logger logger = Logger.get("Path Utils", false);

    static final Map<Uri, int> _pathdepth = <Uri, int>{};

    static int getSubDirectoryCount(Uri path) {
        final String hereUrl = path.toString();
        int depth = _getDepthFromMeta(hereUrl);
        if (depth < 0) {
            logger.warn("Falling back to css path depth detection");
            logger.warn("To avoid this warning, include a meta tag named '$_tagName' with the number of levels removed from site root this page is as content.");
            depth = _getDepthFromCSS(hereUrl);
        }
        if (depth < 0) {
            logger.warn("Unable to determine relative path depth, assuming this page is on the relative root");
            return 0;
        }
        return depth;
    }

    static int _getDepthFromMeta(String hereUrl) {
        final List<Element> meta = querySelectorAll("meta");
        for (final Element e in meta) {
            if (e is MetaElement && e.name == _tagName) {
                logger.debug("is path meta: ${e.content}");
                try {
                    return int.parse(e.content);
                } on Exception {
                    logger.warn("$_tagName meta element has invalid value (should be an int): ${e.content}");
                    return -1;
                }
            }
        }
        logger.warn("Didn't find rootdepth meta element");
        return -1;
    }

    static int _getDepthFromCSS(String hereUrl) {
        final List<Element> links = querySelectorAll("link");
        for (final Element e in links) {
            if (e is LinkElement && e.rel == "stylesheet") {
                logger.debug("is sheet: ${e.href}");
                final int shorter = Math.min(hereUrl.length, e.href.length);
                for (int i=0; i<shorter; i++) {
                    if (!(hereUrl[i] == e.href[i])) {
                        final String local = hereUrl.substring(i);
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
        final Uri path = Uri.base;
        if (!_pathdepth.containsKey(path)) {
            _pathdepth[path] = getSubDirectoryCount(path);
        }
        return _pathdepth[path];
    }
}
