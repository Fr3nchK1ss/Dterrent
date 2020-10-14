/**
	Authors: ludo456 on github
	Copyright: proprietary / contact dev

 */
 
module dterrent.system.logger;

import std.experimental.logger;
import dterrent.system.consolelogger;


/**
  A simple logger to write simultaneously into a console and a file.

  The most important class of the engine!
 */
class DtrtLogger : MultiLogger
{

    this(LogLevel lv = LogLevel.all)
    {
      super(lv);
      insertLogger("console", new ConsoleLogger());
      insertLogger("file", new FileLogger(logFile, lv));
    }

private:
    immutable string logFile = "dterrent.log";

}
