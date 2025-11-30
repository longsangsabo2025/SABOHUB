# 🛠️ QUICK DEVELOPMENT GUIDE

## 📋 Table of Contents
- [Scripts](#scripts)
- [VS Code Tasks](#vs-code-tasks)
- [Recommended Extensions](#recommended-extensions)
- [Testing](#testing)
- [Database Setup](#database-setup)
- [Troubleshooting](#troubleshooting)

---

## 🚀 Scripts

### Testing
```bash
# Run all tests
npm test

# Run with coverage
./scripts/test.sh --coverage

# Watch mode
./scripts/test.sh --watch

# Specific test pattern
./scripts/test.sh --pattern "role-utils"

# Verbose output
./scripts/test.sh --verbose
```

### Linting & Type Checking
```bash
# Full check (TypeScript + ESLint)
./scripts/lint.sh

# Auto-fix issues
./scripts/lint.sh --fix

# Skip TypeScript check
./scripts/lint.sh --no-type

# Skip ESLint check
./scripts/lint.sh --no-lint
```

### Database
```bash
# Setup RLS policies
./scripts/db-setup.sh

# Apply migration
supabase db push
```

---

## ⌨️ VS Code Tasks

Press `Ctrl+Shift+B` (Windows/Linux) or `Cmd+Shift+B` (Mac) to see all tasks:

### Testing Tasks
- **🧪 Run All Tests** - Run complete test suite
- **🧪 Run Tests with Coverage** - Generate coverage report
- **👀 Run Tests in Watch Mode** - Auto-rerun on changes

### Code Quality Tasks
- **🔍 TypeScript Check** - Check for type errors
- **✨ ESLint Check** - Check for linting issues
- **🔧 ESLint Fix** - Auto-fix linting issues
- **🎨 Prettier Format** - Format all code

### Development Tasks
- **🚀 Start Expo Dev Server** - Start development server
- **📱 Run on Android** - Launch Android emulator
- **🍎 Run on iOS** - Launch iOS simulator
- **🌐 Run on Web** - Launch web browser

### Database Tasks
- **🔐 Setup Database RLS** - Create RLS policies

### Combo Tasks
- **📊 Full Quality Check** - Run TypeScript + ESLint + Tests

---

## 🔌 Recommended Extensions

### Essential (Auto-install prompted)
- **ESLint** - JavaScript/TypeScript linting
- **Prettier** - Code formatting
- **TypeScript** - Enhanced TypeScript support

### React Native & Expo
- **React Native Tools** - Debugging & IntelliSense
- **Expo Tools** - Expo-specific features
- **ES7+ React Snippets** - Code snippets

### Testing
- **Jest** - Test runner integration
- **Jest Runner** - Run tests from editor

### Database
- **Supabase** - Database management
- **SQLTools** - SQL query execution

### Productivity
- **GitLens** - Git supercharged
- **Error Lens** - Inline error display
- **Path IntelliSense** - Auto-complete paths
- **TODO Tree** - Track TODO comments
- **Code Spell Checker** - Catch typos

### AI Assistance
- **GitHub Copilot** - AI pair programmer
- **GitHub Copilot Chat** - AI assistant

---

## 🧪 Testing

### Test Structure
```
__tests__/
├── role-utils.test.ts         # Role hierarchy tests
├── role-guard.test.tsx        # Component protection tests
└── store-access-middleware.test.ts  # Backend filtering tests
```

### Running Tests

**Single test file:**
```bash
npm test role-utils.test.ts
```

**With coverage:**
```bash
npm test -- --coverage
```

**Debug in VS Code:**
1. Set breakpoint in test file
2. Press `F5` → Select "Debug Jest Tests"

### Writing Tests

**Example test:**
```typescript
import { hasRoleLevel } from '../lib/role-utils';

describe('hasRoleLevel', () => {
  it('should return true for CEO >= MANAGER', () => {
    expect(hasRoleLevel('CEO', 'MANAGER')).toBe(true);
  });
});
```

---

## 🗄️ Database Setup

### Initial Setup
```bash
# 1. Create migration
./scripts/db-setup.sh

# 2. Review generated SQL
cat supabase/migrations/*_rls_policies.sql

# 3. Apply to database
supabase db push

# 4. Verify in Supabase dashboard
```

### Testing RLS Policies
```sql
-- Test as MANAGER
SELECT set_config('request.jwt.claim.role', 'MANAGER', true);
SELECT set_config('request.jwt.claim.store_id', 'your-store-id', true);

-- Should only see own store data
SELECT * FROM stores;
```

---

## 🐛 Troubleshooting

### TypeScript Errors

**Problem:** Type errors after enabling strict mode
```bash
# Check errors
npx tsc --noEmit

# Common fix: Add type annotations
const user: User = { ... }
```

### Jest Not Running

**Problem:** Tests fail to run
```bash
# Clear cache
npm test -- --clearCache

# Reinstall dependencies
rm -rf node_modules
npm install
```

### ESLint Issues

**Problem:** Linting errors
```bash
# Auto-fix
npx eslint . --fix

# Ignore specific line
// eslint-disable-next-line @typescript-eslint/no-explicit-any
```

### Expo Build Issues

**Problem:** Metro bundler errors
```bash
# Clear cache
npx expo start --clear

# Reset completely
rm -rf node_modules .expo .expo-shared
npm install
```

### Database Connection

**Problem:** Cannot connect to Supabase
```bash
# Check .env file
cat .env | grep SUPABASE

# Test connection
supabase projects list
```

---

## 📚 Additional Resources

- [PERMISSIONS.md](./PERMISSIONS.md) - Complete permission matrix
- [ROLE-ARCHITECTURE-EVALUATION.md](./ROLE-ARCHITECTURE-EVALUATION.md) - Role system design
- [PRODUCTION-READINESS-AUDIT.md](./PRODUCTION-READINESS-AUDIT.md) - Production checklist
- [API-REFERENCE.md](./API-REFERENCE.md) - Backend API docs

---

## 🔥 Quick Commands Cheatsheet

```bash
# Development
npm start              # Start Expo
npm run android        # Android emulator
npm run ios            # iOS simulator
npm run web            # Web browser

# Testing
npm test               # Run tests
npm test -- --watch    # Watch mode
npm test -- --coverage # With coverage

# Code Quality
npx tsc --noEmit       # Type check
npx eslint . --fix     # Lint & fix
npx prettier --write . # Format

# Database
./scripts/db-setup.sh  # Setup RLS
supabase db push       # Apply migrations

# Full Check
./scripts/lint.sh && ./scripts/test.sh
```

---

**Pro Tip:** Use VS Code Command Palette (`Ctrl+Shift+P`) → Type "Tasks" → See all available tasks! 🎯
