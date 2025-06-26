import fs from 'fs';

// Read the current file
let content = fs.readFileSync('runtime/step-executor.ts', 'utf8');

// Find and replace the resolveValue function
const functionStart = 'function resolveValue(value: any, context: RLangContext): any {';
const functionEnd = '  }';

// Find the start of the function
const startIndex = content.indexOf(functionStart);
if (startIndex === -1) {
  console.log('Could not find resolveValue function');
  process.exit(1);
}

// Find the end of the function (look for the closing of the if statement)
const searchFrom = startIndex + functionStart.length;
const ifEnd = content.indexOf('  }', searchFrom + content.substring(searchFrom).indexOf('  if (Array.isArray(value))'));
const endIndex = ifEnd + 3; // Include the closing brace

const oldFunction = content.substring(startIndex, endIndex);

const newFunction = `function resolveValue(value: any, context: RLangContext): any {
  if (value === undefined || value === null) return value;
  if (typeof value === "string" && value.includes("\${")) {
    try {
      // Check if this is a pure variable reference (entire string is just \${variable})
      const pureMatch = value.match(/^\\\$\\\{([^}]+)\\\}$/);
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
        return value.replace(/\\\$\\\{([^}]+)\\\}/g, (match, path) => {
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
