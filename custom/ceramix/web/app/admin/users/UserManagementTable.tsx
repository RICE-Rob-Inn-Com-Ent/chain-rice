"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMemo, useState } from "react";
import {
  Mail,
  User as UserIcon,
  Shield,
  Loader2,
  Filter,
  AlertCircle,
  CheckCircle2,
  Phone,
  Plus,
  Trash2,
} from "lucide-react";

type UserRow = {
  id: string;
  username: string;
  email: string;
  display_name: string;
  first_name: string | null;
  last_name: string | null;
  pesel: string | null;
  patient_number: string | null;
  phone: string | null;
  role: string;
  active: boolean;
  email_verified: boolean;
  phone_verified: boolean;
  employment_type: string | null;
  employment_status: string | null;
  last_login_at: string | null;
};

type RoleGroup = {
  id: string;
  role_key: string;
  label: string;
  description: string | null;
  color_class: string | null;
};

type Props = {
  currentUserId: string;
  initialUsers: UserRow[];
  initialRoleGroups: RoleGroup[];
  canEditRoles: boolean;
  isSuperadmin?: boolean;
};

const defaultBadgeClass = "bg-white/10 text-ivory-100";

const searchableFields: {
  key: string;
  label: string;
  accessor: (user: UserRow) => string | null;
}[] = [
  { key: "email", label: "Email", accessor: (user) => user.email },
  { key: "displayName", label: "Nazwa", accessor: (user) => user.display_name },
  {
    key: "fullName",
    label: "Imię i nazwisko",
    accessor: (user) => `${user.first_name || ""} ${user.last_name || ""}`.trim() || null,
  },
  { key: "patientNumber", label: "Numer pacjenta", accessor: (user) => user.patient_number },
  { key: "phone", label: "Telefon", accessor: (user) => user.phone },
  { key: "pesel", label: "PESEL", accessor: (user) => user.pesel },
  { key: "role", label: "Rola", accessor: (user) => user.role },
];

const escapeRegExp = (str: string) => str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const highlightText = (text: string | null | undefined, query: string) => {
  if (!text) return "";
  if (!query) return text;
  const lowerQuery = query.toLowerCase();
  const regex = new RegExp(`(${escapeRegExp(query)})`, "ig");
  const parts = text.split(regex);
  return parts.map((part, idx) => {
    if (!part) return null;
    const isMatch = part.toLowerCase() === lowerQuery;
    return isMatch ? (
      <mark key={idx} className="rounded bg-amber-500/40 px-0.5 text-current">
        {part}
      </mark>
    ) : (
      <span key={idx}>{part}</span>
    );
  });
};

const doesUserMatch = (user: UserRow, query: string) => {
  if (!query) return true;
  const lower = query.toLowerCase();
  return searchableFields.some((field) => {
    const value = field.accessor(user);
    return value ? value.toLowerCase().includes(lower) : false;
  });
};

const getMatchedFields = (user: UserRow, query: string) => {
  if (!query) return [];
  const lower = query.toLowerCase();
  return searchableFields
    .filter((field) => {
      const value = field.accessor(user);
      return value ? value.toLowerCase().includes(lower) : false;
    })
    .map((field) => field.label);
};

function formatDate(dateString: string | null) {
  if (!dateString) return "Nigdy";
  const date = new Date(dateString);
  if (Number.isNaN(date.getTime())) return "Nieznany";
  return date.toLocaleDateString("pl-PL");
}

export default function UserManagementTable({
  currentUserId,
  initialUsers,
  initialRoleGroups,
  canEditRoles,
  isSuperadmin = false,
}: Props) {
  const router = useRouter();
  const [users, setUsers] = useState<UserRow[]>(initialUsers);
  const [roleGroups, setRoleGroups] = useState<RoleGroup[]>(initialRoleGroups);
  const [selectedRoleKey, setSelectedRoleKey] = useState<string>("all");
  const [roleLoadingUser, setRoleLoadingUser] = useState<string | null>(null);
  const [banner, setBanner] = useState<{ type: "success" | "error"; text: string } | null>(
    null
  );
  const [filterMenuOpen, setFilterMenuOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedUserIds, setSelectedUserIds] = useState<Set<string>>(new Set());
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [activeLoadingUser, setActiveLoadingUser] = useState<string | null>(null);

  const normalizedQuery = searchQuery.trim().toLowerCase();

  const filteredByRole = useMemo(() => {
    if (selectedRoleKey === "all") return users;
    return users.filter((user) => user.role === selectedRoleKey);
  }, [users, selectedRoleKey]);

  const filteredUsers = useMemo(() => {
    if (!normalizedQuery) return filteredByRole;
    return filteredByRole.filter((user) => doesUserMatch(user, normalizedQuery));
  }, [filteredByRole, normalizedQuery]);

  const badgeForRole = (role: string) => {
    const group = roleGroups.find((g) => g.role_key === role);
    return {
      className: group?.color_class || defaultBadgeClass,
      label: group?.label || role,
    };
  };

  const handleRoleChange = async (userId: string, newRole: string) => {
    setBanner(null);
    setRoleLoadingUser(userId);
    try {
      const res = await fetch(`/api/users/${userId}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ role: newRole }),
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || "Nie udało się zaktualizować roli");
      }

      // Update user with new role and potentially new ID if migration occurred
      const updatedUser = data.user;
      if (updatedUser && updatedUser.id !== userId) {
        // User ID was changed (role migration), update the user list
        setUsers((prev) => {
          const filtered = prev.filter((user) => user.id !== userId);
          return [...filtered, { ...updatedUser, role: newRole }];
        });
        setBanner({ 
          type: "success", 
          text: `Rola użytkownika została zaktualizowana. Nowe ID: ${updatedUser.id}` 
        });
      } else {
        // Just update the role
        setUsers((prev) =>
          prev.map((user) => (user.id === userId ? { ...user, role: newRole } : user))
        );
        setBanner({ type: "success", text: "Rola użytkownika została zaktualizowana." });
      }
    } catch (error: any) {
      setBanner({ type: "error", text: error.message || "Wystąpił błąd." });
    } finally {
      setRoleLoadingUser(null);
    }
  };

  const handleSelectUser = (userId: string) => {
    setSelectedUserIds((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(userId)) {
        newSet.delete(userId);
      } else {
        newSet.add(userId);
      }
      return newSet;
    });
  };

  const handleSelectAll = () => {
    if (selectedUserIds.size === filteredUsers.length) {
      setSelectedUserIds(new Set());
    } else {
      setSelectedUserIds(new Set(filteredUsers.map((u) => u.id)));
    }
  };

  const handleDelete = async () => {
    if (selectedUserIds.size === 0) return;
    if (!confirm(`Czy na pewno chcesz usunąć ${selectedUserIds.size} użytkownik(ów)?`)) return;

    setBanner(null);
    setDeleteLoading(true);
    try {
      const deletePromises = Array.from(selectedUserIds).map((userId) =>
        fetch(`/api/users/${userId}`, { method: "DELETE" })
      );
      const results = await Promise.all(deletePromises);
      const errors = results.filter((r) => !r.ok);
      
      if (errors.length > 0) {
        throw new Error("Nie udało się usunąć niektórych użytkowników");
      }

      setUsers((prev) => prev.filter((u) => !selectedUserIds.has(u.id)));
      setSelectedUserIds(new Set());
      setBanner({ type: "success", text: "Użytkownicy zostali usunięci." });
    } catch (error: any) {
      setBanner({ type: "error", text: error.message || "Wystąpił błąd podczas usuwania." });
    } finally {
      setDeleteLoading(false);
    }
  };

  const handleToggleActive = async (userId: string, currentActive: boolean) => {
    setBanner(null);
    setActiveLoadingUser(userId);
    try {
      const res = await fetch(`/api/users/${userId}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ active: !currentActive }),
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || "Nie udało się zaktualizować statusu");
      }

      setUsers((prev) =>
        prev.map((user) => (user.id === userId ? { ...user, active: !currentActive } : user))
      );
      setBanner({ 
        type: "success", 
        text: `Konto zostało ${!currentActive ? "aktywowane" : "dezaktywowane"}.` 
      });
    } catch (error: any) {
      setBanner({ type: "error", text: error.message || "Wystąpił błąd." });
    } finally {
      setActiveLoadingUser(null);
    }
  };


  return (
    <div className="space-y-6">
      {banner && (
        <div
          className={`rounded-2xl border p-4 text-sm ${
            banner.type === "error"
              ? "border-red-500/40 bg-red-500/10 text-red-200"
              : "border-emerald-500/40 bg-emerald-500/10 text-emerald-100"
          }`}
        >
          {banner.type === "error" ? (
            <div className="flex items-center gap-2">
              <AlertCircle className="h-4 w-4" />
              <span>{banner.text}</span>
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <CheckCircle2 className="h-4 w-4" />
              <span>{banner.text}</span>
            </div>
          )}
        </div>
      )}

      <div className="marble-card p-6">
        <div className="flex flex-wrap items-center justify-between gap-3 pb-4 border-b border-white/10">
          <div className="flex items-center gap-3 text-sm text-ivory-100/60">
            <Filter className="h-4 w-4" />
            <span>
              Widok:{" "}
              {selectedRoleKey === "all"
                ? "wszyscy użytkownicy"
                : badgeForRole(selectedRoleKey).label}
            </span>
            <span className="text-xs text-ivory-100/40">
              {filteredUsers.length} / {users.length}
            </span>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {isSuperadmin && (
              <>
                <Link
                  href={`/${currentUserId}/users/new`}
                  className="flex items-center justify-center rounded-lg border border-white/10 bg-white/5 p-2 text-ivory-100 hover:bg-white/10 transition"
                  title="Dodaj użytkownika"
                  onClick={(e) => e.stopPropagation()}
                >
                  <Plus className="h-4 w-4" />
                </Link>
                {selectedUserIds.size > 0 && (
                  <button
                    type="button"
                    disabled={deleteLoading || selectedUserIds.size === 0}
                    className="flex items-center justify-center rounded-lg border border-red-500/50 bg-red-500/20 p-2 text-red-400 hover:bg-red-500/30 transition disabled:opacity-50 disabled:cursor-not-allowed"
                    title="Usuń użytkowników"
                    onClick={(e) => {
                      e.stopPropagation();
                      handleDelete();
                    }}
                  >
                    {deleteLoading ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : (
                      <Trash2 className="h-4 w-4" />
                    )}
                  </button>
                )}
              </>
            )}
            <div className="relative">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Szukaj: imię, email, numer, PESEL..."
                className="w-64 rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-sm text-ivory-100 placeholder:text-ivory-100/40 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20"
              />
              {searchQuery && (
                <button
                  type="button"
                  className="absolute right-2 top-1/2 -translate-y-1/2 text-xs text-ivory-100/60 hover:text-ivory-100"
                  onClick={() => setSearchQuery("")}
                >
                  Wyczyść
                </button>
              )}
            </div>
            <div className="relative">
              <button
                type="button"
                className="inline-flex items-center gap-2 rounded-lg border border-white/10 px-4 py-2 text-sm text-ivory-100 hover:bg-white/5"
                onClick={() => setFilterMenuOpen((prev) => !prev)}
              >
                Filtruj role
                <Filter className="h-4 w-4" />
              </button>
              {filterMenuOpen && (
                <div className="absolute right-0 mt-2 w-48 rounded-xl border border-white/10 bg-obsidian-900/95 shadow-lg z-10">
                  <button
                    type="button"
                    className={`w-full px-4 py-2 text-left text-sm ${
                      selectedRoleKey === "all"
                        ? "text-amber-400 bg-white/5"
                        : "text-ivory-100/80 hover:bg-white/5"
                    }`}
                    onClick={() => {
                      setSelectedRoleKey("all");
                      setFilterMenuOpen(false);
                    }}
                  >
                    Wszyscy użytkownicy
                  </button>
                  {roleGroups.map((group) => (
                    <button
                      key={group.id}
                      type="button"
                      className={`w-full px-4 py-2 text-left text-sm ${
                        selectedRoleKey === group.role_key
                          ? "text-amber-400 bg-white/5"
                          : "text-ivory-100/80 hover:bg-white/5"
                      }`}
                      onClick={() => {
                        setSelectedRoleKey(group.role_key);
                        setFilterMenuOpen(false);
                      }}
                    >
                      {group.label}
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-white/10">
                {isSuperadmin && (
                  <th className="px-6 py-4 text-left text-sm font-semibold text-ivory-100/60 w-12">
                    <input
                      type="checkbox"
                      checked={filteredUsers.length > 0 && selectedUserIds.size === filteredUsers.length}
                      onChange={handleSelectAll}
                      className="rounded border-white/20 bg-white/5 text-amber-500 focus:ring-amber-500"
                      onClick={(e) => e.stopPropagation()}
                    />
                  </th>
                )}
                <th className="px-6 py-4 text-left text-sm font-semibold text-ivory-100/60">
                  Email
                </th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-ivory-100/60">
                  Imię i nazwisko
                </th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-ivory-100/60">
                  PESEL
                </th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-ivory-100/60">
                  Telefon
                </th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-ivory-100/60">
                  Rola
                </th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-ivory-100/60">
                  Status
                </th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-ivory-100/60">
                  Ostatnie logowanie
                </th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.length === 0 ? (
                <tr>
                  <td
                    colSpan={isSuperadmin ? 8 : 7}
                    className="px-6 py-10 text-center text-sm text-ivory-100/60"
                  >
                    Brak użytkowników w tej grupie.
                  </td>
                </tr>
              ) : (
                filteredUsers.map((user) => {
                  const badge = badgeForRole(user.role);
                  const matchedFields =
                    normalizedQuery.length > 0 ? getMatchedFields(user, normalizedQuery) : [];
                  const fullName = `${user.first_name || ""} ${user.last_name || ""}`.trim() || user.display_name;
                  return (
                    <tr 
                      key={user.id} 
                      className={`border-b border-white/5 hover:bg-white/5 transition-colors cursor-pointer ${
                        selectedUserIds.has(user.id) ? "bg-amber-500/10" : ""
                      }`}
                      onClick={() => router.push(`/${user.username}/dashboard`)}
                    >
                      {isSuperadmin && (
                        <td className="px-6 py-4 text-sm" onClick={(e) => e.stopPropagation()}>
                          <input
                            type="checkbox"
                            checked={selectedUserIds.has(user.id)}
                            onChange={() => handleSelectUser(user.id)}
                            className="rounded border-white/20 bg-white/5 text-amber-500 focus:ring-amber-500"
                            onClick={(e) => e.stopPropagation()}
                          />
                        </td>
                      )}
                      <td 
                        className="px-6 py-4 text-sm text-ivory-100 cursor-pointer"
                        onClick={() => router.push(`/${user.username}/dashboard`)}
                      >
                        <div className="flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
                          <Mail className="h-4 w-4 text-ivory-100/40" />
                          <span>{highlightText(user.email, normalizedQuery)}</span>
                        </div>
                      </td>
                      <td 
                        className="px-6 py-4 text-sm text-ivory-100 cursor-pointer"
                        onClick={() => router.push(`/${user.username}/dashboard`)}
                      >
                        <div className="flex items-center gap-2">
                          <UserIcon className="h-4 w-4 text-ivory-100/40" />
                          <span>{highlightText(fullName, normalizedQuery)}</span>
                        </div>
                        {matchedFields.length > 0 && (
                          <div className="mt-1 text-xs text-amber-300">
                            Dopasowanie: {matchedFields.join(", ")}
                          </div>
                        )}
                      </td>
                      <td 
                        className="px-6 py-4 text-sm text-ivory-100/80 cursor-pointer"
                        onClick={() => router.push(`/${user.username}/dashboard`)}
                      >
                        {user.pesel ? highlightText(user.pesel, normalizedQuery) : "-"}
                      </td>
                      <td 
                        className="px-6 py-4 text-sm text-ivory-100/80 cursor-pointer"
                        onClick={() => router.push(`/${user.username}/dashboard`)}
                      >
                        {user.phone ? (
                          <div className="flex items-center gap-2">
                            <Phone className="h-4 w-4 text-ivory-100/40" />
                            <span>{highlightText(user.phone, normalizedQuery)}</span>
                          </div>
                        ) : (
                          "-"
                        )}
                      </td>
                      <td className="px-6 py-4 text-sm" onClick={(e) => e.stopPropagation()}>
                        <div className="flex items-center gap-2">
                          <span
                            className={`inline-flex items-center justify-center rounded-full p-1.5 ${badge.className}`}
                            title={badge.label}
                          >
                            <Shield className="h-4 w-4" />
                          </span>
                          {canEditRoles ? (
                            <>
                              <select
                                value={user.role}
                                disabled={roleLoadingUser === user.id}
                                onChange={(e) => handleRoleChange(user.id, e.target.value)}
                                className="flex-1 rounded-lg border border-white/10 bg-white/5 px-2 py-1 text-xs text-ivory-100 focus:border-amber-400 focus:outline-none"
                              >
                                {roleGroups.map((group) => (
                                  <option key={group.id} value={group.role_key}>
                                    {group.label}
                                  </option>
                                ))}
                              </select>
                              {roleLoadingUser === user.id && (
                                <Loader2 className="h-4 w-4 animate-spin text-ivory-100/50" />
                              )}
                            </>
                          ) : (
                            <span className="text-xs text-ivory-100/80">{badge.label}</span>
                          )}
                        </div>
                      </td>
                      <td 
                        className="px-6 py-4 text-sm"
                        onClick={(e) => e.stopPropagation()}
                      >
                        <div className="flex flex-col gap-2">
                          {/* Status aktywny - tylko dla właściciela */}
                          {isSuperadmin && (
                            <div className="flex items-center gap-2">
                              <button
                                type="button"
                                onClick={() => handleToggleActive(user.id, user.active)}
                                disabled={activeLoadingUser === user.id}
                                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-amber-500 focus:ring-offset-2 focus:ring-offset-obsidian-900 disabled:opacity-50 ${
                                  user.active ? "bg-green-500" : "bg-gray-600"
                                }`}
                                title={user.active ? "Kliknij aby dezaktywować" : "Kliknij aby aktywować"}
                              >
                                <span
                                  className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                                    user.active ? "translate-x-6" : "translate-x-1"
                                  }`}
                                />
                              </button>
                              <span className={`text-xs font-medium ${
                                user.active ? "text-green-400" : "text-gray-400"
                              }`}>
                                {user.active ? "Aktywny" : "Nieaktywny"}
                              </span>
                              {activeLoadingUser === user.id && (
                                <Loader2 className="h-3 w-3 animate-spin text-ivory-100/50" />
                              )}
                            </div>
                          )}
                          {!isSuperadmin && (
                            <span className={`text-xs font-medium ${
                              user.active ? "text-green-400" : "text-gray-400"
                            }`}>
                              {user.active ? "Aktywny" : "Nieaktywny"}
                            </span>
                          )}
                          <span
                            className={`inline-block w-fit rounded-full px-2 py-1 text-xs font-medium ${
                              user.phone_verified
                                ? "bg-green-500/20 text-green-400"
                                : "bg-yellow-500/20 text-yellow-400"
                            }`}
                          >
                            {user.phone_verified ? "Zweryfikowany" : "Niezweryfikowany"}
                          </span>
                          {user.employment_status && (
                            <span className="text-xs text-ivory-100/60">
                              Kadry:{" "}
                              {user.employment_status === "terminated"
                                ? "Zakończony"
                                : user.employment_status === "on_leave"
                                ? "Urlop"
                                : "Aktywny"}
                            </span>
                          )}
                          {user.employment_type && (
                            <span className="text-xs text-ivory-100/60">
                              Typ: {user.employment_type}
                            </span>
                          )}
                        </div>
                      </td>
                      <td 
                        className="px-6 py-4 text-sm text-ivory-100/70 cursor-pointer"
                        onClick={() => router.push(`/${user.username}/dashboard`)}
                      >
                        {formatDate(user.last_login_at)}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
        {normalizedQuery && (
          <p className="mt-3 text-xs text-ivory-100/50">
            Wyszukiwanie obejmuje: Email, Nazwa, Imię i nazwisko, Numer pacjenta, Telefon, PESEL
            oraz rolę. Dopasowane pola podświetlam wierszem i opisem „Dopasowanie”.
          </p>
        )}
      </div>
    </div>
  );
}


