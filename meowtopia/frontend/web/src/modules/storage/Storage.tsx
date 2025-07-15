import React, { useState, useEffect } from "react";
import { Routes, Route, Navigate, useNavigate, useLocation } from "react-router-dom";
import { 
  storagePageMessages,
  uploadMessages,
  downloadMessages,
  manageMessages
} from "./configs/pages";
import type { 
  UploadFormData, 
  DownloadFormData, 
  ManageFormData 
} from "./interfaces/pages";
import { validateField, makeApiCall, handleStorageError } from "./utils";

const Storage: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  
  // Form states
  const [uploadData, setUploadData] = useState<UploadFormData>({
    file: null,
    description: "",
    tags: "",
    isPublic: false,
  });
  
  const [downloadData, setDownloadData] = useState<DownloadFormData>({
    fileId: "",
    destination: "",
  });
  
  const [manageData, setManageData] = useState<ManageFormData>({
    fileId: "",
    action: "delete",
  });
  
  // UI states
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [files, setFiles] = useState([]);

  // Clear messages when route changes
  useEffect(() => {
    setError("");
    setSuccess("");
  }, [location.pathname]);

  // ============================================================================
  // UTILITY FUNCTIONS
  // ============================================================================

  const clearMessages = () => {
    setError("");
    setSuccess("");
  };

  const setLoadingState = (isLoading: boolean) => {
    setLoading(isLoading);
    if (isLoading) clearMessages();
  };

  // ============================================================================
  // UPLOAD LOGIC
  // ============================================================================

  const handleUploadInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value, type } = e.target;
    const checked = (e.target as HTMLInputElement).checked;
    const files = (e.target as HTMLInputElement).files;
    setUploadData(prev => ({
      ...prev,
      [name]: type === "checkbox" ? checked : type === "file" ? files?.[0] || null : value,
    }));
  };

  const handleUploadSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoadingState(true);

    try {
      // Validate file
      if (!uploadData.file) {
        setError("Plik jest wymagany");
        return;
      }

      // Validate file size
      const maxSize = 100 * 1024 * 1024; // 100MB
      if (uploadData.file.size > maxSize) {
        setError("Plik jest za duży. Maksymalny rozmiar to 100MB");
        return;
      }

      // Create form data
      const formData = new FormData();
      formData.append("file", uploadData.file);
      formData.append("description", uploadData.description);
      formData.append("tags", uploadData.tags);
      formData.append("isPublic", uploadData.isPublic.toString());

      // Make API call
      const response = await makeApiCall({
        url: "/api/storage/upload",
        method: "POST",
        headers: {},
        timeout: 60000,
        retryAttempts: 3
      }, formData);

      setSuccess(uploadMessages.success);
      
      // Reset form
      setUploadData({
        file: null,
        description: "",
        tags: "",
        isPublic: false,
      });

    } catch (err: any) {
      setError(handleStorageError(err));
    } finally {
      setLoadingState(false);
    }
  };

  // ============================================================================
  // DOWNLOAD LOGIC
  // ============================================================================

  const handleDownloadInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setDownloadData(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleDownloadSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoadingState(true);

    try {
      // Validate file ID
      if (!downloadData.fileId) {
        setError("ID pliku jest wymagane");
        return;
      }

      // Make API call
      const response = await makeApiCall({
        url: `/api/storage/download/${downloadData.fileId}`,
        method: "GET",
        headers: {},
        timeout: 30000,
        retryAttempts: 3
      });

      // Handle file download
      const blob = new Blob([response.data]);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = response.filename || 'download';
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);

      setSuccess(downloadMessages.success);

    } catch (err: any) {
      setError(handleStorageError(err));
    } finally {
      setLoadingState(false);
    }
  };

  // ============================================================================
  // MANAGE LOGIC
  // ============================================================================

  const handleManageInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setManageData(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleManageSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoadingState(true);

    try {
      // Validate file ID
      if (!manageData.fileId) {
        setError("ID pliku jest wymagane");
        return;
      }

      // Make API call based on action
      const response = await makeApiCall({
        url: `/api/storage/${manageData.action}/${manageData.fileId}`,
        method: manageData.action === "delete" ? "DELETE" : "PUT",
        headers: {},
        timeout: 30000,
        retryAttempts: 3
      });

      setSuccess(manageMessages.success);

    } catch (err: any) {
      setError(handleStorageError(err));
    } finally {
      setLoadingState(false);
    }
  };

  // ============================================================================
  // NAVIGATION HANDLERS
  // ============================================================================

  const handleUpload = () => {
    navigate("/storage/upload");
  };

  const handleDownload = () => {
    navigate("/storage/download");
  };

  const handleManage = () => {
    navigate("/storage/manage");
  };

  const handleBackToStorage = () => {
    navigate("/storage");
  };

  // ============================================================================
  // RENDER
  // ============================================================================

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Storage Management
        </h2>
        <p className="mt-2 text-center text-sm text-gray-600">
          Upload, download, and manage your files
        </p>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          <Routes>
            <Route path="/" element={
              <div className="space-y-4">
                <button
                  onClick={handleUpload}
                  className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Upload File
                </button>
                <button
                  onClick={handleDownload}
                  className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                >
                  Download File
                </button>
                <button
                  onClick={handleManage}
                  className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-yellow-600 hover:bg-yellow-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500"
                >
                  Manage Files
                </button>
              </div>
            } />
            <Route path="/upload" element={
              <form onSubmit={handleUploadSubmit} className="space-y-6">
                <div>
                  <label htmlFor="file" className="block text-sm font-medium text-gray-700">
                    File
                  </label>
                  <input
                    id="file"
                    name="file"
                    type="file"
                    required
                    onChange={handleUploadInputChange}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label htmlFor="description" className="block text-sm font-medium text-gray-700">
                    Description
                  </label>
                  <textarea
                    id="description"
                    name="description"
                    value={uploadData.description}
                    onChange={handleUploadInputChange}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label htmlFor="tags" className="block text-sm font-medium text-gray-700">
                    Tags
                  </label>
                  <input
                    id="tags"
                    name="tags"
                    type="text"
                    value={uploadData.tags}
                    onChange={handleUploadInputChange}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  />
                </div>
                <div className="flex items-center">
                  <input
                    id="isPublic"
                    name="isPublic"
                    type="checkbox"
                    checked={uploadData.isPublic}
                    onChange={handleUploadInputChange}
                    className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                  />
                  <label htmlFor="isPublic" className="ml-2 block text-sm text-gray-900">
                    Make file public
                  </label>
                </div>
                <div>
                  <button
                    type="submit"
                    disabled={loading}
                    className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
                  >
                    {loading ? "Uploading..." : "Upload File"}
                  </button>
                </div>
                <div>
                  <button
                    type="button"
                    onClick={handleBackToStorage}
                    className="w-full flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    Back to Storage
                  </button>
                </div>
              </form>
            } />
            <Route path="/download" element={
              <form onSubmit={handleDownloadSubmit} className="space-y-6">
                <div>
                  <label htmlFor="fileId" className="block text-sm font-medium text-gray-700">
                    File ID
                  </label>
                  <input
                    id="fileId"
                    name="fileId"
                    type="text"
                    required
                    value={downloadData.fileId}
                    onChange={handleDownloadInputChange}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  />
                </div>
                <div>
                  <button
                    type="submit"
                    disabled={loading}
                    className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50"
                  >
                    {loading ? "Downloading..." : "Download File"}
                  </button>
                </div>
                <div>
                  <button
                    type="button"
                    onClick={handleBackToStorage}
                    className="w-full flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    Back to Storage
                  </button>
                </div>
              </form>
            } />
            <Route path="/manage" element={
              <form onSubmit={handleManageSubmit} className="space-y-6">
                <div>
                  <label htmlFor="fileId" className="block text-sm font-medium text-gray-700">
                    File ID
                  </label>
                  <input
                    id="fileId"
                    name="fileId"
                    type="text"
                    required
                    value={manageData.fileId}
                    onChange={handleManageInputChange}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label htmlFor="action" className="block text-sm font-medium text-gray-700">
                    Action
                  </label>
                  <select
                    id="action"
                    name="action"
                    value={manageData.action}
                    onChange={handleManageInputChange}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  >
                    <option value="delete">Delete</option>
                    <option value="update">Update</option>
                  </select>
                </div>
                <div>
                  <button
                    type="submit"
                    disabled={loading}
                    className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-yellow-600 hover:bg-yellow-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 disabled:opacity-50"
                  >
                    {loading ? "Processing..." : "Process Action"}
                  </button>
                </div>
                <div>
                  <button
                    type="button"
                    onClick={handleBackToStorage}
                    className="w-full flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    Back to Storage
                  </button>
                </div>
              </form>
            } />
          </Routes>

          {error && (
            <div className="mt-4 bg-red-50 border border-red-200 rounded-md p-4">
              <div className="text-sm text-red-600">{error}</div>
            </div>
          )}

          {success && (
            <div className="mt-4 bg-green-50 border border-green-200 rounded-md p-4">
              <div className="text-sm text-green-600">{success}</div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Storage; 