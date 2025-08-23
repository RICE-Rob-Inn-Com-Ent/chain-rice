import { Container, Text, Field, Click } from "@/ui/components";

const AdminApp: React.FC = () => {
    return (
      <Container>
        <Text tag="h1" variant="title-1">Hello</Text>
        <Field tag="input" type="text">Hello</Field>
        <Click>Hello</Click>
      </Container>
    );
  };

export default AdminApp;