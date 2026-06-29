# PH-SAAS-T8.12AS.21.208 - corrected pricing verification

Date UTC: 2026-06-29T05:01:17Z


=== contract explanation ===
The previous raw HTML marker check counted embedded Next error-boundary strings.
This corrected pass uses positive route contracts: HTTP 200, pricing title/copy, plan prices, CTA links, prod URLs, no dev URLs, no old prices, no business conversion trigger strings.

=== pricing contract repeated ===
contract_ok=100
contract_bad=0

=== all public route status ===
https://www.keybuzz.pro/pricing http=200 time=0.149175 size=71917 effective=https://www.keybuzz.pro/pricing
https://keybuzz.pro/pricing http=200 time=0.184382 size=71917 effective=https://keybuzz.pro/pricing
https://www.keybuzz.pro/ http=200 time=0.146440 size=84128 effective=https://www.keybuzz.pro/
https://www.keybuzz.pro/features http=200 time=0.161295 size=64453 effective=https://www.keybuzz.pro/features
https://www.keybuzz.pro/contact http=200 time=0.135473 size=28364 effective=https://www.keybuzz.pro/contact
https://www.keybuzz.pro/amazon http=200 time=0.135586 size=47077 effective=https://www.keybuzz.pro/amazon
https://www.keybuzz.pro/privacy http=200 time=0.138899 size=57152 effective=https://www.keybuzz.pro/privacy
https://www.keybuzz.pro/cookies http=200 time=0.130354 size=46105 effective=https://www.keybuzz.pro/cookies
https://www.keybuzz.pro/terms http=200 time=0.149681 size=60147 effective=https://www.keybuzz.pro/terms
https://www.keybuzz.pro/sla http=200 time=0.148770 size=53289 effective=https://www.keybuzz.pro/sla

=== rsc burst ===
duration_sec=3.585
status_counts={'200': 300}
slow_or_errors=[]

=== log counts since 30m ===
keybuzz_503_count=0
pricing_503_count=0
latest_pricing_lines=
10.0.0.5 - - [29/Jun/2026:05:01:39 +0000] "GET /pricing?_rsc=ph21208b276 HTTP/2.0" 200 71917 "-" "curl/8.5.0" 48 0.138 [keybuzz-website-prod-keybuzz-website-80] [] 10.244.36.231:3000 71917 0.138 200 10014377393808776e8616a23655fd8c
10.0.0.5 - - [29/Jun/2026:05:01:40 +0000] "GET /pricing?_rsc=ph21208b282 HTTP/2.0" 200 71917 "-" "curl/8.5.0" 48 0.260 [keybuzz-website-prod-keybuzz-website-80] [] 10.244.118.67:3000 71917 0.260 200 2e0d6b9a075b987dd06ef0d23c09fbe5
10.0.0.6 - - [29/Jun/2026:05:01:40 +0000] "GET /pricing?_rsc=ph21208b126 HTTP/2.0" 200 71917 "-" "curl/8.5.0" 48 2.137 [keybuzz-website-prod-keybuzz-website-80] [] 10.244.36.231:3000 71917 2.137 200 871ed85641c68f77b694a9ad35a3639f
10.0.0.6 - - [29/Jun/2026:05:01:40 +0000] "GET /pricing?_rsc=ph21208b168 HTTP/2.0" 200 71917 "-" "curl/8.5.0" 48 1.883 [keybuzz-website-prod-keybuzz-website-80] [] 10.244.36.231:3000 71917 1.883 200 41f0bd8bf367fca6bf4e70481cbb0dbf
10.0.0.5 - - [29/Jun/2026:05:01:40 +0000] "GET /pricing?_rsc=ph21208b204 HTTP/2.0" 200 71917 "-" "curl/8.5.0" 48 1.758 [keybuzz-website-prod-keybuzz-website-80] [] 10.244.36.231:3000 71917 1.758 200 16741a7dbc2d18e16c90da7ef49f0e8f
10.0.0.5 - - [29/Jun/2026:05:01:40 +0000] "GET /pricing?_rsc=ph21208b270 HTTP/2.0" 200 71917 "-" "curl/8.5.0" 48 0.959 [keybuzz-website-prod-keybuzz-website-80] [] 10.244.36.231:3000 71917 0.959 200 f32e1ff4a18f54e8cf5cc81e5e107841
10.0.0.5 - - [29/Jun/2026:05:01:39 +0000] "GET /pricing?_rsc=ph21208b264 HTTP/2.0" 200 71917 "-" "curl/8.5.0" 48 0.014 [keybuzz-website-prod-keybuzz-website-80] [] 10.244.118.67:3000 71917 0.014 200 962a0b8f3b14fbe7b30967a5335efeb5
10.0.0.6 - - [29/Jun/2026:05:01:39 +0000] "GET /pricing?_rsc=ph21208b240 HTTP/2.0" 200 71917 "-" "curl/8.5.0" 48 0.587 [keybuzz-website-prod-keybuzz-website-80] [] 10.244.36.231:3000 71917 0.588 200 6286ac01518cbf4d17214d52765d2d2b
10.0.0.6 - - [29/Jun/2026:05:01:40 +0000] "GET /pricing?_rsc=ph21208b294 HTTP/2.0" 200 71917 "-" "curl/8.5.0" 48 0.254 [keybuzz-website-prod-keybuzz-website-80] [] 10.244.118.67:3000 71917 0.254 200 df4d5a4bac4ddb687575d590ad3ca97a
10.0.0.6 - - [29/Jun/2026:05:01:40 +0000] "GET /pricing?_rsc=ph21208b180 HTTP/2.0" 200 71917 "-" "curl/8.5.0" 48 1.940 [keybuzz-website-prod-keybuzz-website-80] [] 10.244.36.231:3000 71917 1.940 200 2511c7ade4bf50bc7867f0f7f4618829
10.0.0.6 - - [29/Jun/2026:05:01:40 +0000] "GET /pricing?_rsc=ph21208b210 HTTP/2.0" 200 71917 "-" "curl/8.5.0" 48 1.699 [keybuzz-website-prod-keybuzz-website-80] [] 10.244.118.67:3000 71917 1.699 200 e4747f2320eea10bc8ddd09f893f073d
10.0.0.6 - - [29/Jun/2026:05:01:40 +0000] "GET /pricing?_rsc=ph21208b228 HTTP/2.0" 200 71917 "-" "curl/8.5.0" 48 1.575 [keybuzz-website-prod-keybuzz-website-80] [] 10.244.118.67:3000 71917 1.575 200 a9d19cfb1356d00b22546eac4712ba98
10.0.0.6 - - [29/Jun/2026:05:01:40 +0000] "GET /pricing?_rsc=ph21208b252 HTTP/2.0" 200 71917 "-" "curl/8.5.0" 48 1.205 [keybuzz-website-prod-keybuzz-website-80] [] 10.244.118.67:3000 71917 1.205 200 b90179038f85363fbfd5014a0c8b9143

=== website logs since 30m ===
--- pod=keybuzz-website-744b68df4d-c48xb ---
--- pod=keybuzz-website-744b68df4d-lrjz5 ---

=== runtime summary ===
keybuzz-website-744b68df4d-c48xb|ghcr.io/keybuzzio/keybuzz-website@sha256:81adb5e2325953692c86fed3d15eae84882b5b4c78fd4fda0e666d3b1a856c35|ready=true|restarts=0
keybuzz-website-744b68df4d-lrjz5|ghcr.io/keybuzzio/keybuzz-website@sha256:81adb5e2325953692c86fed3d15eae84882b5b4c78fd4fda0e666d3b1a856c35|ready=true|restarts=0
infra_head=e534ba1721703a3ee10d6ef0a8b34253c1e1bce0
infra_origin=e534ba1721703a3ee10d6ef0a8b34253c1e1bce0
infra_ab=0	0
infra_dirty=0

=== verdict ===
CORRECTED_VERIFY_DONE
report=/tmp/PH-SAAS-T8.12AS.21.208_CORRECTED_VERIFY.md
