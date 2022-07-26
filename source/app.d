import std.stdio;
import cairo;

// Lindenmayer system demo

void main()
{
	import std.math : PI;
	/*
		The primary points of interaction with Cairo are Contexts and surfaces.

		Contexts are where one draws, writes, rotates etc.

		Surfaces are bassssicallly where one interacts with the outside world i.e. Input and Output.

		Below, `surf` defines a bitmap that we are going to paint our Context onto.

		The terminology is somewhat stupid in that "source" in the lexicon of the API can
		also be a sink.
	*/
	auto surf = new ImageSurface(Format.CAIRO_FORMAT_ARGB32, 1200, 1200);
	/*
	 	Above we prepared a surface to be written on,
		this is an example of surface we can read from.

		I haven't used it in this example but one draws a bitmap onto a context
		in cairo by setting the source to it then painting.
	*/
	auto lPng = ImageSurface.fromPng("USD.png");
	// Where the magic is going to happen
	auto context = Context(surf);
	// Arbitrary
	auto start = Point!double(128, 128);
	double angle1 = 60 * (PI / 180.0); /* angles are specified */

	// Save shoves the context onto a stack that can be restored later
	context.save();

	context.setSourceRGB(1.0, 1.0, 1.0);
	// Paint over the entire clip with the above colour (white)
	context.paint();
	// Pop off the aforementioned stack
	context.restore();

	context.save();
	context.moveTo(60, 60);
	context.setFontSize(50.0);
	context.textPath("Cairo demo: Koch curves");
	context.stroke();

	// Set colour but this time with an alpha parameter (rightmost, 0.9)
	context.setSourceRGBA(1, 0.2, 0.2, 0.9);
	// Does what it says on the tin.
	context.setLineWidth(1);

	/*
		This example is pinched from a book called the algorithmic beauty of plants.

		The book attempts to systematically construct ways to draw fractals and plants (Consider Romanesco broccoli - real nerds eat their
		fractals) using formal grammars, rewriting methods, and stochastic variations on those two.

		This specific example is called an L-system. We have a string of commands:

		The alphabet in this examples is as follows:

			F: Move forward some distance

			+: Rotate by an angle x

			-: Rotate by an angle -x

		By specifying "rewriting" rules we can substitute patterns in an input string to a new output string.

		The example below is for generating Koch curves, we start with a straight line "F" then simply do the substitution
		F -> F+F--F+F

		This is specified in the associative array (dictionary/hashmap in the terminologies of other languages) `map` given below.
	*/
	auto map = [
		'F': "F+F--F+F",
		'+': "+",
		'-': "-"
	];
	// Preemptively set font sizes
	context.setFontSize(12.0);
	string tmp = "F";
	foreach(i; 0..5)
	{
		context.moveTo(start);
		// Draw them one below the other
		context.relMoveTo(0.0, i * 100.0);
		string saveOld = tmp;
		tmp = iterateLSystem(tmp, map);
		import std.math;
		drawLCommands(context, tmp, 70.0 / exp(cast(float) i) /* scale lengths a bit */, angle1);

		context.relMoveTo(50.0, 0.0);

		context.textPath(saveOld);
	}
	// Draw/commit the stuff to surface
	context.stroke();
	// context.setAntiAlias(AntiAlias.CAIRO_ANTIALIAS_SUBPIXEL);
	surf.writeToPNG("example.png");

}

void drawLCommands(Context con, string pattern, double length, double angle)
{
	foreach (c; pattern)
	{
		switch (c)
		{
			case 'F':
				con.relLineTo(length, 0.0);
				break;
			case '+':
				con.rotate(-angle);
				break;
			case '-':
				con.rotate(angle);
				break;
			default:
				assert(0, "Invalid character " ~ pattern);
		}
	}
}
// Character-by-character iteration of an input string L-system subject to map
string iterateLSystem(string pattern, string[char] map)
{
	string output;
	foreach(c; pattern)
	{
		auto key = c in map;
		output ~= (key ? *key : [c]);
	}
	return output;
}