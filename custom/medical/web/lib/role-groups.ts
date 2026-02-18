import { query, queryOne } from "@/lib/db";

export type RoleGroupRow = {
  id: string;
  role_key: string;
  label: string;
  description: string | null;
  color_class: string | null;
  sort_order: number | null;
  created_at: Date;
  updated_at: Date;
};

const defaultRoleGroups = [
  {
    role_key: "user",
    label: "Pacjent",
    description: "Standardowy dostęp pacjenta",
    color_class: "bg-white/10 text-ivory-100",
    sort_order: 10,
  },
  {
    role_key: "doctor",
    label: "Lekarz",
    description: "Dostęp do widoków gabinetu",
    color_class: "bg-green-500/20 text-green-400",
    sort_order: 20,
  },
  {
    role_key: "admin",
    label: "Administrator",
    description: "Zarządzanie placówką",
    color_class: "bg-blue-500/20 text-blue-400",
    sort_order: 30,
  },
  {
    role_key: "owner",
    label: "Właściciel",
    description: "Pełny dostęp i kontrola ról",
    color_class: "bg-purple-500/20 text-purple-400",
    sort_order: 40,
  },
];

export async function ensureRoleGroupsTable() {
  await query(`
    CREATE TABLE IF NOT EXISTS role_groups (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      role_key VARCHAR(50) UNIQUE NOT NULL,
      label VARCHAR(100) NOT NULL,
      description TEXT,
      color_class VARCHAR(120) DEFAULT 'bg-white/10 text-ivory-100',
      sort_order INTEGER DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    CREATE UNIQUE INDEX IF NOT EXISTS idx_role_groups_role_key ON role_groups(role_key);
  `);

  // Remove superadmin role if it exists
  await query(`DELETE FROM role_groups WHERE role_key = 'superadmin'`);

  // Seed defaults (update existing records) - only 4 roles: user, dentist, admin, owner
  await Promise.all(
    defaultRoleGroups.map((group) =>
      query(
        `
          INSERT INTO role_groups (role_key, label, description, color_class, sort_order)
          VALUES ($1, $2, $3, $4, $5)
          ON CONFLICT (role_key) DO UPDATE SET
            label = EXCLUDED.label,
            description = EXCLUDED.description,
            color_class = EXCLUDED.color_class,
            sort_order = EXCLUDED.sort_order,
            updated_at = CURRENT_TIMESTAMP
        `,
        [group.role_key, group.label, group.description, group.color_class, group.sort_order]
      )
    )
  );
}

export async function getRoleGroups() {
  await ensureRoleGroupsTable();
  const result = await query<RoleGroupRow>(`
    SELECT id, role_key, label, description, color_class, sort_order, created_at, updated_at
    FROM role_groups
    ORDER BY sort_order ASC, label ASC
  `);
  return result.rows;
}

export async function createRoleGroup({
  roleKey,
  label,
  description,
  colorClass,
}: {
  roleKey: string;
  label: string;
  description?: string | null;
  colorClass?: string | null;
}) {
  await ensureRoleGroupsTable();
  const normalizedKey = roleKey.toLowerCase().trim();
  const normalizedLabel = label.trim();

  const inserted = await queryOne<RoleGroupRow>(
    `
      INSERT INTO role_groups (role_key, label, description, color_class, sort_order)
      VALUES (
        $1,
        $2,
        $3,
        COALESCE($4, 'bg-white/10 text-ivory-100'),
        COALESCE((SELECT MAX(sort_order) + 10 FROM role_groups), 10)
      )
      RETURNING id, role_key, label, description, color_class, sort_order, created_at, updated_at
    `,
    [normalizedKey, normalizedLabel, description || null, colorClass || null]
  );

  if (!inserted) {
    throw new Error("Nie udało się utworzyć grupy ról");
  }

  return inserted;
}


