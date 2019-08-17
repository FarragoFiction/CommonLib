import "../logger.dart";

/// Logger implementation, Web edition
class LoggerImpl extends Logger {

    LoggerImpl.create(String name, [bool debug = false]) : super.create(name, debug);

    @override
    LoggerPrintFunction getPrintForLevel(LogLevel level) {
        if (level == LogLevel.error) { return _error; }
        if (level == LogLevel.warn) { return _warn; }
        if (level == LogLevel.verbose) { return _info; }
        if (level == LogLevel.debug) { return _debug; }
        return print;
    }

    void _error(Object o) => print("[Error]: $o");
    void _warn(Object o)  => print("[Warning]: $o");
    void _info(Object o)  => print("[Info]: $o");
    void _debug(Object o) => print("[Debug]: $o");
}