import React, { useState } from "react";
import { Icon } from "@iconify/react";

/**
 * Isis Training - Medical & Audio AI Training
 * For: Medical Imaging, Speech Synthesis, Voice Cloning, Music Generation
 */
export const IsisTraining: React.FC = () => {
  const [trainingType, setTrainingType] = useState<"medical" | "voice" | "music">("voice");

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <span className="text-5xl">✨</span>
        <div>
          <h2 className="text-3xl font-bold text-white">Isis - Medical & Audio Training</h2>
          <p className="text-gray-400">Trenuj modele medyczne i syntezę audio</p>
        </div>
      </div>

      {/* Training Type Selection */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Wybierz Typ Treningu</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button
            onClick={() => setTrainingType("medical")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "medical"
                ? "bg-red-500/20 border-red-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:hospital-box" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Medical Imaging</div>
            <div className="text-xs mt-1">MONAI segmentation</div>
          </button>

          <button
            onClick={() => setTrainingType("voice")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "voice"
                ? "bg-purple-500/20 border-purple-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:microphone" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Voice Cloning</div>
            <div className="text-xs mt-1">XTTS fine-tuning</div>
          </button>

          <button
            onClick={() => setTrainingType("music")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "music"
                ? "bg-pink-500/20 border-pink-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:music" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Music Generation</div>
            <div className="text-xs mt-1">MusicGen training</div>
          </button>
        </div>
      </div>

      {/* Medical Imaging Training */}
      {trainingType === "medical" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Medical Imaging Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Imaging Type</label>
              <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-red-500 focus:outline-none">
                <option>CT Scans</option>
                <option>MRI Scans</option>
                <option>X-Ray</option>
                <option>Ultrasound</option>
                <option>Pathology Slides</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Medical Images (DICOM/PNG)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:file-image-outline" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload medical scans</div>
                <div className="text-sm text-gray-400 mt-1">DICOM, PNG, JPG formats supported</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Segmentation Masks (Ground Truth)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:vector-polygon" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload annotation masks</div>
                <div className="text-sm text-gray-400 mt-1">Pixel-wise labels for organs/tumors</div>
              </div>
            </div>

            <div className="bg-red-900/20 border border-red-500/30 rounded-lg p-4">
              <div className="flex gap-2 text-red-400 text-sm">
                <Icon icon="mdi:shield-alert" width={20} className="flex-shrink-0 mt-0.5" />
                <div>
                  <strong>UWAGA:</strong> Dane medyczne muszą być zanonimizowane (HIPAA/GDPR compliant). Usuń wszystkie
                  dane osobowe pacjentów przed uploadem.
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Voice Cloning Training */}
      {trainingType === "voice" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Voice Training Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Audio Recordings (WAV/MP3)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:waveform" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload 10-30 minutes of clean speech</div>
                <div className="text-sm text-gray-400 mt-1">
                  WAV 22050Hz or MP3, minimal background noise
                </div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Transcriptions</label>
              <textarea
                className="w-full px-4 py-3 bg-black/30 border border-white/20 rounded-lg text-white text-sm focus:border-purple-500 focus:outline-none font-mono"
                rows={6}
                placeholder="audio1.wav|To jest przykładowa transkrypcja pierwszego nagrania.
audio2.wav|Druga transkrypcja musi dokładnie odpowiadać audio.
audio3.wav|Każda linia to: nazwa_pliku|tekst"
              />
              <p className="text-xs text-gray-400 mt-1">
                Format: nazwa_pliku.wav|dokładna transkrypcja (jedna linia na plik)
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Voice Speaker Name</label>
              <input
                type="text"
                placeholder="np. 'Anna', 'Jakub', 'Company_Voice'"
                className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none"
              />
            </div>

            <div className="bg-purple-900/20 border border-purple-500/30 rounded-lg p-4">
              <div className="flex gap-2 text-purple-400 text-sm">
                <Icon icon="mdi:information" width={20} className="flex-shrink-0 mt-0.5" />
                <div>
                  <strong>Tips:</strong> Używaj nagrań bez muzyki w tle, wyraźnej mowy, różnych zdań (nie powtarzaj
                  tych samych fraz).
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Music Generation Training */}
      {trainingType === "music" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Music Training Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Music Style/Genre</label>
              <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-pink-500 focus:outline-none">
                <option>Electronic</option>
                <option>Classical</option>
                <option>Jazz</option>
                <option>Rock</option>
                <option>Ambient</option>
                <option>Pop</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Music Files (WAV/MP3)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:music-note" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload 20-50 music tracks</div>
                <div className="text-sm text-gray-400 mt-1">WAV or MP3, similar style/genre</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Text Descriptions (Optional)</label>
              <textarea
                className="w-full px-4 py-3 bg-black/30 border border-white/20 rounded-lg text-white text-sm focus:border-pink-500 focus:outline-none"
                rows={4}
                placeholder="Describe each track:
track1.wav: upbeat electronic with heavy bass
track2.wav: calm ambient with piano
..."
              />
            </div>
          </div>
        </div>
      )}

      {/* Training Configuration */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Konfiguracja</h3>
        <div className="grid grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Epochs</label>
            <input
              type="number"
              defaultValue={10}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Batch Size</label>
            <input
              type="number"
              defaultValue={4}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Learning Rate</label>
            <input
              type="number"
              step="0.0001"
              defaultValue={0.0001}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none"
            />
          </div>
        </div>
      </div>

      {/* Start Button */}
      <button className="w-full px-6 py-4 bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-lg font-bold text-lg hover:opacity-90 transition flex items-center justify-center gap-2">
        <Icon icon="mdi:play" width={24} />
        Start Isis Training
      </button>
    </div>
  );
};

