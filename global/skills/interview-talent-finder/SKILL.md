---
name: interview-talent-finder
description: "Expert interview and talent finder for DBA team hiring. Use when: screening candidates, evaluating resumes, preparing interview questions, assessing cultural fit, checking for multiplier mindset, tailoring questions to a specific role level, reviewing CVs, comparing candidates to role expectations, building interview scorecards."
argument-hint: "Describe the candidate, role level, or interview scenario"
---

# Interview Talent Finder

Evaluate candidates for DBA team roles using role-specific expectations and the Multiplier leadership framework to identify people who amplify team intelligence.

## Available Roles

Load the role doc matching the position before generating questions or evaluating a candidate.

| Level | Role Doc | Key Differentiator |
|-------|----------|--------------------|
| Mid-Level | `DBALeadership/Roles/Role_Cloud_Database_Engineer_MidLevel.md` | Builds fundamentals, follows process, asks for help |
| Senior | `DBALeadership/Roles/Role_Senior_Cloud_Database_Engineer.md` | Executes independently once scoped, documents own work |
| Lead | `DBALeadership/Roles/Role_Lead_Cloud_Database_Engineer.md` | Owns workstreams, coordinates cross-team, mentors others |
| Principal | `DBALeadership/Roles/Role_Principal_Cloud_Database_Engineer.md` | Owns initiatives end-to-end, defines standards, represents team |
| All Levels | `DBALeadership/Roles/Role_Expectations_All_Levels.md` | Core expectations every level must meet |

## Interview Assets

| Asset | Path | Purpose |
|-------|------|---------|
| Job Requirements | `DBALeadership/Interview/Job_requirements.md` | Official posting requirements |
| Minimum Requirements | `DBALeadership/Interview/Minimum_Requirements_Reference.md` | Screening decision matrix |
| Interview Template | `DBALeadership/Interview/Interview_Template.md` | 30-min screening framework |
| Screen Questions | `DBALeadership/Interview/ScreenQuestions.md` | Quick-screen packet for recruiters |
| Resume Rating | `DBALeadership/Interview/Resume_Rating_Process.md` | Resume scoring criteria |

## Workflow

### Step 1: Identify the Role Level

Ask or infer which level is being hired for. Load the corresponding role doc from the table above.

### Step 2: Load the Multiplier Skill Context

The multiplier-leadership skill defines the framework. Key concepts to evaluate in candidates:

**Multiplier indicators** -- signs a candidate will amplify the team:
- Describes lifting others up, sharing knowledge, mentoring
- Talks about team wins, not just personal achievements
- Shows curiosity: asks questions, learns from mistakes
- Gives credit to others when describing successes
- Describes situations where they let others lead or grow
- Shows comfort with "I don't know" followed by how they figured it out

**Diminisher red flags** -- signs a candidate may drain team intelligence:
- Only talks about personal heroics ("I saved the day")
- Dismisses others' contributions or blames teammates
- Shows rigid thinking: "my way is the right way"
- Cannot describe a time they were wrong or learned from a mistake
- Takes credit for group outcomes
- Describes leadership as control rather than enablement

### Step 3: Generate Role-Appropriate Questions and Write to File

Combine technical requirements from the role doc with multiplier-mindset probes.

**IMPORTANT: All output goes to files, not chat.** Create an interview questions file at:
`DBALeadership/Interview/<ActiveReqFolder>/Interview_Questions_<CandidateName>.md`

The file should include:
- Candidate summary (from resume)
- Resume-based technical fit assessment
- Tailored interview questions with what-to-look-for notes
- Multiplier mindset questions with scoring guidance
- Blank answer/assessment fields for the interviewer to fill in during the interview

After writing the file, give a brief summary in chat (candidate name, recommendation to advance or not, and the file path). Do not reproduce the full content in chat.

#### Security Clearance (UK SOV roles)

For UK sovereign environment positions, candidates must be eligible for **NPPV L3 clearance**. They do not need to hold it at time of hire, but they must qualify for it. The clearance process can take a few months after start. Always ask:
- "Are you eligible for NPPV L3 clearance?" (UK residency, background check eligibility, etc.)
- "Are you aware this role requires NPPV L3, and that the clearance process will begin after you start?"

Document eligibility status in the assessment. If a candidate may not qualify, flag it as a blocker.

#### Technical Questions (from role level)

Pull directly from the Interview Template and Screen Questions. Adjust depth by level:
- **Mid-Level**: Verify fundamentals -- can they do the work with guidance?
- **Senior**: Verify independence -- can they own tasks with defined scope?
- **Lead**: Verify coordination -- can they drive workstreams and mentor?
- **Principal**: Verify initiative -- can they define direction and standards?

#### Multiplier Mindset Questions (use for all levels)

These questions reveal whether the candidate naturally multiplies or diminishes:

**Talent Magnet indicators:**
- "Tell me about a time you helped a teammate get better at something."
- "Describe a situation where someone on your team had a skill you didn't. How did you leverage that?"

**Liberator indicators:**
- "Describe an environment where you did your best work. What made it different?"
- "Tell me about a time you disagreed with a decision. What did you do?"

**Challenger indicators:**
- "Tell me about a problem you solved that you initially thought was impossible."
- "How do you handle a situation where the standard approach isn't working?"

**Debate Maker indicators:**
- "When you and a colleague disagree on a technical approach, how do you resolve it?"
- "Tell me about a time you changed your mind based on someone else's argument."

**Investor indicators:**
- "Describe a project you owned end-to-end. How did you handle setbacks?"
- "Tell me about a time you had to figure something out without much guidance."

### Step 4: Evaluate the Candidate

Score on two dimensions:

#### A. Technical Fit (from role requirements)

Use the Resume Rating Process criteria:
- **Strong Yes**: Exceeds requirements, priority candidate
- **Yes**: Meets minimum requirements, worth interviewing
- **No**: Meets some requirements but has significant concerns
- **Definitely Not**: Does not meet minimums, major gaps

Decision formula from Minimum Requirements Reference:
- Fail 0 of critical requirements = advance
- Fail 1 = borderline
- Fail 2+ = reject
- Fail T-SQL or Replication = automatic rejection

#### B. Multiplier Fit (from behavioral answers)

| Rating | Indicators |
|--------|-----------|
| **Strong Multiplier** | Multiple examples of lifting others, learning from failure, team-first language, curiosity-driven |
| **Likely Multiplier** | Some team-oriented language, shows growth mindset, can describe learning moments |
| **Neutral** | Neither strong multiplier nor diminisher signals; need more data |
| **Diminisher Risk** | Hero narratives, blame language, rigid thinking, cannot describe mistakes |

### Step 5: Produce Output (always to file)

**Pre-interview (resume review + question prep):** Write to the active req folder:
`DBALeadership/Interview/<ActiveReqFolder>/Interview_Questions_<CandidateName>.md`

**Post-interview (assessment after interview):** Write to the active req folder:
`DBALeadership/Interview/<ActiveReqFolder>/<CandidateName>_Assessment.md`

If the candidate is rejected, also copy both files + CV to `Archive/YYYY-MM_ReqName/`.

**Never dump full assessments or question lists into chat.** Write the file, then confirm in chat with a 1-2 sentence summary and the file path.

#### Post-Interview Clarification

When the user provides completed interview notes (filled-in answers), **ask clarifying questions before writing the assessment**. Review the notes for:
- Answers that are vague or missing detail (e.g., "yes" with no evidence)
- Scorecard fields that weren't covered by any question (see Scorecard Fields below)
- Contradictions between answers
- Gaps where the interviewer's assessment field is blank

Ask concise, targeted questions like:
- "Q3 answer mentions AG experience but no detail on failover scenarios -- did he describe any specific incidents?"
- "The Winning@NICE 'Adjust Rapidly with Resilience' field needs evidence -- did anything in the interview map to that?"
- "Night shift answer was brief -- was there more context around his motivation?"

Once clarifications are gathered, proceed to the assessment + key takeaways.

#### Scorecard Fields

The assessment must provide evidence-based notes for every scorecard field. These go in the **Key Takeaways** section of the assessment file.

**Skills & Qualifications:**

| Field | Requirement |
|-------|-------------|
| SQL Server mission-critical | 5+ years maintaining SQL Server mission-critical databases |
| T-SQL programming | 5+ years of T-SQL programming |
| Database replication | 2+ years implementing and maintaining database replication |
| Availability Groups | 2+ years implementing and maintaining SQL Server Availability Groups |
| Cross-functional communication | Ability to work with technical and non-technical people |

**Winning@NICE Competencies:**

| Competency | What to listen for |
|------------|-------------------|
| Execute with Excellence | Takes ownership, delivers quality work, follows through on commitments |
| Keep Aiming Higher | Shows growth mindset, pursues improvement, raises the bar |
| Adjust Rapidly with Resilience | Adapts to change, recovers from setbacks, stays productive under pressure |
| Partner for Success | Collaborates across teams, builds relationships, shares credit |
| Earn our Customers' Admiration | Customer-focused thinking, understands business impact of technical work |

Map interview answers to these fields. If a field has no evidence from the interview, note "Not covered -- ask in next round."

#### Assessment template (for the .md file):

```
## Candidate Assessment: [Name]
**Position:** [Role Level] Cloud Database Engineer
**Date:** [Date]
**Interviewer:** Jeremy Allen

### Key Takeaways
> Freeform section -- copy directly into the scorecard "Conclusions, pros, cons, and things to follow up on" field.

**Conclusions:** [1-2 sentence overall verdict]

**Pros:**
- [strength 1]
- [strength 2]
- ...

**Cons:**
- [concern 1]
- [concern 2]
- ...

**Follow up:**
- [open item 1]
- [open item 2]

**Skills & Qualifications:**
- SQL Server mission-critical (5+ yrs): [evidence + years]
- T-SQL programming (5+ yrs): [evidence + years]
- Database replication (2+ yrs): [evidence + years]
- Availability Groups (2+ yrs): [evidence + years]
- Cross-functional communication: [evidence]

**Winning@NICE:**
- Execute with Excellence: [evidence or "Not covered -- ask in next round"]
- Keep Aiming Higher: [evidence or "Not covered -- ask in next round"]
- Adjust Rapidly with Resilience: [evidence or "Not covered -- ask in next round"]
- Partner for Success: [evidence or "Not covered -- ask in next round"]
- Earn our Customers' Admiration: [evidence or "Not covered -- ask in next round"]

### Technical Fit: [Strong Yes / Yes / No / Definitely Not]
- Requirement 1: [Met/Partial/Not Met] -- [evidence]
- Requirement 2: [Met/Partial/Not Met] -- [evidence]
- ...

### Multiplier Fit: [Strong Multiplier / Likely Multiplier / Neutral / Diminisher Risk]
- Talent Magnet: [evidence from resume/answers]
- Liberator: [evidence]
- Challenger: [evidence]
- Debate Maker: [evidence]
- Investor: [evidence]

### Overall Recommendation: [Definitely Not / No / Yes / Strong Yes]
[1-2 sentence summary]

### Questions to Ask in Next Round
- [Targeted questions based on gaps identified]
```

#### Interview questions template (for the .md file):

```
# Interview Questions - [Candidate Name]
**Position:** [Role Level] Cloud Database Engineer
**Interview Date:** _______________
**Interviewer:** Jeremy Allen

## Candidate Summary (from resume)
- [Key facts: experience, certifications, current role, strengths, gaps]

## Resume Assessment
- **Technical Fit (pre-interview):** [Strong Yes / Yes / No / Definitely Not]
- **Key Strengths:** [list]
- **Gaps to Probe:** [list]

## Interview Questions

### Section 1: Role Fit (5 min)
Q1: [question]
- **Target:** [what this tests]
- **Answer:**
- **Assessment:**

### Section 2: Technical (15 min)
Q2-Q5: [questions tailored to resume gaps and role level]
- **Target:** [what this tests]
- **Looking for:** [good/bad answers]
- **Answer:**
- **Assessment:**

### Section 3: Multiplier Mindset (5 min)
Q6-Q8: [selected from multiplier questions, tailored to resume signals]
- **Target:** [which multiplier discipline]
- **Multiplier signal:** [what a good answer sounds like]
- **Diminisher signal:** [what a bad answer sounds like]
- **Answer:**
- **Assessment:**

### Section 4: Wrap-up (5 min)
Q9: Do you have any questions for me?
- **Notes:**

## Post-Interview Summary
- **Technical Fit:** [fill after interview]
- **Multiplier Fit:** [fill after interview]
- **Recommendation:** [Advance / Hold / Pass]
- **Notes:**
```

## Folder Conventions

```
DBALeadership/Interview/
    Archive/                              <-- Rejected/closed candidates
        YYYY-MM_ReqName/                  <-- Grouped by requisition
            CandidateName_Assessment.md   <-- Structured assessment
            CandidateName_CV.docx         <-- Resume copy
    SeniorCloudDatabaseEngineer(NightShift)/  <-- Active req example
        Candidates.md                     <-- Tracking
        JobPosting.md
        Resume/                           <-- Incoming CVs
    Interview_Template.md                 <-- Shared templates (root level)
    Job_requirements.md
    ...
```

**When a candidate is rejected:** Copy their CV and create an assessment file in `Archive/YYYY-MM_ReqName/`. Use the structured assessment template from Step 5.

**When a req closes:** Move the entire active req folder contents to a dated archive subfolder.

## Reading Resumes (.docx files)

Use python-docx (installed in workspace venv) to extract text from .docx resume files:

```python
from docx import Document
doc = Document(r"path\to\resume.docx")
text = "\n".join([p.text for p in doc.paragraphs])
print(text)
```

Resume files are typically stored in active req subfolders (e.g., `DBALeadership/Interview/SeniorCloudDatabaseEngineer(NightShift)/Resume/`).

## Key Principles

1. **Role level matters.** Do not hold a Mid-Level candidate to Lead expectations. Match the evaluation to the actual role.
2. **Multiplier mindset is a tiebreaker.** Two technically equal candidates -- pick the one who will multiply the team.
3. **Look for growth trajectory.** A Mid-Level with multiplier traits will grow faster than a Senior with diminisher tendencies.
4. **"I don't know" is a good answer** -- if followed by how they'd find out. This signals intellectual honesty and learning orientation.
5. **Beware accidental diminisher patterns.** Someone who "always saves the day" may be preventing others from growing. Probe deeper.
