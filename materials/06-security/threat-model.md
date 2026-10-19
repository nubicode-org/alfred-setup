# Threat model: ___ (service name)

The course's capstone. Keep it to one page, and revisit it whenever the service changes shape.

## 1. What are we building?

One paragraph, and a diagram of the parts and the arrows between them. Mark every **trust boundary**:
each place data crosses from something you control to something you do not (the internet, a
partner's API, a user's browser).

## 2. What can go wrong?

Walk each arrow that crosses a boundary with STRIDE:

| Arrow | Spoofing | Tampering | Repudiation | Information disclosure | Denial of service | Elevation of privilege |
| --- | --- | --- | --- | --- | --- | --- |
| Browser > API | | | | | | |
| API > database | | | | | | |
| CI > production | | | | | | |

## 3. What are we doing about it?

| Threat | Likelihood | Impact | Mitigation | Owner | Done? |
| --- | --- | --- | --- | --- | --- |
| | | | | | |

Accepting a risk is a valid answer. Write down who accepted it and why.

## 4. Did we do a good job?

- [ ] Every boundary arrow has at least one row in step 3.
- [ ] Every secret the service uses is listed, with where it lives and who can read it.
- [ ] We know what we would see in the logs if the top threat happened.
- [ ] Someone outside the team has read this.

Last reviewed: ___
