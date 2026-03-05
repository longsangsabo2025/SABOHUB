content = open('docs/PROGRESS.md', encoding='utf-8').read()
content = content.replace('- [ ] P5: AppColors adoption', '- [x] P5: AppColors adoption')
content = content.replace('- [ ] **TODO P5**: AppColors adoption', '- [x] **TODO P5**: AppColors adoption')
open('docs/PROGRESS.md', 'w', encoding='utf-8').write(content)
