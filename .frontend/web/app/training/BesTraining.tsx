import React, { useState } from "react";
import { Icon } from "@iconify/react";

/**
 * Bes Training - Audio AI Training
 * For: TTS, Voice Cloning, Music Generation
 */
export const BesTraining: React.FC = () => {
  const [trainingType, setTrainingType] = useState<"tts" | "voice" | "music">("voice");

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <span className="text-5xl">🎵</span>
        <div>
          <h2 className="text-3xl font-bold text-white">Bes - Audio AI Training</h2>
          <p className="text-gray-400">Trenuj modele do generacji głosu, klonowania i muzyki</p>
        </div>
      </div>

      {/* Training Type Selection */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Wybierz Typ Treningu</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button
            onClick={() => setTrainingType("tts")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "tts"
                ? "bg-indigo-500/20 border-indigo-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:account-voice" width={32} className="mx-auto mb-2" />
            <div className="font-bold">TTS (Text-to-Speech)</div>
            <div className="text-xs mt-1">Coqui TTS LoRA</div>
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
            <Icon icon="mdi:music-note" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Music Generation</div>
            <div className="text-xs mt-1">MusicGen style training</div>
          </button>
        </div>
      </div>

      {/* TTS Training */}
      {trainingType === "tts" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Training Data for TTS LoRA</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Audio Samples (WAV, 22050Hz)
              </label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:waveform" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Drop 20-100 audio files here</div>
                <div className="text-sm text-gray-400 mt-1">
                  WAV format, 22050Hz, 5-30 seconds each, same speaker
                </div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Transcriptions</label>
              <textarea
                className="w-full px-4 py-3 bg-black/30 border border-white/20 rounded-lg text-white text-sm focus:border-indigo-500 focus:outline-none"
                rows={4}
                placeholder="Enter text for each audio file (one per line):
audio1.wav|This is the first sentence.
audio2.wav|This is the second sentence.
..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Speaker Name</label>
              <input
                type="text"
                placeholder="np. 'my_voice', 'narrator'"
                className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-indigo-500 focus:outline-none"
              />
              <p className="text-xs text-gray-400 mt-1">Nazwa dla twojego custom voice model</p>
            </div>
          </div>
        </div>
      )}

      {/* Voice Cloning Training */}
      {trainingType === "voice" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Voice Cloning Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Reference Voice Samples</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:account-voice" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload 5-15 clean voice samples</div>
                <div className="text-sm text-gray-400 mt-1">
                  WAV format, 22050Hz, clear speech, same voice
                </div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Transcripts (Paired)</label>
              <textarea
                className="w-full px-4 py-3 bg-black/30 border border-white/20 rounded-lg text-white text-sm focus:border-purple-500 focus:outline-none"
                rows={4}
                placeholder="filename.wav|exact transcript of what is said
sample1.wav|Hello, this is a test of voice cloning.
sample2.wav|The voice should match exactly."
              />
            </div>

            <div className="bg-blue-900/20 border border-blue-500/30 rounded-lg p-4">
              <div className="flex gap-2 text-blue-400 text-sm">
                <Icon icon="mdi:information" width={20} className="flex-shrink-0 mt-0.5" />
                <div>
                  <strong>Tip:</strong> Use clean, noise-free recordings with consistent tone. 
                  5-10 minutes of audio total is recommended.
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Music Generation Training */}
      {trainingType === "music" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Music Style Training Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Music Samples</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:music" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload 10-50 music tracks</div>
                <div className="text-sm text-gray-400 mt-1">
                  WAV/MP3, same genre/style, 30-180 seconds each
                </div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Music Descriptions</label>
              <textarea
                className="w-full px-4 py-3 bg-black/30 border border-white/20 rounded-lg text-white text-sm focus:border-pink-500 focus:outline-none"
                rows={4}
                placeholder="Describe each track's characteristics:
track1.mp3|upbeat electronic dance music with heavy bass
track2.mp3|mellow ambient soundscape with piano
..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Style/Genre Name</label>
              <input
                type="text"
                placeholder="np. 'synthwave', 'lofi_beats'"
                className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-pink-500 focus:outline-none"
              />
              <p className="text-xs text-gray-400 mt-1">Identifier for your music style LoRA</p>
            </div>
          </div>
        </div>
      )}

      {/* Training Configuration */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Konfiguracja LoRA</h3>
        <div className="grid grid-cols-4 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Epochs</label>
            <input
              type="number"
              defaultValue={10}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-indigo-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Learning Rate</label>
            <input
              type="number"
              step="0.0001"
              defaultValue={0.0001}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-indigo-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Batch Size</label>
            <input
              type="number"
              defaultValue={4}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-indigo-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">LoRA Rank</label>
            <input
              type="number"
              defaultValue={16}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-indigo-500 focus:outline-none"
            />
          </div>
        </div>
      </div>

      {/* Audio Quality Settings */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Audio Settings</h3>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Sample Rate</label>
            <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-indigo-500 focus:outline-none">
              <option value="22050">22050 Hz (Default)</option>
              <option value="44100">44100 Hz (High Quality)</option>
              <option value="48000">48000 Hz (Studio)</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Audio Length (sec)</label>
            <input
              type="number"
              defaultValue={10}
              min={5}
              max={30}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-indigo-500 focus:outline-none"
            />
          </div>
        </div>
      </div>

      {/* Start Button */}
      <button className="w-full px-6 py-4 bg-gradient-to-r from-indigo-600 to-purple-600 text-white rounded-lg font-bold text-lg hover:opacity-90 transition flex items-center justify-center gap-2">
        <Icon icon="mdi:play" width={24} />
        Start Bes Training
      </button>
    </div>
  );
};

