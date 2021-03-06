/**
  A logger module which logs both in a terminal and in a file (unix tee)

	Authors: Fr3nchK1ss on github
	Copyright: public domain
 */

module dterrent.system.logger.teelogger;

public import std.experimental.logger; //to use global sharedLog
import dterrent.system.logger.consolelogger;

/**
  A simple logger to write simultaneously into a console and a file.

  The most important class of the engine!
 */
class DtrtLogger : MultiLogger
{
  ///
  this(LogLevel lv = LogLevel.all)
  {
    super(lv);
    insertLogger("console", new ConsoleLogger());
    insertLogger("file", new FileLogger(logFile, lv));
  }

private:
  immutable string logFile = "dterrent.log";

}
