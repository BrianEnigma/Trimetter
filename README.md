#Overview

This library allows you to quickly and easily include [Trimet] -- the public
transit system of Portland, Oregon -- transit arrival information to your
application.  The information is obtained via REST commands from their
transit tracker site and returned to you as easy to use objects.  More 
information about the API is at [Trimet's developre site][TrimetDev].

[Trimet]: http://trimet.org/
[TrimetDev]: http://developer.trimet.org/

#Requirements

Any application that makes use of Trimet's API requires that developer to
register a developer key.  This allows them to better check who is using
the resources that they provide free to the public.  It also allows them
to squelch distributed denial of service (DDoS) attacks in case there's
a bug in an app that ends up hammering their servers.  

Having a general developer ID that is embedded in the library is a generally
bad idea, in that the actions of one developer could end up locking out all
other developers.  For this reason, you will need to ask for your own
developer key.

#Future Direction

- Other query types.  Currently this only hits the arrivals API, but there are geolocation APIs that look fun.
- Verify things other than buses.  I'm not sure if or how well this works with, for instance, Max trains.

