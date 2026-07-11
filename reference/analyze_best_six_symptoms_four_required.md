# Find optimal non-hierarchical six-symptom combinations for PTSD diagnosis

\`r lifecycle::badge("deprecated")\`

Convenience wrapper around
[`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
with the original PCL-5 defaults: 6 symptoms, 4 required, top 3
returned.

Identifies the three best six-symptom combinations for PTSD diagnosis
where any four symptoms must be present, regardless of their cluster
membership.

## Usage

``` r
analyze_best_six_symptoms_four_required(
  data,
  score_by = "balanced_accuracy",
  DT = FALSE
)
```

## Arguments

- data:

  A dataframe containing exactly 20 columns with PCL-5 item scores
  (output of rename_ptsd_columns). Each symptom should be scored on a
  0-4 scale where:

  - 0 = Not at all

  - 1 = A little bit

  - 2 = Moderately

  - 3 = Quite a bit

  - 4 = Extremely

- score_by:

  Character string specifying optimization criterion:

  - "balanced_accuracy": Maximise balanced accuracy, the mean of
    sensitivity and specificity. Robust when one diagnostic class is
    much more common than the other. Default.

  - "accuracy": Minimize total misclassifications (FP + FN, i.e.
    maximise overall accuracy).

  - "sensitivity": Minimize false negatives only (i.e. maximise
    sensitivity relative to the full DSM-5-TR diagnosis).

- DT:

  Logical. If `TRUE`, return the summary as an interactive
  [`datatable`](https://rdrr.io/pkg/DT/man/datatable.html) widget. If
  `FALSE` (default), return a plain data.frame.

## Value

A list containing:

- best_symptoms: List of three vectors, each containing six symptom
  numbers representing the best combinations found

- diagnosis_comparison: Dataframe comparing original DSM-5 diagnosis
  with diagnoses based on the three best combinations

- summary: Diagnostic accuracy metrics for each combination. A
  data.frame by default, or an interactive
  [`datatable`](https://rdrr.io/pkg/DT/man/datatable.html) if
  `DT = TRUE`.

## Details

The function:

1.  Tests all possible combinations of 6 symptoms from the 20 PCL-5
    items

2.  Requires 4 symptoms to be present (\>=2 on original 0-4 scale) for
    diagnosis

3.  Identifies the three combinations that best match the original DSM-5
    diagnosis

Optimization can be based on:

- Maximizing balanced accuracy, the mean of sensitivity and specificity
  (the default)

- Minimizing false cases (both false positives and false negatives)

- Minimizing only false negatives (newly non-diagnosed cases)

The symptom clusters in PCL-5 are:

- Items 1-5: Intrusion symptoms (Criterion B)

- Items 6-7: Avoidance symptoms (Criterion C)

- Items 8-14: Negative alterations in cognitions and mood (Criterion D)

- Items 15-20: Alterations in arousal and reactivity (Criterion E)

## See also

[`optimize_combinations`](https://tobiasrspiller.github.io/PTSDdiag/reference/optimize_combinations.md)
for the generalized version with configurable parameters.

## Examples

``` r
# Use a 250-row subset of the bundled data to keep the example fast
ptsd_data <- rename_ptsd_columns(simulated_ptsd[1:250, ],
                                 id_col = c("patient_id", "age", "sex"))

# \donttest{
# Find best combinations with the default balanced-accuracy criterion
results <- analyze_best_six_symptoms_four_required(ptsd_data)
#> Warning: `analyze_best_six_symptoms_four_required()` was deprecated in PTSDdiag 0.2.1.
#> ℹ Please use `optimize_combinations()` instead.
#> Evaluating combinations ■■■■■■■                           21% | ETA:  4s
#> Evaluating combinations ■■■■■■■■■■■■■■■■■■■■■■■■■■        83% | ETA:  1s
#> Evaluating combinations ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  100% | ETA:  0s
#> ℹ Evaluated 38760 combinations. Best: 6, 7, 8, 11, 13, 17 (1 additional tied)

# Get symptom numbers
results$best_symptoms
#> [[1]]
#> [1]  6  7  8 11 13 17
#> 
#> [[2]]
#> [1]  6  7 10 11 13 15
#> 
#> [[3]]
#> [1]  4  6  7  8 11 17
#> 

# View raw comparison data
results$diagnosis_comparison
#>     patient_id age    sex PTSD_orig symptom_6_7_8_11_13_17
#> 1        P0001  48   male      TRUE                   TRUE
#> 2        P0002  29   male      TRUE                   TRUE
#> 3        P0003  44   male      TRUE                   TRUE
#> 4        P0004  41 female      TRUE                   TRUE
#> 5        P0005  34   male      TRUE                   TRUE
#> 6        P0006  18   male      TRUE                  FALSE
#> 7        P0007  33   male      TRUE                   TRUE
#> 8        P0008  30 female      TRUE                   TRUE
#> 9        P0009  43 female      TRUE                   TRUE
#> 10       P0010  36 female      TRUE                   TRUE
#> 11       P0011  37 female      TRUE                   TRUE
#> 12       P0012  33   male      TRUE                   TRUE
#> 13       P0013  39 female      TRUE                   TRUE
#> 14       P0014  39   male      TRUE                   TRUE
#> 15       P0015  18 female      TRUE                   TRUE
#> 16       P0016  58 female     FALSE                  FALSE
#> 17       P0017  49 female      TRUE                   TRUE
#> 18       P0018  45 female      TRUE                   TRUE
#> 19       P0019  32 female      TRUE                   TRUE
#> 20       P0020  50   male      TRUE                   TRUE
#> 21       P0021  38   male      TRUE                   TRUE
#> 22       P0022  40 female      TRUE                   TRUE
#> 23       P0023  25   male      TRUE                   TRUE
#> 24       P0024  60 female      TRUE                   TRUE
#> 25       P0025  43 female      TRUE                   TRUE
#> 26       P0026  65   male      TRUE                   TRUE
#> 27       P0027  63   male      TRUE                   TRUE
#> 28       P0028  43 female      TRUE                   TRUE
#> 29       P0029  50 female      TRUE                   TRUE
#> 30       P0030  63   male     FALSE                  FALSE
#> 31       P0031  36   male      TRUE                   TRUE
#> 32       P0032  44   male      TRUE                   TRUE
#> 33       P0033  39   male      TRUE                   TRUE
#> 34       P0034  46   male      TRUE                   TRUE
#> 35       P0035  44 female      TRUE                   TRUE
#> 36       P0036  56   male      TRUE                   TRUE
#> 37       P0037  49   male      TRUE                   TRUE
#> 38       P0038  31 female     FALSE                   TRUE
#> 39       P0039  49 female      TRUE                   TRUE
#> 40       P0040  32 female      TRUE                   TRUE
#> 41       P0041  28 female      TRUE                   TRUE
#> 42       P0042  51 female      TRUE                   TRUE
#> 43       P0043  28 female      TRUE                   TRUE
#> 44       P0044  46 female     FALSE                  FALSE
#> 45       P0045  32 female      TRUE                   TRUE
#> 46       P0046  59   male      TRUE                   TRUE
#> 47       P0047  51   male      TRUE                   TRUE
#> 48       P0048  37 female      TRUE                   TRUE
#> 49       P0049  52   male     FALSE                  FALSE
#> 50       P0050  47 female      TRUE                   TRUE
#> 51       P0051  28 female      TRUE                   TRUE
#> 52       P0052  40 female      TRUE                   TRUE
#> 53       P0053  31   male      TRUE                   TRUE
#> 54       P0054  47   male      TRUE                   TRUE
#> 55       P0055  34   male      TRUE                   TRUE
#> 56       P0056  39   male      TRUE                   TRUE
#> 57       P0057  27   male      TRUE                   TRUE
#> 58       P0058  30 female      TRUE                   TRUE
#> 59       P0059  44   male      TRUE                   TRUE
#> 60       P0060  30 female      TRUE                   TRUE
#> 61       P0061  40 female      TRUE                   TRUE
#> 62       P0062  44 female      TRUE                   TRUE
#> 63       P0063  40   male      TRUE                   TRUE
#> 64       P0064  39 female      TRUE                   TRUE
#> 65       P0065  21   male      TRUE                   TRUE
#> 66       P0066  39 female      TRUE                   TRUE
#> 67       P0067  20 female      TRUE                   TRUE
#> 68       P0068  56   male      TRUE                   TRUE
#> 69       P0069  30 female      TRUE                   TRUE
#> 70       P0070  44 female     FALSE                  FALSE
#> 71       P0071  48   male      TRUE                   TRUE
#> 72       P0072  42   male      TRUE                   TRUE
#> 73       P0073  58 female      TRUE                   TRUE
#> 74       P0074  32   male      TRUE                   TRUE
#> 75       P0075  47 female      TRUE                   TRUE
#> 76       P0076  30   male     FALSE                  FALSE
#> 77       P0077  67 female      TRUE                   TRUE
#> 78       P0078  50 female      TRUE                   TRUE
#> 79       P0079  38   male      TRUE                   TRUE
#> 80       P0080  51   male      TRUE                   TRUE
#> 81       P0081  28   male      TRUE                   TRUE
#> 82       P0082  60 female      TRUE                   TRUE
#> 83       P0083  28   male      TRUE                   TRUE
#> 84       P0084  23   male      TRUE                   TRUE
#> 85       P0085  41   male      TRUE                   TRUE
#> 86       P0086  52   male      TRUE                   TRUE
#> 87       P0087  42   male      TRUE                   TRUE
#> 88       P0088  33 female      TRUE                   TRUE
#> 89       P0089  56 female      TRUE                   TRUE
#> 90       P0090  71 female      TRUE                   TRUE
#> 91       P0091  18 female      TRUE                   TRUE
#> 92       P0092  60   male      TRUE                   TRUE
#> 93       P0093  36 female      TRUE                   TRUE
#> 94       P0094  54   male      TRUE                   TRUE
#> 95       P0095  20 female      TRUE                   TRUE
#> 96       P0096  39 female      TRUE                   TRUE
#> 97       P0097  30   male     FALSE                  FALSE
#> 98       P0098  36 female     FALSE                  FALSE
#> 99       P0099  29 female      TRUE                   TRUE
#> 100      P0100  46   male      TRUE                   TRUE
#> 101      P0101  57   male      TRUE                   TRUE
#> 102      P0102  36 female      TRUE                   TRUE
#> 103      P0103  39   male      TRUE                   TRUE
#> 104      P0104  29 female      TRUE                   TRUE
#> 105      P0105  54 female      TRUE                   TRUE
#> 106      P0106  49 female      TRUE                   TRUE
#> 107      P0107  23 female      TRUE                   TRUE
#> 108      P0108  60   male      TRUE                   TRUE
#> 109      P0109  28   male      TRUE                   TRUE
#> 110      P0110  29 female      TRUE                   TRUE
#> 111      P0111  24   male      TRUE                   TRUE
#> 112      P0112  28 female      TRUE                   TRUE
#> 113      P0113  38 female      TRUE                   TRUE
#> 114      P0114  48   male      TRUE                   TRUE
#> 115      P0115  33   male      TRUE                   TRUE
#> 116      P0116  40 female      TRUE                   TRUE
#> 117      P0117  39   male      TRUE                   TRUE
#> 118      P0118  56 female      TRUE                   TRUE
#> 119      P0119  69   male      TRUE                   TRUE
#> 120      P0120  29   male      TRUE                   TRUE
#> 121      P0121  65   male      TRUE                   TRUE
#> 122      P0122  68   male      TRUE                   TRUE
#> 123      P0123  45   male      TRUE                   TRUE
#> 124      P0124  53 female      TRUE                   TRUE
#> 125      P0125  21   male      TRUE                   TRUE
#> 126      P0126  48 female      TRUE                   TRUE
#> 127      P0127  35   male      TRUE                   TRUE
#> 128      P0128  40   male      TRUE                   TRUE
#> 129      P0129  49   male      TRUE                   TRUE
#> 130      P0130  54 female      TRUE                   TRUE
#> 131      P0131  41   male      TRUE                   TRUE
#> 132      P0132  74 female      TRUE                   TRUE
#> 133      P0133  49   male      TRUE                   TRUE
#> 134      P0134  40   male      TRUE                   TRUE
#> 135      P0135  47 female      TRUE                   TRUE
#> 136      P0136  41   male      TRUE                   TRUE
#> 137      P0137  29   male      TRUE                   TRUE
#> 138      P0138  48 female      TRUE                   TRUE
#> 139      P0139  53 female      TRUE                  FALSE
#> 140      P0140  47 female      TRUE                   TRUE
#> 141      P0141  46 female      TRUE                   TRUE
#> 142      P0142  44 female      TRUE                   TRUE
#> 143      P0143  52   male      TRUE                   TRUE
#> 144      P0144  27 female      TRUE                   TRUE
#> 145      P0145  56 female      TRUE                   TRUE
#> 146      P0146  31   male      TRUE                   TRUE
#> 147      P0147  46 female      TRUE                   TRUE
#> 148      P0148  51 female      TRUE                   TRUE
#> 149      P0149  45   male     FALSE                  FALSE
#> 150      P0150  23   male      TRUE                   TRUE
#> 151      P0151  42 female      TRUE                   TRUE
#> 152      P0152  46   male      TRUE                   TRUE
#> 153      P0153  54 female      TRUE                   TRUE
#> 154      P0154  48   male      TRUE                   TRUE
#> 155      P0155  49 female      TRUE                   TRUE
#> 156      P0156  56 female      TRUE                   TRUE
#> 157      P0157  34 female      TRUE                   TRUE
#> 158      P0158  35   male      TRUE                   TRUE
#> 159      P0159  42   male      TRUE                   TRUE
#> 160      P0160  46   male      TRUE                   TRUE
#> 161      P0161  59 female     FALSE                  FALSE
#> 162      P0162  32 female      TRUE                   TRUE
#> 163      P0163  32   male      TRUE                   TRUE
#> 164      P0164  51 female     FALSE                  FALSE
#> 165      P0165  37 female      TRUE                   TRUE
#> 166      P0166  39   male      TRUE                   TRUE
#> 167      P0167  49   male      TRUE                   TRUE
#> 168      P0168  35 female      TRUE                   TRUE
#> 169      P0169  33 female      TRUE                   TRUE
#> 170      P0170  39 female      TRUE                   TRUE
#> 171      P0171  37 female      TRUE                   TRUE
#> 172      P0172  34 female      TRUE                   TRUE
#> 173      P0173  53 female      TRUE                   TRUE
#> 174      P0174  36 female     FALSE                  FALSE
#> 175      P0175  43   male      TRUE                   TRUE
#> 176      P0176  44 female      TRUE                   TRUE
#> 177      P0177  20 female      TRUE                   TRUE
#> 178      P0178  46 female      TRUE                   TRUE
#> 179      P0179  60   male      TRUE                   TRUE
#> 180      P0180  42 female      TRUE                   TRUE
#> 181      P0181  33   male      TRUE                   TRUE
#> 182      P0182  58   male      TRUE                   TRUE
#> 183      P0183  45 female      TRUE                   TRUE
#> 184      P0184  54   male      TRUE                   TRUE
#> 185      P0185  45 female      TRUE                   TRUE
#> 186      P0186  49   male      TRUE                   TRUE
#> 187      P0187  59   male      TRUE                   TRUE
#> 188      P0188  50 female      TRUE                   TRUE
#> 189      P0189  47   male      TRUE                   TRUE
#> 190      P0190  34 female      TRUE                   TRUE
#> 191      P0191  49   male      TRUE                   TRUE
#> 192      P0192  37 female      TRUE                   TRUE
#> 193      P0193  68 female      TRUE                   TRUE
#> 194      P0194  46 female      TRUE                   TRUE
#> 195      P0195  32 female      TRUE                   TRUE
#> 196      P0196  62 female      TRUE                   TRUE
#> 197      P0197  36 female      TRUE                   TRUE
#> 198      P0198  23 female      TRUE                   TRUE
#> 199      P0199  29 female      TRUE                   TRUE
#> 200      P0200  42   male      TRUE                   TRUE
#> 201      P0201  37 female     FALSE                  FALSE
#> 202      P0202  48 female      TRUE                   TRUE
#> 203      P0203  39   male      TRUE                   TRUE
#> 204      P0204  20   male      TRUE                   TRUE
#> 205      P0205  39 female      TRUE                   TRUE
#> 206      P0206  63 female      TRUE                   TRUE
#> 207      P0207  37   male      TRUE                   TRUE
#> 208      P0208  35 female      TRUE                   TRUE
#> 209      P0209  41   male     FALSE                  FALSE
#> 210      P0210  62 female      TRUE                   TRUE
#> 211      P0211  32   male      TRUE                   TRUE
#> 212      P0212  51   male      TRUE                   TRUE
#> 213      P0213  35   male      TRUE                   TRUE
#> 214      P0214  38 female      TRUE                   TRUE
#> 215      P0215  38   male      TRUE                   TRUE
#> 216      P0216  51   male     FALSE                  FALSE
#> 217      P0217  49   male      TRUE                   TRUE
#> 218      P0218  55 female      TRUE                   TRUE
#> 219      P0219  55   male      TRUE                   TRUE
#> 220      P0220  68 female      TRUE                   TRUE
#> 221      P0221  43 female      TRUE                   TRUE
#> 222      P0222  18 female      TRUE                   TRUE
#> 223      P0223  36 female      TRUE                   TRUE
#> 224      P0224  33   male      TRUE                   TRUE
#> 225      P0225  38   male      TRUE                   TRUE
#> 226      P0226  56   male      TRUE                   TRUE
#> 227      P0227  35   male      TRUE                   TRUE
#> 228      P0228  32   male      TRUE                   TRUE
#> 229      P0229  48 female      TRUE                   TRUE
#> 230      P0230  50   male      TRUE                   TRUE
#> 231      P0231  39   male     FALSE                  FALSE
#> 232      P0232  47 female      TRUE                   TRUE
#> 233      P0233  48 female      TRUE                   TRUE
#> 234      P0234  46 female      TRUE                   TRUE
#> 235      P0235  35   male      TRUE                   TRUE
#> 236      P0236  51 female      TRUE                   TRUE
#> 237      P0237  18 female      TRUE                   TRUE
#> 238      P0238  49   male      TRUE                   TRUE
#> 239      P0239  47 female      TRUE                   TRUE
#> 240      P0240  67 female      TRUE                   TRUE
#> 241      P0241  45 female      TRUE                   TRUE
#> 242      P0242  43   male      TRUE                   TRUE
#> 243      P0243  56   male      TRUE                  FALSE
#> 244      P0244  51   male      TRUE                   TRUE
#> 245      P0245  42   male      TRUE                   TRUE
#> 246      P0246  42   male     FALSE                  FALSE
#> 247      P0247  44 female      TRUE                   TRUE
#> 248      P0248  29 female      TRUE                   TRUE
#> 249      P0249  57   male      TRUE                   TRUE
#> 250      P0250  36   male      TRUE                   TRUE
#>     symptom_6_7_10_11_13_15 symptom_4_6_7_8_11_17
#> 1                      TRUE                  TRUE
#> 2                      TRUE                  TRUE
#> 3                      TRUE                  TRUE
#> 4                      TRUE                  TRUE
#> 5                      TRUE                  TRUE
#> 6                     FALSE                 FALSE
#> 7                      TRUE                  TRUE
#> 8                      TRUE                  TRUE
#> 9                      TRUE                  TRUE
#> 10                     TRUE                  TRUE
#> 11                     TRUE                  TRUE
#> 12                     TRUE                  TRUE
#> 13                     TRUE                  TRUE
#> 14                     TRUE                  TRUE
#> 15                     TRUE                  TRUE
#> 16                    FALSE                 FALSE
#> 17                     TRUE                  TRUE
#> 18                     TRUE                  TRUE
#> 19                     TRUE                  TRUE
#> 20                     TRUE                  TRUE
#> 21                     TRUE                  TRUE
#> 22                     TRUE                  TRUE
#> 23                     TRUE                  TRUE
#> 24                     TRUE                  TRUE
#> 25                     TRUE                  TRUE
#> 26                     TRUE                  TRUE
#> 27                     TRUE                  TRUE
#> 28                     TRUE                  TRUE
#> 29                     TRUE                  TRUE
#> 30                    FALSE                 FALSE
#> 31                     TRUE                  TRUE
#> 32                     TRUE                  TRUE
#> 33                     TRUE                  TRUE
#> 34                     TRUE                  TRUE
#> 35                     TRUE                  TRUE
#> 36                     TRUE                  TRUE
#> 37                     TRUE                  TRUE
#> 38                     TRUE                  TRUE
#> 39                     TRUE                  TRUE
#> 40                     TRUE                  TRUE
#> 41                     TRUE                  TRUE
#> 42                     TRUE                  TRUE
#> 43                     TRUE                  TRUE
#> 44                    FALSE                 FALSE
#> 45                     TRUE                  TRUE
#> 46                     TRUE                  TRUE
#> 47                     TRUE                  TRUE
#> 48                     TRUE                  TRUE
#> 49                    FALSE                 FALSE
#> 50                     TRUE                  TRUE
#> 51                     TRUE                  TRUE
#> 52                     TRUE                  TRUE
#> 53                     TRUE                  TRUE
#> 54                     TRUE                  TRUE
#> 55                     TRUE                  TRUE
#> 56                     TRUE                  TRUE
#> 57                     TRUE                  TRUE
#> 58                     TRUE                  TRUE
#> 59                     TRUE                  TRUE
#> 60                     TRUE                  TRUE
#> 61                     TRUE                  TRUE
#> 62                     TRUE                  TRUE
#> 63                     TRUE                  TRUE
#> 64                     TRUE                  TRUE
#> 65                     TRUE                  TRUE
#> 66                     TRUE                  TRUE
#> 67                     TRUE                  TRUE
#> 68                     TRUE                  TRUE
#> 69                     TRUE                  TRUE
#> 70                    FALSE                 FALSE
#> 71                     TRUE                  TRUE
#> 72                     TRUE                  TRUE
#> 73                     TRUE                  TRUE
#> 74                     TRUE                  TRUE
#> 75                     TRUE                  TRUE
#> 76                    FALSE                 FALSE
#> 77                     TRUE                  TRUE
#> 78                     TRUE                  TRUE
#> 79                     TRUE                  TRUE
#> 80                     TRUE                  TRUE
#> 81                     TRUE                  TRUE
#> 82                     TRUE                  TRUE
#> 83                     TRUE                  TRUE
#> 84                     TRUE                  TRUE
#> 85                     TRUE                  TRUE
#> 86                     TRUE                  TRUE
#> 87                     TRUE                  TRUE
#> 88                     TRUE                  TRUE
#> 89                     TRUE                  TRUE
#> 90                     TRUE                  TRUE
#> 91                     TRUE                  TRUE
#> 92                     TRUE                  TRUE
#> 93                     TRUE                  TRUE
#> 94                     TRUE                  TRUE
#> 95                     TRUE                  TRUE
#> 96                     TRUE                  TRUE
#> 97                    FALSE                 FALSE
#> 98                    FALSE                 FALSE
#> 99                     TRUE                  TRUE
#> 100                    TRUE                  TRUE
#> 101                    TRUE                  TRUE
#> 102                    TRUE                  TRUE
#> 103                    TRUE                  TRUE
#> 104                    TRUE                  TRUE
#> 105                    TRUE                  TRUE
#> 106                    TRUE                  TRUE
#> 107                    TRUE                  TRUE
#> 108                    TRUE                  TRUE
#> 109                    TRUE                  TRUE
#> 110                    TRUE                  TRUE
#> 111                    TRUE                  TRUE
#> 112                    TRUE                  TRUE
#> 113                    TRUE                  TRUE
#> 114                    TRUE                  TRUE
#> 115                    TRUE                  TRUE
#> 116                    TRUE                  TRUE
#> 117                    TRUE                  TRUE
#> 118                    TRUE                  TRUE
#> 119                    TRUE                  TRUE
#> 120                    TRUE                  TRUE
#> 121                    TRUE                  TRUE
#> 122                    TRUE                  TRUE
#> 123                    TRUE                  TRUE
#> 124                    TRUE                  TRUE
#> 125                   FALSE                  TRUE
#> 126                    TRUE                  TRUE
#> 127                    TRUE                  TRUE
#> 128                    TRUE                  TRUE
#> 129                    TRUE                  TRUE
#> 130                    TRUE                  TRUE
#> 131                    TRUE                  TRUE
#> 132                    TRUE                  TRUE
#> 133                    TRUE                  TRUE
#> 134                    TRUE                  TRUE
#> 135                    TRUE                  TRUE
#> 136                    TRUE                  TRUE
#> 137                    TRUE                  TRUE
#> 138                    TRUE                  TRUE
#> 139                   FALSE                 FALSE
#> 140                    TRUE                  TRUE
#> 141                    TRUE                  TRUE
#> 142                    TRUE                  TRUE
#> 143                    TRUE                  TRUE
#> 144                    TRUE                  TRUE
#> 145                    TRUE                  TRUE
#> 146                    TRUE                  TRUE
#> 147                    TRUE                  TRUE
#> 148                    TRUE                  TRUE
#> 149                   FALSE                 FALSE
#> 150                    TRUE                  TRUE
#> 151                    TRUE                  TRUE
#> 152                    TRUE                 FALSE
#> 153                    TRUE                  TRUE
#> 154                    TRUE                  TRUE
#> 155                    TRUE                  TRUE
#> 156                    TRUE                  TRUE
#> 157                    TRUE                  TRUE
#> 158                    TRUE                  TRUE
#> 159                    TRUE                  TRUE
#> 160                    TRUE                  TRUE
#> 161                   FALSE                 FALSE
#> 162                    TRUE                  TRUE
#> 163                    TRUE                  TRUE
#> 164                   FALSE                 FALSE
#> 165                    TRUE                  TRUE
#> 166                    TRUE                  TRUE
#> 167                    TRUE                  TRUE
#> 168                    TRUE                  TRUE
#> 169                    TRUE                  TRUE
#> 170                    TRUE                  TRUE
#> 171                    TRUE                  TRUE
#> 172                    TRUE                  TRUE
#> 173                    TRUE                  TRUE
#> 174                   FALSE                 FALSE
#> 175                    TRUE                  TRUE
#> 176                    TRUE                  TRUE
#> 177                    TRUE                  TRUE
#> 178                    TRUE                  TRUE
#> 179                    TRUE                  TRUE
#> 180                    TRUE                  TRUE
#> 181                    TRUE                  TRUE
#> 182                    TRUE                  TRUE
#> 183                    TRUE                  TRUE
#> 184                    TRUE                  TRUE
#> 185                    TRUE                  TRUE
#> 186                    TRUE                  TRUE
#> 187                    TRUE                  TRUE
#> 188                    TRUE                  TRUE
#> 189                    TRUE                  TRUE
#> 190                    TRUE                  TRUE
#> 191                    TRUE                  TRUE
#> 192                    TRUE                  TRUE
#> 193                    TRUE                  TRUE
#> 194                    TRUE                  TRUE
#> 195                    TRUE                  TRUE
#> 196                    TRUE                  TRUE
#> 197                    TRUE                  TRUE
#> 198                    TRUE                  TRUE
#> 199                    TRUE                  TRUE
#> 200                    TRUE                  TRUE
#> 201                   FALSE                 FALSE
#> 202                    TRUE                  TRUE
#> 203                    TRUE                  TRUE
#> 204                    TRUE                  TRUE
#> 205                    TRUE                  TRUE
#> 206                    TRUE                  TRUE
#> 207                    TRUE                  TRUE
#> 208                    TRUE                  TRUE
#> 209                   FALSE                 FALSE
#> 210                    TRUE                  TRUE
#> 211                    TRUE                  TRUE
#> 212                    TRUE                  TRUE
#> 213                    TRUE                  TRUE
#> 214                    TRUE                  TRUE
#> 215                    TRUE                  TRUE
#> 216                   FALSE                 FALSE
#> 217                    TRUE                  TRUE
#> 218                    TRUE                  TRUE
#> 219                    TRUE                  TRUE
#> 220                    TRUE                  TRUE
#> 221                    TRUE                  TRUE
#> 222                    TRUE                  TRUE
#> 223                    TRUE                  TRUE
#> 224                    TRUE                  TRUE
#> 225                    TRUE                  TRUE
#> 226                    TRUE                  TRUE
#> 227                    TRUE                  TRUE
#> 228                    TRUE                  TRUE
#> 229                    TRUE                  TRUE
#> 230                    TRUE                  TRUE
#> 231                   FALSE                 FALSE
#> 232                    TRUE                  TRUE
#> 233                    TRUE                  TRUE
#> 234                    TRUE                  TRUE
#> 235                    TRUE                  TRUE
#> 236                    TRUE                  TRUE
#> 237                    TRUE                  TRUE
#> 238                    TRUE                  TRUE
#> 239                    TRUE                  TRUE
#> 240                    TRUE                  TRUE
#> 241                    TRUE                  TRUE
#> 242                    TRUE                  TRUE
#> 243                    TRUE                 FALSE
#> 244                    TRUE                  TRUE
#> 245                    TRUE                  TRUE
#> 246                   FALSE                 FALSE
#> 247                    TRUE                  TRUE
#> 248                    TRUE                  TRUE
#> 249                    TRUE                  TRUE
#> 250                    TRUE                  TRUE

# View summary statistics
results$summary
#>                  Scenario  combination_id rank Total Diagnosed
#> 1               PTSD_orig            <NA>   NA     232 (92.8%)
#> 2  symptom_6_7_8_11_13_17  6_7_8_11_13_17    1       230 (92%)
#> 3 symptom_6_7_10_11_13_15 6_7_10_11_13_15    2       230 (92%)
#> 4   symptom_4_6_7_8_11_17   4_6_7_8_11_17    3     229 (91.6%)
#>   Total Non-Diagnosed True Positive True Negative Newly Diagnosed
#> 1           18 (7.2%)           232            18               0
#> 2             20 (8%)           229            17               1
#> 3             20 (8%)           229            17               1
#> 4           21 (8.4%)           228            17               1
#>   Newly Non-Diagnosed True Cases False Cases Sensitivity Specificity    PPV
#> 1                   0        250           0      1.0000      1.0000 1.0000
#> 2                   3        246           4      0.9871      0.9444 0.9957
#> 3                   3        246           4      0.9871      0.9444 0.9957
#> 4                   4        245           5      0.9828      0.9444 0.9956
#>      NPV Accuracy Balanced Accuracy
#> 1 1.0000    1.000            1.0000
#> 2 0.8500    0.984            0.9658
#> 3 0.8500    0.984            0.9658
#> 4 0.8095    0.980            0.9636
# }
```
