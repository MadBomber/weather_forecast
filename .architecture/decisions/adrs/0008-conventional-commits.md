# ADR-0008: Use Conventional Commits for Commit Messages

## Status

Accepted

## Context

Git commit messages are a critical form of project documentation. They provide historical context for why changes were made, enable automated tooling (changelog generation, semantic versioning), and improve team collaboration.

The WeatherForecast API needs a consistent commit message standard to:
- Document the history of changes clearly
- Enable automated changelog generation
- Support semantic versioning
- Improve code review process
- Facilitate debugging and troubleshooting
- Provide clear communication in git history

### Current State

Without a commit message standard:
- Inconsistent message formats
- Unclear change context
- Difficult to categorize changes
- Manual changelog creation
- No automated version bumping
- Poor git history readability

### Conventional Commits Specification

**Conventional Commits** is a lightweight convention for commit messages that:
- Provides clear structure: `type(scope): description`
- Enables automated tooling
- Communicates intent clearly
- Is widely adopted in open source
- Supports semantic versioning (SemVer)

**Format**:
```
<type>(<optional scope>): <description>

[optional body]

[optional footer(s)]
```

**Types**:
- `feat`: New feature (minor version bump)
- `fix`: Bug fix (patch version bump)
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring (no feat/fix)
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `build`: Build system or dependency changes
- `ci`: CI/CD configuration changes
- `chore`: Maintenance tasks (no production code change)
- `revert`: Revert previous commit

**Breaking Changes**: `BREAKING CHANGE:` in footer or `!` after type triggers major version

**Examples**:
```
feat(weather): add NWS weather adapter

Implements National Weather Service API integration following
the adapter pattern established in OpenWeathermapAdapter.

Includes comprehensive RSpec tests and VCR cassettes.

Closes #23
```

```
fix(cache): correct TTL for zipcode-based weather data

Changed cache expiration from 1 hour to 30 minutes to align
with ADR-0001 requirements.
```

```
docs(adr): add ADR-0008 for conventional commits

Documents decision to use conventional commits specification
for all commit messages.
```

### Tooling Options

To enforce and assist with conventional commits, several tools are available:

#### 1. aigcm (AI Git Commit Message Generator)

**Description**: Uses AI to generate conventional commit messages

**Features**:
- Analyzes git diff
- Generates appropriate conventional commit message
- Learns from project context
- AI-powered (GPT/Claude)
- CLI-based workflow

**Pros**:
- AI understands changes and generates meaningful messages
- Automatically follows conventional commits format
- Fast and convenient
- Works with existing git workflow
- Can analyze complex changes

**Cons**:
- Requires AI API access (cost)
- May generate incorrect context
- Need to review generated messages
- External dependency

**Usage**:
```bash
git add .
aigcm  # AI generates commit message
# Review and edit if needed
git commit -m "<generated message>"
```

#### 2. overcommit

**Description**: Git hook manager with commit message validation

**Features**:
- Manages git hooks (pre-commit, commit-msg, etc.)
- Plugin-based architecture
- Can enforce conventional commits format
- Runs linters, tests, etc.
- Per-project configuration

**Pros**:
- Comprehensive hook management
- Enforces standards automatically
- Can run multiple checks
- Well-established in Ruby community
- Highly configurable

**Cons**:
- Requires Ruby gem installation
- Configuration complexity
- Can slow down commits with many hooks
- Team must install and configure locally

**Configuration**:
```yaml
# .overcommit.yml
CommitMsg:
  TextWidth:
    enabled: true
    max_subject_width: 72
  TrailingPeriod:
    enabled: true
  ConventionalCommits:
    enabled: true
```

#### 3. lefthook

**Description**: Fast and powerful git hooks manager

**Features**:
- Written in Go (fast, single binary)
- Cross-platform (no runtime dependencies)
- Parallel hook execution
- YAML configuration
- Can enforce commit message format

**Pros**:
- **Fast**: Faster than overcommit (Go vs Ruby)
- **No dependencies**: Single binary
- **Simple setup**: One command installation
- **Parallel execution**: Runs hooks concurrently
- **Modern**: Active development

**Cons**:
- Newer than overcommit (smaller community)
- Less Ruby ecosystem integration
- Requires manual plugin configuration for conventional commits

**Configuration**:
```yaml
# lefthook.yml
commit-msg:
  commands:
    conventional:
      run: |
        grep -qE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?: .+' {1}
```

### AI Coding Agent Integration

With **ADR-0007** (AI Coding Agents), we have Claude Code available for commit message generation:

**Claude Code Can**:
- Analyze changes and generate commit messages
- Follow conventional commits format
- Include detailed descriptions
- Reference related ADRs and issues
- Generate breaking change footers when appropriate

**Example Workflow**:
```bash
git add .
# Ask Claude Code to create commit message
> "Create a conventional commit message for these changes"
# Claude analyzes diff and generates proper message
git commit -m "<claude-generated message>"
```

## Decision

We will adopt the **Conventional Commits specification** for all commit messages in the WeatherForecast API project.

We recommend using **aigcm** (AI Git Commit Message Generator) as the primary tool for generating commit messages, with **lefthook** as an optional enforcement layer for teams.

### Rationale

**1. Conventional Commits Benefits**
- Clear, structured commit history
- Enables automated changelog generation
- Supports semantic versioning
- Industry-standard format
- Improves collaboration
- Better git log readability

**2. aigcm Recommendation**
- **AI Integration**: Aligns with ADR-0007 (AI Coding Agents)
- **Convenience**: Analyzes changes and generates appropriate messages
- **Quality**: AI understands context and writes meaningful messages
- **Consistency**: Always follows conventional commits format
- **Speed**: Faster than manual composition
- **Learning**: Can be customized to project conventions

**3. lefthook as Optional Enforcement**
- **Fast**: Go-based, minimal overhead
- **Simple**: Single binary, no dependencies
- **Flexible**: Can enforce without blocking workflow
- **Modern**: Active development and support
- **Non-invasive**: Developers can choose to install

**4. Overcommit Not Chosen (but acceptable)**
- Heavier than lefthook
- Ruby dependency adds overhead
- aigcm + lefthook covers needs
- Still acceptable if team prefers

### Implementation Strategy

**Phase 1: Adopt Conventional Commits** (Immediate)
- Document commit message format
- Provide examples and templates
- Manual adherence initially
- Code review feedback on commit messages

**Phase 2: Add aigcm** (Recommended)
```bash
# Install aigcm
npm install -g aigcm
# or
brew install aigcm

# Configure for project
aigcm config set model claude-3-sonnet
aigcm config set provider anthropic

# Use for commits
git add .
aigcm
# Review generated message
# Commit with generated message
```

**Phase 3: Optional lefthook Enforcement**
```bash
# Install lefthook
brew install lefthook
# or download binary

# Initialize
lefthook install

# Configure in lefthook.yml (see configuration below)

# Hooks run automatically on commit
```

### Commit Message Format

**Template**:
```
<type>(<scope>): <short description>

<longer description if needed>

<footer (breaking changes, issues, co-authors)>
```

**Rules**:
1. **Type**: Required (feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert)
2. **Scope**: Optional (weather, cache, api, adapter, etc.)
3. **Description**: Required, imperative mood, lowercase, no period
4. **Body**: Optional, explain what and why vs how
5. **Footer**: Optional, breaking changes, issue references

**WeatherForecast-Specific Scopes**:
- `weather`: Weather data and forecasting
- `adapter`: Weather provider adapters (NWS, OpenWeatherMap)
- `cache`: Caching logic and Redis integration
- `api`: API endpoints and controllers
- `models`: Data models and value objects
- `services`: Service objects
- `tests`: Test suite changes
- `docs`: Documentation
- `adr`: Architecture decision records
- `config`: Configuration changes
- `deps`: Dependency updates

### Examples for This Project

**Feature Addition**:
```
feat(adapter): add NWS weather adapter

Implements National Weather Service API integration following
the adapter pattern. Supports lat/lon queries and transforms
NWS API responses to Weather::Forecast objects.

Includes:
- Weather::NwsAdapter class
- Comprehensive RSpec tests
- VCR cassettes for API responses
- Error handling for NWS-specific errors

Refs: ADR-0004 (OpenWeatherMap as Primary)
Closes: #45
```

**Bug Fix**:
```
fix(cache): correct zipcode cache TTL to 30 minutes

Cache was expiring after 1 hour instead of required 30 minutes.
Updated cache write call to use correct expires_in value.

Refs: ADR-0001 (Redis Caching)
```

**Documentation**:
```
docs(adr): add ADR-0008 for conventional commits

Documents decision to adopt conventional commits specification
and recommends aigcm for message generation.
```

**Breaking Change**:
```
feat(api)!: change forecast response format to include metadata

BREAKING CHANGE: API response now includes metadata wrapper.
Clients must update to access forecast data under 'data' key.

Before:
{ "temperature": 72, "conditions": "sunny" }

After:
{
  "data": { "temperature": 72, "conditions": "sunny" },
  "metadata": { "provider": "openweathermap", "cached": true }
}

Migration guide: docs/api-v2-migration.md
```

**With AI Attribution** (optional):
```
feat(weather): implement forecast caching with variable TTL

Allow different TTL values per provider and data type.
OpenWeatherMap defaults to 30 minutes, NWS to 15 minutes.

🤖 Generated with Claude Code
```

## Consequences

### Positive Consequences

1. **Clear History**:
   - Structured, scannable commit log
   - Easy to identify change types
   - Quick understanding of project evolution
   - Better git blame context

2. **Automation**:
   - Automated changelog generation
   - Semantic version bumping
   - Release note creation
   - CI/CD integration possibilities

3. **Communication**:
   - Clear intent of each commit
   - Better code review context
   - Easier to find related changes
   - Improved team collaboration

4. **Standards**:
   - Industry-standard format
   - Familiar to most developers
   - Clear guidelines
   - Reduced bikeshedding

5. **Tooling Benefits**:
   - AI can generate messages (aigcm, Claude Code)
   - Hooks can enforce format (lefthook)
   - Multiple tool options
   - Integration with git ecosystem

6. **Debugging**:
   - Easier to find when bugs introduced
   - Clear context for changes
   - Better git bisect experience
   - Faster troubleshooting

7. **Documentation**:
   - Commits document the "why"
   - Historical context preserved
   - Automatic changelog generation
   - Release notes from commits

### Negative Consequences

1. **Learning Curve**:
   - Team must learn conventional commits format
   - Takes time to become habit
   - May slow initial commits
   - Requires discipline

2. **Tooling Setup**:
   - aigcm requires installation and API key
   - lefthook requires setup
   - Configuration maintenance
   - Potential CI/CD integration work

3. **Enforcement Challenges**:
   - Need to review commit messages
   - May slow workflow if hooks too strict
   - Requires team buy-in
   - Rebasing may complicate messages

4. **Overhead**:
   - More time per commit (initially)
   - Thinking about type/scope
   - Writing good descriptions
   - AI tool costs (aigcm API calls)

5. **Rigidity**:
   - Format constraints may feel restrictive
   - Not all changes fit neatly into types
   - Edge cases require judgment
   - May discourage small commits

### Neutral Consequences

1. **Habit Formation**: Takes 2-4 weeks to become natural
2. **Tool Preference**: Developers may prefer different tools (aigcm vs manual)
3. **Commit Frequency**: May encourage more granular commits (good practice)

## Implementation Guidelines

### Setup aigcm

```bash
# Install
npm install -g aigcm

# Configure (first time)
aigcm config set provider anthropic
aigcm config set model claude-3-sonnet-20240229
aigcm config set apiKey <your-api-key>

# Optional: Set project-specific prompt
aigcm config set prompt "Generate conventional commit following WeatherForecast project style. Use scopes: weather, adapter, cache, api, models, services, tests, docs, adr, config, deps"
```

### Setup lefthook (Optional)

```yaml
# lefthook.yml
commit-msg:
  parallel: true
  commands:
    conventional-commits:
      run: |
        # Check if commit message follows conventional commits format
        MSG=$(cat {1})
        if ! echo "$MSG" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?: .{1,}'; then
          echo "❌ Commit message must follow Conventional Commits format"
          echo ""
          echo "Format: <type>(<scope>): <description>"
          echo ""
          echo "Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"
          echo "Scopes: weather, adapter, cache, api, models, services, tests, docs, adr, config, deps"
          echo ""
          echo "Example: feat(adapter): add NWS weather adapter"
          exit 1
        fi

    length-check:
      run: |
        # Check subject line length (max 72 chars)
        MSG=$(cat {1})
        SUBJECT=$(echo "$MSG" | head -n 1)
        if [ ${#SUBJECT} -gt 72 ]; then
          echo "⚠️  Subject line too long (${#SUBJECT} chars, max 72)"
          echo "Consider shortening: $SUBJECT"
          exit 1
        fi
```

### Workflow Examples

**Using aigcm**:
```bash
# Make changes
git add app/services/weather/nws_adapter.rb
git add spec/services/weather/nws_adapter_spec.rb

# Generate commit message with AI
aigcm

# AI analyzes diff and suggests:
# feat(adapter): add NWS weather adapter
#
# Implements National Weather Service API integration
# following the adapter pattern...

# Review, edit if needed, commit
```

**Manual (with template)**:
```bash
# Create commit message template
cat > ~/.gitmessage.txt << 'EOF'
# <type>(<scope>): <subject>
# |<----  Max 72 chars  ---->|

# Explain what and why (not how)

# Footer (Breaking changes, issues)
# BREAKING CHANGE: description
# Closes: #123
EOF

# Configure git to use template
git config --global commit.template ~/.gitmessage.txt

# Commit with template
git commit
# Editor opens with template
```

**Using Claude Code**:
```
# In Claude Code session
> Stage the weather adapter changes and create a conventional commit

# Claude:
# - Stages files
# - Analyzes changes
# - Generates commit message
# - Creates commit with proper format
```

### Commit Message Quality Checklist

- [ ] Type is appropriate (feat, fix, docs, etc.)
- [ ] Scope is clear (weather, adapter, cache, etc.)
- [ ] Subject is imperative mood ("add" not "added")
- [ ] Subject is lowercase (except proper nouns)
- [ ] Subject has no trailing period
- [ ] Subject is ≤72 characters
- [ ] Body explains what and why (if needed)
- [ ] Footer includes breaking changes (if any)
- [ ] Footer references issues (if applicable)
- [ ] Message provides context for future readers

## Tool Comparison

| Feature | aigcm | lefthook | overcommit | Manual |
|---------|-------|----------|------------|--------|
| AI Generation | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Enforcement | ❌ No | ✅ Yes | ✅ Yes | ❌ No |
| Speed | ⚡ Fast | ⚡ Fast | 🐢 Slower | ⚡ Fast |
| Dependencies | Node/API | None (Go) | Ruby | None |
| Learning Curve | Low | Medium | Medium | High |
| Cost | API calls | Free | Free | Free |
| Flexibility | High | High | High | High |
| Setup Time | 5 min | 10 min | 15 min | 0 min |

**Recommendation**: Use **aigcm** for generation + **lefthook** (optional) for enforcement

## Alternatives Considered

### 1. No Standard (Freeform Commits)

**Why Not Chosen**:
- Inconsistent history
- No automation possible
- Poor documentation
- Harder to review
- Unprofessional

**When It Would Be Better**:
- Solo hobby projects
- Throwaway prototypes
- Non-collaborative work

### 2. Custom Commit Format

**Description**: Create project-specific commit format

**Why Not Chosen**:
- Reinventing the wheel
- No tooling support
- Not transferable knowledge
- Extra documentation burden
- Conventional Commits already exists

**When It Would Be Better**:
- Very specific needs not met by Conventional Commits
- Existing large codebase with different standard

### 3. commitizen (Interactive CLI)

**Description**: Interactive CLI for creating conventional commits

**Why Not Chosen**:
- **Interactive workflow** slower than AI generation
- More manual than aigcm
- Still requires thinking about format
- aigcm provides better UX with AI

**When It Would Be Better**:
- Team prefers guided prompts over AI
- No AI API access
- Prefer manual control

### 4. Only AI (No Enforcement)

**Description**: Use aigcm/Claude Code but no hooks to enforce

**Why Chosen**: This IS our approach (aigcm recommended, lefthook optional)

**Rationale**:
- Trust developers + AI
- Enforcement can be added later
- Code review catches issues
- Flexibility preferred initially

## Related Decisions

- **ADR-0007**: AI Coding Agents - aigcm and Claude Code can generate commits
- **All ADRs**: Commits should reference related ADRs
- **Git Workflow**: Conventional commits enable better git history

## References

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [aigcm](https://github.com/tak-bro/aicommit2)
- [lefthook](https://github.com/evilmartians/lefthook)
- [overcommit](https://github.com/sds/overcommit)
- [Semantic Versioning](https://semver.org/)
- [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/)

## Review Notes

This decision reflects:
- **Professionalism**: Industry-standard commit format
- **Automation**: Enables tooling and automation
- **AI Integration**: Leverages AI for commit message generation (ADR-0007)
- **Flexibility**: Recommends tools but doesn't mandate
- **Practicality**: Optional enforcement allows gradual adoption
- **Quality**: Better git history improves long-term maintainability

**Key Principle**: Good commit messages are documentation. Conventional Commits provides structure, and AI tools (aigcm, Claude Code) make it easy to write them well.

**Implementation Approach**: Start with aigcm for AI-generated messages, optionally add lefthook for enforcement, and rely on code review to maintain quality.

---

*Date*: 2025-10-10
*Author*: Lead Engineer, Architecture Team
*Reviewers*: Systems Architect, Development Team
*Related ADRs*: ADR-0007 (AI Coding Agents)
*Recommended Tools*: aigcm (primary), lefthook (optional), Claude Code (AI generation)
*Status*: Accepted - Conventional Commits adopted, aigcm recommended
