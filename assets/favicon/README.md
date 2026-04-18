# Favicon Package

This directory contains the favicon assets for sidewayz8solutions.com.

## Files to Generate

Use the source `favicon.svg` to generate the following formats:

### Browser Favicons
- `favicon-16x16.png` - Standard browser favicon
- `favicon-32x32.png` - Retina display favicon
- `favicon-48x48.png` - Windows taskbar

### Apple Touch Icons
- `apple-touch-icon.png` (180x180) - iOS home screen
- `apple-touch-icon-152x152.png` - iPad
- `apple-touch-icon-120x120.png` - iPhone

### Android/Chrome
- `android-chrome-192x192.png` - Android home screen
- `android-chrome-512x512.png` - Android splash screen

### Microsoft
- `mstile-150x150.png` - Windows 8/10 tiles
- `browserconfig.xml` - Microsoft tile configuration

## Generation Script

```bash
# Using ImageMagick
for size in 16 32 48 152 180 192 512; do
  convert favicon.svg -resize ${size}x${size} favicon-${size}x${size}.png
done

# Or using Inkscape (higher quality)
for size in 16 32 48 152 180 192 512; do
  inkscape favicon.svg --export-filename=favicon-${size}x${size}.png --export-width=$size --export-height=$size
done
```

## HTML Head Tags

```html
<!-- Standard favicon -->
<link rel="icon" type="image/svg+xml" href="/assets/favicon.svg">
<link rel="icon" type="image/png" sizes="32x32" href="/assets/favicon-32x32.png">
<link rel="icon" type="image/png" sizes="16x16" href="/assets/favicon-16x16.png">

<!-- Apple Touch Icon -->
<link rel="apple-touch-icon" sizes="180x180" href="/assets/apple-touch-icon.png">

<!-- Android/Chrome -->
<link rel="manifest" href="/site.webmanifest">

<!-- Safari Pinned Tab -->
<link rel="mask-icon" href="/assets/safari-pinned-tab.svg" color="#6366f1">

<!-- MS Tile Color -->
<meta name="msapplication-TileColor" content="#0a0a0a">
<meta name="theme-color" content="#0a0a0a">
```

## Web App Manifest

Create `site.webmanifest`:

```json
{
  "name": "Sidewayz8Solutions",
  "short_name": "S8S",
  "icons": [
    {
      "src": "/assets/android-chrome-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/assets/android-chrome-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ],
  "theme_color": "#0a0a0a",
  "background_color": "#0a0a0a",
  "display": "standalone"
}
```
