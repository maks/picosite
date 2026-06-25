# Picosite

## Welcome

This is Picosite, a *minimalist* static site generator.

## Usage

Picosite is published as a single, stand alone executable. You can get a copy of the latest version builds for Linux, MacOS and Windows from [the releases page](https://github.com/maks/picosite/releases).

_NOTE:_ The MacOS binary is for ARM system and users on MacOS will need to remove the quarantine on it with: xattr -d com.apple.quarantine /path/to/picosite  because its only adhoc signed.

The basic use of Picosite is to run it from the command line, passing in the path to a `site` directory, containing a `pages` subdirectory with markdown content files. The markdown files are expected to have YAML frontmatter which at the very minimum specifies a template file in [Handlebars](https://handlebarsjs.com/) format which will then cause Picosite to create output based on the content using the specified template file in the `output` directory.

For example if you run Picosite in the top level of this git repo using:

```
picosite -s doc -d

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
saved pdf: output.pdf
```

and then look in the created `output` directory, you will see the [documentation for Picosite](doc/) itself processed into html output. A basic PDF version of the content will also have been generated into `output.pdf`. 

Looking in the `docs` folder serves as an example of how to use Picosite for your own content.


### Preview mode

Picosite can be run to watch for content file changes and automatically rebuild the HTML or both HTML and PDF outputs, eg.
```
# Watch mode with HTML only (no PDF rebuild):
picosite -p -s . -o output -i includes -a assets -t templates -d pdfconfig.yaml -v                                                                                                                                                                                                                                                                    
# Watch mode WITH PDF rebuild on every change:
picosite -p -s . -o output -i includes -a assets -t templates -d pdfconfig.yaml --pdf-preview -v  
 ``` 

### PDF Output

PDF out is enabled using the `-d` command line parameter.

PDF output is configured by supplying a yaml configuration file as the value of the `-d` command line parameter.
Current supported options are:

```yaml
title: picoTracker User Manual
author: xiphonics

styles:
  code:
    # background color for code blocks
    background-color: 0x9999FF
  show-page-numbers-from: 1
  # path from inside assets dir
  ttf-font-path: fonts/Exo2-Regular.ttf
  pdf:
    # paragraph margin bottom (points)
    paragraph_margin_bottom: 10
    # list margin left (points)
    list_margin_left: 18
    # list margin bottom (points)
    list_margin_bottom: 10
    # h1 bottom margin (points)
    h1_margin_bottom: 12
    # h1 font size (points)
    h1_font_size: 22
    # h1 color (hex or int)
    h1_color: "#222222"
    # h1 font weight (normal|bold|400|700)
    h1_font_weight: bold

    # inline code styling (text only; no padding/border)
    inline_code_text_color: "#222222"
    inline_code_background_color: "#EEEEEE"
    inline_code_border_color: "#CCCCCC"
    inline_code_border_width: 1
    inline_code_padding: 2

    # inline class styles for spans like <span class="key">...</span>
    class_styles:
      key:
        text_color: "#222222"
        background_color: "#EEEEEE"
        border_color: "#CCCCCC"
        border_width: 1
        padding: 2

    # block class styles for elements like <div class="note">...</div>
    block_class_styles:
      note:
        text_color: "#222222"
        background_color: "#F9F9F9"
        border_color: "#CCCCCC"
        border_width: 1
        padding: 6
        margin: 6
        border_radius: 4
        font_size: 12
        font_weight: normal
        font_style: normal

# add table of contents page, insert it after given number of normal pages
tocPagePosition: 0
# list of files to include as multi-pages in the PDF, 
# added to the PDF in the order specificed
pages:
    - page1.md
    - page2.md

```

The template used is  `${template}_pdf.html` in the templates directory and **MUST** be present if PDF output is enabled. Thus if in this repo, the template specified in markdown documents is `page` then the expected name for to be used in PDF generation will be `page_pdf.html`.

#### PDF Styling Reference

All PDF styling lives under `styles:` in the pdf config file. The `pdf:` section is optional and lets you tune margins, headings, and inline styles used by the PDF renderer.

Supported keys:

- `styles.code.background-color`: Background color for code blocks.
- `styles.show-page-numbers-from`: Enable page numbers in the footer starting from this page number (1-based).
- `styles.ttf-font-path`: Path (relative to the assets directory) to a TTF font used as the default PDF font.
- `styles.pdf.paragraph_margin_bottom`: Space after paragraphs, in points.
- `styles.pdf.list_margin_left`: Left indent for lists, in points.
- `styles.pdf.list_margin_bottom`: Space after lists, in points.
- `styles.pdf.h1_margin_bottom`: Space after H1, in points.
- `styles.pdf.h1_font_size`: H1 font size in points.
- `styles.pdf.h1_color`: H1 text color (`#RRGGBB`, `#AARRGGBB`, or `0xAARRGGBB` int).
- `styles.pdf.h1_font_weight`: `normal` or `bold` (or numeric string like `400` / `700`).
- `styles.pdf.inline_code_text_color`: Inline code text color.
- `styles.pdf.inline_code_background_color`: Inline code background color.
- `styles.pdf.inline_code_border_color`: Inline code border color (currently not rendered for inline code).
- `styles.pdf.inline_code_border_width`: Inline code border width (currently not rendered for inline code).
- `styles.pdf.inline_code_padding`: Inline code padding (currently not rendered for inline code).
- `styles.pdf.class_styles`: Inline class styles for `<span class="...">` elements.
- `styles.pdf.block_class_styles`: Block class styles for elements like `<div class="...">`.

Notes:
- Inline code is rendered as plain text for correct baseline alignment. Background color is supported; borders and padding are currently ignored.
- Colors accept either hex strings (`#RRGGBB` / `#AARRGGBB`) or integer literals like `0xAARRGGBB`.

### Shortcodes

Picosite supports generic shortcodes to easily wrap markdown content inside reusable Handlebars/Mustache templates without writing raw HTML in your markdown files.

A shortcode is mapped directly to a template file in your `includes` (partials) directory. For example, a shortcode named `callout` will look for `includes/callout.html`.

You can use shortcodes in two ways:

**1. Multi-line Block:**
```markdown
{% callout type=note %}
This is a multi-line callout.
It can contain **markdown**!
{% endcallout %}
```

**2. Single-line Block:**
```markdown
{% callout type=warn | This is a single-line warning! %}
```

#### Shortcode Templates and Attributes

Attributes passed in the shortcode (e.g., `type=note`) are exposed as variables to the Mustache template, along with a special `{{{content}}}` variable containing the parsed HTML of the inner markdown.

To allow for conditional rendering in logic-less Mustache templates, Picosite automatically injects boolean flags for every string attribute. For example, passing `type=note` creates a boolean variable `is_type_note` set to `true`.

**Example `includes/callout.html` template:**
```html
<div class="callout callout-{{type}}">
  <table class="callout-table">
    <tr>
      <td class="callout-icon" width="40">
        {{#is_type_note}}
        <img src="image/pico-note.png" alt="Note" />
        {{/is_type_note}}
        {{#is_type_warn}}
        <img src="image/pico-warn.png" alt="Warning" />
        {{/is_type_warn}}
      </td>
      <td class="callout-text">
        {{#is_type_note}}<em>Note:</em>{{/is_type_note}}
        {{#is_type_warn}}<strong>Warning:</strong>{{/is_type_warn}}
        {{{content}}}
      </td>
    </tr>
  </table>
</div>
```

To style these blocks in PDF output, you can use `styles.pdf.block_class_styles` in your PDF configuration YAML:

```yaml
styles:
  pdf:
    block_class_styles:
      callout:
        background_color: "#F7F7F7"
        border_color: "#CCCCCC"
        border_width: 1
        padding: 6
        margin: 6
        border_radius: 4
      callout-note:
        border_color: "#4A90E2"
      callout-warn:
        border_color: "#D0021B"
      callout-text:
        font_size: 12
```




## Options

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
-d, --pdf          Generate a PDF using this config file.
-h, --help         Print this usage information.
-v, --verbose      Show additional command output.
    --version      Print the tool version.
```

## Acknowledgements

My thanks to @munificent for his [Markymark package](https://github.com/munificent/markymark), which was the starting point for Picosite.
```
