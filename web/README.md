# SoundHop website

Static, single-page site for SoundHop. No build step in this folder, no
JavaScript, no external requests.

## Deploy

The page lives in the portfolio site at:

```text
https://egemenbaki.com.tr/soundhop
```

The integrated copy is served from `public/soundhop/` through a rewrite in the
portfolio's `next.config.ts`. If you deploy the `web/` folder separately,
upload its contents to a `/soundhop/` directory and keep the URL layout the
same.

Update the canonical, Open Graph, JSON-LD and sitemap URLs if the path changes.

## Download link

The download buttons point to the latest GitHub release asset:

```text
https://github.com/EgemenBaki/SoundHop/releases/latest/download/SoundHop.dmg
```

Keep the release asset name exactly `SoundHop.dmg`. The link automatically
resolves to the latest release.

Release instructions live in the SoundHop repository at
`RELEASING.md`.

## Installation note

The release is ad-hoc signed and not notarized by Apple. On first launch macOS
may ask the user to approve it in **System Settings → Privacy & Security**. The
page should not imply that the app is notarized or approved by Apple.

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
- After deploying, submit the page in Google Search Console and request
  indexing.
- Test the Open Graph preview with the LinkedIn Post Inspector or Facebook
  Sharing Debugger.
- Keep the title under about 60 characters and the description under about 160
  characters when editing.
