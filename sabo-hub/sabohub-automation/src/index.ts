import cron from 'node-cron';
import { ReportService } from './services/reportService';

const reportService = new ReportService();

console.log('SaboHub Automation Service started.');
console.log('Scheduled tasks:');
console.log('- Daily Report: 07:00 AM');

// Schedule: 7:00 AM every day
cron.schedule('0 7 * * *', async () => {
  console.log('Running scheduled daily report...');
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  await reportService.generateDailyReport(yesterday);
});

// Handle manual run argument
if (process.argv.includes('--run-now')) {
  console.log('Manual run triggered...');
  const date = new Date();
  // If running manually, maybe we want today or yesterday? 
  // Let's default to yesterday as per the logic, or allow date arg.
  // For now, yesterday.
  date.setDate(date.getDate() - 1);
  reportService.generateDailyReport(date).then(() => {
    console.log('Manual run complete.');
    // Don't exit if we want to keep the cron running, but usually manual run is one-off.
    if (!process.argv.includes('--keep-alive')) {
      process.exit(0);
    }
  });
}
