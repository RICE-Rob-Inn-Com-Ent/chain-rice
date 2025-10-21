import { useMemo, useState } from "react";
import { DashboardLayout, StatCard, Card, Table, Button, Badge } from "@rice-mono/next-components";

type TabId =
  | "dashboard"
  | "accounting"
  | "lawyer"
  | "hr"
  | "projects"
  | "sales"
  | "inventory"
  | "compliance"
  | "reports"
  | "analytics"
  | "settings"
  | "signin"
  | "signup";

export default function App() {
  const [activeTab, setActiveTab] = useState<TabId>("accounting");
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [showAuth, setShowAuth] = useState(true);

  const toggleSidebar = () => setSidebarOpen(!sidebarOpen);

  const handleSignIn = () => setActiveTab("signin");
  const handleSignUp = () => setActiveTab("signup");

  const topBarTabs = [
    { id: "dashboard", label: "Dashboard" },
    { id: "accounting", label: "Księgowość" },
    { id: "lawyer", label: "Prawnik" },
    { id: "hr", label: "HR" },
    { id: "projects", label: "Projekty" },
    { id: "sales", label: "Sprzedaż" },
    { id: "inventory", label: "Magazyn" },
    { id: "compliance", label: "Compliance" },
    { id: "reports", label: "Raporty" },
    { id: "analytics", label: "Analityka" },
    { id: "settings", label: "Ustawienia" },
  ];

  const sidebarItemsMap = useMemo(
    () =>
      ({
        dashboard: [
          { id: "overview", label: "Przegląd", icon: "📊" },
          { id: "activity", label: "Aktywność", icon: "⚡" },
        ],
        accounting: [
          { id: "transactions", label: "Transakcje", icon: "💳", badge: 12 },
          { id: "invoices", label: "Faktury", icon: "📄" },
          { id: "clients", label: "Klienci", icon: "👥" },
          { id: "documents", label: "Dokumenty", icon: "📁" },
        ],
        lawyer: [
          { id: "contracts", label: "Umowy", icon: "🧾" },
          { id: "cases", label: "Sprawy", icon: "⚖️" },
          { id: "signatures", label: "Podpisy", icon: "✍️" },
          { id: "advice", label: "Porady", icon: "💡" },
        ],
        hr: [
          { id: "employees", label: "Pracownicy", icon: "👥" },
          { id: "payroll", label: "Płace", icon: "💰" },
          { id: "vacations", label: "Urlopy", icon: "🏖️" },
          { id: "recruitment", label: "Rekrutacja", icon: "🧑‍💼" },
        ],
        projects: [
          { id: "board", label: "Tablica", icon: "📌" },
          { id: "roadmap", label: "Mapa", icon: "🗺️" },
          { id: "resources", label: "Zasoby", icon: "🧱" },
        ],
        sales: [
          { id: "leads", label: "Leady", icon: "🎯" },
          { id: "pipeline", label: "Lejek", icon: "⏳" },
          { id: "quotes", label: "Oferty", icon: "📜" },
        ],
        inventory: [
          { id: "stock", label: "Stany", icon: "📦" },
          { id: "orders", label: "Zamówienia", icon: "🧾" },
          { id: "suppliers", label: "Dostawcy", icon: "🚚" },
        ],
        compliance: [
          { id: "policies", label: "Polityki", icon: "📘" },
          { id: "audits", label: "Audyty", icon: "🔍" },
          { id: "risks", label: "Ryzyka", icon: "⚠️" },
        ],
        reports: [
          { id: "financial", label: "Finansowe", icon: "📈" },
          { id: "operations", label: "Operacyjne", icon: "⚙️" },
        ],
        analytics: [
          { id: "dashboards", label: "Pulpity", icon: "📊" },
          { id: "insights", label: "Wnioski", icon: "🧠" },
        ],
        settings: [
          { id: "profile", label: "Profil", icon: "👤" },
          { id: "team", label: "Zespół", icon: "👨‍👩‍👧‍👦" },
          { id: "billing", label: "Płatności", icon: "💳" },
        ],
        signin: [],
        signup: [],
      } as Record<TabId, { id: string; label: string; icon?: string; badge?: number }[]>),
    []
  );

  const statCardsData = [
    { title: "Przychody", value: "21 500 PLN", change: "+12.5%", type: "increase" as const },
    { title: "Wydatki", value: "11 700 PLN", change: "-5.2%", type: "decrease" as const },
    { title: "Bilans", value: "9 800 PLN", change: "+23.4%", type: "increase" as const },
  ];

  const transactions = [
    { id: 1, date: "2023-10-15", description: "Zakup licencji oprogramowania", amount: -1200, type: "Wydatek" },
    { id: 2, date: "2023-10-14", description: "Sprzedaż usługi konsultingowej", amount: 5000, type: "Przychód" },
    { id: 3, date: "2023-10-13", description: "Opłata za hosting", amount: -150, type: "Wydatek" },
    { id: 4, date: "2023-10-12", description: "Zwrot nadpłaty od klienta", amount: 200, type: "Przychód" },
  ];

  const transactionColumns = [
    { header: "Data", accessor: "date" },
    { header: "Opis", accessor: "description" },
    {
      header: "Kwota",
      accessor: "amount",
      render: (amount: number) => (
        <span className={amount >= 0 ? "text-green-500" : "text-red-500"}>{amount.toFixed(2)} PLN</span>
      ),
    },
    {
      header: "Typ",
      accessor: "type",
      render: (type: string) => <Badge variant={type === "Przychód" ? "success" : "danger"}>{type}</Badge>,
    },
  ];

  return (
    <DashboardLayout
      topBarProps={{
        title: "InfiniR Księgowość",
        tabs: topBarTabs,
        activeTab: activeTab,
        onTabChange: setActiveTab,
        onMenuClick: toggleSidebar,
        logoUrl: "/infinir-logo.png",
        showAuth: showAuth,
        onSignIn: handleSignIn,
        onSignUp: handleSignUp,
        tabsDisabled: activeTab === "signin" || activeTab === "signup",
      }}
      sidebarProps={{
        isOpen: activeTab === "signin" || activeTab === "signup" ? false : sidebarOpen,
        onClose: toggleSidebar,
        items: sidebarItemsMap[activeTab] ?? [],
        activeItem: sidebarItemsMap[activeTab]?.[0]?.id,
      }}
    >
      {activeTab === "signin" && (
        <div className="p-6 max-w-xl mx-auto">
          <Card title="Zaloguj się">
            <form className="space-y-4">
              <div>
                <label className="block text-sm text-gray-700 mb-1">Email</label>
                <input className="w-full border rounded-md px-3 py-2" type="email" placeholder="you@example.com" />
              </div>
              <div>
                <label className="block text-sm text-gray-700 mb-1">Hasło</label>
                <input className="w-full border rounded-md px-3 py-2" type="password" placeholder="••••••••" />
              </div>
              <div className="flex justify-between items-center">
                <Button variant="primary" size="md">
                  Zaloguj
                </Button>
                <Button variant="outline" size="md" onClick={() => setActiveTab("signup")}>
                  Załóż konto
                </Button>
              </div>
            </form>
          </Card>
        </div>
      )}

      {activeTab === "signup" && (
        <div className="p-6 max-w-xl mx-auto">
          <Card title="Rejestracja">
            <form className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-gray-700 mb-1">Imię</label>
                  <input className="w-full border rounded-md px-3 py-2" type="text" placeholder="Jan" />
                </div>
                <div>
                  <label className="block text-sm text-gray-700 mb-1">Nazwisko</label>
                  <input className="w-full border rounded-md px-3 py-2" type="text" placeholder="Kowalski" />
                </div>
              </div>
              <div>
                <label className="block text-sm text-gray-700 mb-1">Email</label>
                <input className="w-full border rounded-md px-3 py-2" type="email" placeholder="you@example.com" />
              </div>
              <div>
                <label className="block text-sm text-gray-700 mb-1">Hasło</label>
                <input className="w-full border rounded-md px-3 py-2" type="password" placeholder="••••••••" />
              </div>
              <div className="flex justify-between items-center">
                <Button variant="primary" size="md">
                  Utwórz konto
                </Button>
                <Button variant="outline" size="md" onClick={() => setActiveTab("signin")}>
                  Masz konto? Zaloguj
                </Button>
              </div>
            </form>
          </Card>
        </div>
      )}
      {activeTab === "accounting" && (
        <div className="p-6">
          <h2 className="text-3xl font-bold text-gray-800 mb-6">Księgowość</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            {statCardsData.map((card) => (
              <StatCard key={card.title} title={card.title} value={card.value} change={card.change} type={card.type} />
            ))}
          </div>

          <Card title="Ostatnie Transakcje" className="mb-8">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-xl font-semibold text-gray-700">Transakcje</h3>
              <div className="space-x-2">
                <Button variant="primary" size="md" icon="add">
                  Dodaj Transakcję
                </Button>
                <Button variant="outline" size="md" icon="download">
                  Eksportuj do PDF
                </Button>
              </div>
            </div>
            <Table data={transactions} columns={transactionColumns} />
          </Card>
        </div>
      )}

      {activeTab !== "accounting" && activeTab !== "signin" && activeTab !== "signup" && (
        <div className="p-6 text-center text-gray-500">
          <h2 className="text-3xl font-bold mb-4">🚧 {topBarTabs.find((tab) => tab.id === activeTab)?.label}</h2>
          <p className="text-lg">Sekcja w budowie. Wróć wkrótce!</p>
        </div>
      )}
    </DashboardLayout>
  );
}
