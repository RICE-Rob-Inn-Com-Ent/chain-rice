import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { getRoleGroups, createRoleGroup } from "@/lib/role-groups";
import { isOwner } from "@/lib/rbac";

export async function GET() {
  try {
    const user = await getCurrentUser();
    if (!user || !isOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const roleGroups = await getRoleGroups();
    return NextResponse.json({ roleGroups });
  } catch (error: any) {
    console.error("Get role groups error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || !isOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { roleKey, label, description, colorClass } = body;

    if (!roleKey || !label) {
      return NextResponse.json(
        { error: "Wprowadź unikalny klucz oraz nazwę grupy" },
        { status: 400 }
      );
    }

    const newGroup = await createRoleGroup({ roleKey, label, description, colorClass });

    return NextResponse.json({ roleGroup: newGroup });
  } catch (error: any) {
    console.error("Create role group error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}


