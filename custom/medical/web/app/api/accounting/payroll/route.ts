import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { queryMany } from "@/lib/db";
import { getRoleFromId } from "@/lib/user-id-generator";

type PayrollEmployee = {
  id: string;
  display_name: string;
  email: string;
  employment_type: string | null;
  employment_status: string | null;
  salary_type: string | null;
  hourly_rate: string | null;
  monthly_salary: string | null;
  hire_date: Date | null;
  termination_date: Date | null;
  department: string | null;
  position: string | null;
  roles: string[];
};

export async function GET(_request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || (user.role !== "admin" && user.role !== "superadmin")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const employees = await queryMany<PayrollEmployee>(
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
        get_user_text_field(u.id, 'termination_date')::timestamp as termination_date,
        get_user_text_field(u.id, 'department') as department,
        get_user_text_field(u.id, 'position') as position
       FROM users u
       WHERE u.id::text LIKE 'ADM-%' OR u.id::text LIKE 'SUP-%' OR u.id::text LIKE 'DOC-%'`
    );

    // Add role from ID prefix
    const employeesWithRoles = employees.map((emp: any) => ({
      ...emp,
      roles: [getRoleFromId(emp.id) || 'user']
    }));

    return NextResponse.json({ employees: employeesWithRoles });
  } catch (error) {
    console.error("Payroll API error:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}


