# SoundHop website

Static, single-page site for SoundHop. No build step, no JavaScript, no
external requests.

## Deploy

Upload the contents of this folder to:

```text
https://egemenbaki.com.tr/soundhop/
```

The canonical URL, Open Graph URL, JSON-LD URL and sitemap all assume that
path. If it changes, update those values in `index.html` and `sitemap.xml`.

Place `robots.txt` at the domain root (`https://egemenbaki.com.tr/robots.txt`).
If the portfolio already has one, add only the `Sitemap:` line instead of
replacing the file.

## App Store link

The download buttons are currently non-interactive “Coming soon on the Mac App
Store” badges because there is no listing yet. When the App Store page exists,
replace each placeholder span in `index.html` with:

```html
<a class="store-button" href="https://apps.apple.com/app/idXXXXXXXX" rel="noopener">
  …same icon and label…
</a>
```

Search for `APP STORE LINK` in `index.html`.

## Performance

The page is a single HTML document with inline CSS, no JavaScript and one
in-request image. Serve it gzipped or brotli-compressed over HTTPS. A reasonable
cache policy is:

- `index.html`: `Cache-Control: public, max-age=300, must-revalidate`
- images: `Cache-Control: public, max-age=31536000, immutable`

Initial transfer is roughly 30 KB on a 2x display (HTML + icon), excluding the
social preview image, which only crawlers download.

## SEO checklist

- Update the canonical/OG/sitemap URLs if the page path changes.
- After deploying, submit `https://egemenbaki.com.tr/soundhop/` in Google Search
  Console and request indexing.
- Test the Open Graph preview with the LinkedIn Post Inspector or Facebook
  Sharing Debugger.
- Keep the title under ~60 characters and the description under ~160
  characters when editing.
