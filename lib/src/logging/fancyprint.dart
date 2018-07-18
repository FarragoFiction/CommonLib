import "dart:js";

void fancyPrint(Object message, String css) => context["console"].callMethod("log", <String>["%c$message", css]);