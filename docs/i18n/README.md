# Localization working documents

Telltale supports eleven UI languages. The claim depends on the language and surface.
The eight additions use the reviewed final translation packets; the review record and
its limits are stated below.

| Language | UI translation claim | Android Auto claim |
|---|---|---|
| English (`en`) | Source template | Source template |
| Traditional Chinese (`zh_Hant`) | Human translation, reviewed against the documents below | Existing translation; no new review in this integration |
| German (`de`) | DeepL output, read end to end and corrected by hand; not read by a native speaker on a screen | Machine-assisted translation using the German ARB terms, checked mechanically for keys and format placeholders; no end-to-end or native-speaker screen read |
| Japanese (`ja`) | New-language claim and review status below | Same claim and status |
| Korean (`ko`) | New-language claim and review status below | Same claim and status |
| Spanish (`es`) | New-language claim and review status below | Same claim and status |
| French (`fr`) | New-language claim and review status below | Same claim and status |
| Brazilian Portuguese (`pt`) | New-language claim and review status below | Same claim and status |
| Simplified Chinese (`zh_Hans`) | New-language claim and review status below | Same claim and status |
| Italian (`it`) | New-language claim and review status below | Same claim and status |
| Dutch (`nl`) | New-language claim and review status below | Same claim and status |

The eight new languages are LLM translations of the English template. Each packet
was mechanically checked for keys, ICU arguments, plural/select branches,
do-not-translate tokens, Android XML escaping and store length limits, then reviewed
by a second model. Codex reviewed each against the [hedge register](hedge-register.md):
for seven languages, two to five full passes were made; Dutch had one full pass.
A pass found no meaning blocker, or the remaining findings were fixed and the changed
strings were re-read against English. Korean's four reported results include two
parallel reviewers, whose findings differed rather than forming one linear sequence.

A Gemini 4 Argon fluency pass followed. Every string it changed was re-read against
English to check that its force was preserved: 69–99 changes per language, with 27
corrected in total. The handoff records these results:

| Language | Second-model reviewer | Codex passes: blockers found | Fluency changes / corrected |
|---|---|---|---|
| Japanese | Grok | 4: 18, 5, 2, 0 | 94 / 9 |
| Korean | Codex | 4: 12, 2, 9, 4; includes two parallel reviewers | 99 / 2 |
| Spanish | agy | 2: 1, 0 | 95 / 4 |
| French | agy | 3: 5, 1, 0 | 93 / 0 |
| Brazilian Portuguese | Codex | 2: 2, 0 | 89 / 3 |
| Simplified Chinese | Codex | 5: 32, 18, 4, 2, 0 | 85 / 5 |
| Italian | Grok | 3: 1, 1, 0 | 87 / 3 |
| Dutch | Codex | 1: 0; 48 major findings fixed and re-read | 69 / 1 |

No native speaker has read these translations on a screen. Two independent reviewers
of the same Korean file found entirely different problems, so residual defects are
likely. A translation that weakens, adds or drops a qualifier is a defect: please
report it using the guidance in [CONTRIBUTING.md](../../CONTRIBUTING.md). Integration
and device verification are tracked separately. The adjusted store language and
readiness bullets and the machine-translated current-version release notes were not
part of the packets' model review; the release notes have not been reviewed.

Chinese scripts take priority over regions: Hans/CN/SG resolve to Simplified Chinese;
Hant/TW/HK/MO resolve to Traditional Chinese. Bare `zh` retains the existing Traditional
Chinese fallback, also guarded by tests. Other unrecognized regions remain unsupported.
All Portuguese device regions use the Brazilian Portuguese bundle (`pt`), with `pt-BR`
in Android per-app settings and language-only `values-pt` car resources so a `pt-PT`
device also finds that bundle. Apple bundle localization declarations use `pt` to
match the language-only Dart bundle and cover regional Portuguese preferences.

## What the German locale claims, and what it does not

Mechanically it is held to the same standard as any other locale, and the checks are the
ones that can be automated: `test/l10n/arb_parity_test.dart` and
`tool/i18n_verify/check_arb.py` require the same keys, the same ICU arguments and no empty
values, every token on [do-not-translate.md](do-not-translate.md) was held out of the
translation request and verified in the result, and each plural branch was rewritten by
hand — a machine glues the argument to the noun (`{count}-Codes`) and starts new sentences
inside a branch, which breaks the sentence the branch sits in.

What it does not claim is a native speaker's reading on a screen. The correction pass fixed
the errors a reader of German can see in the string: `Port` as *Hafen*, `Mass` as *Messe*,
`Drive` as *Laufwerk*, `Displacement` as *Verdrängung*, `Stopped by you` as *Ich habe bei
Ihnen vorbeigeschaut*, and — the ones that matter here — `read-only` as *schreibgeschützt*,
`clear` drifting between *löschen*, *Freigabe* and *Bereinigung*, and `The ECU did not
answer` becoming *Der Befehl „ECU" wurde nicht beantwortet*. What it cannot fix is a
sentence that reads correctly and lands with less force than the English, which is the
failure [hedge-register.md](hedge-register.md) exists to name. So: a German string that
reads wrongly is a defect report, not a matter of taste, and the register is the standard
it is judged against.

These three documents and this index are the contract a translation is reviewed against. They are written in
English because they are read while editing English ARB entries, and because the terms
they define appear in both languages side by side.

| Document | What it settles |
|---|---|
| [glossary.md](glossary.md) | Term pairs, each with the file and line that established it |
| [do-not-translate.md](do-not-translate.md) | Tokens that must stay byte-identical, and why the line falls where it does |
| [hedge-register.md](hedge-register.md) | Sentences whose qualifiers are load-bearing |

## The rule these exist to enforce

> A plausible wrong number is worse than no number.

The same holds for prose. A fluent English sentence that quietly drops "not certification",
"observed", "estimated" or "partial" is not a good translation with a small flaw in it — it
is a false claim about a vehicle, published under this project's name. Fluency is not the
acceptance criterion; preserved force is.

## What is checked automatically

`test/l10n/glossary_evidence_test.dart` parses `glossary.md` and fails when a cited term is
no longer within a few lines of the place the glossary says it is. A glossary nobody
verifies becomes folklore within one refactor.

Seven guards: every table row parses (a row count, not a lower bound, so a section cannot
change shape and vanish); every row cites a file that exists **with a line number**; the
Chinese term is at that line; the English term is at that line; an `evidenced` pairing was
actually written down together — in one file, or in the two language versions of one
document; no Chinese term carries two English forms; and the glossary never translates a
token the do-not-translate list says to leave alone.

The line numbers are the part that makes it bite. An earlier version discarded them and
compared whole files, which passed for any two words that happened to appear in two large
documents.

**What it cannot tell you** is whether a translation is *good*. It answers one question a
machine can answer honestly: is the evidence still where the glossary says it is? Force,
tone and preserved hedging are a human's job, which is what
[hedge-register.md](hedge-register.md) exists to make reviewable.

The glossary guard does not check ARB content; the parity test and ARB checker above do.

### Packet token exceptions

`Torque` exceptions occur only where English means the physical quantity or torque
converter, rather than the protected Torque app name. The table covers all shipped
ARBs, including the reviewed packets, and records where the exact English spelling
`Torque` is absent; Portuguese retains it in `derivedTorque`, while its converter
descriptions use lowercase `torque`.

| Key | Shipped locales |
|---|---|
| `derivedTorque` | `de`, `ja`, `ko`, `es`, `fr`, `zh`, `zh_Hant`, `zh_Hans`, `it`, `nl` |
| `dtcDescriptionP0740` | `ja`, `ko`, `es`, `fr`, `pt`, `zh`, `zh_Hant`, `zh_Hans`, `it`, `nl` |
| `dtcDescriptionP0741` | `ja`, `ko`, `es`, `fr`, `pt`, `zh`, `zh_Hant`, `zh_Hans`, `it`, `nl` |

These agree with the glossary's product/quantity distinction. The repository checker
has no per-key DNT exception file; packet acceptance checked these cases separately.
Per-locale English-identical values and their reasons are retained in
`test/l10n/arb_parity_test.dart`.
