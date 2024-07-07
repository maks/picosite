const template = """
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-type" content="text/html;charset=UTF-8" />
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Source+Code+Pro&family=Source+Serif+Pro:ital,wght@0,300;0,400;0,600;1,400&display=swap" rel="stylesheet"> 
<style>
html {
  background: hsl(0, 0%, 90%);
}

body {
  max-width: 720px;
  margin: 0 auto;
  padding: 48px;

  font: normal 17px/24px 'Source Serif Pro', Georgia, serif;

  background: hsl(0, 0%, 100%);
  color: hsl(0, 0%, 20%);
}

code, pre {
  font-family: 'Source Code Pro', monospace;
  border-radius: 3px;
  background: hsl(0, 0%, 97%);
  color: hsl(0, 0%, 40%);
}

pre {
  padding: 12px;
  margin: -12px;

  font-size: 14px;
  line-height: 20px;
}

code {
  padding: 1px 4px;
}

pre code {
  padding: 0;
}

h1 {
  margin: 24px 0;
  font: normal 48px/48px 'Source Serif Pro', Georgia, serif;
}

h2 {
  margin: 48px 0 24px 0;
  font: bold 30px/48px 'Source Serif Pro', Georgia, serif;
}

h3 {
  margin: 48px 0 24px 0;
  font: italic 24px/24px 'Source Serif Pro', Georgia, serif;
}

p {
  margin: 24px 0;
}

li > p:first-child {
  margin-top: 0;
}

li > p:last-child {
  margin-bottom: 0;
}

li + li {
  margin-top: 12px;
}
</style>
<title>{{title}}</title>
</head>
<body>
{{header}}{{body}}
</body>
</html>
""";
