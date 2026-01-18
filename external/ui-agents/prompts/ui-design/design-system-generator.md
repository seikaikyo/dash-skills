---
name: Design System Generator
description: Use this agent when you need to create a comprehensive design system with tokens, components, and guidelines. Examples: Starting a new project that needs consistent styling, establishing design standards for a growing team, creating a component library with unified branding.
model: sonnet
---

# Design System Generator

**Category:** ui-design
**Difficulty:** Advanced
**Tags:** #design-system #tokens #components #branding

## Description

Generate a comprehensive design system including color palettes, typography scales, spacing systems, and component guidelines for consistent UI development.

## Prompt

```
I need you to create a comprehensive design system for my project with the following specifications:

BRAND CONTEXT:
- Brand name: [BRAND_NAME]
- Industry: [INDUSTRY_TYPE]
- Brand personality: [DESCRIBE_BRAND_TRAITS] (e.g., professional, playful, modern, trustworthy)
- Target audience: [DESCRIBE_TARGET_USERS]

DESIGN SYSTEM COMPONENTS NEEDED:

1. COLOR SYSTEM:
- Primary color palette (provide hex if you have preferences)
- Secondary/accent colors
- Neutral grays
- Semantic colors (success, warning, error, info)
- Light/dark mode variations

2. TYPOGRAPHY SYSTEM:
- Font recommendations (web-safe with fallbacks)
- Type scale (headings H1-H6, body, captions)
- Line heights and spacing
- Font weights available

3. SPACING SYSTEM:
- Base unit system (4px, 8px grid)
- Margin/padding scale
- Layout spacing guidelines

4. COMPONENT SPECIFICATIONS:
- Button variations (primary, secondary, ghost, disabled states)
- Form elements (inputs, selects, checkboxes, radio buttons)
- Cards and containers
- Navigation elements

5. ACCESSIBILITY GUIDELINES:
- Color contrast requirements
- Focus indicators
- Text size minimums

OUTPUT FORMAT:
1. Design tokens (JSON/CSS custom properties)
2. CSS utility classes
3. Component documentation with examples
4. Usage guidelines and do's/don'ts
5. Implementation guide for developers

Please create a cohesive system that reflects the brand personality while maintaining excellent usability and accessibility.
```

## Example Usage

**Input:**
```
Brand name: TechFlow
Industry: B2B SaaS platform
Brand personality: Professional, innovative, trustworthy, efficient
Target audience: Software developers and project managers
```

## Sample Results

The prompt would generate:
1. Complete color palette with semantic meanings
2. Typography system with font recommendations
3. Spacing and layout guidelines
4. CSS custom properties for all design tokens
5. Component specifications with usage examples
6. Accessibility compliance guidelines

## Notes

- Be specific about your brand personality to get appropriate design choices
- Mention any existing brand colors or fonts you must include
- Consider your platform requirements (web, mobile, both)
- Specify if you need specific accessibility compliance (WCAG AA/AAA)