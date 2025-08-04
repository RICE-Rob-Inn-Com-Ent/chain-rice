import type { TextConfig } from "@/components/Text";
import type { FieldConfig } from "@/components/Field";
import type { ClickConfig } from "@/components/Click";
import { useNavigate } from "react-router-dom";
import { useState } from "react";


export const useStorageConfig = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  
  const [uploadData, setUploadData] = useState({
    file: null,
    description: "",
    tags: "",
    isPublic: false,
  });
  
  const [downloadData, setDownloadData] = useState({
    fileId: "",
  });
  
  const [manageData, setManageData] = useState({
    fileId: "",
    action: "delete",
  });

  const handleUploadInputChange = (e: any) => {
    const { name, value, type, checked, files } = e.target;
    setUploadData(prev => ({
      ...prev,
      [name]: type === "checkbox" ? checked : type === "file" ? files[0] : value
    }));
  };

  const handleDownloadInputChange = (e: any) => {
    const { name, value } = e.target;
    setDownloadData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleManageInputChange = (e: any) => {
    const { name, value } = e.target;
    setManageData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleUploadSubmit = async (e: any) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      // TODO: Implement upload logic
      setSuccess("Plik został przesłany pomyślnie!");
    } catch (err) {
      setError("Błąd podczas przesyłania pliku");
    } finally {
      setLoading(false);
    }
  };

  const handleDownloadSubmit = async (e: any) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      // TODO: Implement download logic
      setSuccess("Plik został pobrany pomyślnie!");
    } catch (err) {
      setError("Błąd podczas pobierania pliku");
    } finally {
      setLoading(false);
    }
  };

  const handleManageSubmit = async (e: any) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      // TODO: Implement manage logic
      setSuccess("Akcja została wykonana pomyślnie!");
    } catch (err) {
      setError("Błąd podczas wykonywania akcji");
    } finally {
      setLoading(false);
    }
  };

  return {
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
      name: "file",
      onChange: handleUploadInputChange,
    } as FieldConfig,

    descriptionField: {
      tag: "textarea" as const,
      role: "default" as const,
      size: "md" as const,
      name: "description",
      placeholder: "Opcjonalny opis pliku...",
      value: uploadData.description,
      onChange: handleUploadInputChange,
    } as FieldConfig,

    tagsField: {
      tag: "input" as const,
      type: "text" as const,
      role: "default" as const,
      size: "md" as const,
      name: "tags",
      placeholder: "tag1, tag2, tag3",
      value: uploadData.tags,
      onChange: handleUploadInputChange,
    } as FieldConfig,

    isPublicField: {
      tag: "input" as const,
      type: "checkbox" as const,
      role: "default" as const,
      size: "md" as const,
      name: "isPublic",
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
      name: "fileId",
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
      name: "fileId",
      placeholder: "Wprowadź ID pliku",
      value: manageData.fileId,
      onChange: handleManageInputChange,
    } as FieldConfig,

    actionField: {
      tag: "select" as const,
      role: "default" as const,
      size: "md" as const,
      name: "action",
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

    // Event handlers
    handleUploadSubmit,
    handleDownloadSubmit,
    handleManageSubmit,
  };
}
