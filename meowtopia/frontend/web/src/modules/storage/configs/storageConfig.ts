import type { TextConfig } from "@/components/Text";
import type { FieldConfig } from "@/components/Field";
import type { ClickConfig } from "@/components/Click";
import { useNavigate } from "react-router-dom";
import { useState } from "react";


export const useStorageConfig() {

    // Page configs
    pageTitle: {
      tag: "h2" as const,
      variant: "title-2" as const,
      children: "Zarządzanie magazynem",
    } as TextConfig,

    pageDescription: {
      tag: "p" as const,
      variant: "body" as const,
      children: "Upload, pobieranie i zarządzanie plikami",
    } as TextConfig,

    // Upload form config
    uploadTitle: {
      tag: "h3" as const,
      variant: "title-3" as const,
      children: "Prześlij plik",
    } as TextConfig,

    fileField: {
      tag: "input" as const,
      type: "file" as const,
      role: "default" as const,
      size: "md" as const,
      onChange: handleUploadInputChange,
    } as FieldConfig,

    descriptionField: {
      tag: "textarea" as const,
      role: "default" as const,
      size: "md" as const,
      placeholder: "Opcjonalny opis pliku...",
      value: uploadData.description,
      onChange: handleUploadInputChange,
    } as FieldConfig,

    tagsField: {
      tag: "input" as const,
      type: "text" as const,
      role: "default" as const,
      size: "md" as const,
      placeholder: "tag1, tag2, tag3",
      value: uploadData.tags,
      onChange: handleUploadInputChange,
    } as FieldConfig,

    isPublicField: {
      tag: "input" as const,
      type: "checkbox" as const,
      role: "default" as const,
      size: "md" as const,
      checked: uploadData.isPublic,
      onChange: handleUploadInputChange,
      children: "Udostępnij publicznie",
    } as FieldConfig,

    uploadButton: {
      type: "submit" as const,
      role: "primary" as const,
      ariaLabel: "Prześlij plik",
      children: loading ? "Przesyłanie..." : "Prześlij plik",
    } as ClickConfig,

    // Download form config
    downloadTitle: {
      tag: "h3" as const,
      variant: "title-3" as const,
      children: "Pobierz plik",
    } as TextConfig,

    fileIdField: {
      tag: "input" as const,
      type: "text" as const,
      role: "default" as const,
      size: "md" as const,
      placeholder: "Wprowadź ID pliku",
      value: downloadData.fileId,
      onChange: handleDownloadInputChange,
    } as FieldConfig,

    downloadButton: {
      type: "submit" as const,
      role: "primary" as const,
      ariaLabel: "Pobierz plik",
      children: loading ? "Pobieranie..." : "Pobierz plik",
    } as ClickConfig,

    // Manage form config
    manageTitle: {
      tag: "h3" as const,
      variant: "title-3" as const,
      children: "Zarządzaj plikami",
    } as TextConfig,

    manageFileIdField: {
      tag: "input" as const,
      type: "text" as const,
      role: "default" as const,
      size: "md" as const,
      placeholder: "Wprowadź ID pliku",
      value: manageData.fileId,
      onChange: handleManageInputChange,
    } as FieldConfig,

    actionField: {
      tag: "select" as const,
      role: "default" as const,
      size: "md" as const,
      value: manageData.action,
      onChange: handleManageInputChange,
    } as FieldConfig,

    manageButton: {
      type: "submit" as const,
      role: "primary" as const,
      ariaLabel: "Wykonaj akcję",
      children: loading ? "Wykonywanie..." : "Wykonaj akcję",
    } as ClickConfig,

    // Navigation buttons
    backButton: {
      type: "button" as const,
      role: "secondary" as const,
      ariaLabel: "Powrót do zarządzania plikami",
      children: "Powrót",
      onClick: () => navigate("/admin/storage"),
    } as ClickConfig,

    // Navigation cards
    uploadCard: {
      type: "button" as const,
      role: "primary" as const,
      ariaLabel: "Przejdź do przesyłania plików",
      children: "Upload File",
      onClick: () => navigate("/admin/storage/upload"),
    } as ClickConfig,

    downloadCard: {
      type: "button" as const,
      role: "primary" as const,
      ariaLabel: "Przejdź do pobierania plików",
      children: "Download File",
      onClick: () => navigate("/admin/storage/download"),
    } as ClickConfig,

    manageCard: {
      type: "button" as const,
      role: "primary" as const,
      ariaLabel: "Przejdź do zarządzania plikami",
      children: "Manage Files",
      onClick: () => navigate("/admin/storage/manage"),
    } as ClickConfig,

    // Error and success messages
    errorText: error ? {
      tag: "span" as const,
      variant: "error" as const,
      children: error,
    } as TextConfig : null,

    successText: success ? {
      tag: "span" as const,
      variant: "success" as const,
      children: success,
    } as TextConfig : null,
  };
}
