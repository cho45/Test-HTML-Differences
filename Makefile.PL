use inc::Module::Install;
name 'Test-HTML-Differences';
all_from 'lib/Test/HTML/Differences.pm';

requires 'Exporter::Lite';

build_requires 'Test::Most';

# Module::Install::AuthorTests
author_tests('xt');

# Module::Install::Repository
auto_set_repository;

# Module::Install::TestBase
use_test_base;

# Module::Install::ReadmeFromPod
readme_from 'lib/Test/HTML/Differences.pm';

auto_include;
WriteAll;
