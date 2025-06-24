// cli/run.ts
// CLI entry point for testing

import { runRLang } from '../runtime/interpreter';

const args = process.argv.slice(2);
const file = args[0] || 'r/main-system.r';
const operation = args[1] || 'genesis';

console.log(`🧪 Running ${file} -> ${operation}`);

runRLang({ file, operation })
  .then(result => {
    console.log('✅ Result:', result);
    process.exit(0);
  })
  .catch(error => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
