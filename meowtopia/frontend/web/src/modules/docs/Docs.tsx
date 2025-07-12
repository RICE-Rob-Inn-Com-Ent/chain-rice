import { useParams, useNavigate } from "react-router-dom";
import { useState, useEffect, useCallback } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { docsRoutes, DocsRoute } from "./docsTypes";
import { authPageMessages } from "../auth/configs/pages";

const Docs: React.FC = () => {
  const params = useParams();
  const navigate = useNavigate();
  const [content, setContent] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>("");

  const slug = params.parent
    ? `${params.parent}/${params.slug}`
    : params.slug || "index";

  const doc: DocsRoute | undefined = docsRoutes.find((d) => d.slug === slug);

  const fetchDoc = useCallback(async () => {
    if (!doc) {
      setError("Nie znaleziono dokumentu.");
      setContent("");
      setLoading(false);
      return;
    }
    setLoading(true);
    setError("");
    try {
      const res = await fetch(`/docs/${doc.file}`);
      if (!res.ok) {
        setError("Nie znaleziono dokumentu.");
        setContent("");
      } else {
        const text = await res.text();
        setContent(text);
      }
    } catch (e) {
      setError("Nie znaleziono dokumentu.");
      setContent("");
    } finally {
      setLoading(false);
    }
  }, [doc]);

  useEffect(() => {
    fetchDoc();
  }, [fetchDoc]);

  return (
    <div className="max-w-4xl mx-auto p-6">
      {loading && (
        <div className="text-center py-8">
          <div className="text-lg">{authPageMessages.common.loading}</div>
        </div>
      )}
      {error && (
        <div className="text-center py-8">
          <div className="text-red-600 text-lg">{error}</div>
        </div>
      )}
      {!loading && !error && (
        <div className="prose prose-lg max-w-none">
          <ReactMarkdown remarkPlugins={[remarkGfm]}>{content}</ReactMarkdown>
        </div>
      )}
      <div className="mt-8 text-center">
        <button 
          onClick={() => navigate(-1)}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
        >
          ← {authPageMessages.common.back}
        </button>
      </div>
    </div>
  );
};

export default Docs;
