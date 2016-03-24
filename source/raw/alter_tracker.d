module raw.alter_tracker;

private string wrapper(T)() {
	string ret;
	T tmp;
	foreach (item; __traits(derivedMembers, T)) {
		ret ~= typeof(__traits(getMember, tmp, item)).stringof ~" "~ item ~"("~ typeof(__traits(getMember, tmp, item)).stringof ~" value) { ob."~ item ~" = value; changes ~= "~ item.stringof ~"; return ob."~ item ~"; }\n";
		ret ~= typeof(__traits(getMember, tmp, item)).stringof ~" "~ item ~"() { return ob."~ item ~"; }\n";
	}
	return ret;
}

struct Alter(T) {
	T ob;
	static Alter opCall(T t) {
		Alter!T ret;
		ret.ob = t;
		return ret;
	}
	mixin(wrapper!T);
	string[] changes;
	alias ob this;
}
auto ResolveAlterations(Alter)(Alter alter) {
	import std.traits : moduleName, fullyQualifiedName;
	import std.variant;
	import std.algorithm : canFind;
	Variant[string] ret;
	mixin("import "~ moduleName!(typeof(alter.ob)) ~";");
	mixin("alias "~ fullyQualifiedName!(typeof(alter.ob)) ~" T;");
	T tmp = alter.ob;
	foreach (field; __traits(derivedMembers, T)) {
		if (alter.changes.canFind(field)) {
			ret[field] = __traits(getMember, tmp, field);
		}
	}
	return ret;
}

private:
struct B {
	float b;
}
struct A {
	string one;
	string two;
	int i;
	B b;
}
unittest {
	import std.stdio;

	enum ret = wrapper!A;
	pragma(msg, ret);
	A a = A("hello", "world");
	a.b.b = 1.2;
	auto test = Alter!(A)(a);
	test.one = "altered";
	writeln(test);
	test.b = B(4.2);
	writeln(test);
	writeln("alterations: ", test.changes);
	writeln("alterations: ", ResolveAlterations(test));
}
