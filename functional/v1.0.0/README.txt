Falcon CMS and Switch Test Package
Report version 2.3 dated 21 October 2026
Baseline execution remains 16 October 2026
Reports separated and reformatted on 19 October 2026

SCOPE
The original FALCON-CMS-FUNC-2026-10-16 JMeter run covers W01-W25 of
Falcon CMS API and Events v2 Table 3. Those historical check rows remain:
582 checks, 575 passed, 2 failed and 5 not executed.

Current CMS assessment through 21 October combines several dated runs:
20 PASS, 5 PARTIAL and 0 FAIL within the recorded scenario scope. This
does not represent a single clean latest full-suite execution.

WAIT_FOR_SWITCH_SYNC=true in BOTH complete 20 October reruns. The
06:24 UTC run recorded 1,223 samples and 18 failing samples; the 07:37
UTC PVK/ZPK run recorded 1,314 samples and seven failing samples.
The false setting in the original run is historical 16 October evidence.
The separate focused hot-list run also legitimately used false.

Successful early acknowledgements cover controls, registration,
activation, freeze/release and separate source/successor profiles.
Later Switch wait timeouts remain unresolved: controls 14.10.2,
closed card 18.16.2, registration 19.3.2 and LOST successor 29.5s.2
in the 07:37 run; closure also timed out in the earlier complete run.
Passing earlier fixtures do not supersede these later failures.

W04 lists 18 passing checks including nine later PVK/ZPK checks.
W14 lists 27 including the earlier successful acknowledgement. W17
lists 12 including positive operations/cardholder hot-list evidence
and verified 422 business refusals. W19 includes the successful
20 October rerun of S-0501 (44/44 listed checks). W15 lists nine
passing rows plus one unexecuted authorisation case; the focused
limit run used the Accounting stub and confirmed Switch revision 7.
Live Accounting integration remains unverified.

On 21 October, the W23 correction flushes the prior BIN assignment's
VERIFY_ONLY update before activating its successor in the same transaction.
S-1094 and S-1095 passed; S-1096 issuance confirmed and its new card uses
the successor CVK. S-1097 confirmed that the historical card retained its
original key reference. W23 has 11/11 listed checks passed, and F-01 is
closed. Seven focused regression tests passed, including five against
PostgreSQL for initial activation, repeated rotation, scheduled activation,
reactivation and rollback after a successor database failure.

W15, W16, W19, W23 and W25 remain PARTIAL due to a known test-bed
limitation: the NPCI simulator uses a different transaction card, so final
authorisation on the CMS scenario cards cannot be validated. W16 also
lacks successful PIN selection, change and reset coverage; W25's PIN
leg covers validation only. Tenant isolation remains unproven because
the probe used a platform-scoped client. Original
baseline totals and samples remain historical evidence; dated rerun
results are reflected in the report and the separate verification files.

The package now includes the subsequent NPCI simulator transactions
from the supplied Switch log at 20:24-20:30 IST on 16 October 2026.
Seven attempts across six RRNs comprise three purchases, three
pre-authorisations and one full-amount reversal. Six saved responses
are 00 and one is 30. The eight transaction register rows include a
0430 reversal helper row, which is not another simulator request.

TABLE 3 SCENARIOS
The Switch report, Section 1, retains the latest simulator evidence and adds one selected older
example for each identifiable kind. Older examples cover W26, W30, W32,
W33, W34, W35, W36, W37 and W39. W35 has one wrong-PIN and one limit
decline example. All remain PARTIAL; the older cancellation response is 96.
W27, W28, W29, W38 and W40-W43 remain headings. The Switch report, Section 2, contains
one unassigned contactless candidate and one related network PIN change.
The original W01-W25 JMeter results and latest seven simulator attempts
remain unchanged. The complete historical transaction inventory is excluded.

CONTENTS
Falcon_CMS_Scenario_Test_Report.pdf       CMS scenario report.
Falcon_CMS_Scenario_Test_Report.docx      CMS report, editable.
Falcon_Switch_Test_Report.pdf             Switch transaction report.
Falcon_Switch_Test_Report.docx            Switch report, editable.
Falcon_CMS_Test_Data_and_Evidence.json    Combined CMS, NPCI and historical
                                        evidence. Historical check rows remain.
jmeter/CMS_V2_LIFECYCLE_FUNCTIONAL.jmx   Original 16 October baseline plan.
jmeter/runtime.properties.example       Original sanitized settings.
results/samples.csv                     Original executed samples.
results/switch-sync-verification-2026-10-20.json
                                        Sanitized 20 October Switch-wait
                                        checkpoints. No request bodies.
results/pvk-zpk-verification-2026-10-20.json
                                        Sanitized PVK and ZPK assignment
                                        rerun. No request bodies.
results/w17-hotlist-verification-2026-10-20.json
                                        Sanitized hot-list rerun. No request
                                        bodies or tokens.
results/w15-limit-verification-2026-10-21.json
                                        Sanitized W15 limit rerun. No request
                                        bodies or tokens.
results/w23-rotation-verification-2026-10-21.json
                                        Sanitized W23 correction rerun
                                        and focused regression results.
results/report-current-assessment-2026-10-21.json
                                        Current consolidated CMS assessment,
                                        open items and report reference index.
npci/transactions.csv                   Seven-attempt summary.
npci/database-evidence.json             All eight sanitized transaction
                                        rows and seven saved responses;
                                        scoped related-table results.
npci/database-query-audit.json           Read-only queries and times.
npci/switch-log-analysis.json            Parsed requests, responses,
                                        EMV validation and log evidence.
npci/switch-log.redacted.txt             Numbered redacted source log.
npci/log-db-correlation-review.json      Independent ID and code checks.
history/selected-examples.json          Twelve selected older examples.
history/selected-examples.csv           Index of the selected examples.
SHA256SUMS.txt                          Hashes of all package files
                                        except the manifest itself.

Historical request fields and saved responses use field-by-field tables
in the Switch report. Per-testcase database rows and sections are omitted
from that report; the original evidence remains in the companion files.

HOW TO FIND THE DATA
Original CMS checks remain under sections.<scenario>.checks[].
Current document metadata, scenario assessments, dated references and
remaining integration/coverage items are under current_assessment.
The baseline document metadata is retained separately. W23 verification
combines initial state checks with resumed issuance; its timing window
and original attempt identifiers are explicit.
The simulator analysis is under npci_simulator_run.attempts[].
Search by RRN or stable attempt ID NPCI-001 through NPCI-007.
Each attempt contains request_data, response_data, accounting,
database_details, complete database_records and log_evidence.
Original purchase and reversal share RRN 628920767460; distinguish
them by MTI, STAN and the separate transaction identifiers.
npci_simulator_run retains the original seven-attempt analysis. The older
selected examples are under historical_switch_examples.selected_examples.
Combined scenario links are in sections.<scenario>.historical_example_ids.

DATABASE SOURCE AND PAYLOAD LIMITS
The logged remote database 192.168.158.36:5432/lpsswitch timed out.
Read-only extraction used local PostgreSQL 127.0.0.1:5432/lpsswitch,
which has exact RRN, register ID, ISO transaction ID and timestamp
matches. The relationship between the endpoints was not established.
Queries used read-only transactions and ended with ROLLBACK.
No database records were changed.

All ordinary available stored fields are included with sensitive
data redacted. The pasted log contains selected ISO and accounting
fields. The saved response_message values are empty. Complete
original wire payloads and accounting HTTP bodies are unavailable
and have not been reconstructed as if they were original messages.
Eight scoped CMS event/payload tables and three clearing tables
contained no matching RRN records; this does not establish absence
from every possible system. Accounting holds, settled postings and
before-and-after balances were not independently verified.

OBSERVATIONS TO REVIEW
NPCI-O01: RRN 628920767460 has saved reversal response 0430/00, but
         the primary 0420 and helper 0430 rows are FAILED. The log
         approves in application mode. Hold release is unverified.
NPCI-O02: RRN 628920020523 has saved response 0110/30 for missing
         mandatory EMV tag 9F02, but its transaction remains PENDING.
NPCI-O04: The decline notification to CMS returns HTTP 401.

DATA PROTECTION
The original CMS test data and new simulator evidence retain their
separate provenance. Full PANs are masked. Bearer tokens, credentials,
PIN blocks, track data, raw ISO bytes and cryptographic material are
omitted or redacted. RRNs, STANs, transaction and merchant identifiers,
amounts and DE90 linkage are retained.

REPRODUCING THE ORIGINAL CMS RUN
Supply test environment URLs and credentials in runtime properties:
jmeter -n -t jmeter/CMS_V2_LIFECYCLE_FUNCTIONAL.jmx -q <runtime.properties> -l results.jtl
The simulator transactions were observed from the supplied log and
database evidence; no new transactions were fired during this update.

OLDER EXAMPLES
The historical_switch_examples section in the companion JSON contains
12 distinct selected records, including two separate W35 decline kinds,
one related PIN change and one unresolved contactless candidate. Each
selected record retains safe stored request/response fields and available
reversal linkage. Counts describe the audited history, not newly fired
transactions or full scenario passes. No full historical inventory is added.
