export const authStyles = {
  form: "flex flex-col items-center bg-[#111827] w-[70vw] h-[80vh] p-6 rounded-2xl shadow-2xl shadow-primary/50",
  label: "relative flex flex-row items-center gap-2 m-4 text-base text-white",
  input:
    "border-2 border-secondary rounded-lg p-3 bg-white/10 text-white placeholder-white/70 focus:outline-none focus:border-accent transition-colors",
  btnEye:
    "absolute right-3 top-1/2 transform -translate-y-1/2 border-none bg-transparent cursor-pointer text-white hover:text-accent transition-colors",
  checkbox: "w-4 h-4 text-secondary focus:ring-secondary focus:ring-2 rounded",
  submitBtn:
    "bg-secondary text-primary px-6 py-3 rounded-lg font-semibold hover:bg-secondary/80 transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed",
  link: "text-secondary underline cursor-pointer hover:text-accent transition-colors",
  socialButtonsContainer: "flex gap-4 mt-6",
  socialButton:
    "flex items-center gap-2 bg-white text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-100 transition-colors",
  errorMessage:
    "bg-red-50 border-2 border-red-200 text-red-800 px-4 py-3 rounded-lg mb-4 text-center",
  successMessage:
    "bg-green-50 border-2 border-green-200 text-green-800 px-4 py-3 rounded-lg mb-4 text-center",
  switchFormContainer: "mt-4 text-center",
  switchFormText: "text-white",
  policyList:
    "absolute top-0 left-0 right-0 bottom-0 w-full max-w-2xl mx-auto p-4 bg-white rounded-lg mb-4 overflow-y-auto",
  policyItem:
    "block text-lg text-primary underline mb-2 cursor-pointer hover:text-secondary transition-colors",
  policyContent:
    "w-full max-w-3xl mx-auto p-4 bg-white rounded-lg shadow mb-4 prose prose-slate prose-h1:text-2xl prose-h2:text-xl prose-p:mb-2 prose-a:text-primary prose-a:underline",
  backBtn:
    "mt-4 text-secondary underline cursor-pointer hover:text-accent transition-colors",
};
