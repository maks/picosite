# Picosite

## Welcome

This is Picosite, a *minimalist* static site generator.

## Usage

Picosite is published as a single, stand alone executable. You can get a copy of the latest version builds for Linux, MacOS and Windows from [the releases page](https://github.com/maks/picosite/releases).

The basic use of Picosite is to run it from the command line, passing in the path to a `site` directory, containing a `pages` subdirectory with markdown content files. The markdown files are expected to have YAML frontmatter which at the very minimum specifies a template file in [Handlebars](https://handlebarsjs.com/) format which will then cause Picosite to create output based on the content using the specified template file in the `output` directory.

For example if you run Picosite in the top level of this git repo using:
```
picosite -s doc

Positional arguments: []
site dir: doc includes dir: includes assets dir: assets templates:templates output:output
found input file: index.md
processing: index.md
YAML Front Matter:
title: Picosite Documentation
template: standardpage
finished processing:index
CWD:/home/maks/work/picosite
wrote output to: output
```

and then look in the created `output` directory, you will see the [documentation for Picosite](doc/) itself processed into html output. Looking in the `docs` folder serves as an example of how to use Picosite for your own content.


Run with the `-h` flag to get the traditional list of available options:

```
picosite -h
Usage: dart picosite.dart <flags> [arguments]
-s, --site         Directory containing site source files.
-i, --includes     Directory include (mustache partials) source files.
-a, --assets       Directory containing site asset (static) files.
-t, --templates    Directory containing Handlebars template files.
-o, --output       Directory with processed output files.
-p, --preview      Print this usage information.
-h, --help         Print this usage information.
-v, --verbose      Show additional command output.
    --version      Print the tool version.
```

## Acknowledgements

My thanks to @munificent for his [Markymark package](https://github.com/munificent/markymark), which was the starting point for Picosite.