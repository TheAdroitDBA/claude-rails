=== Quick next steps ===

1. Start your first feature
   Create <feature-name>.feature.md next to the primary code file. If the feature has a user-facing surface (CLI, UI, API humans call, error message, docs page), write or update a *.flow.md first -- the "Outside-in for user-facing work" principle in the claude-config MEMORY.md charter.
   Feature doc should include:
     - What it does
     - Numbered success criteria
     - Status: IN PROGRESS
     - Files and Scope

2. Set the current-feature pointer
   printf '<slug>' > .claude/current-feature
   Sessions load that one doc instead of scanning all of them.

3. Enforcement mode: <enforcement-mode>
   - "off"   -- nothing blocks
   - "warn"  -- edits outside feature scope print a warning
   - "block" -- edits outside feature scope are rejected
   Change with: printf '<mode>' > .claude/feature-doc-mode

4. Write a flow doc when you find yourself re-reading the same pipeline
   <entry-point>.flow.md next to the entry-point file.

5. Something broken? Follow README.md -> "Troubleshooting a feature".

6. Re-audit any time: /project-setup is idempotent.
