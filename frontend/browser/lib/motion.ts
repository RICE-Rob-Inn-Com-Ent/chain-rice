// TODO:
// [ ] variants: fadeIn, slideUp, staggerChildren delay from NEXT_PUBLIC_STAGGER_MS — https://www.framer.com/motion/animation/
// [ ] useReducedMotion — https://www.framer.com/motion/guide-accessibility/
// [ ] AnimatePresence page transitions — https://www.framer.com/motion/layout-animations/
// [ ] spring presets soft/medium/stiff — https://www.framer.com/motion/transitions/
//
import type { Variants } from "motion/react";

export const fadeIn: Variants = {
	hidden: { opacity: 0 },
	show: { opacity: 1, transition: { duration: 0.2, ease: [0.16, 1, 0.3, 1] } },
};

export const slideUp: Variants = {
	hidden: { opacity: 0, y: 12 },
	show: { opacity: 1, y: 0, transition: { duration: 0.25, ease: [0.16, 1, 0.3, 1] } },
};

export const slideDown: Variants = {
	hidden: { opacity: 0, y: -12 },
	show: { opacity: 1, y: 0, transition: { duration: 0.25, ease: [0.16, 1, 0.3, 1] } },
};

export const scaleIn: Variants = {
	hidden: { opacity: 0, scale: 0.96 },
	show: { opacity: 1, scale: 1, transition: { duration: 0.2, ease: [0.16, 1, 0.3, 1] } },
};

export const staggerChildren: Variants = {
	hidden: {},
	show: {
		transition: { staggerChildren: 0.05, delayChildren: 0.02 },
	},
};

export const pageTransition: Variants = {
	initial: { opacity: 0, y: 6 },
	animate: { opacity: 1, y: 0, transition: { duration: 0.22, ease: [0.16, 1, 0.3, 1] } },
	exit: { opacity: 0, y: -4, transition: { duration: 0.18 } },
};

export const modalTransition: Variants = {
	initial: { opacity: 0, scale: 0.98, y: 8 },
	animate: { opacity: 1, scale: 1, y: 0, transition: { duration: 0.2, ease: [0.16, 1, 0.3, 1] } },
	exit: { opacity: 0, scale: 0.98, y: 4, transition: { duration: 0.15 } },
};

export const drawerTransition: Variants = {
	initial: { x: "100%" },
	animate: { x: 0, transition: { duration: 0.28, ease: [0.16, 1, 0.3, 1] } },
	exit: { x: "100%", transition: { duration: 0.22 } },
};
