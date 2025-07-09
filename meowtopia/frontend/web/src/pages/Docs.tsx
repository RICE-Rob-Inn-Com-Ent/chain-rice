import { useParams, useNavigate } from "react-router-dom";
import { useState, useEffect } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { docsRoutes } from "@/types/routes/docsRoutes";

const Docs = () => {
  const params = useParams();
  const navigate = useNavigate();
  const [content, setContent] = useState<string>("");

  const slug = params.parent
    ? `${params.parent}/${params.slug}`
    : params.slug || "index";

  useEffect(() => {
    const doc = docsRoutes.find((d) => d.slug === slug);
    if (doc) {
      fetch(`/docs/${doc.file}`)
        .then((res) => (res.ok ? res.text() : "Nie znaleziono dokumentu."))
        .then(setContent)
        .catch(() => setContent("Nie znaleziono dokumentu."));
    } else {
      setContent("Nie znaleziono dokumentu.");
    }
  }, [slug]);

  return (
    <div>
      <ReactMarkdown remarkPlugins={[remarkGfm]}>{content}</ReactMarkdown>
      <button onClick={() => navigate(-1)}>← Powrót</button>
    </div>
  );
};

export default Docs;
