import React, {lazy} from "react";
import { Routes, Route } from "react-router-dom";
import { Container, ContainerConfig } from "@/components/Container";

const Caffe = lazy(() => import("@/modules/caffe/Caffe"));
const Users = lazy(() => import("@/modules/users/Users"));
const Accounting = lazy(() => import("@/modules/accounting/Accounting"));
const Storage = lazy(() => import("@/modules/storage/Storage"));

export const Admin: React.FC<ContainerConfig> = ({ tag = "main", variant = "card", ...props }) => {
  return (
    <Container tag={tag} variant={variant} {...props}>
        <Routes>
          <Route path="/" element={<Caffe />} />
          <Route path="/users" element={<Users />} />
          <Route path="/storage/*" element={<Storage />} />
          <Route path="/accounting/*" element={<Accounting />} />
        </Routes>
    </Container>
  );
};
