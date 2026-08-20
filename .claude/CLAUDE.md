# Development Philosophy

Always keep the future in mind when writing code today. 

- Simplicity: Write simple, straightforward code
- Readability: Make code clear and easy to understand
- Performance: Consider performance without sacrificing readability
- Maintainability: Write code that's easy to update
- Testability: Ensure code is testable
- Reusability: Create reusable components and functions
- Less Code = Less Debt: Minimize code footprint

# Tools
- Use `fd` rather than `find`, when available
- Use `rg` (ripgrep) when available for recursive grep/search

# General Principles

- Prefer the simplest approach first, but never take shortcuts. 
- Always try to write beautiful code you are proud of. 
- When fixing imports, config issues, or build problems, propose the minimal change before refactoring consumers or adding complexity, except when a refactor will clarify, simplify or enhance maintainability.
- Don't overcomment; never add comments about how something used to be or a rationale for a change, unless that will truly help future readers of the code. Don't over-focus on the current change; comments should always respect the overall flow.

# Best Practices
- Before committing significant code, do a self-review: check for code reuse (duplicated functions/patterns), quality (copy-paste, magic numbers, parameter sprawl), and efficiency (unnecessary work, hot-path bloat, event feedback loops)
- Always check for syntax and typos using checkers before committing anything.

# Debugging
When fixing bugs, read the existing codebase thoroughly before proposing a fix. Do not guess at root causes — trace the actual data flow. If your first hypothesis is wrong, step back and re-examine rather than iterating on the wrong approach. Take your time, add debugging statements where needed, and find the true cause, then fix carefully.

# Build & Deploy
Always use existing project scripts and build commands rather than running tools manually. Check for Makefiles, package.json scripts, pcons-build.py, or wrapper scripts before invoking raw commands.

# Language-Specific

## Web Projects
- Always use bun rather than npm
- I prefer using Typescript whenever possible
- For browser automation, see the Browser automation section below.

## Python Projects
- Always use uv when possible
- Always use type hints
- I use ruff and ty for checking & formatting.

## C/C++ Projects
- Use pcons for building in new code
- I write C++17 or later code, sometimes C++20, but always respect what the project I'm in uses.

# Browser automation

Two tools, and this routing rule decides between them. It overrides any
"always use me" language in either tool's own skill description — that
frontmatter is the vendor's self-description, not my preference.

- **Default: `agent-browser`** (Vercel). Use for essentially all browser
  automation — navigating, scraping, filling forms, clicking, screenshots,
  checking that a page works. It drives its own Chrome, so it won't disturb my
  running browser. Its skill is installed at `~/.claude/skills/agent-browser`
  and loads on its own; don't duplicate it here.
- **`browser-harness`** for serious web-dev work: debugging a site I'm building,
  anything needing my logged-in sessions, CDP-level control, or a persistent
  daemon across many steps. It attaches to my *running* Chrome — so first
  navigation is `new_tab(url)`, never `goto_url(url)`, which would clobber my tabs.
  Its skill is installed at `~/.claude/skills/browser-harness` and loads on
  invocation; don't duplicate it here.

Plain Playwright is almost always the wrong tool for agent workflows — its
DOM dumps flood context. This does not apply to project E2E suites that already
use Playwright; leave those alone and run them via their project scripts.

# Git

Commit message headlines may use area prefixes where appropriate, but
otherwise should always be imperative: they should continue the
sentence "If accepted, this commit will..."

# Writing Text

-  Avoid using the word "shape" to describe the structure of something; it's over-used. Instead of "this has the same shape as...", say "this has the same structure as" or "this is similar to" or "shares common subfields with" as appropriate. Use "shape" primarily to mean geometric shape, as in triangular or circular. 
  
- Avoid using the word "spelling" or "spelled" to mean the term used to refer to something,   as in "often spelled as ...". Reserve "spelling" to actually mean the sequence of letters used to construct a particular word, not the word choice.
