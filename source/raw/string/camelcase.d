module raw.string.camelcase;

import std.stdio;
import std.regex;

//enum re = ctRegex!(`([A-Z][a-z0-9]+)|([A-Za-z][A-Za-z0-9]+)_?|([a-z0-9]+[A-Z][a-z0-9]+)`);
enum re = ctRegex!(`[A-Z][^A-Z]*|[A-Za-z][^A-Z_]*`);

auto toCamelCase(string str)
out {
	assert(str !is null && str.length > 0);
}
body {
	import std.array;
	//import std.uni : asUpperCase;
	import std.ascii : isLower, toUpper; // NOTE: work around missing asUpperCase in gdc
	auto stringBuilder = appender!string;
	stringBuilder.reserve(str.length);

	if (__ctfe) {
		auto lastWasUnderScore = false;
		foreach (i, c; str) {
			// handle the word separators that we ignore
			if (c == '_' || c == ' ') {
				lastWasUnderScore = true;
				continue;
			}

			if (c.isLower) {
				if (lastWasUnderScore || i==0) {
					stringBuilder ~= c.toUpper;
				} else {
					stringBuilder ~= c;
				}
			} else {
				stringBuilder ~= c;
			}
			lastWasUnderScore = false;
		}
	} else {
		auto matches = matchAll(str, re);
		foreach (match; matches) {
			//stringBuilder ~= match[0][0..1].asUpperCase);
			stringBuilder ~= match[0][0].toUpper; // NOTE: work around missing asUpperCase in gdc
			stringBuilder ~= match[0][1..$];
			//writefln("done m:%s pre:%s post:%s hit:%s", match, match.pre, match.post, match.hit);
		}
	}
	auto data = stringBuilder.data;
	if (data !is null && data.length > 0) {
		return data;
	} else {
		return str; // just return original if we didn't add any characters
	}
}


bool test() {
	enum tests = [
		"test_this",
		"ThisTest",
		"testThis",
	];
	enum asserts = [
		"TestThis",
		"ThisTest",
		"TestThis"

	];
	foreach (i, str; tests) {
		//writeln("=======", str , "========");
		//writeln(i, asserts[i], "vs", toCamelCase(str));
		assert(toCamelCase(str) == asserts[i]);
	}
	return true;
}

// compile time unittests
unittest {
	enum passes = test();
}
// runtime unittests
unittest {
	test();
}
