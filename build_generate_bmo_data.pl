#!/usr/bin/env perl
use 5.24.0;
use strict;
use warnings;

use JSON::MaybeXS;
use Data::Printer;
use File::Slurper qw(read_text);
use PPI;
use List::Util qw(any);
use Data::Dumper;

my $json       = JSON::MaybeXS->new(utf8 => 0, canonical => 1, pretty => 1);
my $modal_str  = read_text("modal.json");
my $config_str = read_text("configuration.json");
my $config     = $json->decode($config_str);
my $modal      = $json->decode($modal_str);
my $template   = PPI::Document->new($ARGV[0]);

my @keywords;
foreach my $keyword (@{ $modal->{keywords} }) {
    push @keywords, { name => $keyword, description => "description for $keyword" };
}

my @classifications;
foreach my $name (keys %{ $config->{classification} }) {
    my $desc = $config->{classification}{$name}{description};
    push @classifications, {
        name => $name,
        description => $desc,
    };
}

my @products;
foreach my $name ( keys %{ $config->{product} } ) {
    my $product = $config->{product}{$name};
    my @components;
    foreach my $component_name (keys %{ $product->{component} }) {
        my $watch_user = lc($component_name) . '@' . lc($name) . '.bugs';
        $watch_user =~ s/[^\w.\@-]+/-/ga;

        push @components, {
            name => $component_name,
            description => $product->{component}{$component_name}{description} || "DEFAULT DESCRIPTION OF COMPONENT",
            initialowner   => 'nobody@mozilla.org',
            initialqaowner => '',
            initial_cc     => [],
            watch_user     => $watch_user,
        };
    }

    push @products, {
        product_name       => $name,
        description        => $product->{description},
        classification     => $product->{classification},
        defaultmilestone   => $product->{default_target_milestone},
        versions           => $product->{version},
        milestones         => $product->{target_milestone},
        components         => \@components,
    };
}

my $vars = $template->find(
    sub {
        my ($self, $node) = @_;
        $node->isa('PPI::Statement::Variable') && $node->type eq 'my';
    }
);

my ($classifications_def, $keywords_def);

foreach my $var (@$vars) {
    if (any { $_ eq '@keywords' } $var->variables) {
        replace_variable($var, 'keywords', \@keywords);
    }
    elsif (any { $_ eq '@classifications' } $var->variables) {
        replace_variable($var, 'classifications', \@classifications);
    }
    elsif (any { $_ eq '@products' } $var->variables) {
        replace_variable($var, 'products', \@products);
    }
}

print $template->content;

sub new_watch_user  { undef }
sub new_triage_user { undef }

my @leak;
sub replace_variable {
    my ($node, $name, $new_value) = @_;
    warn "replace $name\n";
    my $new_variable = 'do { my ' . Data::Dumper->Dump([$new_value], ["*$name"]) . " } ";
    my $fragment     = PPI::Document::Fragment->new(\$new_variable);
    my $parent = $node->parent;
    $node->insert_after($fragment->find_first('PPI::Statement::Variable'));
    $node->delete;

    # we need to keep this alive...
    push @leak, $fragment;
}
