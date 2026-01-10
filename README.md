# wbtl.app

A collection of useful tools that run entirely in your browser. No server needed, no tracking, free forever.

## Philosophy

- **100% Local** - All tools run entirely in your browser
- **No Tracking** - No analytics, no cookies, no data collection
- **No Ads** - Clean, distraction-free interfaces
- **Free Forever** - No subscriptions, no paywalls

## Website

The main landing page lives in `dist/index.html`. It's a single static HTML file with everything inlined (no external CSS, JS, or assets).

### Adding a New Tool

Edit `dist/index.html` and add a new card in the `tools-grid` section:

```html
<a href="https://newtool.wbtl.app" class="tool-card">
  <div class="tool-header">
    <div class="tool-icon newtool">EMOJI</div>
    <div>
      <div class="tool-name">Tool Name</div>
      <div class="tool-url">newtool.wbtl.app</div>
    </div>
  </div>
  <p class="tool-description">Description of what the tool does.</p>
</a>
```

Add a corresponding CSS class for the icon gradient:

```css
.tool-icon.newtool {
  background: linear-gradient(135deg, #color1, #color2);
}
```

## Contributing

Want a new tool or have an improvement for an existing one?

- **Request a tool**: [Open an issue](https://github.com/wbtl-app/wbtl-app/issues/new)
- **Contribute**: Pull requests are welcome

## License

MIT
