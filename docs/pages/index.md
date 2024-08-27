title: Picosite Documentation
template: standardpage
---

# Introduction

Welcome Picosite, a *minimalist* static site generator.


## Installation

Picosite is distributed as a single, stand along executables for [Linux, MacOS and Windows](https://github.com/maks/picosite/releases) to make it easy to use on your local computer and CI/CD systems.

If you prefer, you can also make use of it from an installed Dart SDK using: `dart pub global activate picosite`


## Usage

Picosite works by taking a set of markdown content files ("pages") in a given directory and transforming them into HTML and then inserting that HTML into a specified Handlebars template. The template applied to each page is specified in that markdown files YAML "frontmatter". Here is an example from Picosites own documentation index page (ie. the page you are reading now):

```markdown
title: Picosite Documentation
template: standardpage
---

# Introduction
```

The template file is expected to be named with a html extension (`standardpage.html`) and Picosite will look for it in the `templates` subdirectory of the site directory or the path specificed with the `templates` command line argument (`-t`).

Picosite can be run with no arguments given. In that case it will use default values for all the file system paths it requires to find the input files and also where it will write the output.

Asset files such as css, js, images, etc that just need to copied across to the output can be placed in the assets subdirectory of the site directory and all the contents of that directory will be recursively copied to the output directory each time picosite is run.

### Data file, builtin variables and Handlebars

TODO

## Credits

HTML and CSS template for these docs courtesy of [Carlos Yllobre](https://github.com/charlyllo/doctemplate)