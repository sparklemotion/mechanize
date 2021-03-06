# Mechanize [<img src="https://secure.travis-ci.org/sparklemotion/mechanize.svg?rvm=2.3.3" />](http://travis-ci.org/sparklemotion/mechanize)

*   http://docs.seattlerb.org/mechanize
*   https://github.com/sparklemotion/mechanize


## Description

The Mechanize library is used for automating interaction with websites.
Mechanize automatically stores and sends cookies, follows redirects, and can
follow links and submit forms.  Form fields can be populated and submitted. 
Mechanize also keeps track of the sites that you have visited as a history.

## Dependencies

*   ruby 2.5 or newer
*   [nokogiri](https://github.com/sparklemotion/nokogiri)


## Support:

The bug tracker is available here:

*   https://github.com/sparklemotion/mechanize/issues


## Examples

If you are just starting, check out the
[GUIDE](http://docs.seattlerb.org/mechanize/GUIDE_rdoc.html) or the
[EXAMPLES](http://docs.seattlerb.org/mechanize/EXAMPLES_rdoc.html) file.

## Developers

Use bundler to install dependencies:

    bundle install

Run all tests with:

    rake test

You can also use `autotest` from the ZenTest gem to run tests.

See also Mechanize::TestCase to read about the built-in testing
infrastructure.

## Authors

Copyright (c) 2005 by Michael Neumann (mneumann@ntecs.de)

Copyright (c) 2006-2011:

*   [Aaron Patterson](http://tenderlovemaking.com) (aaron.patterson@gmail.com)
*   [Mike Dalessio](http://mike.daless.io) (mike@csa.net)


Copyright (c) 2011-2015:

*   [Eric Hodel](http://blog.segment7.net) (drbrain@segment7.net)
*   [Akinori MUSHA](http://blog.akinori.org) (knu@idaemons.org)
*   [Lee Jarvis](http://twitter.com/lee_jarvis) (ljjarvis@gmail.com)


This library comes with a shameless plug for employing me
([Aaron](http://tenderlovemaking.com/)) programming Ruby, my favorite
language!

## Acknowledgments

This library was heavily influenced by its namesake in the Perl world.  A big
thanks goes to [Andy Lester](http://petdance.com), the author of the original
Perl module WWW::Mechanize which is available
[here](http://search.cpan.org/dist/WWW-Mechanize/).  Ruby Mechanize would not
be around without you!

Thank you to Michael Neumann for starting the Ruby version.  Thanks to
everyone who's helped out in various ways.  Finally, thank you to the people
using this library!

## License

This library is distributed under the MIT license.  Please see the
[LICENSE](http://docs.seattlerb.org/mechanize/LICENSE_rdoc.html) file.

