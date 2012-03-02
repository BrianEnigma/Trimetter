Gem::Specification.new { |s|
    s.name = 'trimetter'
    s.version = '1.0.0'
    s.date = '2012-03-01'
    s.summary = 'Trimet transit tracker API library'
    s.description = 'This gem wrappers the Portland, Oregon Trimet transit tracker API in some simple objects.  Note that a Trimet developer ID is required.  See http://developer.trimet.org for more information on developer IDs.'
    s.requirements = 'A Trimet developer ID, ether embedded in your app or in a dot-file in your home directory'
    s.author = 'Brian Enigma'
    s.email = 'brian@netninja.com'
    s.files = [
        'lib/trimetter.rb',
        'bin/trimetter',
    ]
    s.test_files = ['test/test_trimetter.rb']
    s.executables = [
        'trimetter',
    ]
    s.homepage = 'http://github.com/BrianEnigma/Trimetter'
}

