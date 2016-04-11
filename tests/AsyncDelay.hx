#if neko
import neko.vm.Thread;
#elseif cs
import cs.system.timers.ElapsedEventHandler;
import cs.system.timers.ElapsedEventArgs;
import cs.system.timers.Timer;
#elseif java
import java.util.concurrent.FutureTask;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
#elseif cpp
import cpp.vm.Thread;
#elseif python
@:pythonImport("threading", "Timer")
extern class Timer {
	public function new(delayS : Float, callback : Void -> Void);
	public function start() : Void;
	public function cancel() : Void;
}
#else
import haxe.Timer;
#end

class AsyncDelay
{
	public static function delay(ms : Int, done : Void -> Void) : Void {
		#if (neko || cpp)
		Thread.create(function() {
			Sys.sleep(ms / 1000);
			done();
		});
		#elseif python
		new Timer(ms / 1000, done).start();
		#elseif (js || flash)
		Timer.delay(function() done(), ms);
		#elseif cs
		var t = new Timer(Math.max(ms, 1));
		t.add_Elapsed(new ElapsedEventHandler(function(sender : Dynamic, e : ElapsedEventArgs) {
			t.Stop(); t = null;
			done();
		}));
		t.Start();
		#elseif java
		var executor = Executors.newFixedThreadPool(1);
		var call = new AsyncCallable(function() {
			executor.shutdown(); executor = null;
			done();
		}, ms);
		executor.execute(new FutureTask(call));
		#elseif php
		Sys.sleep(ms / 1000);
		#else
		throw "AsyncDelay.delay not supported for current target.";
		#end
	}
}

#if java
private class AsyncCallable implements Callable<String>
{
	private var done : Void -> Void;
	private var waitMs : Int;

	public function new(done : Void -> Void, waitMs : Int)
	{
		this.done = done;
		this.waitMs = waitMs;
	}

	public function call() : String
	{
		Sys.sleep(waitMs / 1000);
		done();
		return "";
	}
}
#end