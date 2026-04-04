// TODO:
// [ ] theme, sidebarOpen, volume, muted, locale — persisted — https://docs.pmnd.rs/zustand/integrations/persisting-store-data
// [ ] setTheme (html class), toggleSidebar, setVolume → Tone master
//
import { create } from "zustand";

export type ToastItem = {
	id: string;
	message: string;
	type: "info" | "success" | "warning" | "error";
	duration?: number;
};

type UiState = {
	theme: "light" | "dark" | "system";
	sidebarOpen: boolean;
	activeModal: string | null;
	toasts: ToastItem[];
	setTheme: (theme: UiState["theme"]) => void;
	setSidebarOpen: (open: boolean) => void;
	toggleSidebar: () => void;
	setActiveModal: (id: string | null) => void;
	pushToast: (toast: Omit<ToastItem, "id"> & { id?: string }) => void;
	dismissToast: (id: string) => void;
	clearToasts: () => void;
};

export const useUiStore = create<UiState>((set, get) => ({
	theme: "system",
	sidebarOpen: true,
	activeModal: null,
	toasts: [],
	setTheme: (theme) => set({ theme }),
	setSidebarOpen: (sidebarOpen) => set({ sidebarOpen }),
	toggleSidebar: () => set({ sidebarOpen: !get().sidebarOpen }),
	setActiveModal: (activeModal) => set({ activeModal }),
	pushToast: (toast) =>
		set((s) => ({
			toasts: [
				...s.toasts,
				{
					...toast,
					id: toast.id ?? `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
					duration: toast.duration ?? 4000,
				},
			],
		})),
	dismissToast: (id) => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })),
	clearToasts: () => set({ toasts: [] }),
}));
