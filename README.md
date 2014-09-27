troywarr.info
=============

## General Info

Troy Warr's personal website.

This repo contains all of the source code, build processes, and compiled output needed to generate `troywarr.info`.

## Technical Info

Source code is kept in the `master` branch, and served via GitHub Pages on the `gh-pages` branch. The `gh-pages` branch is a subtree push from `master`'s `dist/` folder, which contains the output of the Gulp processes (the content of the public website).

### Production Build

To run a production build:

```
  gulp --prod
```

This runs gulpfile.coffee's `default` task, which does the following:

 * cleans out the `dist/` folder
 * copies assorted files (e.g., CNAME, favicon, robots.txt) from `src/root/` into `dist/`
 * renders and copies HTML
 * compiles and concatenates styles
 * compiles and concatenates scripts

The gulp process then exits, leaving you with a clean production build.

### Dev Build & Watch

To run a dev build:

```
  gulp
```

In addition to the production steps listed above, this also:

 * opens the initial page (`dist/index.html`) in Chrome
 * watches files for changes, rebuilding as needed
 * starts BrowserSync to inject CSS changes or reload the browser as needed

### Deploy to GitHub Pages

After pushing to `master`, run the following:

```
  git subtree push --prefix dist origin gh-pages
```

Alias that to `ghpages` in `~/.bash_profile` for ease of use.

For more information and initial setup of this technique, see [instructions](http://www.damian.oquanta.info/posts/one-line-deployment-of-your-site-to-gh-pages.html) here.
