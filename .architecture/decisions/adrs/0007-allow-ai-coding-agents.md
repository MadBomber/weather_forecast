# ADR-0007: Allow Generative AI Coding Agents

## Status

Accepted

## Context

Software development practices are rapidly evolving with the introduction of generative AI coding assistants and autonomous agents. These tools can significantly accelerate development, improve code quality, and assist with routine coding tasks.

The WeatherForecast API project needs to establish a policy regarding the use of AI coding agents to:
- Set clear expectations for the development team
- Ensure code quality and consistency
- Leverage modern development tools appropriately
- Maintain security and best practices
- Document architectural decisions made with AI assistance

### Available AI Coding Tools

**Types of AI Assistance**:

1. **Code Completion** (e.g., GitHub Copilot, Tabnine)
   - Inline suggestions while typing
   - Autocomplete functions and boilerplate
   - Context-aware code generation

2. **Chat-Based Assistants** (e.g., ChatGPT, Claude Web)
   - Ask questions and get code snippets
   - Explain code and debug issues
   - Generate documentation

3. **Agentic Systems** (e.g., Claude Code, Cursor, Aider)
   - Autonomous code generation
   - Multi-file editing capabilities
   - Integrated with development workflow
   - Context-aware across entire codebase
   - Can execute commands and run tests

### Claude Code CLI

**Claude Code** is Anthropic's official CLI-based agentic coding system:

**Capabilities**:
- Read and write files across the codebase
- Execute shell commands (git, bundle, rails, etc.)
- Run tests and interpret results
- Search code and documentation
- Multi-file refactoring
- Architecture planning and design
- Documentation generation
- Integrated with git workflow

**Advantages**:
- CLI-based: Works in terminal, no IDE lock-in
- Context-aware: Understands project structure
- Autonomous: Can complete multi-step tasks
- Reliable: Built by Anthropic (creators of Claude)
- Integrated: Works with git, testing, documentation
- Extensible: Supports project-specific context files

**Integration Points**:
- `.architecture/` - Architectural context and ADRs
- `.coding-assistants/context.md` - Project-specific patterns
- Git workflow - Commits, branches, PRs
- Testing - Run RSpec, interpret failures
- Documentation - Generate and maintain docs

### Project Context

**Development Approach**:
- Small team or solo developer
- Rapid development expected
- High quality standards (architectural principles)
- Well-documented codebase (ADRs, context files)
- Professional production deployment planned

**Architectural Alignment**:
- **Testable by Design**: AI can help write comprehensive tests
- **Documentation**: AI can maintain ADRs and documentation
- **Best Practices**: AI can enforce coding standards
- **Velocity**: AI accelerates routine tasks

**Risk Considerations**:
- Code quality must be maintained
- Security vulnerabilities from AI-generated code
- Over-reliance on AI without understanding
- Consistency with project conventions
- Intellectual property concerns

## Decision

We will **allow and encourage the use of generative AI coding agents** on the WeatherForecast API project, with **Claude Code CLI specifically recommended** as the primary agentic system.

### Rationale

**1. Development Velocity**
- Accelerate routine coding tasks (boilerplate, tests, documentation)
- Rapid prototyping and iteration
- Free developers to focus on architecture and business logic
- Reduce time on repetitive tasks

**2. Code Quality**
- AI can help maintain consistency with architectural principles
- Generate comprehensive test coverage
- Suggest best practices and patterns
- Identify potential issues and edge cases

**3. Documentation Excellence**
- AI can maintain up-to-date ADRs
- Generate comprehensive code documentation
- Keep context files synchronized
- Create examples and usage guides

**4. Learning and Expertise**
- AI can explain complex concepts
- Suggest modern Ruby/Rails patterns
- Provide alternative approaches
- Teach best practices

**5. Claude Code Advantages**
- **CLI-based**: No vendor lock-in, works anywhere
- **Context-aware**: Understands `.architecture/` and `.coding-assistants/`
- **Integrated workflow**: Works with git, testing, documentation
- **Reliable**: Built by reputable AI company (Anthropic)
- **Project-specific**: Can be trained on our conventions

**6. Competitive Advantage**
- Leverage cutting-edge development tools
- Faster time to market
- Higher quality codebase
- Modern development practices

### Approved AI Tools

**Recommended (Primary)**:
- **Claude Code CLI** - Autonomous agentic coding system
  - Use for: Architecture planning, multi-file refactoring, test generation, documentation
  - Context files: `.architecture/`, `.coding-assistants/context.md`

**Approved (Supplementary)**:
- **GitHub Copilot** - Inline code completion
- **ChatGPT / Claude Web** - Research, debugging, learning
- **Cursor** - AI-powered IDE with agentic capabilities
- **Aider** - Git-aware AI pair programming
- **Other reputable AI coding tools** - At developer discretion

### Usage Guidelines

**1. Review All AI-Generated Code**
- Never commit AI code without review and understanding
- Ensure code aligns with architectural principles
- Verify security and correctness
- Run tests before committing

**2. Maintain Context Files**
- Keep `.coding-assistants/context.md` updated
- Update `.architecture/` documentation
- AI learns from these files - keep them accurate

**3. Document AI-Assisted Decisions**
- ADRs document decisions (including AI-assisted ones)
- Note when AI suggested alternative approaches
- Credit AI assistance in commit messages (optional)

**4. Test Thoroughly**
- AI-generated code must have tests
- Run full test suite before committing
- Verify edge cases and error handling

**5. Security Awareness**
- Review AI code for security vulnerabilities
- Never commit secrets or API keys
- Validate input handling and sanitization
- Be cautious with external dependencies suggested by AI

**6. Learning, Not Dependency**
- Understand AI-generated code
- Use AI to learn, not as a crutch
- Maintain ability to code without AI
- Question AI suggestions

### Integration with Development Workflow

**Claude Code Workflow**:

```bash
# Start coding session with Claude
claude

# Claude has access to:
# - All project files
# - .architecture/ documentation
# - .coding-assistants/context.md
# - Git repository
# - Shell commands (bundle, rails, rspec)

# Example tasks:
> "Create a new weather adapter for NWS API following the existing pattern"
> "Write RSpec tests for the Temperature value object"
> "Generate an ADR for API versioning strategy"
> "Refactor caching logic to support multiple TTLs"
```

**Git Integration**:
```bash
# AI can create commits with proper messages
# Always review before pushing

git log --oneline -5
# Shows AI-assisted commits with clear messages
# Including "Generated with Claude Code" attribution
```

**Documentation Flow**:
```
Developer Request
    ↓
Claude Code Reviews Context
    ↓
AI Generates Code/Tests/Docs
    ↓
Developer Reviews and Refines
    ↓
Tests Pass
    ↓
Commit with Clear Message
    ↓
Update Context Files (if needed)
```

## Consequences

### Positive Consequences

1. **Development Speed**:
   - 2-5x faster for routine tasks
   - Rapid prototyping capabilities
   - Quick iteration on designs
   - Faster bug fixes

2. **Code Quality**:
   - Consistent style and patterns
   - Comprehensive test coverage
   - Better error handling
   - Following best practices

3. **Documentation**:
   - Up-to-date ADRs
   - Well-maintained context files
   - Clear code comments
   - Examples and guides

4. **Learning**:
   - Team learns modern patterns
   - Discovers best practices
   - Explores alternative approaches
   - Continuous improvement

5. **Competitive Advantage**:
   - Faster time to market
   - Higher quality product
   - Modern development practices
   - Efficient use of resources

6. **Reduced Toil**:
   - Less boilerplate code
   - Automated test generation
   - Documentation maintenance
   - Routine refactoring

7. **Consistency**:
   - AI enforces project conventions
   - Follows architectural principles
   - Maintains code style
   - Uses established patterns

### Negative Consequences

1. **Dependency Risk**:
   - Potential over-reliance on AI
   - Skills atrophy if not careful
   - Difficulty without AI access
   - Learning curve for AI tools

2. **Quality Control Required**:
   - Must review all AI code
   - Can generate subtle bugs
   - May not understand context fully
   - Security vulnerabilities possible

3. **Cost**:
   - Claude Code requires subscription (~$20/month)
   - GitHub Copilot costs extra
   - Other AI tools have fees
   - Infrastructure costs (API calls)

4. **Privacy/Security**:
   - Code sent to AI services
   - Potential data exposure
   - API key management
   - Intellectual property concerns

5. **Learning Curve**:
   - Time to learn effective prompting
   - Understanding AI limitations
   - Workflow integration
   - Context file maintenance

6. **Consistency Challenges**:
   - Different developers use AI differently
   - Varying quality of AI interactions
   - Need clear guidelines
   - Training required

### Neutral Consequences

1. **Workflow Changes**: Development process evolves with AI
2. **Code Attribution**: Questions about AI contribution vs human
3. **Review Process**: Different review approach for AI code
4. **Documentation**: More emphasis on context files

## Guidelines and Best Practices

### What AI Should Do

✅ **Encourage AI For**:
- Generating boilerplate code (adapters, services, controllers)
- Writing comprehensive test suites
- Creating and updating documentation
- Refactoring for consistency
- Suggesting architectural improvements
- Finding and fixing bugs
- Generating examples and usage guides
- Maintaining ADRs and context files

### What AI Shouldn't Do

❌ **Use Caution With**:
- Security-critical code (review extra carefully)
- Complex business logic (verify thoroughly)
- Database migrations (review schema changes)
- API design decisions (human judgment required)
- Production deployments (manual verification)
- Credential management (never commit secrets)

### Code Review Checklist for AI-Generated Code

- [ ] Code follows project conventions
- [ ] Tests are comprehensive and pass
- [ ] No security vulnerabilities
- [ ] No hardcoded secrets or API keys
- [ ] Error handling is appropriate
- [ ] Edge cases are covered
- [ ] Performance is acceptable
- [ ] Documentation is clear
- [ ] Aligns with architectural principles
- [ ] **I understand what this code does**

### Context File Maintenance

**Developer Responsibilities**:
1. Update `.coding-assistants/context.md` when patterns change
2. Create ADRs for significant decisions (even AI-assisted)
3. Keep `.architecture/principles.md` accurate
4. Document new conventions and patterns
5. Review AI-generated documentation for accuracy

**AI Responsibilities** (via prompts):
1. Read context files before generating code
2. Follow established patterns and conventions
3. Generate tests following RSpec patterns
4. Use `debug_me` instead of `puts`
5. Create ADRs for architectural decisions
6. Update documentation to reflect changes

## Example AI Prompts

**Good Prompts** (Effective):
```
"Create an NWS weather adapter following the pattern in
OpenweathermapAdapter, with proper error handling and RSpec tests"

"Generate an ADR for API versioning strategy, considering REST
best practices and our API-only architecture"

"Refactor the caching logic to support configurable TTLs per
provider, maintaining the 30-minute default for OpenWeatherMap"
```

**Poor Prompts** (Less Effective):
```
"Make it better"
"Fix the bug"
"Add caching"
```

## Monitoring and Adjustment

**Success Metrics**:
- Development velocity increase
- Test coverage maintained/improved (>80%)
- Code quality scores (Rubocop, Brakeman)
- Developer satisfaction
- Time to ship features

**Regular Review**:
- Monthly assessment of AI tool effectiveness
- Update guidelines based on experience
- Share best practices across team
- Adjust policies as tools evolve

**Failure Modes to Watch**:
- Declining code quality
- Security incidents from AI code
- Over-reliance without understanding
- Inconsistent code patterns
- Test coverage decline

## Alternatives Considered

### 1. Prohibit AI Coding Agents

**Description**: Ban all AI coding assistance

**Why Not Chosen**:
- **Competitive Disadvantage**: Other teams use AI, we'd be slower
- **Inefficient**: Manual work for tasks AI excels at
- **Outdated**: Resisting inevitable industry shift
- **Missed Learning**: No opportunity to develop AI-assisted workflow

**When It Would Be Better**:
- Highly regulated environments (defense, healthcare)
- Intellectual property concerns paramount
- Team philosophically opposed
- Security requirements prohibit external services

### 2. Limit to Code Completion Only

**Description**: Allow Copilot-style completion, not autonomous agents

**Why Not Chosen**:
- **Limited Benefit**: Misses major productivity gains
- **Inconsistent**: Why allow some AI but not others?
- **Arbitrary**: Completion vs agents is a spectrum
- **Missed Opportunity**: Claude Code's capabilities are valuable

**When It Would Be Better**:
- Team uncomfortable with autonomous agents
- Security policies restrict file access
- Simpler approval process needed

### 3. Require Human-Only Code, AI for Research Only

**Description**: AI for learning/research but not code generation

**Why Not Chosen**:
- **Arbitrary Line**: Where's the boundary?
- **Inefficient**: Slow for routine tasks
- **Missed Value**: Underutilizes capable tools
- **Hard to Enforce**: Difficult to distinguish

**When It Would Be Better**:
- Educational environment (learning to code)
- Code ownership critical
- Assessment/evaluation scenarios

## Related Decisions

- **ADR-0006**: RSpec testing - AI can generate comprehensive test suites
- **Architectural Principles**: "Testable by Design" - AI helps achieve this
- **All ADRs**: Can be generated/maintained with AI assistance
- **`.coding-assistants/context.md`**: Provides context to AI tools

## References

- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [GitHub Copilot](https://github.com/features/copilot)
- [Cursor IDE](https://cursor.sh/)
- [Aider](https://aider.chat/)
- [AI Coding Best Practices](https://www.anthropic.com/index/claude-code-best-practices)
- [Responsible AI Development](https://www.anthropic.com/responsible-scaling-policy)

## Review Notes

This decision reflects:
- **Modern Development**: Embracing cutting-edge tools
- **Pragmatism**: Using AI where it provides value
- **Quality Focus**: Review and testing requirements maintained
- **Flexibility**: Allowing various AI tools at developer discretion
- **Documentation**: Clear guidelines and best practices
- **Learning**: Opportunity to develop AI-assisted workflow

**Key Insight**: AI coding agents are tools that amplify developer capabilities, not replacements for developer judgment. Used responsibly with proper review processes, they accelerate development while maintaining quality standards.

**Philosophical Stance**: We view AI as a productivity multiplier, not a shortcut. Code quality, security, and understanding remain paramount. AI helps us build faster and better, but humans remain responsible for all code committed to the repository.

---

*Date*: 2025-10-10
*Author*: Lead Engineer, Architecture Team
*Reviewers*: Systems Architect, Testing Specialist
*Related ADRs*: ADR-0006 (RSpec), All ADRs (AI can assist with ADR creation)
*Tools Recommended*: Claude Code CLI (primary), GitHub Copilot (supplementary)
*Review Cadence*: Monthly evaluation of AI tool effectiveness
*Status*: Active - AI assistance encouraged with proper review
