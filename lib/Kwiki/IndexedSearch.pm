package Kwiki::IndexedSearch;

use strict;
use warnings;
use Kwiki::Search '-Base';
use mixin 'Kwiki::Installer';

our $VERSION = sprintf "%d", q$Rev: 29 $ =~ m/(\d+)/;

const class_id => 'search_indexed';
const class_title => 'Indexed Search';

sub register {
    super;
    my $registry = shift;
    my %config = Kwiki::IndexedSearch::Config->new->all;

    foreach my $method (keys %{$config{methods}}) {
	$registry->add(wafl => $method => 'Kwiki::IndexedSearch::Wafl');
	$registry->add($self->class_id => 
		       $method => $config{methods}->{$method});
    }
    $registry->add($self->class_id => 
		   'result_template' => $config{result_template}); 
    $registry->add($self->class_id => 
		   'search_index' => $config{search_index}); 
}

sub perform_search {
    my $arg;
    if ($self->cgi->search_term) {
        $arg = $self->cgi->search_term;
    } else {
        $arg = shift;
    }
    my $settings = $self->hub->registry->lookup->{search_indexed};
    my $indexer = $settings->{search_index}[1];
    if ($self->hub->have_plugin($indexer)) {
        my $searcher = $self->hub->load_class($indexer);
	return  $searcher->perform_search($arg);
    } else {
        return [];
    }
}

package Kwiki::IndexedSearch::Wafl;
use base 'Spoon::Formatter::WaflPhrase';

sub html {
    my $arg = join(" ", $self->arguments);
    my $method = $self->method;
    my $settings = $self->hub->registry->lookup->{search_indexed};
    if ($self->hub->have_plugin($settings->{$method}[1])) {
	my $searcher = $self->hub->load_class($settings->{$method}[1]);
	my $pages = $searcher->perform_search($arg);
	return $self->hub->template->process($settings->{result_template}->[1],
					     pages => $pages);
    } else {
	return $self->wafl_error;
    }
}

package Kwiki::IndexedSearch::Config;
use Spoon::Config '-Base';
use YAML;

const class_id => 'indexedsearch_config';
const class_title => 'Indexed Search Configuration';
const config_file => 'config/search_indexed.yaml';

sub default_configs { $self->config_file }
sub default_config  { return { }; }
sub parse_yaml {
    my $yaml = shift;
    YAML::Load($yaml);
}

package Kwiki::IndexedSearch;

1;
__DATA__

=head1 NAME

Kwiki::IndexedSearch - Kwiki Plugin for searching a Kwiki

=head1 SYNOPSIS

kwiki -add Kwiki::IndexedSearch

=head1 DESCRIPTION

B<Kwiki::IndexedSearch> is a search plugin for Kwiki that inherits from
Brian Ingerson's B<Kwiki::Search> Plugin.

In addition to the features if B<Kwiki::Search>, B<Kwiki::IndexedSearch>
has the following features:

=over 4

=item Indexing

B<Kwiki::IndexedSearch> can use any loaded B<Kwiki::Indexer> plugins to
search the Kwiki.  By using indexed searches, search times can be dramatically
reduced on large Kwikis.

=item Inline searches

B<Kwiki::IndexedSearch> adds the ability to display the results of the
search inline on your page.

=back

=head1 CONFIGURATION

The following fields can be set in config/search_indexed.yaml

=over 4

=item search_index

 search_index: indexer_regex

The class_id of the indexer module to use.

=item result_template

 result_template: inline_results.html

The template to use to display results.

=item method

 methods:
  search: indexer_regex

The method parameter is a mapping of keywords to search classes.

The example specifies that the wafl keyword B<search> will search using the
B<perform_search> method of the class B<indexer_regex> (this is the 
B<Kwiki::Indexer::Regex> module that ships with the B<Kwiki::Indexer> module).

=back

=head1 EXAMPLES

Using {search:homepage} in your wiki code will result in the list of pages 
contain the phrase "homepage".

=head1 AUTHOR

Russell Heilling <chewtoy@s8n.net>

=head1 COPYRIGHT

Copyright (c) 2004. Russell Heilling. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__!config/search_indexed.yaml__
result_template: inline_results.html
search_index: indexer_regex
methods:
 search: indexer_regex
__template/tt2/inline_results.html__
<div class='inline_panel'>
[% IF pages.0 %]
[% FOR page = pages %]
<div class='inline_result'>[% page.kwiki_link %]</div>
[% END %]
[% ELSE %]
<div class='inline_result'>No Pages Found</div>
[% END %]
</div>
__template/tt2/search_indexed_content.html__
<!-- BEGIN search_content.html -->
<table class="search">
[% FOR page = pages %]
<tr>
<td class="page_id">[% page.kwiki_link %]</td>
<td class="edit_by">[% page.edit_by_link %]</td>
<td class="edit_time">[% page.edit_time %]</td>
</tr>
[% END %]
</table>
<!-- END search_content.html -->
__!template/tt2/search_box.html__
<!-- BEGIN search_box.html -->
<form method="post" action="[% script_name %]" enctype="application/x-www-form-urlencoded" style="display: inline">
<input type="text" name="search_term" size="8" value="Search" onfocus="this.value=''" />
<input type="hidden" name="action" value="search" />
</form>
<!-- END search_box.html -->

