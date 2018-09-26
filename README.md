genstrings
----

Use this script to generate `Localized.strings` via an Xcode "run script" build phase.

----

Implement this somewhere in your code.

    extension String {
        func localize(_ comment: String? = nil) {
            return NSLocalizedString(self, comment: comment ?? "")
        }
    }

Then usage like this.

    var myString = "my identifier".localize()

– or with a comment.

    var myString = "my identifier".localize("my comment")

What's different between this and the repo I forked from?

Add this script as a "run script" phase directly into your Xcode project (or as a separate .sh file).

1)

Either as a separate, drop in `.swift` file that's called from the Run Script build phase like this:
![separate .swift script file][swiftscript]

[swiftscript]: https://i.imgur.com/TFFaGwFl.jpg "Separate Swift Script"

or

2)

As an inline script like this:

Make sure to change the "`//`" comment prefixes to script appropriate "`#`"

![inline script][inlinescript]

[inlinescript]: https://i.imgur.com/AslL0uol.jpg "Separate Swift Script"

Also, I'm putting the `Localizable.strings` output into the `SRCROOT` folder, so you'll need to add the file you want to write it to as an Run Script output file destination.

