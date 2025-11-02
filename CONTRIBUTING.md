# 🤝 Contributing to SABO Hub

Thank you for your interest in contributing! This guide will help you get started.

## 🚀 Quick Start

1. **Fork & Clone**

   ```bash
   git clone https://github.com/YOUR_USERNAME/rork-sabohub-255.git
   cd rork-sabohub-255
   ```

2. **Install Dependencies**

   ```bash
   npm install --legacy-peer-deps
   ```

3. **Start Development**
   ```bash
   npm run dev
   ```

## 🌳 Branching Strategy

### Branch Naming Convention

```
feature/short-description    # New features
fix/short-description        # Bug fixes
refactor/short-description   # Code refactoring
docs/short-description       # Documentation
test/short-description       # Test improvements
chore/short-description      # Maintenance tasks
```

### Examples

- `feature/user-authentication`
- `fix/login-button-crash`
- `refactor/api-client-structure`
- `docs/setup-instructions`

## 📝 Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/). A commit message template is provided in `.gitmessage`.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation
- **style**: Code style/formatting
- **refactor**: Code refactoring
- **test**: Tests
- **chore**: Maintenance
- **perf**: Performance
- **ci**: CI/CD changes

### Examples

```bash
feat(auth): Add JWT token refresh logic

- Implement refresh token endpoint
- Store tokens in AsyncStorage
- Add automatic token refresh

Closes #123
```

```bash
fix(payment): Resolve payment modal crash on Android

The modal was crashing due to missing null check.
Added proper error handling.

Fixes #456
```

## 🔄 Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

- Write clean, readable code
- Follow existing code style
- Add comments for complex logic
- Update tests

### 3. Test Your Changes

```bash
# Type checking
npm run type-check

# Linting
npm run lint

# Tests
npm test

# Or run all at once
npm run validate
```

### 4. Commit Your Changes

```bash
git add .
git commit
# This will open your editor with the commit template
```

### 5. Push to GitHub

```bash
git push origin feature/your-feature-name
```

### 6. Create Pull Request

- Go to GitHub and create a PR
- Fill out the PR template completely
- Wait for CI to pass
- Request review from team members

## ✅ Code Quality Standards

### TypeScript

- Always use TypeScript, not JavaScript
- Define types for all props and state
- Avoid `any` type (use `unknown` if needed)
- Use interfaces for object types

### React/React Native

- Use functional components with hooks
- Keep components small and focused
- Use proper prop types
- Follow React hooks rules

### Code Style

- Use Prettier for formatting (automatic)
- Follow ESLint rules
- Use meaningful variable names
- Add JSDoc comments for complex functions

### Testing

- Write tests for new features
- Maintain test coverage > 80%
- Test edge cases
- Test on iOS, Android, and Web

## 📁 Project Structure

```
├── app/                    # Expo Router screens
│   ├── (auth)/            # Auth screens
│   ├── (core)/            # Core app screens
│   ├── (tabs)/            # Bottom tab screens
│   └── _layout.tsx        # Root layout
├── components/            # Reusable components
├── contexts/              # React contexts
├── hooks/                 # Custom hooks
├── lib/                   # Utilities & helpers
│   ├── trpc.ts           # tRPC client
│   ├── logger.ts         # Logging utility
│   └── supabase.ts       # Supabase client
├── backend/              # Backend code
│   └── trpc/             # tRPC routers
├── types/                # TypeScript types
└── docs/                 # Documentation
```

## 🎨 UI Guidelines

### Components

- Use iOS native design system components from `components/`
- Follow Apple Human Interface Guidelines
- Ensure proper SafeAreaView usage
- Test on different screen sizes

### Colors & Themes

- Use colors from `constants/colors.ts`
- Support light/dark mode (future)
- Use semantic color names

### Typography

- Use typography constants from `constants/typography.ts`
- Maintain consistent font sizes
- Ensure readability

## 🧪 Testing Guidelines

### Unit Tests

- Location: `__tests__/`
- Run: `npm test`
- Coverage: `npm run test:coverage`

### What to Test

- Business logic
- Utilities and helpers
- API calls (mocked)
- Component behavior

### Example

```typescript
import { render, fireEvent } from '@testing-library/react-native';
import { LoginScreen } from '@/app/(auth)/login';

describe('LoginScreen', () => {
  it('shows error on invalid credentials', async () => {
    const { getByText, getByTestId } = render(<LoginScreen />);

    fireEvent.changeText(getByTestId('email-input'), 'invalid@email');
    fireEvent.press(getByText('Login'));

    expect(getByText('Invalid credentials')).toBeTruthy();
  });
});
```

## 📚 Documentation

### When to Update Docs

- Adding new features
- Changing APIs
- Updating dependencies
- Changing workflows

### Where to Document

- Code comments: Complex logic
- JSDoc: Public APIs
- README: Getting started
- `docs/`: Detailed guides

## 🐛 Bug Reports

### Before Reporting

1. Search existing issues
2. Update to latest version
3. Try to reproduce on clean install

### What to Include

- Clear description
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/videos
- Environment details (OS, device, versions)
- Error logs

### Template

```markdown
**Describe the bug**
A clear description of the bug.

**To Reproduce**
Steps to reproduce:

1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What should happen.

**Screenshots**
If applicable.

**Environment**

- OS: [e.g. iOS 16]
- Device: [e.g. iPhone 14]
- App Version: [e.g. 1.0.0]
```

## ✨ Feature Requests

### Before Requesting

1. Check if feature already exists
2. Search existing feature requests
3. Consider if it fits project scope

### What to Include

- Clear use case
- Proposed solution
- Alternative solutions considered
- Mockups/wireframes (if UI)

## 🔐 Security

### Reporting Vulnerabilities

- **DO NOT** open public issues for security issues
- Email: [security contact]
- Include: Description, steps to reproduce, impact

### Security Best Practices

- Never commit secrets/keys
- Use environment variables
- Validate all inputs
- Use HTTPS only
- Follow OWASP guidelines

## 📋 Review Process

### For Authors

1. Ensure CI passes
2. Complete PR template
3. Respond to feedback
4. Keep PR focused and small

### For Reviewers

1. Check code quality
2. Test locally if needed
3. Review tests
4. Check documentation
5. Leave constructive feedback

### Approval Criteria

- ✅ CI passes
- ✅ Code review approved
- ✅ Tests pass
- ✅ Documentation updated
- ✅ No merge conflicts

## 🎯 Best Practices

### Do's ✅

- Write clean, readable code
- Add tests for new features
- Update documentation
- Keep PRs small and focused
- Respond to feedback promptly
- Test on all platforms

### Don'ts ❌

- Don't commit directly to main
- Don't skip tests
- Don't ignore CI failures
- Don't add unnecessary dependencies
- Don't leave TODO comments without issues
- Don't commit sensitive data

## 🆘 Getting Help

### Resources

- [Documentation](./docs/)
- [Learning Resources](./docs/LEARNING-RESOURCES.md)
- [Automation Guide](./docs/AUTOMATION.md)

### Communication

- GitHub Issues: Bug reports, features
- GitHub Discussions: Questions, ideas
- PR Comments: Code-specific questions
- Team Chat: Quick questions

## 🙏 Code of Conduct

Be respectful, inclusive, and professional. We're all here to learn and build great software together!

---

**Thank you for contributing!** 🎉

Every contribution, no matter how small, makes a difference. We appreciate your time and effort!
