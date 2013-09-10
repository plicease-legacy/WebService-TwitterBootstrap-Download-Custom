# WebService::TwitterBootstrap::Download::Custom [![Build Status](https://secure.travis-ci.org/plicease/WebService-TwitterBootstrap-Download-Custom.png)](http://travis-ci.org/plicease/WebService-TwitterBootstrap-Download-Custom)

Download a customized version of Twitter Bootstrap

# SYNOPSIS

    use WebService::TwitterBootstrap::Download::Custom;
    my $dl = WebService::TwitterBootstrap::Download::Custom->new;
    # ... adjust js, css, vars and img attributes appropriately ...
    $dl->fetch_defaults;
    my $zip = $dl->download;
    $zip->extract_all('/your/project/location');

# DESCRIPTION

This module allows you to create a custom Twitter Bootstrap and download
directly from the website without having to muck about with make files or
node.js.

The most common pattern is probably

1. fetch default values 

    Using the `fetch_defalts` method:

        use WebService::TwitterBootstrap::Download::Custom;
        my $dl = WebService::TwitterBootstrap::Download::Custom->new;
        $dl->fetch_defaults;

2. filter

    Remove any jQuery plugins or CSS components that you don't want.
    As an example here we are removing the tooltip component and the
    tab plugin.

        @{ $dl->css } = grep !/^tooltip\.less$/,     @{ $dl->css };
        @{ $dl->js  } = grep !/^bootstrap-tab\.js$/, @{ $dl->js };

3. modify variables

    Replace the values of any variables with new ones appropriate for your project

        $dl->vars->{'@altFontFamily'} = '@serifFontFamily';

4. download

    Fetch the custom bootstrap using the `download` method.

        my $zip = $dl->download;

5. extract

    Using the resulting instance of [WebService::TwitterBootstrap::Download::Custom::Zip](http://search.cpan.org/perldoc?WebService::TwitterBootstrap::Download::Custom::Zip),
    extract files using its `extract_all` method.

        $zip->extract_all('/your/project/location');

To visualize all of the defaults, it is probably worth looking at
[http://twitter.github.com/bootstrap/customize.html](http://twitter.github.com/bootstrap/customize.html), where the 
defaults are retrieved.

# ATTRIBUTES

## js

List reference containing the jQuery plugins to include in your
custom bootstrap.

## css

List reference containing the CSS components to include in your
custom bootstrap.

## vars

Hash table containing the variable/value pairs.

## img

List reference containing the images to include in your custom bootstrap.

## labels

Hash table containing human understandable labels for the CSS and jQuery
plugins.

## cache

Cache customizations of bootstrap.  That is, if you provide the same input
customization it will used a local cached copy instead of consulting the
website.  Cached copies are kept only for a set time and will be refreshed.

Set this to 0 (zero) to turn of caching.   Set to 1 (one) to use the default
location (somewhere in your home directory using [File::HomeDir](http://search.cpan.org/perldoc?File::HomeDir)).  Anything
else will be treated as a directory bath to find the cache.

This value gets converted and is used internally as a [Path::Class::Dir](http://search.cpan.org/perldoc?Path::Class::Dir).

# METHODS

## $dl->download

Download your custom bootstrap.  This will return an instance of
[WebService::TwitterBootstrap::Download::Custom::Zip](http://search.cpan.org/perldoc?WebService::TwitterBootstrap::Download::Custom::Zip), which can
be interrogated to retrieve the various files that make up your
custom bootstrap.  This method requires Internet access.

## $dl->fetch\_defaults

Fetch the default values for the `js`, `css`, `img` and `var` attributes, and
fill out the `labels` attribute.  This method requires Internet access.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
