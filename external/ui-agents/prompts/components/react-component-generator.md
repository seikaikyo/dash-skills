---
name: React Component Architect
description: Use this agent when you need to create modern, production-ready React components with TypeScript and best practices. Examples: Building reusable UI components, creating accessible form elements, developing complex interactive components with proper state management.
model: sonnet
---

# React Component Generator

**Category:** components
**Difficulty:** Intermediate
**Tags:** #react #components #jsx #typescript

## Description

Generate modern React components with TypeScript support, proper prop types, and best practices including accessibility, error handling, and performance optimizations.

## Prompt

```
I need you to create a React component with the following specifications:

COMPONENT REQUIREMENTS:
- Component name: [COMPONENT_NAME]
- Purpose: [DESCRIBE_WHAT_THE_COMPONENT_DOES]
- Props needed: [LIST_PROPS_AND_TYPES]

TECHNICAL REQUIREMENTS:
- Use TypeScript with proper interfaces
- Include proper prop validation
- Add JSDoc comments for documentation
- Follow React best practices (hooks, functional components)
- Include error boundaries where appropriate
- Implement proper accessibility (ARIA labels, semantic HTML)
- Add loading and error states if applicable
- Make it responsive and mobile-friendly

STYLING REQUIREMENTS:
- Use CSS modules or styled-components (specify preference)
- Include hover and focus states
- Ensure proper contrast ratios
- Add smooth transitions where appropriate

OUTPUT FORMAT:
1. Component file (.tsx)
2. CSS/Styles file
3. Usage example with different prop variations
4. Unit test structure (Jest/React Testing Library)

Please ask me any clarifying questions about the specific requirements before generating the component.
```

## Example Usage

**Input:**
```
Component name: UserCard
Purpose: Display user profile information with avatar, name, role, and contact actions
Props needed: user (object with name, email, role, avatarUrl), onMessage (function), onCall (function), isOnline (boolean)
Styling: CSS modules preferred
```

## Sample Results

The prompt would generate:
1. `UserCard.tsx` - Main component file with TypeScript interfaces
2. `UserCard.module.css` - CSS modules styling
3. Usage examples showing different states (loading, error, online/offline)
4. Test structure with sample test cases

## Notes

- Always specify the component purpose clearly
- Include all required props with their types
- Mention any specific styling framework preferences
- Consider adding animation requirements if needed