# Simulated General Population PCL-5 Data

A dataset containing simulated responses from 1,200 individuals in a
general population sample on the PCL-5 (PTSD Checklist for DSM-5). Each
individual rated 20 PTSD symptoms on a scale from 0 to 4. This dataset
has a lower PTSD prevalence (~21
[`simulated_ptsd`](https://tobiasrspiller.github.io/PTSDdiag/reference/simulated_ptsd.md)
(~94 validation of diagnostic criteria derived from clinical samples.
Like `simulated_ptsd`, it ships with three demographic columns
(`patient_id`, `age`, `sex`). It also ships paired
clinician-administered CAPS-5 severity ratings (`C1`–`C20`) for the same
participants, simulated to correlate with the PCL-5 items so that the
PCL-5 and CAPS-5 total scores correlate about 0.8 (the level usually
reported empirically). This supports the paired-instrument workflow in
the CAPS-5 vignette without inventing data inline.

## Usage

``` r
simulated_ptsd_genpop
```

## Format

A data frame with 1,200 rows and 43 columns:

- patient_id:

  Character. Synthetic participant identifier (`"G0001"`–`"G1200"`).

- age:

  Integer. Age in years (truncated normal, range 18–80).

- sex:

  Factor. `"female"` / `"male"`.

- S1:

  PCL-5: Intrusive memories

- S2:

  PCL-5: Nightmares

- S3:

  PCL-5: Flashbacks

- S4:

  PCL-5: Emotional reactivity to reminders

- S5:

  PCL-5: Physical reactions to reminders

- S6:

  PCL-5: Avoiding memories/thoughts/feelings

- S7:

  PCL-5: Avoiding external reminders

- S8:

  PCL-5: Amnesia

- S9:

  PCL-5: Strong negative beliefs

- S10:

  PCL-5: Distorted blame

- S11:

  PCL-5: Negative trauma-related emotions

- S12:

  PCL-5: Decreased interest in activities

- S13:

  PCL-5: Detachment or estrangement

- S14:

  PCL-5: Trouble experiencing positive emotions

- S15:

  PCL-5: Irritability/aggression

- S16:

  PCL-5: Risk-taking behavior

- S17:

  PCL-5: Hypervigilance

- S18:

  PCL-5: Heightened startle reaction

- S19:

  PCL-5: Difficulty concentrating

- S20:

  PCL-5: Sleep problems

- C1:

  CAPS-5: Intrusive memories

- C2:

  CAPS-5: Nightmares

- C3:

  CAPS-5: Flashbacks

- C4:

  CAPS-5: Emotional reactivity to reminders

- C5:

  CAPS-5: Physical reactions to reminders

- C6:

  CAPS-5: Avoiding memories/thoughts/feelings

- C7:

  CAPS-5: Avoiding external reminders

- C8:

  CAPS-5: Amnesia

- C9:

  CAPS-5: Strong negative beliefs

- C10:

  CAPS-5: Distorted blame

- C11:

  CAPS-5: Negative trauma-related emotions

- C12:

  CAPS-5: Decreased interest in activities

- C13:

  CAPS-5: Detachment or estrangement

- C14:

  CAPS-5: Trouble experiencing positive emotions

- C15:

  CAPS-5: Irritability/aggression

- C16:

  CAPS-5: Risk-taking behavior

- C17:

  CAPS-5: Hypervigilance

- C18:

  CAPS-5: Heightened startle reaction

- C19:

  CAPS-5: Difficulty concentrating

- C20:

  CAPS-5: Sleep problems

The CAPS-5 items (`C1`–`C20`) are paired clinician-administered severity
ratings for the same participants and the same symptoms as the PCL-5
items, simulated to correlate with them at a total-score r of about 0.8.

## Source

Simulated data for demonstration purposes

## Details

The symptoms are rated on a 5-point scale:

- 0 = Not at all

- 1 = A little bit

- 2 = Moderately

- 3 = Quite a bit

- 4 = Extremely

The symptoms correspond to DSM-5 PTSD criteria:

- Symptoms 1-5: Criterion B (Intrusion)

- Symptoms 6-7: Criterion C (Avoidance)

- Symptoms 8-14: Criterion D (Negative alterations in cognitions and
  mood)

- Symptoms 15-20: Criterion E (Alterations in arousal and reactivity)

The data was simulated as a mixture of approximately 17% individuals
with elevated symptom profiles (PTSD-like) and 83% with low symptom
levels, resulting in approximately 21% meeting full DSM-5 diagnostic
criteria.

## Note

Symptoms were simulated independently. Real PCL-5 data exhibits
within-cluster correlations (e.g., between intrusion symptoms).
Optimization results on these data are for illustration only; real-world
performance should be evaluated on empirical datasets.

## See also

[`simulated_ptsd`](https://tobiasrspiller.github.io/PTSDdiag/reference/simulated_ptsd.md)
for the clinical veteran sample with higher prevalence.
