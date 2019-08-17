import "web/logger.dart"
    if (dart.library.io) "vm/logger.dart";

enum LogLevel {
    error,
    warn,
    info,
    verbose,
    debug
}

/// Template for methods which print stuff
typedef LoggerPrintFunction = void Function(Object arg);

abstract class Logger {
    /// Whether .verbose messages should be shown at all.
    static bool printVerbose = false;

    /// Whether this Logger should display .debug messages.
    /// Debug messages are never shown in compiled js.
    bool printDebug;

    /// Setting this to true disables the logger entirely, for when you want to suppress output.
    bool disabled = false;

    /// Section name displayed in output.
    final String name;

    /// Gets the right logger implementation for side
    factory Logger(String name, [bool debug = false]) {
        return new LoggerImpl.create(name, debug);
    }

    /// A simple logger for controlling console output.
    ///
    /// printDebug specifies whether this logger prints .debug messages.
    /// Debug messages are never printed in compiled js.
    Logger.create(String this.name, [bool this.printDebug = false]);

    /// Convenience method for getting a logger.
    factory Logger.get(String name, [bool debug = true]) {
        return new Logger(name, debug);
    }

    /// Pretties up the output
    String _format(LogLevel level, Object arg) {
        return "(${this.name})[${level.toString().split(".").last}]: $arg";
    }

    /// Gets the console method for a LogLevel
    LoggerPrintFunction getPrintForLevel(LogLevel level);

    /// Prefer one of the level specific methods
    void log(LogLevel level, Object arg) {
        if (disabled) { return; }
        getPrintForLevel(level)(_format(level, arg));
    }

    /// NOW YOU FUCKED UP
    void error(Object arg) {
        this.log(LogLevel.error, arg);
    }

    /// Yellow, for picking out mistakes
    void warn(Object arg) {
        this.log(LogLevel.warn, arg);
    }

    /// Normal output
    void info(Object arg) {
        this.log(LogLevel.info, arg);
    }

    /// For extra info not shown in some cases
    void verbose(Object arg) {
        if (printVerbose) {
            this.log(LogLevel.verbose, arg);
        }
    }

    /// For development
    void debug(Object arg) {
        if (this.printDebug) {
            this.log(LogLevel.debug, arg);
        }
    }
}