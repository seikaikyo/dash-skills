# Claude Designer Skill

Uncompromising UI/UX design skill for Claude Code with Jobs-style perfectionism and Rams-style functionalism.

## Overview

The Designer skill is a specialized design agent that transforms frontend designs with uncompromising perfectionism. It activates when you mention design improvements, beautification, or visual polish for your interfaces.

## Key Features

- **Three-Phase Workflow**: Deep diagnosis → Three solution options → Meticulous execution
- **Jobs + Rams Philosophy**: Combines Steve Jobs' product intuition with Dieter Rams' functionalism
- **Design System Ready**: Includes comprehensive color, typography, spacing, and shadow systems
- **Pragmatic Options**: Progressive, radical, and ideal solutions based on project constraints

## How to Use

### Installation

1. Copy the `SKILL.md` file to your Claude skills directory:
   ```
   ~/.claude/skills/designer/SKILL.md
   ```

2. Or use the Claude MCP skill installer:
   ```bash
   claude skill install designer
   ```

### Triggering the Skill

The skill automatically activates when you mention:

- "美化" (beautify)
- "重新设计" (redesign)
- "改进UI" (improve UI)
- "提升体验" (enhance experience)
- "设计优化" (design optimization)
- "视觉效果" (visual effects)
- "看起来不太好看" (doesn't look good)
- "需要打磨" (needs polish)
- "更好的设计" (better design)

### Example Usage

```markdown
用户: 把这个页面美化一下

Designer: [Analyzes current design]

## 深度诊断

### 现状分析
[Evaluation of current implementation]

### 核心问题
[Identifies key design issues]

### 真实需求
[Digs deeper than surface requirements]

---

## 方案 A：渐进优化
[Minimal changes, low risk]

## 方案 B：激进革新
[Breaks framework, new interaction]

## 方案 C：理想终极
[Unlimited resources, ultimate experience]

---

## 我的建议
**推荐方案：** [A/B/C]
**理由：** [Detailed rationale]
```

## Design Philosophy

### Three Solution Framework

1. **方案 A：渐进优化**
   - 改动最小，风险最低
   - 适合时间紧张、预算有限的项目

2. **方案 B：激进革新**
   - 打破现有框架，重新设计
   - 适合有预算、敢于创新的项目

3. **方案 C：理想终极**
   - 不考虑技术限制，追求极致体验
   - 适合长期愿景规划和高端产品

### Core Principles

1. **少即是多** - Delete unnecessary elements
2. **形式追随功能** - Beauty is functional expression
3. **一致性即信任** - Establish predictable patterns
4. **微交互的魔力** - Every detail matters
5. **层级决定重要性** - Guide user attention

## Design System

### Color System

```css
/* Semantic Colors */
--primary: #000000;
--accent: #007AFF;
--success: #10B981;
--warning: #F59E0B;
--error: #EF4444;

/* Neutrals */
--gray-50: #F9FAFB;
--gray-100: #F3F4F6;
--gray-200: #E5E7EB;
--gray-300: #D1D5DB;
--gray-400: #9CA3AF;
--gray-500: #6B7280;
--gray-600: #4B5563;
--gray-700: #374151;
--gray-800: #1F2937;
--gray-900: #111827;
```

### Typography

```css
/* Font Families */
--font-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
--font-mono: 'SF Mono', 'Monaco', 'Inconsolata', monospace;

/* Scale */
--text-xs: 0.75rem;   /* 12px */
--text-sm: 0.875rem;  /* 14px */
--text-base: 1rem;    /* 16px */
--text-lg: 1.125rem;  /* 18px */
--text-xl: 1.25rem;   /* 20px */
--text-2xl: 1.5rem;  /* 24px */
--text-3xl: 1.875rem; /* 30px */
--text-4xl: 2.25rem;  /* 36px */
```

### Spacing

```css
/* Base Unit: 4px */
--space-1: 0.25rem;  /* 4px */
--space-2: 0.5rem;   /* 8px */
--space-3: 0.75rem;  /* 12px */
--space-4: 1rem;     /* 16px */
--space-5: 1.25rem;  /* 20px */
--space-6: 1.5rem;   /* 24px */
--space-8: 2rem;     /* 32px */
--space-10: 2.5rem;  /* 40px */
--space-12: 3rem;    /* 48px */
--space-16: 4rem;    /* 64px */
```

### Shadows

```css
--shadow-xs: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
--shadow-sm: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
--shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
--shadow-md: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
--shadow-lg: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
--shadow-xl: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
```

## Example Output

See the `examples/` directory for real-world design transformations:

- **Progressive Optimization**: Simple enhancements to existing designs
- **Radical Innovation**: Complete visual language overhauls
- **Ideal Ultimate**: Industry-leading UX experiences

## Requirements

- Claude Code MCP installed
- Claude CLI configured

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

Inspired by:
- Steve Jobs' product intuition and attention to detail
- Dieter Rams' "Ten Principles of Good Design"
- The uncompromising pursuit of design excellence

## Support

For issues or questions, please open an issue on GitHub.

---

**Remember**: Good design is not about decoration—it's about clarity, purpose, and creating experiences that users love.
