/**
 * 📚 SABOHUB Documentation Organizer
 * Auto-organize markdown files into _DOCS folder structure
 * Run: node scripts/organize-project-docs.js
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '..');
const DOCS_ROOT = path.join(PROJECT_ROOT, '_DOCS');

// Category definitions with keywords
const CATEGORIES = {
  '01-ARCHITECTURE': {
    keywords: ['architecture', 'auth', 'authentication', 'system', 'structure', 'role-linkage', 'router'],
    patterns: [/^AUTH/, /ARCHITECTURE/, /SYSTEM/, /STRUCTURE/]
  },
  '02-FEATURES': {
    keywords: ['feature', 'complete', 'commission', 'kpi', 'task', 'attendance', 'employee', 'company', 'profile', 'team', 'daily-report', 'recurring', 'cache', 'google-drive'],
    patterns: [/FEATURE/, /COMPLETE$/, /COMMISSION/, /KPI/, /TASK/, /ATTENDANCE/, /EMPLOYEE/, /COMPANY/, /PROFILE/, /TEAM/, /DAILY/, /RECURRING/, /CACHE/, /GOOGLE/]
  },
  '03-OPERATIONS': {
    keywords: ['bugfix', 'fix', 'critical', 'warning', 'cleanup', 'optimization'],
    patterns: [/^BUGFIX/, /^FIX/, /^CRITICAL/, /WARNING/, /CLEANUP/, /OPTIMIZATION/]
  },
  '04-DEPLOYMENT': {
    keywords: ['deployment', 'deploy', 'codemagic', 'app-store', 'ios', 'android', 'env', 'setup'],
    patterns: [/DEPLOYMENT/, /DEPLOY/, /CODEMAGIC/, /APP.?STORE/, /IOS/, /ANDROID/, /ENV/, /SETUP/]
  },
  '05-GUIDES': {
    keywords: ['guide', 'quick-start', 'quickstart', 'how-to', 'readme', 'tutorial', 'manual', 'huong-dan', 'contributing'],
    patterns: [/GUIDE/, /QUICK/, /START/, /HOW.?TO/, /README/, /TUTORIAL/, /HUONG.?DAN/]
  },
  '06-AI': {
    keywords: ['ai', 'assistant', 'openai', 'chatgpt', 'machine-learning'],
    patterns: [/^AI/, /ASSISTANT/, /OPENAI/]
  },
  '07-API': {
    keywords: ['api', 'rpc', 'edge-function', 'supabase', 'backend'],
    patterns: [/API/, /RPC/, /EDGE/, /SUPABASE/, /BACKEND/]
  },
  '08-DATABASE': {
    keywords: ['database', 'schema', 'migration', 'rls', 'table', 'column', 'constraint'],
    patterns: [/DATABASE/, /SCHEMA/, /MIGRATION/, /RLS/, /TABLE/]
  },
  '09-REPORTS': {
    keywords: ['report', 'audit', 'summary', 'status', 'completion', 'test-report', 'qa'],
    patterns: [/REPORT/, /AUDIT/, /SUMMARY/, /STATUS/, /COMPLETION/, /QA/]
  },
  '10-ARCHIVE': {
    keywords: ['old', 'deprecated', 'legacy', 'archive'],
    patterns: [/OLD/, /DEPRECATED/, /LEGACY/]
  }
};

// Ensure directories exist
function ensureDirs() {
  if (!fs.existsSync(DOCS_ROOT)) {
    fs.mkdirSync(DOCS_ROOT, { recursive: true });
  }
  
  Object.keys(CATEGORIES).forEach(cat => {
    const catPath = path.join(DOCS_ROOT, cat);
    if (!fs.existsSync(catPath)) {
      fs.mkdirSync(catPath, { recursive: true });
    }
  });
}

// Determine category for a file
function categorizeFile(filename) {
  const upperName = filename.toUpperCase().replace(/\.MD$/, '');
  
  for (const [category, config] of Object.entries(CATEGORIES)) {
    // Check patterns
    if (config.patterns.some(p => p.test(upperName))) {
      return category;
    }
    // Check keywords
    if (config.keywords.some(k => upperName.toLowerCase().includes(k.toLowerCase()))) {
      return category;
    }
  }
  
  // Default based on content type
  if (upperName.includes('COMPLETE') || upperName.includes('DONE')) {
    return '09-REPORTS';
  }
  
  return '10-ARCHIVE'; // Default to archive
}

// Main organize function
function organizeDocuments() {
  ensureDirs();
  
  const files = fs.readdirSync(PROJECT_ROOT);
  const mdFiles = files.filter(f => f.endsWith('.md') && f !== 'README.md' && f !== 'CHANGELOG.md');
  
  const moves = [];
  const stats = {
    total: mdFiles.length,
    moved: 0,
    skipped: 0,
    byCategory: {}
  };
  
  mdFiles.forEach(file => {
    const sourcePath = path.join(PROJECT_ROOT, file);
    const category = categorizeFile(file);
    const destPath = path.join(DOCS_ROOT, category, file);
    
    // Skip if already exists
    if (fs.existsSync(destPath)) {
      stats.skipped++;
      return;
    }
    
    try {
      fs.renameSync(sourcePath, destPath);
      moves.push({ file, from: sourcePath, to: destPath, category });
      stats.moved++;
      stats.byCategory[category] = (stats.byCategory[category] || 0) + 1;
      console.log(`✅ ${file} → ${category}`);
    } catch (err) {
      console.error(`❌ Failed to move ${file}: ${err.message}`);
    }
  });
  
  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('📊 ORGANIZATION SUMMARY');
  console.log('='.repeat(60));
  console.log(`Total MD files found: ${stats.total}`);
  console.log(`Files moved: ${stats.moved}`);
  console.log(`Files skipped: ${stats.skipped}`);
  console.log('\nBy Category:');
  Object.entries(stats.byCategory)
    .sort((a, b) => b[1] - a[1])
    .forEach(([cat, count]) => {
      console.log(`  ${cat}: ${count}`);
    });
  
  return { moves, stats };
}

// Generate INDEX.md with all documents
function generateIndex() {
  const categories = fs.readdirSync(DOCS_ROOT)
    .filter(d => fs.statSync(path.join(DOCS_ROOT, d)).isDirectory())
    .sort();
  
  let index = `# 📚 SABOHUB Documentation Index\n\n`;
  index += `**Generated:** ${new Date().toISOString()}\n\n`;
  index += `---\n\n`;
  
  categories.forEach(cat => {
    const catPath = path.join(DOCS_ROOT, cat);
    const files = fs.readdirSync(catPath).filter(f => f.endsWith('.md'));
    
    if (files.length === 0) return;
    
    const catName = cat.replace(/^\d+-/, '');
    index += `## 📁 ${catName}\n\n`;
    
    files.sort().forEach(file => {
      const title = file.replace(/\.md$/, '').replace(/-/g, ' ');
      index += `- [${title}](${cat}/${file})\n`;
    });
    
    index += `\n`;
  });
  
  fs.writeFileSync(path.join(DOCS_ROOT, 'INDEX.md'), index);
  console.log('\n✅ INDEX.md generated');
}

// Run
console.log('📚 SABOHUB Documentation Organizer\n');
console.log('Project:', PROJECT_ROOT);
console.log('Docs:', DOCS_ROOT);
console.log('');

organizeDocuments();
generateIndex();

console.log('\n✅ Done!');
