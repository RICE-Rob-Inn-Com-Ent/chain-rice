import { getCurrentUser } from "@/lib/auth";
import { query } from "@/lib/db";
import { getRoleFromId } from "@/lib/user-id-generator";
import Link from "next/link";
import { Plus, DollarSign, FileText, TrendingUp, Calendar, Calculator } from "lucide-react";
import AccountingCharts from "./charts";
import AIWorkflow from "@/app/admin/components/AIWorkflow";

type Invoice = {
  id: string;
  invoice_number: string;
  issue_date: Date;
  due_date: Date;
  total_amount: string;
  status: string;
  patient_first_name: string;
  patient_last_name: string;
};

type Employee = {
  id: string;
  display_name: string;
  email: string;
  employment_type: string | null;
  employment_status: string | null;
  salary_type: string | null;
  hourly_rate: string | null;
  monthly_salary: string | null;
  hire_date: Date | null;
  department: string | null;
  position: string | null;
  roles: string[];
};

export default async function AccountingPage() {
  const user = await getCurrentUser();

  // Fetch accounting statistics
  const [monthlyRevenueResult, totalInvoicesResult, paidInvoicesResult, overdueInvoicesResult] = await Promise.all([
    query<{ total: string }>(
      `SELECT COALESCE(SUM(total_amount), 0) as total 
       FROM invoices 
       WHERE status = 'paid' AND issue_date >= DATE_TRUNC('month', CURRENT_DATE)`
    ),
    query<{ count: string }>(`SELECT COUNT(*) as count FROM invoices`),
    query<{ count: string }>(`SELECT COUNT(*) as count FROM invoices WHERE status = 'paid'`),
    query<{ count: string }>(`SELECT COUNT(*) as count FROM invoices WHERE status = 'overdue'`),
  ]);
  
  const monthlyRevenue = monthlyRevenueResult.rows[0]?.total || "0";
  const totalInvoices = totalInvoicesResult.rows[0]?.count || "0";
  const paidInvoices = paidInvoicesResult.rows[0]?.count || "0";
  const overdueInvoices = overdueInvoicesResult.rows[0]?.count || "0";

  const [invoicesResult, employeesResult] = await Promise.all([
    query<Invoice>(
      `SELECT 
        i.id, i.invoice_number, i.issue_date, i.due_date, 
        i.total_amount, i.status,
        p.first_name as patient_first_name, p.last_name as patient_last_name
       FROM invoices i
       JOIN users p ON i.patient_id::text = p.id
       ORDER BY i.issue_date DESC
       LIMIT 50`
    ),
    query<Employee>(
      `SELECT 
        u.id,
        u.display_name,
        u.email,
        get_user_text_field(u.id, 'employment_type') as employment_type,
        get_user_text_field(u.id, 'employment_status') as employment_status,
        get_user_text_field(u.id, 'salary_type') as salary_type,
        get_user_text_field(u.id, 'hourly_rate') as hourly_rate,
        get_user_text_field(u.id, 'monthly_salary') as monthly_salary,
        get_user_text_field(u.id, 'hire_date')::timestamp as hire_date,
        get_user_text_field(u.id, 'department') as department,
        get_user_text_field(u.id, 'position') as position
       FROM users u
       WHERE u.id::text LIKE 'ADM-%' OR u.id::text LIKE 'SUP-%' OR u.id::text LIKE 'DOC-%'`
    ),
  ]);
  
  const invoices = invoicesResult.rows || [];
  const employees = employeesResult.rows.map((emp: any) => ({
    ...emp,
    roles: [getRoleFromId(emp.id) || 'user']
  })) || [];
  const activeEmployees = employees.filter((employee: Employee) => employee.employment_status !== "terminated").length;
  const monthlyPayrollCost = employees.reduce((total: number, employee: Employee) => {
    if (employee.salary_type === "monthly" && employee.monthly_salary) {
      return total + parseFloat(employee.monthly_salary);
    }
    if (employee.salary_type === "hourly" && employee.hourly_rate) {
      return total + parseFloat(employee.hourly_rate) * 160; // przybliżenie 160h
    }
    return total;
  }, 0);

  const statusColors: Record<string, string> = {
    draft: "bg-gray-500/20 text-gray-400",
    sent: "bg-blue-500/20 text-blue-400",
    paid: "bg-green-500/20 text-green-400",
    overdue: "bg-red-500/20 text-red-400",
    cancelled: "bg-orange-500/20 text-orange-400",
  };

  return (
    <div>
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="font-display text-4xl text-ivory-100">Księgowość</h1>
          <p className="mt-2 text-ivory-100/70">Zarządzaj fakturami i płatnościami</p>
        </div>
        <Link
          href={`/${user.username}/ksiegowosc/nowa-faktura`}
          className="flex items-center gap-2 rounded-lg bg-ember-500 px-4 py-2 font-semibold text-white transition hover:bg-ember-600"
        >
          <Plus className="h-5 w-5" />
          <span>Nowa faktura</span>
        </Link>
      </div>

      {/* Statistics */}
      <div className="mb-8 grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <div className="marble-card p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-ivory-100/60">Przychód (miesiąc)</p>
              <p className="mt-2 text-2xl font-bold text-ivory-100">
                {parseFloat(monthlyRevenue || "0").toLocaleString("pl-PL", {
                  style: "currency",
                  currency: "PLN",
                })}
              </p>
            </div>
            <div className="rounded-full bg-green-500/20 p-3">
              <TrendingUp className="h-6 w-6 text-green-400" />
            </div>
          </div>
        </div>
        <div className="marble-card p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-ivory-100/60">Wszystkie faktury</p>
              <p className="mt-2 text-2xl font-bold text-ivory-100">{totalInvoices || "0"}</p>
            </div>
            <div className="rounded-full bg-blue-500/20 p-3">
              <FileText className="h-6 w-6 text-blue-400" />
            </div>
          </div>
        </div>
        <div className="marble-card p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-ivory-100/60">Opłacone</p>
              <p className="mt-2 text-2xl font-bold text-ivory-100">{paidInvoices || "0"}</p>
            </div>
            <div className="rounded-full bg-green-500/20 p-3">
              <DollarSign className="h-6 w-6 text-green-400" />
            </div>
          </div>
        </div>
        <div className="marble-card p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-ivory-100/60">Przeterminowane</p>
              <p className="mt-2 text-2xl font-bold text-ivory-100">{overdueInvoices || "0"}</p>
            </div>
            <div className="rounded-full bg-red-500/20 p-3">
              <Calendar className="h-6 w-6 text-red-400" />
            </div>
          </div>
        </div>
      </div>

      {/* Charts */}
      <AccountingCharts />

      {/* Invoices table */}
      <div className="marble-card p-6">
        <h2 className="mb-4 text-xl font-semibold text-ivory-100">Faktury</h2>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-white/10">
                <th className="px-4 py-3 text-left text-sm font-semibold text-ivory-100/60">Numer faktury</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-ivory-100/60">Pacjent</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-ivory-100/60">Data wystawienia</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-ivory-100/60">Termin płatności</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-ivory-100/60">Kwota</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-ivory-100/60">Status</th>
                <th className="px-4 py-3 text-right text-sm font-semibold text-ivory-100/60">Akcje</th>
              </tr>
            </thead>
            <tbody>
              {invoices.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-4 py-8 text-center text-ivory-100/60">
                    Brak faktur
                  </td>
                </tr>
              ) : (
                invoices.map((invoice: Invoice) => (
                  <tr key={invoice.id} className="border-b border-white/5 hover:bg-white/5">
                    <td className="px-4 py-3 text-sm font-medium text-ivory-100">{invoice.invoice_number}</td>
                    <td className="px-4 py-3 text-sm text-ivory-100">
                      {invoice.patient_first_name} {invoice.patient_last_name}
                    </td>
                    <td className="px-4 py-3 text-sm text-ivory-100/70">
                      {new Date(invoice.issue_date).toLocaleDateString("pl-PL")}
                    </td>
                    <td className="px-4 py-3 text-sm text-ivory-100/70">
                      {new Date(invoice.due_date).toLocaleDateString("pl-PL")}
                    </td>
                    <td className="px-4 py-3 text-sm font-semibold text-ivory-100">
                      {parseFloat(invoice.total_amount).toLocaleString("pl-PL", {
                        style: "currency",
                        currency: "PLN",
                      })}
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`rounded-full px-2 py-1 text-xs font-medium ${
                          statusColors[invoice.status] || "bg-gray-500/20 text-gray-400"
                        }`}
                      >
                        {invoice.status === "draft"
                          ? "Szkic"
                          : invoice.status === "sent"
                          ? "Wysłana"
                          : invoice.status === "paid"
                          ? "Opłacona"
                          : invoice.status === "overdue"
                          ? "Przeterminowana"
                          : invoice.status === "cancelled"
                          ? "Anulowana"
                          : invoice.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <Link
                        href={`/${user.username}/ksiegowosc/faktury/${invoice.id}`}
                        className="text-sm text-ember-400 hover:text-ember-300"
                      >
                        Szczegóły
                      </Link>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Payroll section */}
      <div className="mt-8">
        <div className="mb-6">
          <h2 className="font-display text-3xl text-ivory-100">Kadry i płace</h2>
          <p className="mt-2 text-ivory-100/70">Status kadry medycznej oraz administracyjnej</p>
        </div>

        <div className="mb-6 grid gap-6 md:grid-cols-3">
          <div className="marble-card p-6">
            <p className="text-sm text-ivory-100/60">Aktywni pracownicy</p>
            <p className="mt-2 text-3xl font-bold text-ivory-100">{activeEmployees}</p>
          </div>
          <div className="marble-card p-6">
            <p className="text-sm text-ivory-100/60">Planowany koszt (miesiąc)</p>
            <p className="mt-2 text-3xl font-bold text-ivory-100">
              {monthlyPayrollCost.toLocaleString("pl-PL", {
                style: "currency",
                currency: "PLN",
              })}
            </p>
          </div>
          <div className="marble-card p-6">
            <p className="text-sm text-ivory-100/60">Średni koszt / pracownika</p>
            <p className="mt-2 text-3xl font-bold text-ivory-100">
              {activeEmployees > 0
                ? (monthlyPayrollCost / activeEmployees).toLocaleString("pl-PL", {
                    style: "currency",
                    currency: "PLN",
                  })
                : "0,00 zł"}
            </p>
          </div>
        </div>

        <div className="marble-card p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-xl font-semibold text-ivory-100">Lista pracowników</h3>
            <p className="text-sm text-ivory-100/60">{employees.length} osób</p>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/10">
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-ivory-100/60">
                    Pracownik
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-ivory-100/60">
                    Dział
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-ivory-100/60">
                    Typ zatrudnienia
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-ivory-100/60">
                    Wynagrodzenie
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-ivory-100/60">
                    Status
                  </th>
                </tr>
              </thead>
              <tbody>
                {employees.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-4 py-8 text-center text-ivory-100/60">
                      Brak danych kadrowych
                    </td>
                  </tr>
                ) : (
                  employees.map((employee: Employee) => {
                    const salaryLabel =
                      employee.salary_type === "monthly" && employee.monthly_salary
                        ? `${parseFloat(employee.monthly_salary).toLocaleString("pl-PL", {
                            style: "currency",
                            currency: "PLN",
                          })} / mies.`
                        : employee.salary_type === "hourly" && employee.hourly_rate
                        ? `${parseFloat(employee.hourly_rate).toLocaleString("pl-PL", {
                            style: "currency",
                            currency: "PLN",
                          })} / h`
                        : "Brak danych";

                    const roleLabel =
                      employee.roles.includes("owner")
                        ? "Właściciel"
                        : employee.roles.includes("admin")
                        ? "Administrator"
                        : employee.roles.includes("doctor") || employee.roles.includes("dentist")
                        ? "Lekarz"
                        : "Pracownik";

                    return (
                      <tr key={employee.id} className="border-b border-white/5 hover:bg-white/5">
                        <td className="px-4 py-3 text-sm text-ivory-100">
                          <div className="font-semibold">{employee.display_name}</div>
                          <div className="text-xs text-ivory-100/60">{employee.email}</div>
                          <div className="text-xs text-ivory-100/60">{roleLabel}</div>
                        </td>
                        <td className="px-4 py-3 text-sm text-ivory-100/70">
                          <div>{employee.department || "—"}</div>
                          <div className="text-xs text-ivory-100/50">{employee.position || "—"}</div>
                        </td>
                        <td className="px-4 py-3 text-sm text-ivory-100/70">
                          {employee.employment_type || "—"}
                        </td>
                        <td className="px-4 py-3 text-sm text-ivory-100">{salaryLabel}</td>
                        <td className="px-4 py-3 text-sm">
                          <span
                            className={`rounded-full px-2 py-1 text-xs font-medium ${
                              employee.employment_status === "terminated"
                                ? "bg-red-500/20 text-red-400"
                                : employee.employment_status === "on_leave"
                                ? "bg-yellow-500/20 text-yellow-400"
                                : "bg-green-500/20 text-green-400"
                            }`}
                          >
                            {employee.employment_status === "terminated"
                              ? "Zakończony"
                              : employee.employment_status === "on_leave"
                              ? "Urlop"
                              : "Aktywny"}
                          </span>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* AI Workflow - Accounting Assistant */}
      <AIWorkflow
        workflowName="Asystent Księgowy"
        workflowDescription="Asystent AI do zarządzania finansami, fakturami i raportami"
        iconName="calculator"
        iconColor="text-green-400"
        iconBgColor="bg-green-500/20"
        workflowType="accounting"
      />
    </div>
  );
}

