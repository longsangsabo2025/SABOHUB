/**
 * Quick Test for Gemini AI Integration
 * Run this to verify AI service is working
 */

import { aiService } from './src/services/aiService';

async function testGeminiIntegration() {
  console.log('🧪 Testing Gemini AI Integration...\n');

  // Check provider
  const info = aiService.getProviderInfo();
  console.log('📊 Provider Info:');
  console.log(`   Provider: ${info.provider}`);
  console.log(`   Model: ${info.model}`);
  console.log(`   Status: ${info.status}\n`);

  if (info.provider === 'mock') {
    console.log('⚠️  WARNING: Using mock AI (rule-based)');
    console.log('   Gemini API key not found in environment');
    console.log('   Set VITE_GEMINI_API_KEY in .env file\n');
    return;
  }

  // Test simple chat
  console.log('💬 Testing chat...');
  try {
    const response = await aiService.chat([
      {
        role: 'user',
        content: 'Xin chào! Bạn là ai?',
      },
    ]);

    console.log('✅ Chat Response:');
    console.log(`   ${response.content}`);
    console.log(`   Confidence: ${response.confidence}`);
    if (response.tokens_used) {
      console.log(`   Tokens: ${response.tokens_used}`);
    }
    console.log('\n✅ SUCCESS! Gemini AI is working!\n');
  } catch (error) {
    console.error('❌ Chat Error:', error);
    console.log('\n🔧 Troubleshooting:');
    console.log('   1. Check VITE_GEMINI_API_KEY in .env');
    console.log('   2. Verify API key at: https://aistudio.google.com/');
    console.log('   3. Check API quota and billing');
  }

  // Test company context
  console.log('📊 Testing with company context...');
  try {
    const contextResponse = await aiService.generateInsights({
      tasks: {
        total: 45,
        overdue: 16,
        completed: 10,
        completion_rate: 22,
      },
      team: {
        total: 5,
        active: 4,
      },
      recent_issues: ['16 tasks overdue', 'Low completion rate', 'Team capacity'],
    });

    console.log('✅ Insights Generated:');
    console.log(`   ${contextResponse.content.substring(0, 200)}...`);
    console.log(`   Confidence: ${contextResponse.confidence}\n`);
  } catch (error) {
    console.error('❌ Insights Error:', error);
  }
}

// Run test
testGeminiIntegration().catch(console.error);
