# pithfinder: Online Safety Act assessments

**Service:** pithfinder (https://robertskylar.github.io/pithfinder/), a public map where anyone can add citrus trees growing outdoors, with a location, notes and an optional photo.
**Provider and person accountable:** [YOUR NAME], the person who runs pithfinder.
**Assessment date:** [DATE] · **Next review:** [DATE + 12 months], or sooner if the service changes (see "When to review").

This is a draft prepared for the provider to check, complete and keep. It follows the four steps in Ofcom's guidance on illegal content risk assessments, and Ofcom's children's access assessment. It is not legal advice.

---

## Part 1: Illegal content risk assessment

### Step 1. How the service works (risk factors)

| Factor | pithfinder |
|---|---|
| Type of service | User-to-user: visitors post content (trees, notes, photos) that other visitors see. |
| User accounts | None. Posting is anonymous. |
| What users can post | A tree record: kind, street and area (free text, 120 characters), notes (free text, 600 characters), a map pin, a date, and one optional JPEG photo (max 2 MB). |
| Messaging, comments, profiles, following, livestreaming | None. Users cannot contact each other through the service. |
| Search | Search of trees and place names only. Users cannot search for other users. |
| Who sees content | Anyone with the link. Content is public. |
| Size | Small (tens of records, low traffic) as of the assessment date. |
| Existing safeguards | Posting terms, a consent checkbox, a public report form, owner moderation (hide or delete), a 50-posts-per-hour site-wide limit, photo size and type limits. |

### Step 2. Risk of each kind of priority illegal harm

Risk = likelihood × impact, judged for this service's features. "Negligible" means the feature set gives almost no route for the harm.

| Kind of illegal harm | Likelihood | Impact | Risk | Reasoning |
|---|---|---|---|---|
| Child sexual abuse material (images, links) | Low | Severe | **Low** | Anonymous photo upload is a possible route, but there's no private sharing, every upload is public, and the topic gives no reason to visit. |
| Grooming | Negligible | Severe | **Negligible** | No messaging, profiles or way to contact another user. |
| Intimate image abuse | Low | Severe | **Low** | Possible via photo upload. Public display and owner review reduce it. |
| Harassment, stalking, threats, abuse | Low | Medium | **Low** | Pins and notes could point at someone's home. Mitigated by street-level pins, no house numbers, and removal on request. |
| Hate offences | Low | Medium | **Low** | Possible via free-text notes or photos. Short fields, public display, reporting. |
| Terrorism | Negligible | Severe | **Negligible** | No plausible use for the service's features. |
| Encouraging suicide or self-harm | Negligible | Severe | **Negligible** | No plausible route. |
| Fraud and financial offences | Low | Low | **Low** | Possible spam or scam links in notes. Short fields, rate limit, removal. |
| Drugs, firearms, weapons, people smuggling, sexual exploitation, extreme pornography, foreign interference, animal cruelty, other priority offences | Negligible | Varies | **Negligible** | Features (short text, a garden photo, a map pin) give no meaningful route. Content would be obviously off-topic and removed. |

**Overall:** low risk for all kinds of illegal harm. The main residual risks come from anonymous photo uploads and free-text notes.

### Step 3. Measures in place

1. **Clear terms** saying what can't be posted (privacy.html#terms), shown at the point of posting with a consent checkbox.
2. **Reporting:** a "Report this tree" link on every tree, and a public report and removal form (privacy.html#report). It is easy to find and doesn't need an account.
3. **Review and takedown:** the provider checks new trees and reports at least weekly, and as soon as possible after a report. Illegal content is hidden at once (`hidden` = true) and then deleted, with its photo. Where content may be child sexual abuse material, the provider will not download or share it, will delete it, and will report it to the Internet Watch Foundation (report.iwf.org.uk).
4. **Rate and size limits:** at most 50 new trees an hour site-wide, photos limited to JPEG under 2 MB, text fields length-limited.
5. **Privacy by design:** street-level pins in private gardens, no house numbers, guidance against photos of people or number plates.
6. **Complaints:** the report form also handles complaints about moderation decisions. Replies go to the contact details given, if any.

### Step 4. Records, review and accountability

- This document is the written record of the assessment. Keep a copy and update it at each review.
- Keep a simple log of reports received, the action taken and the date (the `reports` table, with `resolved` ticked once dealt with).
- **When to review:** every 12 months; before adding new features such as accounts, comments, messaging or video; if traffic grows significantly; or if reports show a new kind of harm.

---

## Part 2: Children's access assessment

**Stage 1. Is it possible for children to use the service?**
Yes. There is no age check, so a child could visit and post.

**Stage 2. Is the child user condition met?** (A significant number of UK child users, or a service likely to attract a significant number of children.)
Not at present, in the provider's assessment:
- the service is aimed at adults interested in gardening, citrus and urban nature
- it isn't promoted to children or designed to appeal to them, and has no games, social features or messaging
- traffic is low, and nothing so far suggests a significant number of child users

**Conclusion:** the child user condition is not currently met, so children's risk assessment duties do not apply. **Review** this conclusion at least yearly, and immediately if the service is promoted to schools or families, adds social features, or analytics or reports suggest significant use by children.

---

**Signed:** ______________________ (provider) · **Date:** ____________
