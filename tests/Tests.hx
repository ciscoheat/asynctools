import buddy.*;
using buddy.Should;
#if multithreaded
#if neko
import neko.vm.Mutex;
#elseif cpp
import cpp.vm.Mutex;
#elseif java
import java.vm.Mutex;
#end
#end

class Tests extends BuddySuite implements Buddy <[Tests]> implements Async
{	
	var running : Int;
	#if multithreaded
	var mutex : Mutex;
	#end
	
	function sleep(delayMs : Int, char : String, limit : Int, done : String -> String -> Void) : Void {
		#if multithreaded mutex.acquire(); #end
		running++;
		if (limit > 0 && running > limit) done("Exceeded limit: " + running, null);
		else if (delayMs == -1) done('Error: $char', null);
		else {
			#if multithreaded mutex.release(); #end		
			
			AsyncDelay.delay(delayMs, function() {
				#if multithreaded mutex.acquire(); #end
				running--;
				#if multithreaded mutex.release(); #end
				done(null, '#$char');
			});
		}
	}
	
    public function new() {
		//BuddySuite.useDefaultTrace = true;
		function asyncDone(err : String, newChars : Array<String>, done) {
			if (err != null) fail(err);
			else {
				newChars.should.containExactly(["#A", "#B", "#C", "#D", "#E", "#F", "#G", "#H"]);
				done();
			}
		}

		describe("AsyncTools", {
			#if multithreaded
			trace("--- Multithreaded ---");
			#end
			var chars = ["A", "B", "C", "D", "E", "F", "G", "H"];
			
			beforeEach({
				#if multithreaded mutex = new Mutex(); #end
				running = 0;
			});
			
			describe("AMapLimit", {
				it("should return an array in correct order, and not exceed its limit", function(done) {
					AsyncTools.aMapLimit(chars, 4, function(char, done) {
						var delay = switch char {
							case "A": 150;
							case "B": 1;
							case "C": 50;
							case "D": 100;
							case "E": 300;
							case "F": 10;
							case "G": 100;
							case "H": 50;
							case _: throw "Very error";
						}
						sleep(delay, char, 4, done);
					}, asyncDone.bind(_, _, done));						
				});
				
				@include it("should fail immediately if an error", function(done) {
					AsyncTools.aMapLimit(chars, 6, function(char, done) {
						var delay = switch char {
							case "A": 100;
							case "B": 1;
							case "C": -1;
							case _: 10;
						}
						sleep(delay, char, 3, done);
					}, function(err : String, newChars : Array<String>) {
						err.should.be("Error: C");
						done();
					});
				});
			});
			
			describe("AMap", {
				it("should return an array in correct order, with no speed limit.", function(done) {
					var err, newChars = @async(err => fail) AsyncTools.aMap(chars, function(char, done) {
						sleep(0, char, 0, done);
					});
					asyncDone(err, newChars, done);
				});
			});

			describe("AMapSeries", {
				it("should return an array in correct order, with 1 as limit.", function(done) {
					AsyncTools.aMapSeries(chars, function(char, done) {
						sleep(0, char, 1, done);
					}, asyncDone.bind(_, _, done));
				});
			});
			
			describe("AEach", {
				it("should loop through an array, with no limit.", function(done) {
					var output = [];
					AsyncTools.aEach(chars, function(char, done) {
						sleep(0, char, 0, function(err, char) {
							if (err != null) {
								fail(err);
							}
							else {
								output.push(char);
								done();
							}
						});
					},
					function(err : String) {
						if (err != null) fail(err);
						else {
							output.length.should.be(8);
							output.should.containAll(["#A", "#B", "#C", "#D", "#E", "#F", "#G", "#H"]);
							done();
						}
					});
				});
			});
			
			describe("AEachSeries", {
				it("should loop through an array, with 1 as limit.", function(done) {
					var output = [];
					AsyncTools.aEachSeries(chars, function(char, done) {
						sleep(0, char, 1, function(err, char) {
							if (err != null) {
								fail(err);
							}
							else {
								output.push(char);
								done();
							}
						});
					},
					function(err : String) {
						if (err != null) fail(err);
						else {
							output.length.should.be(8);
							output.should.containAll(["#A", "#B", "#C", "#D", "#E", "#F", "#G", "#H"]);
							done();
						}
					});
				});
			});

			describe("AFilterLimit", {
				it("should filter an array, with a limit.", function(done) {
					AsyncTools.aFilterLimit(chars, 6, function(char, done) {
						sleep(0, char, 6, function(err, char) {
							done(err, char == "#B");
						});
					},
					function(err : String, output : Array<String>) {
						if (err != null) fail(err);
						else {
							output.length.should.be(1);
							output.should.containExactly(["B"]);
							done();
						}
					});
				});
			});
		});
    }
}