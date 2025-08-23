import React from "react";
import { Container, Text, Field, Click } from "@/ui/components";

const UserApp: React.FC = () => {
  return (
    <Container>
      <Text tag="h1" variant="title-1">Hello World</Text>
      <Field tag="input" type="text" placeholder="Enter text here" />
      <Click>Click me!</Click>
    </Container>
  );
};

export default UserApp;
