"use client";

import { useState, useRef, useEffect } from "react";
import { Sparkles, X, Send, Upload, FileText, BarChart3, Loader2, Plus } from "lucide-react";

// Invoice Form Component
type InvoiceFormData = {
  invoice_number?: string;
  issue_date?: string;
  sale_date?: string;
  seller?: { name?: string; address?: string; nip?: string };
  buyer?: { name?: string; address?: string; nip?: string };
  payment_method?: string;
  items?: Array<{
    name?: string;
    quantity?: string;
    unit_price?: string;
    net_amount?: number;
    vat_rate?: string;
    vat_amount?: number;
    gross_amount?: number;
  }>;
  totals?: {
    net_amount?: number;
    vat_amount?: number;
    gross_amount?: number;
    currency?: string;
  };
  vat_summary?: Array<{
    rate?: string;
    net_amount?: number;
    vat_amount?: number;
    gross_amount?: number;
  }>;
};

function InvoiceForm({ data }: { data: InvoiceFormData }) {
  return (
    <div className="space-y-3 text-xs">
      {/* Basic Info */}
      {(data.invoice_number || data.issue_date || data.sale_date) && (
        <div className="space-y-1">
          <div className="font-semibold text-ivory-100 mb-2">Informacje podstawowe</div>
          {data.invoice_number && (
            <div className="flex justify-between">
              <span className="text-ivory-100/70">Numer faktury:</span>
              <span className="text-ivory-100 font-medium">{data.invoice_number}</span>
            </div>
          )}
          {data.issue_date && (
            <div className="flex justify-between">
              <span className="text-ivory-100/70">Data wystawienia:</span>
              <span className="text-ivory-100 font-medium">{data.issue_date}</span>
            </div>
          )}
          {data.sale_date && (
            <div className="flex justify-between">
              <span className="text-ivory-100/70">Data sprzedaży:</span>
              <span className="text-ivory-100 font-medium">{data.sale_date}</span>
            </div>
          )}
        </div>
      )}

      {/* Seller */}
      {data.seller && (data.seller.name || data.seller.address || data.seller.nip) && (
        <div className="space-y-1 pt-2 border-t border-white/10">
          <div className="font-semibold text-ivory-100 mb-2">Sprzedawca</div>
          {data.seller.name && (
            <div className="text-ivory-100/90">{data.seller.name}</div>
          )}
          {data.seller.address && (
            <div className="text-ivory-100/70">{data.seller.address}</div>
          )}
          {data.seller.nip && (
            <div className="text-ivory-100/70">NIP: {data.seller.nip}</div>
          )}
        </div>
      )}

      {/* Buyer */}
      {data.buyer && (data.buyer.name || data.buyer.address || data.buyer.nip) && (
        <div className="space-y-1 pt-2 border-t border-white/10">
          <div className="font-semibold text-ivory-100 mb-2">Nabywca</div>
          {data.buyer.name && (
            <div className="text-ivory-100/90">{data.buyer.name}</div>
          )}
          {data.buyer.address && (
            <div className="text-ivory-100/70">{data.buyer.address}</div>
          )}
          {data.buyer.nip && (
            <div className="text-ivory-100/70">NIP: {data.buyer.nip}</div>
          )}
        </div>
      )}

      {/* Payment Method */}
      {data.payment_method && (
        <div className="pt-2 border-t border-white/10">
          <div className="flex justify-between">
            <span className="text-ivory-100/70">Forma płatności:</span>
            <span className="text-ivory-100 font-medium">{data.payment_method}</span>
          </div>
        </div>
      )}

      {/* Items */}
      {data.items && data.items.length > 0 && (
        <div className="pt-2 border-t border-white/10">
          <div className="font-semibold text-ivory-100 mb-2">Pozycje</div>
          <div className="space-y-2">
            {data.items.map((item, idx) => (
              <div key={idx} className="bg-white/5 p-2 rounded">
                {item.name && (
                  <div className="text-ivory-100/90 font-medium mb-1">{item.name}</div>
                )}
                <div className="grid grid-cols-2 gap-2 text-ivory-100/70">
                  {item.quantity && (
                    <div>Ilość: {item.quantity}</div>
                  )}
                  {item.unit_price && (
                    <div>Cena: {item.unit_price}</div>
                  )}
                  {item.net_amount !== undefined && (
                    <div>Netto: {item.net_amount.toFixed(2)}</div>
                  )}
                  {item.vat_rate && (
                    <div>VAT: {item.vat_rate}</div>
                  )}
                  {item.vat_amount !== undefined && (
                    <div>Kwota VAT: {item.vat_amount.toFixed(2)}</div>
                  )}
                  {item.gross_amount !== undefined && (
                    <div className="col-span-2 font-semibold text-ivory-100">
                      Brutto: {item.gross_amount.toFixed(2)}
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Totals */}
      {data.totals && (
        <div className="pt-2 border-t border-white/10 space-y-1">
          <div className="font-semibold text-ivory-100 mb-2">Podsumowanie</div>
          {data.totals.net_amount !== undefined && (
            <div className="flex justify-between">
              <span className="text-ivory-100/70">Wartość netto:</span>
              <span className="text-ivory-100 font-medium">{data.totals.net_amount.toFixed(2)} {data.totals.currency || "PLN"}</span>
            </div>
          )}
          {data.totals.vat_amount !== undefined && (
            <div className="flex justify-between">
              <span className="text-ivory-100/70">Kwota VAT:</span>
              <span className="text-ivory-100 font-medium">{data.totals.vat_amount.toFixed(2)} {data.totals.currency || "PLN"}</span>
            </div>
          )}
          {data.totals.gross_amount !== undefined && (
            <div className="flex justify-between pt-1 border-t border-white/10">
              <span className="text-ivory-100 font-semibold">Suma brutto:</span>
              <span className="text-ivory-100 font-bold">{data.totals.gross_amount.toFixed(2)} {data.totals.currency || "PLN"}</span>
            </div>
          )}
        </div>
      )}

      {/* VAT Summary */}
      {data.vat_summary && data.vat_summary.length > 0 && (
        <div className="pt-2 border-t border-white/10">
          <div className="font-semibold text-ivory-100 mb-2">Podsumowanie VAT</div>
          <div className="space-y-1">
            {data.vat_summary.map((vat, idx) => (
              <div key={idx} className="flex justify-between text-ivory-100/70">
                <span>VAT {vat.rate}:</span>
                <span>
                  {vat.net_amount !== undefined && `${vat.net_amount.toFixed(2)} netto`}
                  {vat.vat_amount !== undefined && ` + ${vat.vat_amount.toFixed(2)} VAT`}
                  {vat.gross_amount !== undefined && ` = ${vat.gross_amount.toFixed(2)} brutto`}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

type Message = {
  id: string;
  role: "user" | "assistant";
  content: string;
  timestamp: Date;
  images?: string[];
  report?: {
    type: string;
    data: any;
    charts: any[];
  };
  extractedData?: {
    invoice_number?: string;
    issue_date?: string;
    sale_date?: string;
    seller?: { name?: string; address?: string; nip?: string };
    buyer?: { name?: string; address?: string; nip?: string };
    payment_method?: string;
    items?: Array<{
      name?: string;
      quantity?: string;
      unit_price?: string;
      net_amount?: number;
      vat_rate?: string;
      vat_amount?: number;
      gross_amount?: number;
    }>;
    totals?: {
      net_amount?: number;
      vat_amount?: number;
      gross_amount?: number;
      currency?: string;
    };
    vat_summary?: Array<{
      rate?: string;
      net_amount?: number;
      vat_amount?: number;
      gross_amount?: number;
    }>;
  };
};

type CerAIProps = {
  botType: "accounting" | "client_management";
  context?: string;
};

// Use environment variable or default
// In browser, use Next.js API route as proxy (same origin, no CORS issues)
// In server-side, use container name
const CERAI_API_URL = process.env.NEXT_PUBLIC_CERAI_API_URL || 
  (typeof window !== "undefined" 
    ? "/api/cerai"  // Use Next.js API route as proxy - same origin
    : "http://ceramix-bot:8000");

export default function CerAI({ botType, context }: CerAIProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Welcome message on open
  useEffect(() => {
    if (isOpen && messages.length === 0) {
      const welcomeMessage: Message = {
        id: "welcome",
        role: "assistant",
        content: botType === "accounting"
          ? "Cześć! Jestem CerAI, twój asystent księgowy. Mogę pomóc w:\n\n• Analizie paragonów i faktur (wyślij zdjęcie)\n• Generowaniu raportów finansowych\n• Analizie przychodów i kosztów\n• Wypełnianiu formularzy sprawozdawczych\n\nWyślij zdjęcie paragonu lub zadaj pytanie!"
          : "Cześć! Jestem CerAI, twój asystent do zarządzania klientami. Mogę pomóc w:\n\n• Wyszukiwaniu informacji o klientach\n• Analizie danych klientów\n• Raportowaniu aktywności\n• Optymalizacji procesów\n\nZadaj pytanie!",
        timestamp: new Date()
      };
      setMessages([welcomeMessage]);
    }
  }, [isOpen, botType]);

  const sendMessage = async () => {
    if (!input.trim() || isLoading) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: "user",
      content: input,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInput("");
    setIsLoading(true);

    try {
      const response = await fetch(`${CERAI_API_URL}/chat`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          message: input,
          bot_type: botType,
          context: context
        })
      });

      if (!response.ok) {
        throw new Error("Failed to get response");
      }

      const data = await response.json();

      const assistantMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: "assistant",
        content: data.response || "Brak odpowiedzi",
        timestamp: new Date(),
        report: data.report
      };

      setMessages(prev => [...prev, assistantMessage]);
    } catch (error: any) {
      const errorMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: "assistant",
        content: `Błąd: ${error.message}. Upewnij się, że serwer CerAI jest uruchomiony.`,
        timestamp: new Date()
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    // Check if valid file type (image or PDF)
    const isValidImage = file.type.startsWith("image/");
    const isValidPdf = file.type === "application/pdf" || file.name.toLowerCase().endsWith(".pdf");
    
    if (!isValidImage && !isValidPdf) {
      alert("Proszę wybrać plik obrazu (JPG, PNG) lub dokument PDF (faktura/paragon)");
      return;
    }

    setIsUploading(true);

    try {
      // For PDF, we'll need to send it as a file upload to the /ocr endpoint
      // For images, we can use base64
      if (isValidPdf) {
        // Send PDF as multipart form data
        const formData = new FormData();
        formData.append("file", file);
        formData.append("document_type", botType === "accounting" ? "receipt" : "invoice");

        const response = await fetch(`${CERAI_API_URL}/ocr`, {
          method: "POST",
          body: formData
        });

        if (!response.ok) {
          const errorData = await response.json().catch(() => ({ detail: "Unknown error" }));
          const errorMessage = errorData.detail || `OCR processing failed: ${response.status} ${response.statusText}`;
          
          const errorMsg: Message = {
            id: Date.now().toString(),
            role: "assistant",
            content: `❌ Błąd OCR: ${errorMessage}\n\nMożesz jednak opisać dokument tekstowo, a ja pomogę Ci go przeanalizować.`,
            timestamp: new Date(),
          };
          setMessages(prev => [...prev, errorMsg]);
          setIsUploading(false);
          return;
        }

        const ocrData = await response.json();

        // Add user message
        const userMessage: Message = {
          id: Date.now().toString(),
          role: "user",
          content: "Przeanalizuj ten dokument:",
          timestamp: new Date()
        };

        setMessages(prev => [...prev, userMessage]);

        // Send OCR text to chat for analysis
        const chatResponse = await fetch(`${CERAI_API_URL}/chat`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            message: `Przeanalizuj ten dokument i wyciągnij kluczowe informacje:\n\n${ocrData.text}`,
            bot_type: botType,
            context: context
          })
        });

        if (chatResponse.ok) {
          const chatData = await chatResponse.json();
          
          // Try to parse extracted data from response
          let extractedData = null;
          try {
            // Check if response contains JSON with invoice data
            const jsonMatch = chatData.response?.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
              extractedData = JSON.parse(jsonMatch[0]);
            }
          } catch (e) {
            // If response already contains extracted_data, use it
            if (chatData.extracted_data) {
              extractedData = chatData.extracted_data;
            }
          }

          const assistantMessage: Message = {
            id: (Date.now() + 1).toString(),
            role: "assistant",
            content: chatData.response || "Dokument został przetworzony.",
            timestamp: new Date(),
            extractedData: extractedData || chatData.extracted_data
          };
          setMessages(prev => [...prev, assistantMessage]);
        } else {
          const errorData = await chatResponse.json().catch(() => ({ detail: "Unknown error" }));
          const errorMsg: Message = {
            id: (Date.now() + 1).toString(),
            role: "assistant",
            content: `❌ Błąd analizy: ${errorData.detail || "Nie udało się przeanalizować dokumentu"}`,
            timestamp: new Date()
          };
          setMessages(prev => [...prev, errorMsg]);
        }
        
        setIsUploading(false);
      } else {
        // Handle images (existing logic)
        const reader = new FileReader();
        reader.onload = async (e) => {
          const base64 = e.target?.result as string;
          const base64Data = base64.split(",")[1];

          // Send to OCR endpoint
          const response = await fetch(`${CERAI_API_URL}/ocr/base64`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json"
            },
            body: JSON.stringify({
              image_base64: base64Data,
              document_type: botType === "accounting" ? "receipt" : "invoice"
            })
          });

          if (!response.ok) {
            const errorData = await response.json().catch(() => ({ detail: "Unknown error" }));
            const errorMessage = errorData.detail || `OCR processing failed: ${response.status} ${response.statusText}`;
            
            const errorMsg: Message = {
              id: Date.now().toString(),
              role: "assistant",
              content: `❌ Błąd OCR: ${errorMessage}\n\nMożesz jednak opisać dokument tekstowo, a ja pomogę Ci go przeanalizować.`,
              timestamp: new Date(),
            };
            setMessages(prev => [...prev, errorMsg]);
            setIsUploading(false);
            return;
          }

          const ocrData = await response.json();

          // Add user message with image
          const userMessage: Message = {
            id: Date.now().toString(),
            role: "user",
            content: "Przeanalizuj ten dokument:",
            timestamp: new Date(),
            images: [base64]
          };

          setMessages(prev => [...prev, userMessage]);

          // Send OCR text to chat for analysis
          const chatResponse = await fetch(`${CERAI_API_URL}/chat`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json"
            },
            body: JSON.stringify({
              message: `Przeanalizuj ten dokument i wyciągnij kluczowe informacje:\n\n${ocrData.text}`,
              bot_type: botType,
              context: context
            })
          });

          if (chatResponse.ok) {
            const chatData = await chatResponse.json();
            
            // Try to parse extracted data from response
            let extractedData = null;
            try {
              const jsonMatch = chatData.response?.match(/\{[\s\S]*\}/);
              if (jsonMatch) {
                extractedData = JSON.parse(jsonMatch[0]);
              }
            } catch (e) {
              if (chatData.extracted_data) {
                extractedData = chatData.extracted_data;
              }
            }

            const assistantMessage: Message = {
              id: (Date.now() + 1).toString(),
              role: "assistant",
              content: chatData.response || "Dokument został przetworzony.",
              timestamp: new Date(),
              extractedData: extractedData || chatData.extracted_data
            };
            setMessages(prev => [...prev, assistantMessage]);
          } else {
            const errorData = await chatResponse.json().catch(() => ({ detail: "Unknown error" }));
            const errorMsg: Message = {
              id: (Date.now() + 1).toString(),
              role: "assistant",
              content: `❌ Błąd analizy: ${errorData.detail || "Nie udało się przeanalizować dokumentu"}`,
              timestamp: new Date()
            };
            setMessages(prev => [...prev, errorMsg]);
          }
          
          setIsUploading(false);
        };
        reader.readAsDataURL(file);
      }
    } catch (error: any) {
      const errorMessage: Message = {
        id: Date.now().toString(),
        role: "assistant",
        content: `Błąd podczas przetwarzania dokumentu: ${error.message}`,
        timestamp: new Date()
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsUploading(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
    }
  };

  const generateReport = async (reportType: string) => {
    setIsLoading(true);
    try {
      const response = await fetch(`${CERAI_API_URL}/reports/generate`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          report_type: reportType,
          bot_type: botType
        })
      });

      if (!response.ok) throw new Error("Failed to generate report");

      const data = await response.json();

      const reportMessage: Message = {
        id: Date.now().toString(),
        role: "assistant",
        content: `Raport wygenerowany: ${data.report_type}`,
        timestamp: new Date(),
        report: data
      };

      setMessages(prev => [...prev, reportMessage]);
    } catch (error: any) {
      const errorMessage: Message = {
        id: Date.now().toString(),
        role: "assistant",
        content: `Błąd: ${error.message}`,
        timestamp: new Date()
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  if (!isOpen) {
    return (
      <button
        onClick={() => setIsOpen(true)}
        className="fixed bottom-20 right-6 lg:bottom-6 w-16 h-16 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 text-white shadow-xl flex items-center justify-center hover:from-blue-600 hover:to-purple-700 transition-all transform hover:scale-110 z-30"
        title="CerAI Assistant"
      >
        <Sparkles className="h-7 w-7" />
      </button>
    );
  }

  return (
    <div className="fixed bottom-20 right-6 lg:bottom-6 w-[500px] h-[700px] rounded-2xl border border-white/10 bg-obsidian-900 shadow-2xl flex flex-col z-30">
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b border-white/10 bg-obsidian-800/50 rounded-t-2xl">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
            <Sparkles className="h-5 w-5 text-white" />
          </div>
          <div>
            <h3 className="font-semibold text-ivory-100">CerAI</h3>
            <p className="text-xs text-ivory-100/60">
              {botType === "accounting" ? "Asystent Księgowy" : "Zarządzanie Klientami"}
            </p>
          </div>
        </div>
        <button
          onClick={() => setIsOpen(false)}
          className="p-1.5 rounded-lg hover:bg-white/10 transition text-ivory-100/70 hover:text-ivory-100"
        >
          <X className="h-5 w-5" />
        </button>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`flex ${message.role === "user" ? "justify-end" : "justify-start"}`}
          >
            <div
              className={`max-w-[80%] rounded-lg px-4 py-2 ${
                message.role === "user"
                  ? "bg-blue-500/20 text-ivory-100"
                  : "bg-white/5 text-ivory-100/90"
              }`}
            >
              {message.images && message.images.map((img, idx) => (
                <img
                  key={idx}
                  src={img}
                  alt="Uploaded document"
                  className="max-w-full rounded mb-2"
                />
              ))}
              {message.extractedData && (
                <div className="mt-3 p-3 bg-white/5 rounded border border-white/10 mb-2">
                  <div className="flex items-center gap-2 mb-3">
                    <FileText className="h-4 w-4 text-blue-400" />
                    <span className="text-xs font-semibold text-ivory-100">Wypełniony formularz faktury</span>
                  </div>
                  <InvoiceForm data={message.extractedData} />
                </div>
              )}
              <p className="whitespace-pre-wrap text-sm">{message.content}</p>
              {message.report && (
                <div className="mt-3 p-3 bg-white/5 rounded border border-white/10">
                  <div className="flex items-center gap-2 mb-2">
                    <BarChart3 className="h-4 w-4 text-blue-400" />
                    <span className="text-xs font-semibold text-ivory-100">Raport</span>
                  </div>
                  <pre className="text-xs text-ivory-100/70 overflow-auto">
                    {JSON.stringify(message.report.data, null, 2)}
                  </pre>
                </div>
              )}
              <p className="text-xs text-ivory-100/40 mt-1">
                {message.timestamp.toLocaleTimeString("pl-PL", { hour: "2-digit", minute: "2-digit" })}
              </p>
            </div>
          </div>
        ))}
        {isLoading && (
          <div className="flex justify-start">
            <div className="bg-white/5 rounded-lg px-4 py-2">
              <Loader2 className="h-4 w-4 animate-spin text-blue-400" />
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Quick Actions */}
      {botType === "accounting" && messages.length > 1 && (
        <div className="px-4 py-2 border-t border-white/10 bg-obsidian-800/30">
          <div className="flex gap-2">
            <button
              onClick={() => generateReport("accounting_summary")}
              disabled={isLoading}
              className="flex-1 text-xs px-3 py-1.5 rounded bg-blue-500/20 text-blue-400 hover:bg-blue-500/30 transition disabled:opacity-50"
            >
              <BarChart3 className="h-3 w-3 inline mr-1" />
              Raport
            </button>
          </div>
        </div>
      )}

      {/* Input */}
      <div className="p-4 border-t border-white/10 bg-obsidian-800/50 rounded-b-2xl">
        <div className="flex gap-2">
          <input
            type="file"
            ref={fileInputRef}
            accept="image/jpeg,image/jpg,image/png,.pdf,application/pdf"
            onChange={handleFileUpload}
            className="hidden"
          />
          <button
            onClick={() => fileInputRef.current?.click()}
            disabled={isUploading || isLoading}
            className="p-2 rounded-lg hover:bg-white/10 transition text-ivory-100/70 hover:text-ivory-100 disabled:opacity-50 flex items-center gap-1"
            title="Dodaj dokument (JPG, PNG, PDF)"
          >
            {isUploading ? (
              <Loader2 className="h-5 w-5 animate-spin" />
            ) : (
              <>
                <Plus className="h-4 w-4" />
                <FileText className="h-4 w-4" />
              </>
            )}
          </button>
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={(e) => e.key === "Enter" && !e.shiftKey && sendMessage()}
            placeholder="Napisz wiadomość..."
            className="flex-1 px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 placeholder:text-ivory-100/40 focus:outline-none focus:ring-2 focus:ring-blue-500/50"
            disabled={isLoading || isUploading}
          />
          <button
            onClick={sendMessage}
            disabled={!input.trim() || isLoading || isUploading}
            className="p-2 rounded-lg bg-blue-500 hover:bg-blue-600 text-white transition disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Send className="h-5 w-5" />
          </button>
        </div>
      </div>
    </div>
  );
}

