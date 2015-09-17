module raw.var.definition;

struct var(PrimaryT = int) {
private:
	TypeInfo currentType;
	static string genHolders() {
		string ret;
		foreach (type; SupportedTypes) {
			ret ~= type.stringof ~" "~ type.stringof ~"_;\n";
		}
		return ret;
	}
	union {
		mixin(genHolders);
	}
	import std.typetuple;
	alias SupportedTypes = TypeTuple!(int, double, string, bool);
public:
	void opAssign(T)(T value) {
		currentType = typeid(T);
		mixin(T.stringof ~ "_ = value;");
	}
	T get(T)() {
		import std.conv;
		// fast path for asking for the type that is currently held
		if (typeid(T) is currentType) {
			mixin("return "~ T.stringof ~"_;");
		}
		try {
			foreach (type; SupportedTypes) {
				if (currentType is typeid(type)) { // only ouput code for the type T
					//pragma(msg, "return to!T("~ type.stringof ~"_);");
					mixin("return to!T("~ type.stringof ~"_);");
				}
			}
		} catch (ConvException e) {
			return T.init;
		}
		assert(0, "unsupport type in get");
	}
	string toString() {
		import std.conv;
		foreach (type; SupportedTypes) {
			mixin("if (currentType is typeid("~ type.stringof ~")) return to!string("~ type.stringof ~"_);");
		}
		assert(0, "unsupport currentType");
	}

	T opCast(T)() { // seems there is only an opCast bool operator overload feature
		return get!T();
	}

	// Generate multiple alias this
	static string genAliasThis() {
		string ret;
		foreach (type; SupportedTypes) {
			// Until multiple alias this works we can make the var be a "default" type
			if (typeid(type) is typeid(PrimaryT)) {
				ret ~= "alias "~ type.stringof ~"_ this; // access as if this struct was the current type\n";
			}
		}
		return ret;
	}
	pragma(msg, genAliasThis());
	mixin(genAliasThis());
}

unittest {
	import std.stdio;
	auto v = var!()();
	v = 1234;
	assert(v.toString == "1234");
	assert(v.get!string == "1234");
	assert(v.get!double == 1234.0);
	writeln("v", v);
	if (v) { writeln("v okay");}
	int i = v;

	v = "hello";
	assert(v.get!string == "hello");
	import std.math : isNaN;
	assert(v.get!double.isNaN);
	writeln("v", v);

	v = 1234.3;
	assert(v.get!double == 1234.3);
	assert(v.get!int == 1234);

	writeln("v", v);

}