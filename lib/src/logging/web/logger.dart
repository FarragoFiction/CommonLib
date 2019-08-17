import "dart:html";

import "../logger.dart";

/// Logger implementation, Web edition
class LoggerImpl extends Logger {

    LoggerImpl.create(String name, [bool debug = true]) : super.create(name, debug);

    @override
    LoggerPrintFunction getPrintForLevel(LogLevel level) {
        if (level == LogLevel.error) { return window.console.error; }
        if (level == LogLevel.warn) { return window.console.warn; }
        if (level == LogLevel.verbose) { return window.console.info; }
        return print;
    }
}