/**
🧠 TASK: As a senior frontend architect, generate a complete, scalable React + TypeScript component structure for a large modular project.
The app must support layouts, dashboards, multi-level navigation, UI kit, forms, tables, modals, authentication, and global state management.

📁 Generate a folder and file structure that follows clean architecture and atomic design principles:
- atoms → small UI elements (buttons, inputs, icons)
- molecules → composed UI elements (cards, nav items, dropdowns)
- organisms → larger sections (navbars, sidebars, modals, forms)
- layouts → templates for pages (dashboard layout, auth layout, settings layout)
- pages → route-level screens (Dashboard, Settings, Profile, Login, Register, NotFound)
- hooks → reusable logic (useAuth, useTheme, useFetch, useModal)
- context → global providers (AuthContext, ThemeContext, UIContext)
- utils → helpers (formatDate, classNames, fetcher)
- services → API clients and integrations
- types → shared TypeScript types and interfaces
- assets → images, icons, fonts
- styles → global styles, Tailwind config, animations

🔧 Include example UI components for all common cases:
- Buttons (primary, secondary, ghost, danger, icon-only, loading)
- Inputs (text, password, email, textarea, select, checkbox, switch)
- Navigation (Sidebar, Topbar, Breadcrumbs, Tabs, MobileNav)
- Layouts (MainLayout, AuthLayout, DashboardLayout, ModalLayout)
- Feedback (Alert, Toast, Tooltip, Spinner, EmptyState)
- Modals (ConfirmModal, FormModal, InfoModal)
- Tables (DataTable with pagination, sorting, filtering)
- Cards (InfoCard, StatCard, ProfileCard)
- Forms (LoginForm, RegisterForm, ProfileForm, SettingsForm)
- Misc (Avatar, Badge, Tag, Chip, Divider)

📚 Each file should have:
- descriptive component name
- typed props (interface Props)
- Tailwind + shadcn/ui integration
- accessibility best practices
- clear comments

⚙️ Also include:
- routes config file (e.g., routes.ts)
- protected routes handling
- centralized constants and theme
- sample AppProvider wrapping everything
- index files exporting grouped modules

🧩 Finally, output everything as a complete directory tree with file names.
Write clean and modern code, optimized for scalability and clarity.
*/
