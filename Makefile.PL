use inc::Module::Install;

name('Kwiki-IndexedSearch');
abstract('Kwiki Plugin to search a kwiki');
author('Russell Heilling <chewtoy@s8n.net');
version_from('lib/Kwiki/IndexedSearch.pm');
license('perl');

requires( qw(perl 5.6.0
             Kwiki 0.32
	     Kwiki::Search 0.11
	     Kwiki::Indexer 2
             YAML 0.35) );

&WriteAll;
