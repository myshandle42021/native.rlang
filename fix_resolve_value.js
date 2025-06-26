const fs = require('fs');

// Read the current file
let content = fs.readFileSync('runtime/step-executor.ts', 'utf8');

// Replace the resolveValue function with a better implementation
const oldFunction = `function resolveValue(value: any, context: RLangContext): any {
  if (value === undefined || value === null) return value;
  if (typeof value === "string" && value.includes("\${")) {
    try {
      return value.replace(/\$\{([^}]+)\}/g, (match, path) => {
        const keys = path.split(".");
        let result: any = context;
        for (const key of keys) {
          result = result?.[key];
        }
        return result ?? match;
      });
    } catch (err) {
      return value;
    }
  }`;

const newFunction = `function resolveValue(value: any, context: RLangContext): any {
  if (value === undefined || value === null) return value;
  if (typeof value === "string" && value.includes("\${")) {
    try {
      // Check if this is a pure variable reference (entire string is just \${variable})
      const pureMatch = value.match(/^\$\{([^}]+)\}$/);
      if (pureMatch) {
        // Pure reference - return the object directly
        const path = pureMatch[1];
        const keys = path.split(".");
        let result: any = context;
        for (const key of keys) {
          result = result?.[key];
        }
        return result ?? value;
      } else {
        // Mixed string - stringify objects in replacements
        return value.replace(/\$\{([^}]+)\}/g, (match, path) => {
          const keys = path.split(".");
          let result: any = context;
          for (const key of keys) {
            result = result?.[key];
          }
          return String(result ?? match);
        });
      }
    } catch (err) {
      return value;
    }
  }`;

content = content.replace(oldFunction, newFunction);
fs.writeFileSync('runtime/step-executor.ts', content);
console.log('Fixed resolveValue function to handle pure object references');
