import { NextResponse } from "next/server";
import { queryMany } from "@/lib/db";
import { format, subMonths, subDays, startOfDay } from "date-fns";
import { pl } from "date-fns/locale";

type MonthlyRevenue = { month: string; revenue: number };
type DailyRevenue = { date: string; revenue: number };
type PaymentMethod = { name: string; value: number };
type StatusDistribution = { name: string; value: number };

export async function GET() {
  try {
    // Monthly revenue for last 12 months
    const monthlyRevenue = await queryMany<MonthlyRevenue>(
      `SELECT 
        TO_CHAR(issue_date, 'YYYY-MM') as month,
        COALESCE(SUM(total_amount), 0) as revenue
       FROM invoices
       WHERE status = 'paid' 
         AND issue_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12 months')
       GROUP BY TO_CHAR(issue_date, 'YYYY-MM')
       ORDER BY month`
    );

    // Daily revenue for last 30 days
    const dailyRevenue = await queryMany<DailyRevenue>(
      `SELECT 
        DATE(paid_at) as date,
        COALESCE(SUM(amount), 0) as revenue
       FROM payments
       WHERE paid_at >= CURRENT_DATE - INTERVAL '30 days'
       GROUP BY DATE(paid_at)
       ORDER BY date`
    );

    // Payment methods distribution
    const paymentMethods = await queryMany<PaymentMethod>(
      `SELECT 
        payment_method as name,
        COALESCE(SUM(amount), 0) as value
       FROM payments
       WHERE payment_date >= DATE_TRUNC('month', CURRENT_DATE)
       GROUP BY payment_method
       ORDER BY value DESC`
    );

    // Invoice status distribution
    const statusDistribution = await queryMany<StatusDistribution>(
      `SELECT 
        CASE 
          WHEN status = 'paid' THEN 'Opłacone'
          WHEN status = 'sent' THEN 'Wysłane'
          WHEN status = 'draft' THEN 'Szkice'
          WHEN status = 'overdue' THEN 'Przeterminowane'
          ELSE status
        END as name,
        COUNT(*) as value
       FROM invoices
       GROUP BY status
       ORDER BY value DESC`
    );

    // Format monthly data
    const formattedMonthly = monthlyRevenue.map((item: MonthlyRevenue) => ({
      month: format(new Date(`${item.month}-01`), "MMM yyyy", { locale: pl }),
      revenue: parseFloat(item.revenue.toString()),
    }));

    // Format daily data
    const formattedDaily = dailyRevenue.map((item: DailyRevenue) => ({
      date: format(new Date(item.date), "d MMM", { locale: pl }),
      revenue: parseFloat(item.revenue.toString()),
    }));

    // Format payment methods
    const formattedPaymentMethods = paymentMethods.map((item: PaymentMethod) => ({
      name: item.name === "cash" ? "Gotówka" : item.name === "card" ? "Karta" : item.name === "transfer" ? "Przelew" : item.name,
      value: parseFloat(item.value.toString()),
    }));

    return NextResponse.json({
      monthlyRevenue: formattedMonthly,
      dailyRevenue: formattedDaily,
      paymentMethods: formattedPaymentMethods,
      statusDistribution: statusDistribution.map((item: StatusDistribution) => ({
        name: item.name,
        value: parseInt(item.value.toString()),
      })),
    });
  } catch (error) {
    console.error("Error fetching chart data:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}

