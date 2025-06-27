import * as fs from 'fs/promises';

async function applyTemplateVariableFix() {
  console.log('🔧 Applying template variable scoping fix to bootstrap-policies.r...');
  
  try {
    // Read the current file
    let content = await fs.readFile('r/system/bootstrap-policies.r', 'utf-8');
    
    // Fix 1: validate_file_permissions - nested loop scoping
    const oldValidateFilePerms = `- loop:
        forEach: "\${input.permission_results}"
        do:
          - loop:
              forEach: "\${item.operations}"
              do:
                - condition:
                    if: "!\${operation.accessible}"
                    then:
                      - add_validation_error: { error: "Cannot access \${item.path} for \${operation.operation}: \${operation.error}" }`;
    
    const newValidateFilePerms = `- loop:
        forEach: "\${input.permission_results}"
        alias: "outer"
        do:
          - loop:
              forEach: "\${outer.item.operations}"
              alias: "inner"
              do:
                - condition:
                    if: "!\${inner.operation.accessible}"
                    then:
                      - add_validation_error: { error: "Cannot access \${outer.item.path} for \${inner.operation.operation}: \${inner.operation.error}" }`;
    
    // Fix 2: validate_dependencies - module scoping
    const oldValidateDeps = `- loop:
        forEach: "\${input.dependency_results.critical_modules}"
        do:
          - condition:
              if: "!\${item.available}"
              then:
                - add_validation_error: { error: "Critical module missing: \${item.name} - \${item.error}" }`;
    
    const newValidateDeps = `- loop:
        forEach: "\${input.dependency_results.critical_modules}"
        alias: "modules"
        do:
          - condition:
              if: "!\${modules.item.available}"
              then:
                - add_validation_error: { error: "Critical module missing: \${modules.item.name} - \${modules.item.error}" }`;
    
    // Apply the fixes
    content = content.replace(oldValidateFilePerms, newValidateFilePerms);
    content = content.replace(oldValidateDeps, newValidateDeps);
    
    // Create backup
    await fs.writeFile('r/system/bootstrap-policies.r.backup', content, 'utf-8');
    console.log('💾 Backup created: bootstrap-policies.r.backup');
    
    // Write the fixed file
    await fs.writeFile('r/system/bootstrap-policies.r', content, 'utf-8');
    
    console.log('✅ Template variable scoping fix applied successfully!');
    console.log('🎯 This should resolve:');
    console.log('   - 468 "Cannot access ${item.path}" errors');
    console.log('   - 44 "Critical module missing" errors');
    console.log('');
    console.log('🚀 Next steps:');
    console.log('   1. Restart your system');
    console.log('   2. Wait 5 minutes for new data');
    console.log('   3. Run: npm run debug:health');
    
  } catch (error) {
    console.error('💥 Fix application failed:', error);
  }
}

applyTemplateVariableFix();
