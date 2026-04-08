#!/usr/bin/env python3
"""Fix daysLate scope issue in BFF simulate route"""

f = '/opt/keybuzz/keybuzz-client/app/api/playbooks/[id]/simulate/route.ts'
with open(f, 'r', encoding='utf-8') as fh:
    c = fh.read()

# Fix 1: Add daysLate to SimulateContext interface
old1 = """interface SimulateContext {
  channel?: string;
  orderStatus?: string;
  hasTracking?: boolean;
  orderAmount?: number;
}"""
new1 = """interface SimulateContext {
  channel?: string;
  orderStatus?: string;
  hasTracking?: boolean;
  orderAmount?: number;
  daysLate?: number;
}"""
if old1 in c:
    c = c.replace(old1, new1)
    print("OK: Added daysLate to SimulateContext")
else:
    print("WARN: SimulateContext not found as expected")

# Fix 2: Use context.daysLate instead of bare daysLate
old2 = "actual = Number(daysLate) || 0;"
new2 = "actual = Number(context.daysLate) || 0;"
if old2 in c:
    c = c.replace(old2, new2)
    print("OK: Fixed daysLate reference to context.daysLate")
else:
    print("WARN: daysLate reference not found")

# Fix 3: Pass daysLate in the context object  
old3 = """    const conditionsMatch = evaluateConditions(conditions, {
      channel, orderStatus, hasTracking, orderAmount,
    });"""
new3 = """    const conditionsMatch = evaluateConditions(conditions, {
      channel, orderStatus, hasTracking, orderAmount, daysLate: Number(daysLate) || 0,
    });"""
if old3 in c:
    c = c.replace(old3, new3)
    print("OK: Passed daysLate in evaluateConditions context")
else:
    print("WARN: evaluateConditions call not found as expected")

with open(f, 'w', encoding='utf-8') as fh:
    fh.write(c)
print("DONE")
