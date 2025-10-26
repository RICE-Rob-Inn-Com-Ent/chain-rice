import React from "react";
import Section from "@atoms/Section";
import ContactForm from "@molecules/ContactForm";

export const metadata = { title: "Kontakt — RICE" };

export default function ContactPage() {
  return (
    <Section>
      <div className="mx-auto max-w-3xl">
        <h1 className="font-display text-4xl font-bold">Formularz kontaktowy</h1>
        <p className="mt-4 text-slate-300">Napisz do nas — odpowiemy w 24h.</p>
        <div className="mt-8">
          <ContactForm />
        </div>
      </div>
    </Section>
  );
}
