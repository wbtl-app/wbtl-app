# Icon Guidelines for wbtl.app

This document describes the design rules for tool icons used across wbtl.app.

## Icon Style

All tool icons follow a consistent visual style for brand cohesion.

### SVG Properties

| Property | Value |
|----------|-------|
| Size | 28x28 px |
| ViewBox | 0 0 24 24 |
| Fill | none |
| Stroke | white |
| Stroke Width | 2.5 |
| Stroke Linecap | round |
| Stroke Linejoin | round |

### Base Template

```svg
<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <!-- icon paths here -->
</svg>
```

## Background

Each icon sits on a colored background with a gradient.

### Background Properties

| Property | Value |
|----------|-------|
| Size | 48x48 px |
| Border Radius | 12px |
| Background | linear-gradient(135deg, color1, color2) |

### CSS Example

```css
.tool-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.tool-icon.example {
  background: linear-gradient(135deg, #colorLight, #colorDark);
}
```

## Color Palette

Each tool gets a unique gradient. Use colors that relate to the tool's purpose.

| Tool | Light Color | Dark Color | Reasoning |
|------|-------------|------------|-----------|
| Timer | #ff6b6b | #ee5a5a | Red/warm suggests urgency, time |
| Soundcheck | #4ecdc4 | #44a3a0 | Teal/cool suggests audio waves |

### Suggested Colors for Future Tools

| Category | Light | Dark | Use For |
|----------|-------|------|---------|
| Blue | #5b9bd5 | #4a89c4 | Data, text, documents |
| Purple | #9b7bd4 | #8a6ac3 | Creative, random, fun |
| Orange | #f5a623 | #e49512 | Warnings, calculators |
| Green | #7ed321 | #6dc210 | Success, validation |
| Pink | #ff6b9d | #ee5a8c | Design, colors |
| Yellow | #f8d347 | #e7c236 | Notes, highlights |

## Design Principles

1. **Simple shapes** - Icons should be recognizable at small sizes
2. **Thick strokes** - 2.5 stroke width ensures visibility
3. **No fill** - Stroke-only design with white color
4. **Rounded corners** - Use round linecap and linejoin for friendly feel
5. **Centered** - Icons should be visually centered in the viewBox
6. **Consistent sizing** - All icons use 28x28 on 24x24 viewBox

## Icon Sources

Icons are inspired by [Feather Icons](https://feathericons.com/) style but customized with thicker strokes for better visibility on colored backgrounds.

## Adding a New Tool Icon

1. Find or create an SVG icon that represents the tool
2. Simplify to essential shapes only
3. Apply the base template properties
4. Choose a gradient that fits the tool's purpose
5. Add the CSS class for the background
6. Test visibility in both light and dark modes
