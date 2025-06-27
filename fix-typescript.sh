#!/bin/bash
echo "🔧 Applying TypeScript fixes..."

# Fix 1: webhook-handler.ts port issue
sed -i 's/const PORT = process\.env\.PORT || 3001;/const PORT = parseInt(process.env.PORT || "3001", 10);/' server/webhook-handler.ts

# Fix 2: Add input property to RLangContext objects
sed -i 's/return await bootstrap\.getSystemStats({}, {});/return await bootstrap.getSystemStats({}, { agentId: "scan", operation: "stats", input: {}, memory: {}, trace: [], timestamp: new Date().toISOString() });/' complete-system-scan.ts

# Fix 3: Memory property access - add type assertions
sed -i 's/context\.memory\.test === "value"/((context.memory as any).test === "value")/g' complete-system-scan.ts
sed -i 's/testContext\.memory\.test_value/((testContext.memory as any).test_value)/g' test-system.ts
sed -i 's/testContext\.memory\.test_array/((testContext.memory as any).test_array)/g' test-system.ts
sed -i 's/context\.memory\.resolved/((context.memory as any).resolved)/g' test-system.ts
sed -i 's/context\.memory\.count/((context.memory as any).count)/g' test-system.ts

# Fix 4: Error handling
sed -i 's/error\.message/String(error)/g' debug-template-errors.ts
sed -i 's/error\.message/String(error)/g' debug_rocketchat.ts

# Fix 5: rocketchat.ts unknown result
sed -i 's/result\.success/((result as any).success)/g' utils/rocketchat.ts
sed -i 's/result\.message/((result as any).message)/g' utils/rocketchat.ts

echo "✅ TypeScript fixes applied!"
