import React from "react";
import { Routes, Route } from "react-router-dom";
import { Text } from "@/components/Text";
import { Field } from "@/components/Field";
import { Click } from "@/components/Click";
import { Container, ContainerConfigs } from "@/components/Container";
import { useStorageConfig } from "./configs/storageConfig";

const Storage: React.FC = () => {
  const config = useStorageConfig();

  const StorageMain: React.FC = () => (
    <>
      <Container tag="div" variant="section">
        <Text {...config.pageTitle} />
      </Container>

      <Container variant="card">
        <Click {...config.uploadCard} />
        <Click {...config.downloadCard} />
        <Click {...config.manageCard} />
      </Container>
    </>
  );

  const UploadPage: React.FC = () => (
    <Container variant="loader-global">
      <Container variant="section">
        <Text {...config.pageTitle} />
        <Text {...config.pageDescription} />
      </Container>

      <Container variant="section">
        <Container variant="card">
          <Container tag="form" variant="form" onSubmit={config.handleUploadSubmit}>
            <Text {...config.uploadTitle} />
            
            <Container variant="default">
              <Field {...config.fileField} />
            </Container>
            
            <Container variant="default">
              <Field {...config.descriptionField} />
            </Container>
            
            <Container variant="default">
              <Field {...config.tagsField} />
            </Container>
            
            <Container variant="default">
              <Field {...config.isPublicField} />
            </Container>

            <Container variant="default">
              <Click {...config.uploadButton} />
            </Container>

            <Container variant="default">
              <Click {...config.backButton} />
            </Container>

            {config.errorText && (
              <Container variant="default">
                <Text {...config.errorText} />
              </Container>
            )}

            {config.successText && (
              <Container variant="default">
                <Text {...config.successText} />
              </Container>
            )}
          </Container>
        </Container>
      </Container>
    </Container>
  );

  const DownloadPage: React.FC = () => (
    <Container variant="loader-global">
      <Container variant="section">
        <Text {...config.pageTitle} />
        <Text {...config.pageDescription} />
      </Container>

      <Container variant="section">
        <Container variant="card">
          <Container tag="form" variant="form" onSubmit={config.handleDownloadSubmit}>
            <Text {...config.downloadTitle} />
            
            <Container variant="default">
              <Field {...config.fileIdField} />
            </Container>

            <Container variant="default">
              <Click {...config.downloadButton} />
            </Container>

            <Container variant="default">
              <Click {...config.backButton} />
            </Container>

            {config.errorText && (
              <Container variant="default">
                <Text {...config.errorText} />
              </Container>
            )}

            {config.successText && (
              <Container variant="default">
                <Text {...config.successText} />
              </Container>
            )}
          </Container>
        </Container>
      </Container>
    </Container>
  );

  const ManagePage: React.FC = () => (
    <Container variant="loader-global">
      <Container variant="section">
        <Text {...config.pageTitle} />
        <Text {...config.pageDescription} />
      </Container>

      <Container variant="section">
        <Container variant="card">
          <Container tag="form" variant="form" onSubmit={config.handleManageSubmit}>
            <Text {...config.manageTitle} />
            
            <Container variant="default">
              <Field {...config.manageFileIdField} />
            </Container>

            <Container variant="default">
              <Field {...config.actionField}>
                <option value="delete">Usuń plik</option>
                <option value="info">Informacje o pliku</option>
                <option value="share">Udostępnij plik</option>
              </Field>
            </Container>

            <Container variant="default">
              <Click {...config.manageButton} />
            </Container>

            <Container variant="default">
              <Click {...config.backButton} />
            </Container>

            {config.errorText && (
              <Container variant="highlight">
                <Text {...config.errorText} />
              </Container>
            )}

            {config.successText && (
              <Container variant="highlight">
                <Text {...config.successText} />
              </Container>
            )}
          </Container>
        </Container>
      </Container>
    </Container>
  );

  return (
    <Routes>
      <Route path="/" element={<StorageMain />} />
      <Route path="/upload" element={<UploadPage />} />
      <Route path="/download" element={<DownloadPage />} />
      <Route path="/manage" element={<ManagePage />} />
    </Routes>
  );
};

export default Storage; 