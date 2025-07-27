import React, {lazy, Suspense} from "react";
import { Routes, Route, Link } from "react-router-dom";

const Caffe = lazy(() => import("@/modules/accounting/Caffe"));
const Accounting = lazy(() => import("@/modules/accounting/Accounting"));
const Storage = lazy(() => import("@/modules/storage/Storage"));

const config = {
  mainConfig: {
    className: "container mx-auto px-4 py-8",
  },
  navigationCard: {
    className: "bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow duration-200",
  },
  cardTitle: {
    className: "text-xl font-semibold text-gray-900 mb-2",
  },
  cardDescription: {
    className: "text-gray-600 text-sm",
  },
  navigationGrid: {
    className: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-8",
  },
};

export const Admin: React.FC = () => {
  return (
    <main {...config.mainConfig}>
      <Suspense fallback={<div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-gray-900"></div>
      </div>}>
        <Routes>
          <Route path="/" element={<Caffe />} />
          <Route path="/storage/*" element={<Storage />} />
          <Route path="/accounting/*" element={<Accounting />} />
        </Routes>
      </Suspense>
    </main>
  );
};
