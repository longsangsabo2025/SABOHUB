import pool from '../config/db';

export class ReportService {
  async generateDailyReport(date: Date) {
    const client = await pool.connect();
    try {
      const dateStr = date.toISOString().split('T')[0];
      console.log(`Generating report for ${dateStr}...`);

      // 1. Daily Work Reports Stats
      const reportsRes = await client.query(`
        SELECT COUNT(*) as total, SUM(total_hours) as total_hours
        FROM daily_work_reports
        WHERE report_date = $1
      `, [dateStr]);
      const { total: totalReports, total_hours: totalHours } = reportsRes.rows[0];

      // 2. Financial Stats
      const financeRes = await client.query(`
        SELECT type, SUM(amount) as total
        FROM financial_transactions
        WHERE DATE(transaction_date) = $1
        GROUP BY type
      `, [dateStr]);
      
      let revenue = 0;
      let expense = 0;
      financeRes.rows.forEach(row => {
        if (row.type === 'income') revenue = Number(row.total);
        if (row.type === 'expense') expense = Number(row.total);
      });

      // 3. Task Stats
      const tasksRes = await client.query(`
        SELECT status, COUNT(*) as count
        FROM tasks
        WHERE DATE(updated_at) = $1
        GROUP BY status
      `, [dateStr]);
      
      const taskStats = tasksRes.rows.reduce((acc: any, row) => {
        acc[row.status] = row.count;
        return acc;
      }, {});

      // 4. Construct Message
      const message = `
BÁO CÁO TỔNG HỢP NGÀY ${dateStr}

1. NHÂN SỰ:
- Tổng báo cáo: ${totalReports}
- Tổng giờ làm: ${totalHours || 0}

2. TÀI CHÍNH:
- Thu: ${new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(revenue)}
- Chi: ${new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(expense)}
- Lợi nhuận: ${new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(revenue - expense)}

3. CÔNG VIỆC:
- Hoàn thành: ${taskStats['completed'] || 0}
- Đang thực hiện: ${taskStats['in_progress'] || 0}
- Mới: ${taskStats['todo'] || 0}
      `.trim();

      console.log(message);

      // 5. Send Notification to CEO/Managers
      // Find CEOs
      const ceosRes = await client.query(`
        SELECT id FROM employees WHERE role = 'ceo'
      `);
      
      for (const ceo of ceosRes.rows) {
        await client.query(`
          INSERT INTO notifications (user_id, title, message, type, is_read)
          VALUES ($1, $2, $3, $4, $5)
        `, [ceo.id, `Báo cáo tổng hợp ${dateStr}`, message, 'system', false]);
      }

      console.log('Report generated and sent to CEOs.');

    } catch (err) {
      console.error('Error generating report:', err);
    } finally {
      client.release();
    }
  }
}
