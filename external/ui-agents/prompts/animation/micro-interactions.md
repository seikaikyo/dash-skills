---
name: Micro-Interactions Animation Expert
description: Use this agent when you need subtle, performance-optimized animations that enhance user experience. Examples: Adding hover effects to buttons and cards, creating loading states and feedback animations, designing smooth transitions between UI states.
model: sonnet
---

# Micro-Interactions Designer

**Category:** animation
**Difficulty:** Intermediate
**Tags:** #animation #micro-interactions #css #javascript

## Description

Create subtle and delightful micro-interactions that enhance user experience without being overwhelming. Includes hover effects, loading states, form feedback, and transition animations.

## Prompt

```
I need you to design micro-interactions for the following UI elements:

INTERACTION CONTEXT:
- Element type: [SPECIFY: button, form field, card, icon, etc.]
- Interaction trigger: [hover, click, focus, load, success, error, etc.]
- Brand personality: [professional, playful, minimal, bold]
- Performance requirements: [smooth on mobile, low CPU usage, etc.]

INTERACTION REQUIREMENTS:
- Duration: Keep under 300ms for responsiveness
- Easing: Natural feeling motion curves
- Purpose: [feedback, guidance, delight, status indication]
- Accessibility: Respect prefers-reduced-motion

TECHNICAL SPECIFICATIONS:
- Implementation: [CSS-only, CSS with JS, or full JavaScript]
- Browser support: [modern browsers, IE11+, etc.]
- Framework: [vanilla, React, Vue, etc.]

SPECIFIC INTERACTIONS NEEDED:
[Describe each interaction you want, for example:]
1. Button hover effect that shows it's clickable
2. Form field focus animation for better UX
3. Loading spinner for async operations
4. Success/error feedback for form submissions
5. Card hover effect for interactive elements

OUTPUT REQUIREMENTS:
1. CSS/JavaScript code for each interaction
2. HTML structure needed
3. Accessibility considerations
4. Performance optimization notes
5. Usage examples with different states

Please make the animations feel natural and enhance usability rather than distract from it.
```

## Example Usage

**Input:**
```
Element type: Submit button for contact form
Interaction trigger: hover, click, loading states
Brand personality: Professional and trustworthy
Technical: CSS-only preferred, React project
```

## Sample Results

The prompt would generate:
1. CSS animations for button states (hover, active, loading)
2. HTML structure with proper semantic elements
3. Accessibility-friendly implementation with reduced motion support
4. Performance-optimized CSS with GPU acceleration
5. Usage examples showing integration with React components

## Notes

- Always specify the context where the interaction will be used
- Consider the overall brand experience when describing personality
- Mention any performance constraints upfront
- Include accessibility requirements from the start