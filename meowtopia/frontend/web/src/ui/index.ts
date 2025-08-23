import { Click, Container, Field, Text } from "./components";
import { useClick, useContainer, useField, useText } from "./hooks";
import { ContainerConfig, TextConfig, FieldConfig, ClickInterface } from "./interfaces";

// Create a UI type that contains all components and hooks
export const UI = {
  components: {
    Click,
    Container,
    Field,
    Text,
  },
  hooks: {
    useClick,
    useContainer,
    useField,
    useText,
  },
  interfaces: {
    ContainerConfig,
    TextConfig,
    FieldConfig,
    // ClickInterface only refers to a type and cannot be used as a value here.
  },
};

// Export individual items for convenience
export { Click, Container, Field, Text } from "./components";
export { useClick, useContainer, useField, useText } from "./hooks";
export { ContainerConfig, TextConfig, FieldInteface, ClickInterface } from "./interfaces";

export default UI;